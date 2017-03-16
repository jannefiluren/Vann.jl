#!/home/jmg/Julia/bin/julia


################################################################################

# Add packages

using RCall
using Distributions
using DataFrames
using Vann
using DataAssim


################################################################################

path_inputs = "//hdata/fou/jmg/FloodForecasting/Data";
path_save   = "//hdata/fou/jmg/FloodForecasting/Operational";
path_param  = "//hdata/fou/jmg/FloodForecasting/201611021050_Results"

################################################################################

# Folder for saving results

mkpath(path_save * "/plots")
mkpath(path_save * "/tables")

################################################################################

# Perturb input data for snow model

function perturb_input(st_snow, prec, tair, itime)

  n = Uniform(0.5, 1.5);
  prec_noise = rand(n, 1);

  n = Normal(0.0, 2);
  tair_noise = rand(n, 1);

  # Assign inputs to snow model

  for izone in eachindex(st_snow.prec)

    st_snow.prec[izone] = prec[izone, itime] * prec_noise[1];
    st_snow.tair[izone] = tair[izone, itime] + tair_noise[1];

  end

end

################################################################################

# Particle filter

function run_filter(prec, tair, epot, q_obs, param_snow, param_hydro, frac, npart)

  srand(1);

  # Number of elevation bands (rows) and time steps (cols)

  nzones = size(prec, 1);
  ntimes = size(prec, 2);

  # Initilize state variables

  st_snow  = [TinBasicType(param_snow, frac) for i in 1:npart];
  st_hydro = [Gr4jType(param_hydro, frac) for i in 1:npart];

  for i in eachindex(st_snow)
    st_hydro[i].st = zeros(Float64, 2);
  end

  # Initilize particles

  wk = ones(npart) / npart;

  # Run model

  q_sim = zeros(Float64, npart);
  q_res = zeros(Float64, ntimes, 3);

  for itime = 1:ntimes

    for ipart = 1:npart

      perturb_input(st_snow[ipart], prec, tair, itime);

      snow_model(st_snow[ipart]);

      get_input(st_snow[ipart], st_hydro[ipart], epot, itime);

      q_sim[ipart] = hydro_model(st_hydro[ipart]);

    end

    # Run particle filter

    if q_obs[itime] >= 0

      for ipart = 1:npart

        wk[ipart] = pdf(Normal(q_obs[itime], max(0.1 * q_obs[itime], 0.1)), q_sim[ipart]) * wk[ipart];

      end

      if sum(wk) > 0.0
        wk = wk / sum(wk);
      else
        wk = ones(npart) / npart;
      end

      # Perform resampling

      Neff = 1 / sum(wk.^2);

      if round(Int64, Neff) < round(Int64, npart * 0.5)

        println("Perform resampling at $itime")

        indx = resample(wk);

        st_snow  = [deepcopy(st_snow[i]) for i in indx];
        st_hydro = [deepcopy(st_hydro[i]) for i in indx];

        wk = ones(npart) / npart;

      end

    end

    # Store results

    q_res[itime, 1] = sum(wk .* q_sim);
    q_res[itime, 2] = minimum(q_sim);
    q_res[itime, 3] = maximum(q_sim);

  end

  return(q_res);

end

################################################################################

function run_em_all(path_inputs, path_save, path_param, date_start)

  # Loop over all watersheds

  dir_all = readdir(path_inputs);

  for dir_cur in dir_all

    # Load data

    date, tair, prec, q_obs, frac = load_data("$path_inputs/$dir_cur");

    # Crop data

    date, tair, prec, q_obs = crop_data(date, tair, prec, q_obs, date_start);

    # Compute potential evapotranspiration

    epot = epot_zero(date);

    # Load parameters

    filename = dir_cur[1:end-4] * "param_snow.txt";
    param_snow = readdlm("$path_param/param_snow/$filename", '\t');
    param_snow = squeeze(param_snow,2);

    filename = dir_cur[1:end-4] * "param_hydro.txt";
    param_hydro = readdlm("$path_param/param_hydro/$filename", '\t');
    param_hydro = squeeze(param_hydro,2);

    # Run model and filter

    npart = 3000;

    q_res = run_filter(prec, tair, epot, q_obs, param_snow, param_hydro, frac, npart);

    # Add results to dataframe

    x_data = collect(1:size(q_res,1));
    q_sim  = q_res[:, 1];
    q_min  = q_res[:, 2];
    q_max  = q_res[:, 3];

    q_obs = round(q_obs, 2);
    q_sim = round(q_sim, 2);
    q_min = round(q_min, 2);
    q_max = round(q_max, 2);

    df_res = DataFrame(x = x_data, date = date, q_obs = q_obs, q_sim = q_sim, q_min = q_min, q_max = q_max);

    # Save results to txt file

    file_save = dir_cur[1:end-5];

    writetable(string(path_save, "/tables/", file_save, "_station.txt"), df_res, quotemark = '"', separator = '\t');

    # Plot results

    df_res = DataFrame(date = Dates.format(date,"yyyy-mm-dd"), q_obs = q_obs, q_sim = q_sim, q_min = q_min, q_max = q_max);

    df_res = df_res[end-365:end, :];

    R"""
    library(zoo)
    library(hydroGOF)
    library(labeling)
    library(ggplot2)

    df <- $df_res
    df$date <- as.Date(df$date)
    df$q_obs[df$q_obs == -999] <- NA
    kge <- round(KGE(df$q_sim, df$q_obs), digits = 2)
    nse <- round(NSE(df$q_sim, df$q_obs), digits = 2)

    plot_title <- paste('KGE = ', kge, ', NSE = ', nse, ', Generated = ', Sys.time(), sep = '')
    path_save <- $path_save
    file_save <- $file_save

    p <- ggplot(df, aes(date))
    p <- p + geom_ribbon(aes(ymin = q_min, ymax = q_max), fill = "deepskyblue1")
    p <- p + geom_line(aes(y = q_obs), colour = "black", size = 1)
    p <- p + geom_line(aes(y = q_sim), colour = "red", size = 0.5)
    p <- p + geom_vline(aes(xintercept = as.numeric(Sys.Date())), linetype = 2)
    p <- p + theme_bw()

    p <- p + labs(title = plot_title)
    p <- p + labs(x = 'Date')
    p <- p + labs(y = 'Discharge (mm/day)')
    ggsave(file = paste(path_save,"/plots/",file_save,"_pfilter.png", sep = ""), width = 25, height = 16, units = 'cm', dpi = 600)
    """

  end

end


################################################################################

# Run particle filter

date_start = Date(2013,09,01);

run_em_all(path_inputs, path_save, path_param, date_start);
