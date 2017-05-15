
# Add packages

using Vann
using DataAssim
using ExcelReaders
using DataFrames
using PyPlot

# Settings

file_exper  = "C:/Work/Studies/vann/experiments.xlsx"
path_inputs = "C:/Work/Studies/vann/data/norway"
path_save   = "C:/Work/Studies/vann/filter_forecast"

df_exper = readxlsheet(DataFrame, file_exper, "Filter")

# Run one experiment

function run_single_experiment(path_inputs, path_save, df_exper, i_exper)

  # Folder for saving results

  path_save = joinpath(path_save, "experiment_" * string(i_exper))

  mkpath(path_save * "/tables")
  mkpath(path_save * "/figures")

  # Get settings

  opt = Dict()

  opt["epot_choice"]   = parse(df_exper[:epot_choice][i_exper])
  opt["snow_choice"]   = parse(df_exper[:snow_choice][i_exper])
  opt["hydro_choice"]  = parse(df_exper[:hydro_choice][i_exper])

  opt["filter_choice"] = parse(df_exper[:filter_choice][i_exper])
  opt["nens"]          = round(Int64, df_exper[:nens][i_exper])
  opt["test_forecast"] = parse(df_exper[:test_forecast][i_exper])

  opt["warmup"]        = round(Int64, df_exper[:warmup][i_exper])
  opt["tstep"]         = df_exper[:tstep][i_exper]
  opt["date_start"]    = df_exper[:date_start][i_exper]
  opt["date_stop"]     = df_exper[:date_stop][i_exper]

  opt["path_inputs"]   = path_inputs
  opt["path_save"]     = path_save

  # Run for all stations

  run_all_stations(opt)

end

# Run over all stations

function run_all_stations(opt)

  # Empty dataframes for summary statistics

  df_summary = DataFrame()

  header = [:Station :NSE_CAL :KGE_CAL :NSE_DA :KGE_DA]

  for item in header
    df_summary[item] = []
  end 

  df_forecast = DataFrame()

  header = [:Station :NSE1 :NSE2 :NSE3 :NSE4 :NSE5 :NSE6 :NSE7 :KGE1 :KGE2 :KGE3 :KGE4 :KGE5 :KGE6 :KGE7]

  for item in header
    df_forecast[item] = []
  end 
  
  # Loop over all watersheds

  dir_all = readdir(opt["path_inputs"])

  for dir_cur in dir_all

    try

      # Load data

      date, tair, prec, q_obs, frac = load_data("$(opt["path_inputs"])/$dir_cur")

      # Crop data

      date, tair, prec, q_obs = crop_data(date, tair, prec, q_obs, opt["date_start"], opt["date_stop"])

      # Compute potential evapotranspiration

      epot = eval(Expr(:call, opt["epot_choice"], date))

      # Precipitation correction step

      if sum(~isnan(q_obs)) > (3*365)

        ikeep = ~isnan(q_obs)

        prec_tmp = sum(prec .* repmat(frac, 1, size(prec,2)), 1)
        
        prec_sum = sum(prec_tmp[ikeep])
        q_sum = sum(q_obs[ikeep])
        epot_sum = sum(epot[ikeep])

        pcorr = (q_sum + 0.5 * epot_sum) / prec_sum

        prec = pcorr * prec

      else

        warn("Not enough runoff data for calibration (see folder $dir_cur)")
        continue

      end

      # Initilize model

      st_snow = eval(Expr(:call, opt["snow_choice"], opt["tstep"], date[1], frac))
      st_hydro = eval(Expr(:call, opt["hydro_choice"], opt["tstep"], date[1]))

      # Run calibration

      param_snow, param_hydro = run_model_calib(st_snow, st_hydro, date, tair, prec, epot, q_obs;
                                                warmup = opt["warmup"])

      # Run model with optimal parameters

      st_snow = eval(Expr(:call, opt["snow_choice"], opt["tstep"], date[1], param_snow, frac))
      st_hydro = eval(Expr(:call, opt["hydro_choice"], opt["tstep"], date[1], param_hydro))

      q_cal = run_model(st_snow, st_hydro, date, tair, prec, epot)

      # Run model with filter filter

      st_snow = eval(Expr(:call, opt["snow_choice"], opt["tstep"], date[1], param_snow, frac))
      st_hydro = eval(Expr(:call, opt["hydro_choice"], opt["tstep"], date[1], param_hydro))

      kw_args = Expr(:kw, :test_forecast, opt["test_forecast"])

      q_da, q_sim_forecast, q_obs_forecast = eval(Expr(:call, opt["filter_choice"], st_snow, st_hydro, prec, tair, epot, q_obs, opt["nens"], kw_args))
    
      # Add data to summary tables

      station = dir_cur[1:end-5]
      nse_cal = nse(q_cal[opt["warmup"]:end], q_obs[opt["warmup"]:end])
      kge_cal = kge(q_cal[opt["warmup"]:end], q_obs[opt["warmup"]:end])
      nse_da  = nse(q_da[opt["warmup"]:end, 1], q_obs[opt["warmup"]:end])
      kge_da  = kge(q_da[opt["warmup"]:end, 1], q_obs[opt["warmup"]:end])

      push!(df_summary, [station; nse_cal; kge_cal; nse_da; kge_da])

      nse_forecast = [nse(q_sim_forecast[opt["warmup"]:end, i], q_obs_forecast[opt["warmup"]:end, i]) for i in 1:size(q_sim_forecast, 2)]
      kge_forecast = [kge(q_sim_forecast[opt["warmup"]:end, i], q_obs_forecast[opt["warmup"]:end, i]) for i in 1:size(q_sim_forecast, 2)]

      push!(df_forecast, [station; nse_forecast; kge_forecast])
      
      # Add time series to file

      q_obs = round(q_obs, 2)
      q_sim = round(q_da[:, 1], 2)
      q_min = round(q_da[:, 2], 2)
      q_max = round(q_da[:, 3], 2)

      df_res = DataFrame(date = date, q_obs = q_obs, q_sim = q_sim, q_min = q_min, q_max = q_max)

      file_name = joinpath(opt["path_save"], "tables", dir_cur[1:end-5] * "_station.txt")

      writetable(file_name, df_res, quotemark = '"', separator = '\t')

      # Save plots

      ioff()

      fig = plt[:figure](figsize = (12,7))

      plt[:style][:use]("ggplot")

      plt[:plot](date, q_obs, linewidth = 1.2, color = "k", label = "Observed", zorder = 1)
      plt[:fill_between](date, q_max, q_min, facecolor = "r", edgecolor = "r", label = "Simulated", alpha = 0.55, zorder = 2)
      plt[:ylabel]("Runoff (mm/day)")

      plt[:legend]()
      
      file_name = joinpath(opt["path_save"], "figures", dir_cur[1:end-5] * "_station.png")
      
      savefig(file_name, dpi = 600)
      close(fig)

    catch

      info("Unable to run files in directory $(dir_cur)\n")

    end

  end

  # Write summary tables to files

  writetable(string(opt["path_save"], "/summary_table.txt"), df_summary, quotemark = '"', separator = '\t')
  writetable(string(opt["path_save"], "/forecast_table.txt"), df_forecast, quotemark = '"', separator = '\t')

end


# Run all experiments

for i_exper = 1:size(df_exper, 1)

  run_single_experiment(path_inputs, path_save, df_exper, i_exper)

end