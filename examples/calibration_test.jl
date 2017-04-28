# Required packages

using Vann
using PyPlot
using DataFrames

# Load data

path_inputs = Pkg.dir("Vann", "data/atnasjo")

date, tair, prec, q_obs, frac = load_data(path_inputs)

# Compute potential evapotranspiration

epot = epot_zero(date)

# Model choices

snow_choice = TinStandard
hydro_choice = Gr4j

tstep = 24.0

time = date[1]

st_snow = eval(Expr(:call, snow_choice, tstep, time, frac))
st_hydro = eval(Expr(:call, hydro_choice, tstep, time))

# Run calibration

param_snow, param_hydro = run_model_calib(st_snow, st_hydro, date, tair, prec, epot, q_obs)

println(param_snow)
println(param_hydro)

# Reinitilize model

st_snow = eval(Expr(:call, snow_choice, tstep, time, param_snow, frac))
st_hydro = eval(Expr(:call, hydro_choice, tstep, time, param_hydro))

# Run model with best parameter set

q_sim, snow_out, hydro_out = run_model(st_snow, st_hydro, date, tair, prec, epot; return_all = true)

# Plot results

plot_sim(snow_out)
plot_sim(hydro_out)
