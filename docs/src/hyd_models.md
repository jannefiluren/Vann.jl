# Hydrological models

The following rainfall-runoff models are currently included in the package. They can be combined with different snow models.

## GR4J

For details about this model, see the following publication:

*Perrin, Charles, Claude Michel, and Vazken Andréassian. 2003. “Improvement of
a Parsimonious Model for Streamflow Simulation.” Journal of Hydrology 279
(1-4): 275–89. doi:10.1016/S0022-1694(03)00225-7.*


## HBV

For details about this model, see the following publication:

*Seibert, J., and M. J. P. Vis (2012), Teaching hydrological modeling with a
user-friendly catchment-runoff-model software package, Hydrol.Earth Syst. Sci.,
16(9), 3315–3325.*

Construct a model variable of this type as follows:

```
tstep = 24.0

time = DateTime(2000, 1, 1)

model_var = Gr4j(tstep, time)

param = [257.238, 1.012, 88.235, 2.208]

model_var = Gr4j(tstep, time, param)

nothing #hide
```
