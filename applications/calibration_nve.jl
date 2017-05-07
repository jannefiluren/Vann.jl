# Load packages

using Vann
using PyPlot
using DataFrames
using JLD

# Settings

path_inputs = "C:/Work/Studies/vann/data_norway"
path_save   = "C:/Work/Studies/vann/"

epot_choice = epot_monthly
snow_choice = TinBasic
hydro_choice = Hbv

tstep = 24.0

calib_start = DateTime(2000,09,01)
calib_stop = DateTime(2014,12,31)

valid_start = DateTime(1985,09,01)
valid_stop = DateTime(2000,08,31)

# Folder for saving results

path_save = path_save * "/calib_norway"

mkpath(path_save * "/calib_txt")
mkpath(path_save * "/calib_png")
mkpath(path_save * "/valid_txt")
mkpath(path_save * "/valid_png")
mkpath(path_save * "/param_snow")
mkpath(path_save * "/param_hydro")
mkpath(path_save * "/model_data")

# Loop over all watersheds

dir_all = readdir(path_inputs)

for dir_cur in dir_all

  print("Calibration for data in $(dir_cur)\n")

  # Run for calibration period

  # Load data

  try
    date, tair, prec, q_obs, frac = load_data("$path_inputs/$dir_cur")
  catch
    print("Unable to read files in directory $(dir_cur)\n")
    continue
  end

  # Crop data

  date, tair, prec, q_obs = crop_data(date, tair, prec, q_obs, calib_start, calib_stop)

  # Compute potential evapotranspiration

  epot = eval(Expr(:call, epot_choice, date))

  # Precipitation correction step

  if ~all(isnan(q_obs))

    ikeep = ~isnan(q_obs)

    prec_tmp = mean(prec,1)
    
    prec_sum = sum(prec_tmp[ikeep])
    q_sum = sum(q_obs[ikeep])
    epot_sum = sum(epot)

    pcorr = (q_sum + 0.5*epot_sum) / prec_sum

    prec = pcorr * prec

  end

  # Initilize model

  st_snow = eval(Expr(:call, snow_choice, tstep, date[1], frac))
  st_hydro = eval(Expr(:call, hydro_choice, tstep, date[1]))

  # Run calibration

  param_snow, param_hydro = run_model_calib(st_snow, st_hydro, date, tair, prec, epot, q_obs)

  println(param_snow)
  println(param_hydro)

  # Reinitilize model

  st_snow = eval(Expr(:call, snow_choice, tstep, date[1], param_snow, frac))
  st_hydro = eval(Expr(:call, hydro_choice, tstep, date[1], param_hydro))

  # Run model with best parameter set

  q_sim, st_snow, st_hydro = run_model(st_snow, st_hydro, date, tair, prec, epot; return_all = true)

  # Store results in data frame

  q_obs = round(q_obs, 2)
  q_sim = round(q_sim, 2)

  df_res = DataFrame(date = Dates.format(date,"yyyy-mm-dd"), q_sim = q_sim, q_obs = q_obs)

  # Save results to txt file

  file_save = dir_cur[1:end-5]

  writetable(string(path_save, "/calib_txt/", file_save, "_station.txt"), df_res, quotemark = '"', separator = '\t')

  # Plot results

  ioff()

  file_name = string(path_save, "/calib_png/", file_save, "_hydro.png")

  plot_sim(st_hydro; q_obs = q_obs, file_name = file_name)

  file_name = string(path_save, "/calib_png/", file_save, "_snow.png")

  plot_sim(st_snow; file_name = file_name)

  # Run for validation period

  # Reload data

  date, tair, prec, q_obs, frac = load_data("$path_inputs/$dir_cur")

  # Crop data

  date, tair, prec, q_obs = crop_data(date, tair, prec, q_obs, valid_start, valid_stop)

  # Compute potential evapotranspiration

  epot = eval(Expr(:call, epot_choice, date))

  # Precipitation correction step

  if isdefined(:pcorr)
    prec = pcorr * prec
  end

  # Reinitilize model

  st_snow = eval(Expr(:call, snow_choice, tstep, date[1], param_snow, frac))
  st_hydro = eval(Expr(:call, hydro_choice, tstep, date[1], param_hydro))

  # Run model with best parameter set

  q_sim, st_snow, st_hydro = run_model(st_snow, st_hydro, date, tair, prec, epot; return_all = true)

  # Store results in data frame

  q_obs = round(q_obs, 2)
  q_sim = round(q_sim, 2)

  df_res = DataFrame(date = Dates.format(date,"yyyy-mm-dd"), q_sim = q_sim, q_obs = q_obs)

  # Save results to txt file

  file_save = dir_cur[1:end-5]

  writetable(string(path_save, "/valid_txt/", file_save, "_station.txt"), df_res, quotemark = '"', separator = '\t')

  # Plot results

  ioff()

  file_name = string(path_save, "/valid_png/", file_save, "_hydro.png")

  plot_sim(st_hydro; q_obs = q_obs, file_name = file_name)

  file_name = string(path_save, "/valid_png/", file_save, "_snow.png")

  plot_sim(st_snow; file_name = file_name)

  # Save parameter values

  writedlm(path_save * "/param_snow/" * file_save * "_param_snow.txt", param_snow)
  writedlm(path_save * "/param_hydro/" * file_save * "_param_hydro.txt", param_hydro)

  st_snow = eval(Expr(:call, snow_choice, tstep, date[1], param_snow, frac))
  st_hydro = eval(Expr(:call, hydro_choice, tstep, date[1], param_hydro))

  jldopen(path_save * "/model_data/" * file_save * "_modeldata.jld", "w") do file
    addrequire(file, Vann)
    write(file, "st_snow", st_snow)
    write(file, "st_hydro", st_hydro)
  end

end
