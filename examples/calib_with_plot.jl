
using Tmp
using RCall
using DataFrames
import BlackBoxOptim: best_candidate


################################################################################

# Loop over all watersheds

dir_all = readdir("//hdata/fou/jmg/FloodForecasting/Data/");

for dir_curr in dir_all

  # Load data

  date, tair, prec, q_obs, frac = load_data("//hdata/fou/jmg/FloodForecasting/Data/$dir_curr");

  # Crop data

  date, tair, prec, q_obs = crop_data(date, tair, prec, q_obs, Date(1995,10,01), Date(2015,09,30));

  # Initilize model

  st_snow = TinBasicType(frac);
  st_hydro = Gr4jType(frac);

  # Run calibration

  res = run_model_calib(st_snow, st_hydro, date, tair, prec, q_obs);

  # Get optimal parameters

  param_opt = best_candidate(res);

  # Reinitilize model

  param_snow  = param_opt[1:length(st_snow.param)]
  param_hydro = param_opt[length(st_snow.param)+1:end]

  st_snow  = TinBasicType(param_snow, frac);
  st_hydro = Gr4jType(param_hydro, frac);

  # Run model with best parameter Select

  q_sim = run_model(st_snow, st_hydro, date, tair, prec);

  # Store results in data frame

  q_obs = round(q_obs, 2);
  q_sim = round(q_sim, 2);

  df_txt = DataFrame(date = date, q_sim = q_sim);
  df_fig = DataFrame(x = collect(1:length(date)), q_sim = q_sim, q_obs = q_obs);

  # Folder for saving results

  path_save = string("C:/Users/jmg/Desktop/outputs")

  mkpath(path_save * "/txt")
  mkpath(path_save * "/png")

  # Save results to txt file

  file_save = dir_curr[1:end-5]

  writetable(string(path_save, "/txt/", file_save, "_station.txt"), df_txt, quotemark = '"', separator = '\t')

  # Plot results using rcode

  R"""
  library(zoo, lib.loc='C:/Users/jmg/Documents/R/win-library/3.2')
  library(hydroGOF, lib.loc='C:/Users/jmg/Documents/R/win-library/3.2')
  library(labeling, lib.loc='C:/Users/jmg/Documents/R/win-library/3.2')
  library(ggplot2, lib.loc='C:/Users/jmg/Documents/R/win-library/3.2')
  """

  R"""
  df <- $df_fig
  df$q_obs[df$q_obs == -999] <- NA
  kge <- KGE(df$q_sim, df$q_obs)
  plot_title <- paste('KGE = ', round(kge, digits = 2), sep = '')
  path_save <- $path_save
  file_save <- $file_save
  """

  R"""
  p <- ggplot(df, aes(x))
  p <- p + geom_line(aes(y = q_sim),colour = 'red', size = 0.5)
  p <- p + geom_line(aes(y = q_obs),colour = 'blue', size = 0.5)
  p <- p + theme_bw()
  p <- p + labs(title = plot_title)
  p <- p + labs(x = 'Index')
  p <- p + labs(y = 'Discharge')
  ggsave(file = paste(path_save,'/png/',file_save,'_station.png', sep = ''), width = 30, height = 18, units = 'cm', dpi = 600)
  """

end
