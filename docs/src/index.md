# Vann.jl

*A Julia package for hydrological modelling.*

## Package Features

This package includes different model components for computing processes
such as evapotranspiration, snow accumulation and melt, and routing of water
through the subsurface. The model blocks can be combined in arbritraty
combinations. The package additionally includes different data assimilation
procedures for updating the state variables of the hydrological models.

## Installation

The package and so can be installed using:

```julia
Pkg.clone("https://github.com/jmgnve/Vann.jl.git")
```

## Input variables

Input variables depending on the length of the time step, such as precipitation,
should given in units *mm/timestep* For all models, the time step should be
relative to daily inputs. Thus, if hourly input data is used, the model time
step should equal 1/24.
