
# Load packages

using Vann
using PyPlot
using DataFrames
using JLD


# Settings

path_inputs = "C:/Work/Studies/vann/data/norway"

epot_choice = epot_monthly
snow_choice = TinBasic
hydro_choice = Gr4j

tstep = 24.0

calib_start = DateTime(2000,09,01)
calib_stop = DateTime(2014,12,31)

valid_start = DateTime(1985,09,01)
valid_stop = DateTime(2000,08,31)


# Select watersheds

dir_all = readdir(path_inputs)

dir_cur = dir_all[143]

print("Calibration for data in $(dir_cur)\n")


# Run for calibration period

# Load data

date, tair, prec, q_obs, frac = load_data("$path_inputs/$dir_cur")

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

  pcorr = (q_sum + 0.5 * epot_sum) / prec_sum

  prec = pcorr * prec

end

# Initilize model

st_snow = eval(Expr(:call, snow_choice, tstep, date[1], frac))
st_hydro = eval(Expr(:call, hydro_choice, tstep, date[1]))

# Run calibration

param_snow, param_hydro = run_model_calib(st_snow, st_hydro, tair, prec, epot, q_obs)

println(param_snow)
println(param_hydro)

# Reinitilize model

st_snow = eval(Expr(:call, snow_choice, tstep, date[1], param_snow, frac))
st_hydro = eval(Expr(:call, hydro_choice, tstep, date[1], param_hydro))

#=init_states(st_snow)
init_states(st_hydro)=#

# Run model with best parameter set

q_sim, st_snow, st_hydro = run_model(st_snow, st_hydro, tair, prec, epot; return_all = true)

# Plot results

plot_sim(st_hydro; q_obs = q_obs)

plot_sim(st_snow)


# Run for validation period

# Load data

date, tair, prec, q_obs, frac = load_data("$path_inputs/$dir_cur")

# Crop data

date, tair, prec, q_obs = crop_data(date, tair, prec, q_obs, valid_start, valid_stop)

# Compute potential evapotranspiration

epot = eval(Expr(:call, epot_choice, date))

# Reinitilize model

st_snow = eval(Expr(:call, snow_choice, tstep, date[1], param_snow, frac))
st_hydro = eval(Expr(:call, hydro_choice, tstep, date[1], param_hydro))

# Precipitation correction step

if isdefined(:pcorr)
  prec = pcorr * prec
end

# Run model with best parameter set

q_sim, st_snow, st_hydro = run_model(st_snow, st_hydro, tair, prec, epot; return_all = true)

# Plot results

plot_sim(st_hydro; q_obs = q_obs)

plot_sim(st_snow)