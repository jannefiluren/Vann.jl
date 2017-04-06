# Snow models

The package includes different snow models.


## TinBasic

A basic implementation of a temperature index snow model.

```@docs
TinBasic
```

The following constructors are available for generating the types:

```@docs
TinBasic(tstep, frac)
TinBasic(tstep, param, frac)
```

The following functions are mainly used during the calibration of the model:

```@docs
init_states(mdata::TinBasic)
get_param_range(mdata::TinBasic)
assign_param(mdata::TinBasic, param::Array{Float64,1})
```

## TinStandard

A an enhanced implementation of a temperature index snow model including a
liquid water content.

```docs
TinStandard
```

The following constructors are available for generating the types:

```docs
TinStandard(tstep, frac)
TinStandard(tstep, param, frac)
```

The following functions are mainly used during the calibration of the model:

```docs
init_states(mdata::TinStandard)
get_param_range(mdata::TinStandard)
assign_param(mdata::TinStandard, param::Array{Float64,1})
```

The models are written in state-space form. Calling the function below runs the
model for one time step.

```docs
run_timestep(mdata::TinStandard)
```
