# Required packages

using Vann
using PyPlot
using DataFrames

# Model choices

snow_choice = TinBasic
hydro_choice = Gr4j

# Load data

path_inputs = Pkg.dir("Vann", "data/atnasjo")

date, tair, prec, q_obs, frac = load_data(path_inputs)

# Compute potential evapotranspiration

epot = epot_zero(date)

# Initilize model

tstep = 1.0

st_snow = eval(Expr(:call, snow_choice, tstep, frac))
st_hydro = eval(Expr(:call, hydro_choice, tstep))

# Run calibration

param_snow, param_hydro = run_model_calib(st_snow, st_hydro, date, tair, prec, epot, q_obs)

println(param_snow)
println(param_hydro)

# Reinitilize model

st_snow = eval(Expr(:call, snow_choice, tstep, param_snow, frac))
st_hydro = eval(Expr(:call, hydro_choice, tstep, param_hydro))

# Run model with best parameter set

q_sim = run_model(st_snow, st_hydro, date, tair, prec, epot)

# Store results in data frame

q_obs = round(q_obs, 2)
q_sim = round(q_sim, 2)

df_res = DataFrame(date = date, q_sim = q_sim, q_obs = q_obs)

# Plot results using rcode

fig = plt[:figure](figsize = (12,7))

plt[:style][:use]("ggplot")

plt[:plot](df_res[:date], df_res[:q_obs], linewidth = 1.2, color = "k", label = "Observed")
plt[:plot](df_res[:date], df_res[:q_sim], linewidth = 1, color = "r", label = "Simulated")
plt[:legend]()
