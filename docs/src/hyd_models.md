# Hydrological models

The following rainfall-runoff models are currently included in the package. They
can be combined with different snow models.

## GR4J

For details about this model, see the following publication:

*Perrin, Charles, Claude Michel, and Vazken Andréassian. 2003. “Improvement of
a Parsimonious Model for Streamflow Simulation.” Journal of Hydrology 279
(1-4): 275–89. doi:10.1016/S0022-1694(03)00225-7.*

```@docs
Gr4j
```

The following constructors are available for generating the types:

```@docs
Gr4j(tstep)
Gr4j(tstep, param)
```

The following functions are mainly used during the calibration of the model:

```@docs
init_states(mdata::Gr4j)
get_param_range(mdata::Gr4j)
assign_param(mdata::Gr4j, param::Array{Float64,1})
```

The models are written in state-space form. Calling the function below runs the
model for one time step.

```@docs
run_timestep(mdata::Gr4j)
```

## HBV

For details about this model, see the following publication:

*Seibert, J., and M. J. P. Vis (2012), Teaching hydrological modeling with a
user-friendly catchment-runoff-model software package, Hydrol.Earth Syst. Sci.,
16(9), 3315–3325.*

```@docs
Hbv
```

The following constructors are available for generating the types:

```@docs
Hbv(tstep)
Hbv(tstep, param)
```

The following functions are mainly used during the calibration of the model:

```@docs
init_states(mdata::Hbv)
get_param_range(mdata::Hbv)
assign_param(mdata::Hbv, param::Array{Float64,1})
```

The models are written in state-space form. Calling the function below runs the
model for one time step.

```@docs
run_timestep(mdata::Hbv)
```
