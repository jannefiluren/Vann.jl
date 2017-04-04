# Vann

[![Join the chat at https://gitter.im/Vann-jl/Lobby](https://badges.gitter.im/Vann-jl/Lobby.svg)](https://gitter.im/Vann-jl/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

[![Build Status](https://travis-ci.org/jmgnve/Vann.jl.svg?branch=master)](https://travis-ci.org/jmgnve/Vann.jl)
[![codecov](https://codecov.io/gh/jmgnve/Vann.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/jmgnve/Vann.jl)

Julia package containing hydrological models including data assimilation methods (particle filter, ensemble Kalman filter...)

For installing the package, run the following code:

```julia
Pkg.clone("https://github.com/jmgnve/Vann.git")
```

The example below runs one model combination and plots the results:

```julia

using Vann
using PyPlot

filepath = joinpath(Pkg.dir("Vann"), "data/atnasjo")

date, tair, prec, q_obs, frac = load_data(filepath, "Q_ref.txt")

# Compute potential evapotranspiration

epot = epot_zero(date)

# Parameters

param_snow  = [0.0, 3.69, 1.02]
param_hydro = [74.59, 0.81, 214.98, 1.24]

# Select model

step = 1.0

st_snow  = TinBasic(step, param_snow, frac)
st_hydro = Gr4j(step, param_hydro)

q_sim = run_model(st_snow, st_hydro, date, tair, prec, epot)

plot(date, q_sim)

```

The example folder contains code for calibrating model combinations and also a simple particle and ensemble Kalman filter implementations:

```julia

cd(joinpath(Pkg.dir("Vann"), "examples"))

include("calibration_test.jl")

include("enkf_test.jl")

include("pfilter_test.jl")

```
