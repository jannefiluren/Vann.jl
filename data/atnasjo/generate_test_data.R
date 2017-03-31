
# Load packages

library("HMOD")

# Run simulation

NEns <- 1

iwsh <- 3

data_obs <- sample_data[[iwsh]]

param <- c(74.59, 0.81, 214.98, 1.24, 3.69, 1.02)

Q_ref <- run_ensemble(data_obs, param, NEns)


# Get year, month, day, hour

year <- as.numeric(format(data_obs$time_vec, "%Y"))

month <- as.numeric(format(data_obs$time_vec, "%m"))

day <- as.numeric(format(data_obs$time_vec, "%d"))

hour <- rep(0, length(year))


# Write data

write.table(param, file = "Param.txt", sep = "\t", row.names = FALSE, col.names = FALSE)

write.table(data_obs$frac_elev_band, file = "Frac.txt", sep = "\t", row.names = FALSE, col.names = FALSE)


write.table(data.frame(year, month, day, hour, round(Q_ref, digits = 3)), file = "Q_ref.txt", sep = "\t", row.names = FALSE, col.names = FALSE)

write.table(data.frame(year, month, day, hour, round(data_obs$Runoff, digits = 3)), file = "Q_obs.txt", sep = "\t", row.names = FALSE, col.names = FALSE)

write.table(data.frame(year, month, day, hour, round(data_obs$Tair, digits = 3)), file = "Tair.txt", sep = "\t", row.names = FALSE, col.names = FALSE)

write.table(data.frame(year, month, day, hour, round(data_obs$Prec, digits = 3)), file = "Prec.txt", sep = "\t", row.names = FALSE, col.names = FALSE)

