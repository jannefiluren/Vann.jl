# Snow models

The following snow models are currently included in the package.

* TinBasic

*Simple temperature-index snow melt model with constant degree-day factor.*

* TinStandard

*Magnusson, J., D. Gustafsson, F. Husler, and T. Jonas (2014), Assimilation of point SWE data into a distributed snow cover model comparing two contrasting methods, Water Resour. Res., 50, doi:10.1002/2014WR015302.*

## Model initialization

The following examples shows how to initialize the TinBasic model.

```@example
# Load packages

using Vann

# Model time step

tstep = 24.0

# Initial date of the simulation period

time = DateTime(2000, 1, 1)

# Fraction covered by the different elevation bands

frac = [0.5; 0.5]

# Initilize the model with predefined parameters

model_var = TinBasic(tstep, time, frac)

# Initilize the model with custom parameters

param = [0.5, 4.0, 1.2]

model_var = TinBasic(tstep, time, param, frac)
```

## Run the model

The following example shows how to run the TinBasic model.

```@example
# Load packages

using Vann

# Read example input data

filepath = joinpath(Pkg.dir("Vann"), "data", "atnasjo")

date, tair, prec, q_obs, frac = load_data(filepath, "Q_ref.txt")

tstep = 24.0

time = date[1]

# Select model

model_var = TinBasic(tstep, time, frac)

# Run model - output is snowmelt runoff

q_sim = run_model(model_var, date, tair, prec)
```
