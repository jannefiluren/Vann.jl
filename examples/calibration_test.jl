# Required packages

using Vann
using RCall
using DataFrames

# Model choices

snow_choice = TinBasicType;
hydro_choice = Gr4jType;

# Load data

path_inputs = Pkg.dir("Vann", "data_atnasjo");

date, tair, prec, q_obs, frac = load_data(path_inputs);

# Compute potential evapotranspiration

epot = epot_zero(date)

# Initilize model

st_snow = eval(Expr(:call, snow_choice, frac));
st_hydro = eval(Expr(:call, hydro_choice, frac));

# Run calibration

param_opt = run_model_calib(st_snow, st_hydro, date, tair, prec, epot, q_obs);

println(param_opt)

# Reinitilize model

param_snow  = param_opt[1:length(st_snow.param)]
param_hydro = param_opt[length(st_snow.param)+1:end]

st_snow = eval(Expr(:call, snow_choice, param_snow, frac));
st_hydro = eval(Expr(:call, hydro_choice, param_hydro, frac));

# Run model with best parameter set

q_sim = run_model(st_snow, st_hydro, date, tair, prec, epot);

# Store results in data frame

q_obs = round(q_obs, 2);
q_sim = round(q_sim, 2);

df_res = DataFrame(x = collect(1:length(date)), date = Dates.format(date,"yyyy-mm-dd"), q_sim = q_sim, q_obs = q_obs);

# Plot results using rcode

R"""
library(zoo, lib.loc = "C:/Users/jmg/Documents/R/win-library/3.2")
library(hydroGOF, lib.loc = "C:/Users/jmg/Documents/R/win-library/3.2")
library(labeling, lib.loc = "C:/Users/jmg/Documents/R/win-library/3.2")
library(ggplot2, lib.loc = "C:/Users/jmg/Documents/R/win-library/3.2")

df <- $df_res
df$date <- as.Date(df$date)
df$q_obs[df$q_obs == -999] <- NA
kge <- KGE(df$q_sim, df$q_obs)
plot_title <- paste('KGE = ', round(kge, digits = 2), sep = '')

p <- ggplot(df, aes(date))
p <- p + geom_line(aes(y = q_sim),colour = 'red', size = 0.5)
p <- p + geom_line(aes(y = q_obs),colour = 'blue', size = 0.5)
p <- p + theme_bw()
p <- p + labs(title = plot_title)
p <- p + labs(x = 'Index')
p <- p + labs(y = 'Discharge')
"""

