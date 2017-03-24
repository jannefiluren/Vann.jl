

# Add packages

using PyPlot
using DataFrames
using Vann
using DataAssim

# Model choices

snow_choice = TinBasic
hydro_choice = Gr4j

# Filter choices

filter_choice = particle_filter

nens = 100

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

# Run model and filter

st_snow = eval(Expr(:call, snow_choice, tstep, param_snow, frac))
st_hydro = eval(Expr(:call, hydro_choice, tstep, param_hydro))

q_res = eval(Expr(:call, filter_choice, st_snow, st_hydro, prec, tair, epot, q_obs, nens))

# Add results to dataframe

q_sim  = q_res[:, 1]
q_min  = q_res[:, 2]
q_max  = q_res[:, 3]

q_obs = round(q_obs, 2)
q_sim = round(q_sim, 2)
q_min = round(q_min, 2)
q_max = round(q_max, 2)

df_res = DataFrame(date = date, q_obs = q_obs, q_sim = q_sim, q_min = q_min, q_max = q_max)

# Plot results

days_warmup = 3*365

df_res = df_res[days_warmup:end, :]

fig = plt[:figure](figsize = (12,7))

plt[:style][:use]("ggplot")

plt[:plot](df_res[:date], df_res[:q_obs], linewidth = 1.2, color = "k", label = "Observed", zorder = 1)
plt[:fill_between](df_res[:date], df_res[:q_max], df_res[:q_min], facecolor = "r", edgecolor = "r", label = "Simulated", alpha = 0.55, zorder = 2)
plt[:legend]()
