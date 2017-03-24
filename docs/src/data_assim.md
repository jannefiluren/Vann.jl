# Data assimilation methods

The package contains two classical data assimilation methods; the ensemble
Kalman filter and the particle filter. Both filter can be used with any
combinations of the snow and hydrological models. Select the ensemble
Kalman filter using `enkf_filter` and the particle filter using
`particle_filter`.

## Filter example

```@example

using Vann
using DataAssim

# Model choices

snow_choice = TinBasic
hydro_choice = Gr4j

# Filter choices

filter_choice = enkf_filter

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
nothing # hide
```
