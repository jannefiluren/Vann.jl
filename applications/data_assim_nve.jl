
# Add packages

using Vann
using DataAssim
using ExcelReaders
using DataFrames
using PyPlot


# Settings

file_exper  = "C:/Work/Studies/vann/filter_experiments.xlsx"
path_inputs = "C:/Work/Studies/vann/data/norway"
path_save   = "C:/Work/Studies/vann/filter_res"

df_exper = readxlsheet(DataFrame, file_exper, "Filter")

date_start = DateTime(2000,09,01)
date_stop  = DateTime(2008,12,31)


# Run one experiment

function run_single_experiment(path_inputs, path_save, date_start, date_stop, df_exper, i_exper)

  # Get settings

  epot_choice   = df_exper[:Epot][i_exper]
  snow_choice   = df_exper[:Snow][i_exper]
  hydro_choice  = df_exper[:Hydro][i_exper]
  filter_choice = df_exper[:Filter][i_exper]
  nens          = df_exper[:Nens][i_exper]

  nens = convert(Int64, round(nens))

  epot_choice   = parse(epot_choice)
  snow_choice   = parse(snow_choice)
  hydro_choice  = parse(hydro_choice)
  filter_choice = parse(filter_choice)

  # Folder for saving results

  name_experiment = "experiment_" * string(i_exper)

  path_save = joinpath(path_save, name_experiment)

  mkpath(path_save * "/tables")
  mkpath(path_save * "/figures")
  
  # Run for all stations

  run_all_stations(path_inputs, path_save, date_start, date_stop, snow_choice, hydro_choice, filter_choice, nens)

end


# Run over all stations

function run_all_stations(path_inputs, path_save, date_start, date_stop, snow_choice, hydro_choice, filter_choice, nens)

  # Loop over all watersheds

  dir_all = readdir(path_inputs)

  for dir_cur in dir_all

    # Load data

    date, tair, prec, q_obs, frac = load_data("$path_inputs/$dir_cur")

    # Crop data

    date, tair, prec, q_obs = crop_data(date, tair, prec, q_obs, date_start, date_stop)

    # Compute potential evapotranspiration

    epot = epot_monthly(date)

    # Initilize model

    tstep = 24.0

    st_snow = eval(Expr(:call, snow_choice, tstep, date[1], frac))
    st_hydro = eval(Expr(:call, hydro_choice, tstep, date[1]))

    # Run calibration

    param_snow, param_hydro = run_model_calib(st_snow, st_hydro, date, tair, prec, epot, q_obs)
    
    # Run model and filter

    st_snow = eval(Expr(:call, snow_choice, tstep, date[1], param_snow, frac))
    st_hydro = eval(Expr(:call, hydro_choice, tstep,  date[1], param_hydro))

    q_res = eval(Expr(:call, filter_choice, st_snow, st_hydro, prec, tair, epot, q_obs, nens))

    # Add results to dataframe

    q_obs = round(q_obs, 2)
    q_sim = round(q_res[:, 1], 2)
    q_min = round(q_res[:, 2], 2)
    q_max = round(q_res[:, 3], 2)

    df_res = DataFrame(date = date, q_obs = q_obs, q_sim = q_sim, q_min = q_min, q_max = q_max)

    # Save results to txt file

    file_name = joinpath(path_save, "tables", dir_cur[1:end-5] * "_station.txt")

    writetable(file_name, df_res, quotemark = '"', separator = '\t')

    # Plot results

    ioff()

    fig = plt[:figure](figsize = (12,7))

    plt[:style][:use]("ggplot")

    plt[:plot](date, q_obs, linewidth = 1.2, color = "k", label = "Observed", zorder = 1)
    plt[:fill_between](date, q_max, q_min, facecolor = "r", edgecolor = "r", label = "Simulated", alpha = 0.55, zorder = 2)
    plt[:ylabel]("Runoff (mm/day)")

    plt[:legend]()
    
    file_name = joinpath(path_save, "figures", dir_cur[1:end-5] * "_station.png")
    
    savefig(file_name, dpi = 600)
    close(fig)

  end

end


# Run all experiments

for i_exper = 1:size(df_exper, 1)

  run_single_experiment(path_inputs, path_save, date_start, date_stop, df_exper, i_exper)

end