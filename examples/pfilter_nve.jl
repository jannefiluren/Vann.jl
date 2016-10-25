################################################################################

# Add packages

using RCall
using Distributions
using DataFrames
using Vann

################################################################################

# Settings

path_inputs = "//hdata/fou/jmg/FloodForecasting/Data";
path_save = "//hdata/fou/jmg/FloodForecasting/Pfilter"
path_param = "//hdata/fou/jmg/FloodForecasting/Results"

date_start = Date(2010,08,01);

################################################################################

# Particle filter

function run_filter(prec, tair, q_obs, param_snow, param_hydro, frac, npart)

  srand(1);

  # Number of elevation bands (rows) and time steps (cols)

  nzones = size(prec, 1);
  ntimes = size(prec, 2);

  # Initilize state variables

  st_snow  = [Vann.TinBasicType(param_snow, frac) for i in 1:npart];
  st_hydro = [Vann.Gr4jType(param_hydro, frac) for i in 1:npart];

  for i in eachindex(st_snow)
    st_hydro[i].st = zeros(Float64, 2);
  end

  # Initilize particles

  wk = ones(npart) / npart;

  # Run model

  q_tmp = zeros(Float64, npart);
  q_sim = zeros(Float64, npart, ntimes);

  for itime = 1:ntimes

    for ipart = 1:npart

      perturb_input(st_snow[ipart], prec, tair, itime);

      Vann.snow_model(st_snow[ipart]);

      get_input(st_snow[ipart], st_hydro[ipart]);

      q_sim[ipart, itime] = Vann.hydro_model(st_hydro[ipart]);

    end

    # Run particle filter

    for ipart = 1:npart

      wk[ipart] = pdf( Normal(q_obs[itime], max(0.5*q_obs[itime],0.5) ), q_sim[ipart, itime] ) * wk[ipart];

    end

    if sum(wk) > 0.0
      wk = wk / sum(wk);
    else
      wk = ones(npart) / npart;
    end

    Neff = 1 / sum(wk.^2);

    if round(Int64, Neff) < round(Int64, npart * 0.8)

      println("Resampled at step: $itime")

      indx = Vann.resample(wk);

      st_snow  = [deepcopy(st_snow[i]) for i in indx];
      st_hydro = [deepcopy(st_hydro[i]) for i in indx];

      wk = ones(npart) / npart;

    end

  end

  return(q_sim);

end

################################################################################

# Loop over all watersheds

dir_all = readdir(path_inputs);

for dir_cur in dir_all

  # Load data

  date, tair, prec, q_obs, frac = load_data("$path_inputs/$dir_cur");

  # Crop data

  date, tair, prec, q_obs = crop_data(date, tair, prec, q_obs, date_start);

  # Load parameters

  filename = dir_cur[1:end-4] * "param_snow.txt";
  param_snow = readdlm("$path_param/param_snow/$filename", '\t');
  param_snow = squeeze(param_snow,2);

  filename = dir_cur[1:end-4] * "param_hydro.txt";
  param_hydro = readdlm("$path_param/param_hydro/$filename", '\t');
  param_hydro = squeeze(param_hydro,2);

  # Run model and filter

  npart = 3000;

  q_sim = run_filter(prec, tair, q_obs, param_snow, param_hydro, frac, npart);

  # Plot results

  x_data = collect(1:size(q_sim,2));
  q_min  = vec(minimum(q_sim,1));
  q_max  = vec(maximum(q_sim,1));
  q_mean = vec(mean(q_sim,1));

  df_fs = DataFrame(x = x_data, q_obs = q_obs, q_min = q_min, q_max = q_max, q_mean = q_mean);

  mkpath(path_save);

  file_save = dir_cur[1:end-4];

  R"""
  library(zoo, lib.loc = "C:/Users/jmg/Documents/R/win-library/3.2")
  library(hydroGOF, lib.loc = "C:/Users/jmg/Documents/R/win-library/3.2")
  library(labeling, lib.loc = "C:/Users/jmg/Documents/R/win-library/3.2")
  library(ggplot2, lib.loc = "C:/Users/jmg/Documents/R/win-library/3.2")
  library(yaml, lib.loc="C:/Users/jmg/Documents/R/win-library/3.2")
  library(plotly, lib.loc="C:/Users/jmg/Documents/R/win-library/3.2")
  """

  R"""
  df <- $df_fs
  df$q_obs[df$q_obs == -999] <- NA
  kge <- KGE(df$q_mean, df$q_obs)
  plot_title <- paste('KGE = ', round(kge, digits = 2), sep = '')
  path_save <- $path_save
  file_save <- $file_save
  """

  R"""
  p <- ggplot(df, aes(x))
  p <- p + geom_ribbon(aes(ymin = q_min, ymax = q_max), fill = "deepskyblue1")
  p <- p + geom_line(aes(y = q_obs),linetype="dashed")
  p <- p + theme_bw()
  p <- p + labs(title = plot_title)
  p <- p + labs(x = 'Index')
  p <- p + labs(y = 'Discharge')
  ggsave(file = paste(path_save,'/',file_save,'pfilter.png', sep = ''), width = 30, height = 18, units = 'cm', dpi = 600)
  """

end