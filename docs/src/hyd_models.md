# Hydrological model components

## GR4J model

```@docs
Gr4j
Gr4j()
Gr4j(param)
get_param_range(mdata::Gr4j)
init_states(mdata::Gr4j)
assign_param(mdata::Gr4j, param::Array{Float64,1})
hydro_model(mdata::Gr4j)
```

## HBV model

