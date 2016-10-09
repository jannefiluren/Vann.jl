library(airGR)

## loading catchment data
library(airGR)
data(L0123001)

## preparation of the InputsModel object
InputsModel <- CreateInputsModel(FUN_MOD = RunModel_GR4J, DatesR = BasinObs$DatesR,
                                 Precip = BasinObs$P, PotEvap = BasinObs$E)

## run period selection
Ind_Run <- 1:length(InputsModel$DatesR)

## preparation of the RunOptions object
RunOptions <- CreateRunOptions(FUN_MOD = RunModel_GR4J,
                               InputsModel = InputsModel, IndPeriod_Run = Ind_Run)

## simulation
Param <- c(257.238, 1.012, 88.235, 2.208)
OutputsModel <- RunModel_GR4J(InputsModel = InputsModel, RunOptions = RunOptions, Param = Param)

## test data
test_data <- data.frame(Prec = InputsModel$Precip, Epot = InputsModel$PotEvap, Qsim = OutputsModel$Qsim)
write.csv(test_data, "test_data.txt", row.names = FALSE)








