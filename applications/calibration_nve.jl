# Load packages

using Vann
using PyPlot
using DataFrames
using ExcelReaders
using JLD
using CSV


# Settings

file_exper  = "C:/Work/Studies/vann/experiments.xlsx"
path_inputs = "C:/Work/Studies/vann/data/norway"
path_save   = "C:/Work/Studies/vann/calib_res"

df_exper = readxlsheet(DataFrame, file_exper, "Calib")


# Run one experiment

function run_single_experiment(path_inputs, path_save, df_exper, i_exper)

  # Folder for saving results

  name_experiment = "experiment_" * string(i_exper)

  path_save = joinpath(path_save, name_experiment)

  mkpath(path_save * "/calib_txt")
  mkpath(path_save * "/calib_png")
  mkpath(path_save * "/valid_txt")
  mkpath(path_save * "/valid_png")
  mkpath(path_save * "/param_snow")
  mkpath(path_save * "/param_hydro")
  mkpath(path_save * "/model_data")

  # Get settings

  opt = Dict()

  opt[:epot_choice]  = parse(df_exper[:Epot][i_exper])
  opt[:snow_choice]  = parse(df_exper[:Snow][i_exper])
  opt[:hydro_choice] = parse(df_exper[:Hydro][i_exper])
  
  opt[:force_states] = parse(df_exper[:force_states][i_exper])
  
  opt[:calib_start] = df_exper[:calib_start][i_exper]
  opt[:calib_stop]  = df_exper[:calib_stop][i_exper]
  opt[:valid_start] = df_exper[:valid_start][i_exper]
  opt[:valid_stop]  = df_exper[:valid_stop][i_exper]

  opt[:tstep] = df_exper[:tstep][i_exper]

  opt[:path_save] = path_save
  opt[:path_inputs] = path_inputs

  # Run for all stations

  calib_all_stations(opt)

end


# Calibrate all stations for one experiment

