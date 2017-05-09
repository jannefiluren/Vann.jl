# Data assimilation methods

The package contains two classical data assimilation methods: the ensemble
Kalman filter and the particle filter. Both filter can be used with any
combinations of the snow and hydrological models. Select the ensemble
Kalman filter using `enkf_filter` and the particle filter using
`particle_filter`.

## Filter example

```@example
using Vann
using DataAssim
using PyPlot

# Model choices

snow_choice = TinBasic
hydro_choice = Gr4j

# Filter choices

filter_choice = particle_filter

nens = 500

# Load data

path_inputs = Pkg.dir("Vann", "data/atnasjo")

date, tair, prec, q_obs, frac = load_data(path_inputs)

# Compute potential evapotranspiration

epot = epot_zero(date)

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

# Plot results

fig = figure(figsize = (12,7))
plot(date, q_obs, linewidth = 1.2, color = "k", label = "Observed", zorder = 1)
fill_between(date, q_res[:, 3], q_res[:, 2], facecolor = "r", edgecolor = "r", label = "Simulated", alpha = 0.55, zorder = 2)
legend()
nothing # hide
```
