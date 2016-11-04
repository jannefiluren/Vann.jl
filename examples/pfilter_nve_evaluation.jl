################################################################################

# Add packages

using RCall
using Distributions
using DataFrames
using Vann

################################################################################

if is_windows()
  path_inputs = "C:/Users/jmg/Dropbox/Work/VannData/Input";
  path_save   = "C:/Users/jmg/Dropbox/Work/VannData";
  path_param  = "C:/Users/jmg/Dropbox/Work/VannData/201611021050_Results"
end

################################################################################

# Folder for saving results

time_now = Dates.format(now(), "yyyymmddHHMM");

path_save = path_save * "/" * time_now * "_Results";

mkpath(path_save * "/calib_txt")
mkpath(path_save * "/calib_png")
mkpath(path_save * "/valid_txt")
mkpath(path_save * "/valid_png")

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

    if true

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

        println("Resampled at step: $itime")

        indx = Vann.resample(wk);

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

function run_em_all(path_inputs, path_save, path_param, period, date_start, date_stop)

  # Loop over all watersheds

  dir_all = readdir(path_inputs);

  for dir_cur in dir_all

    # Load data

    date, tair, prec, q_obs, frac = load_data("$path_inputs/$dir_cur");

    # Crop data

    date, tair, prec, q_obs = crop_data(date, tair, prec, q_obs, date_start, date_stop);

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

    writetable(string(path_save, "/" * period * "_txt/", file_save, "_station.txt"), df_res, quotemark = '"', separator = '\t');

    # Plot results

    df_res = DataFrame(x = x_data, q_obs = q_obs, q_sim = q_sim, q_min = q_min, q_max = q_max);

    R"""
    library(zoo, lib.loc = "C:/Users/jmg/Documents/R/win-library/3.2")
    library(hydroGOF, lib.loc = "C:/Users/jmg/Documents/R/win-library/3.2")
    library(labeling, lib.loc = "C:/Users/jmg/Documents/R/win-library/3.2")
    library(ggplot2, lib.loc = "C:/Users/jmg/Documents/R/win-library/3.2")
    library(yaml, lib.loc="C:/Users/jmg/Documents/R/win-library/3.2")
    library(plotly, lib.loc="C:/Users/jmg/Documents/R/win-library/3.2")
    """

    R"""
    df <- $df_res
    df$q_obs[df$q_obs == -999] <- NA
    kge <- round(KGE(df$q_sim, df$q_obs), digits = 2)
    nse <- round(NSE(df$q_sim, df$q_obs), digits = 2)
    """

    R"""
    plot_title <- paste('KGE = ', kge, ' NSE = ', nse, sep = '')
    path_save <- $path_save
    file_save <- $file_save
    """

    R"""
    p <- ggplot(df, aes(x))
    p <- p + geom_ribbon(aes(ymin = q_min, ymax = q_max), fill = "deepskyblue1")
    p <- p + geom_line(aes(y = q_obs), colour = "black", size = 1)
    p <- p + geom_line(aes(y = q_sim), colour = "red", size = 0.5)
    p <- p + theme_bw()
    """

    R"""
    p <- p + labs(title = plot_title)
    p <- p + labs(x = 'Index')
    p <- p + labs(y = 'Discharge')
    ggsave(file = paste(path_save,"/",$period,"_png/",file_save,"_pfilter.png", sep = ""), width = 30, height = 18, units = 'cm', dpi = 600)
    """

  end

end


################################################################################

# Run for calibration period

period = "calib";

date_start = Date(2000,09,01);
date_stop  = Date(2014,12,31);

run_em_all(path_inputs, path_save, path_param, period, date_start, date_stop);

# Run for validation period

period = "valid";

date_start = Date(1985,09,01);
date_stop  = Date(2000,08,31);

run_em_all(path_inputs, path_save, path_param, period, date_start, date_stop);