function calib_all_stations(opt)

  # Empty dataframes for summary statistics

  df_calib = DataFrame(Station = String[], NSE = Float64[], KGE = Float64[])
  df_valid = DataFrame(Station = String[], NSE = Float64[], KGE = Float64[])

  # Loop over all watersheds

  dir_all = readdir(opt[:path_inputs])

  for dir_cur in dir_all

    # Only run calibration for watersheds without glaciers

    df_meta = CSV.read("$(opt[:path_inputs])/$dir_cur/metadata.txt", delim = ";")

    perc_glacier = df_meta[:perc_glacier]

    if perc_glacier[1].value < 0.5

      print("Calibration for data in $(dir_cur)\n")

      # Run for calibration period

      # Load data

      try
        date, tair, prec, q_obs, frac = load_data("$(opt[:path_inputs])/$dir_cur")
      catch
        info("Unable to read files in directory $(dir_cur)\n")
        continue
      end

      # Crop data

      date, tair, prec, q_obs = crop_data(date, tair, prec, q_obs, opt[:calib_start], opt[:calib_stop])

      # Compute potential evapotranspiration

      epot = eval(Expr(:call, opt[:epot_choice], date))

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

      st_snow = eval(Expr(:call, opt[:snow_choice], opt[:tstep], date[1], frac))
      st_hydro = eval(Expr(:call, opt[:hydro_choice], opt[:tstep], date[1]))

      # Run calibration

      param_snow, param_hydro = run_model_calib(st_snow, st_hydro, date, tair, prec, epot, q_obs;
                                                force_states = opt[:force_states])

      println("Snow model parameters: $param_snow")
      println("Hydro model parameters: $param_hydro")

      # Reinitilize model

      st_snow = eval(Expr(:call, opt[:snow_choice], opt[:tstep], date[1], param_snow, frac))
      st_hydro = eval(Expr(:call, opt[:hydro_choice], opt[:tstep], date[1], param_hydro))

      # Run model with best parameter set

      q_sim, st_snow, st_hydro = run_model(st_snow, st_hydro, date, tair, prec, epot; return_all = true)
      
      # Store results in data frame

      q_obs = round(q_obs, 2)
      q_sim = round(q_sim, 2)

      df_res = DataFrame(date = Dates.format(date,"yyyy-mm-dd"), q_sim = q_sim, q_obs = q_obs)

      # Save results to txt file

      file_save = dir_cur[1:end-5]

      writetable(string(opt[:path_save], "/calib_txt/", file_save, "_station.txt"), df_res, quotemark = '"', separator = '\t')

      # Plot results

      ioff()

      file_name = string(opt[:path_save], "/calib_png/", file_save, "_hydro.png")

      plot_sim(st_hydro; q_obs = q_obs, file_name = file_name)

      file_name = string(opt[:path_save], "/calib_png/", file_save, "_snow.png")

      plot_sim(st_snow; file_name = file_name)

      # Compute summary statistics

      station = dir_cur[1:end-5]
      kge_res = kge(q_sim[3*365:end], q_obs[3*365:end])
      nse_res = nse(q_sim[3*365:end], q_obs[3*365:end])

      push!(df_calib, [station nse_res kge_res])

      # Run for validation period

      # Reload data

      date, tair, prec, q_obs, frac = load_data("$(opt[:path_inputs])/$dir_cur")
      
      # Crop data

      date, tair, prec, q_obs = crop_data(date, tair, prec, q_obs, opt[:valid_start], opt[:valid_stop])
      
      # Compute potential evapotranspiration

      epot = eval(Expr(:call, opt[:epot_choice], date))
            
      # Reinitilize model

      st_snow = eval(Expr(:call, opt[:snow_choice], opt[:tstep], date[1], param_snow, frac))
      st_hydro = eval(Expr(:call, opt[:hydro_choice], opt[:tstep], date[1], param_hydro))

      # Precipitation correction step

      prec = pcorr * prec
      
      # Run model with best parameter set

      q_sim, st_snow, st_hydro = run_model(st_snow, st_hydro, date, tair, prec, epot; return_all = true)

      # Store results in data frame

      q_obs = round(q_obs, 2)
      q_sim = round(q_sim, 2)

      df_res = DataFrame(date = Dates.format(date,"yyyy-mm-dd"), q_sim = q_sim, q_obs = q_obs)

      # Save results to txt file

      file_save = dir_cur[1:end-5]

      writetable(string(opt[:path_save], "/valid_txt/", file_save, "_station.txt"), df_res, quotemark = '"', separator = '\t')

      # Plot results

      ioff()

      file_name = string(opt[:path_save], "/valid_png/", file_save, "_hydro.png")

      plot_sim(st_hydro; q_obs = q_obs, file_name = file_name)

      file_name = string(opt[:path_save], "/valid_png/", file_save, "_snow.png")

      plot_sim(st_snow; file_name = file_name)

      # Save parameter values

      writedlm(opt[:path_save] * "/param_snow/" * file_save * "_param_snow.txt", param_snow)
      writedlm(opt[:path_save] * "/param_hydro/" * file_save * "_param_hydro.txt", param_hydro)

      st_snow = eval(Expr(:call, opt[:snow_choice], opt[:tstep], date[1], param_snow, frac))
      st_hydro = eval(Expr(:call, opt[:hydro_choice], opt[:tstep], date[1], param_hydro))

      jldopen(opt[:path_save] * "/model_data/" * file_save * "_modeldata.jld", "w") do file
        addrequire(file, Vann)
        write(file, "st_snow", st_snow)
        write(file, "st_hydro", st_hydro)
      end

      # Compute summary statistics

      station = dir_cur[1:end-5]
      kge_res = kge(q_sim[3*365:end], q_obs[3*365:end])
      nse_res = nse(q_sim[3*365:end], q_obs[3*365:end])

      push!(df_valid, [station nse_res kge_res])

    end

  end

  writetable(string(opt[:path_save], "/summary_calib_period.txt"), df_calib, quotemark = '"', separator = '\t')
  writetable(string(opt[:path_save], "/summary_valid_period.txt"), df_valid, quotemark = '"', separator = '\t')

end

# Run all experiments

for i_exper = 1:size(df_exper, 1)

  run_single_experiment(path_inputs, path_save, df_exper, i_exper)

end

