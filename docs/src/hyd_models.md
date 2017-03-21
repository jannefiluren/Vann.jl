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
hydro_model(mdata::Gr4j)
```

## HBV
