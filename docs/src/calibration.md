# Model calibration

The following example illustrates how to calibrate a complete hydrological model, including the snow model and runoff generating part.

```@example
# Load packages

using Vann

# Read example input data

filepath = joinpath(Pkg.dir("Vann"), "data", "atnasjo")

date, tair, prec, q_obs, frac = load_data(filepath, "Q_ref.txt")

# Compute potential evapotranspiration

epot = epot_zero(date)

# Select model

tstep = 24.0

st_snow = TinBasic(tstep, date[1], frac)
st_hydro = Gr4j(tstep, date[1])

# Run calibration

param_snow, param_hydro = run_model_calib(st_snow, st_hydro, date, tair, prec, epot, q_obs; warmup = 1)
```
