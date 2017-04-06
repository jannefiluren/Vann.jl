# Vann.jl

*A Julia package for hydrological modelling.*

## Package Features

This package includes different model components for computing processes
such as evapotranspiration, snow accumulation and melt, and routing of water
through the subsurface. The model blocks can be combined in arbritraty
combinations. The package additionally includes different data assimilation
procedures for updating the state variables of the hydrological models.

## Installation

Install the package using:

```julia
Pkg.clone("https://github.com/jmgnve/Vann.jl.git")
```

## Example

This short example describes how to run one the of the models.

```@example

using Vann

filename = Pkg.dir("Vann", "data/airgr/test_data.txt")

data = readdlm(filename, ',', header = true)

prec  = data[1][:,1]
epot  = data[1][:,2]
q_obs = data[1][:,3]

prec = transpose(prec)
epot = transpose(epot)

frac = zeros(Float64, 1)

param  = [257.238, 1.012, 88.235, 2.208]

tstep = 24.0

# Select model

st_gr4j = Gr4j(tstep, param)

# Run model

q_sim = run_model(st_gr4j, prec, epot)
nothing # hide
```

## Input variables

Input variables depending on the length of the time step, such as precipitation,
should given in units *mm/timestep* For all models, the time step should be
given in hours.
