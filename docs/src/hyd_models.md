# Hydrological models

The following rainfall-runoff models are currently included in the package. They can be combined with different snow models.

* GR4J

*Perrin, Charles, Claude Michel, and Vazken Andréassian. 2003. “Improvement of
a Parsimonious Model for Streamflow Simulation.” Journal of Hydrology 279
(1-4): 275–89. doi:10.1016/S0022-1694(03)00225-7.*

* HBV

*Seibert, J., and M. J. P. Vis (2012), Teaching hydrological modeling with a
user-friendly catchment-runoff-model software package, Hydrol.Earth Syst. Sci.,
16(9), 3315–3325.*

## Model initialization

The following examples shows how to initialize the GR4J model.

```@example
# Load packages 

using Vann

# Model time step

tstep = 24.0

# Initial date of the simulation period

time = DateTime(2000, 1, 1)

# Initilize the model with predefined parameters

model_var = Gr4j(tstep, time)

# Initilize the model with custom parameters

param = [257.238, 1.012, 88.235, 2.208]

model_var = Gr4j(tstep, time, param)
```

## Run the model

The following example shows how to run the GR4J model.

```@example
# Load packages

using Vann

# Read example input data

filename = joinpath(Pkg.dir("Vann"), "data", "airgr", "test_data.txt")

data = readdlm(filename, ',', header = true)

prec  = data[1][:,1]
epot  = data[1][:,2]
q_obs = data[1][:,3]

prec = transpose(prec)
epot = transpose(epot)

param  = [257.238, 1.012, 88.235, 2.208]

tstep = 24.0

time = DateTime(2000,1,1)

# Select model

model_var = Gr4j(tstep, time, param)

# Run model - output is watershed discharge

q_sim = run_model(model_var, prec, epot)
```
