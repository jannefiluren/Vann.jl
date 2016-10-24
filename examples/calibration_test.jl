################################################################################

using Vann
using RCall
using DataFrames
using JLD

################################################################################

path_inputs = Pkg.dir("Vann","data_atnasjo");
path_save = "C:/Users/jmg/Desktop/outputs/test"

snow_choice = TinBasicType;
hydro_choice = Gr4jType;

calib_start = Date(2000,10,01);
calib_stop = Date(2005,10,09);

valid_start = Date(2005,10,10);
valid_stop = Date(2010,07,02);

########################### Calibration period ###############################

# Load data

date, tair, prec, q_obs, frac = load_data(path_inputs);

# Crop data

date, tair, prec, q_obs = crop_data(date, tair, prec, q_obs, calib_start, calib_stop);

# Initilize model

st_snow = eval(Expr(:call, snow_choice, frac));
st_hydro = eval(Expr(:call, hydro_choice, frac));

# Run calibration

param_opt = run_model_calib(st_snow, st_hydro, date, tair, prec, q_obs);

println(param_opt)

# Reinitilize model

param_snow  = param_opt[1:length(st_snow.param)]
param_hydro = param_opt[length(st_snow.param)+1:end]

st_snow = eval(Expr(:call, snow_choice, param_snow, frac));
st_hydro = eval(Expr(:call, hydro_choice, param_hydro, frac));

# Run model with best parameter set

q_sim = run_model(st_snow, st_hydro, date, tair, prec);

# Store results in data frame

q_obs = round(q_obs, 2);
q_sim = round(q_sim, 2);

df_txt = DataFrame(date = date, q_sim = q_sim);
df_fig = DataFrame(x = collect(1:length(date)), q_sim = q_sim, q_obs = q_obs);

# Folder for saving results

mkpath(path_save * "/calib_txt")
mkpath(path_save * "/calib_png")

# Save results to txt file

file_save = "results";

writetable(string(path_save, "/calib_txt/", file_save, "_station.txt"), df_txt, quotemark = '"', separator = '\t')

# Plot results using rcode

R"""
library(zoo, lib.loc = 'C:/Users/jmg/Documents/R/win-library/3.2')
library(hydroGOF, lib.loc = 'C:/Users/jmg/Documents/R/win-library/3.2')
library(labeling, lib.loc = 'C:/Users/jmg/Documents/R/win-library/3.2')
library(ggplot2, lib.loc = 'C:/Users/jmg/Documents/R/win-library/3.2')
"""

R"""
df <- $df_fig
df$q_obs[df$q_obs == -999] <- NA
kge <- KGE(df$q_sim, df$q_obs)
plot_title <- paste('KGE = ', round(kge, digits = 2), sep = '')
path_save <- $path_save
file_save <- $file_save
"""

R"""
p <- ggplot(df, aes(x))
p <- p + geom_line(aes(y = q_sim),colour = 'red', size = 0.5)
p <- p + geom_line(aes(y = q_obs),colour = 'blue', size = 0.5)
p <- p + theme_bw()
p <- p + labs(title = plot_title)
p <- p + labs(x = 'Index')
p <- p + labs(y = 'Discharge')
ggsave(file = paste(path_save,'/calib_png/',file_save,'_station.png', sep = ''), width = 30, height = 18, units = 'cm', dpi = 600)
"""

########################### Validation period ################################

# Load data

date, tair, prec, q_obs, frac = load_data(path_inputs);

# Crop data

date, tair, prec, q_obs = crop_data(date, tair, prec, q_obs, valid_start, valid_stop);

# Reinitilize model

st_snow = eval(Expr(:call, snow_choice, param_snow, frac));
st_hydro = eval(Expr(:call, hydro_choice, param_hydro, frac));

# Run model with best parameter set

q_sim = run_model(st_snow, st_hydro, date, tair, prec);

# Store results in data frame

q_obs = round(q_obs, 2);
q_sim = round(q_sim, 2);

df_txt = DataFrame(date = date, q_sim = q_sim);
df_fig = DataFrame(x = collect(1:length(date)), q_sim = q_sim, q_obs = q_obs);

# Folder for saving results

mkpath(path_save * "/valid_txt")
mkpath(path_save * "/valid_png")

# Save results to txt file

file_save = "results";

writetable(string(path_save, "/valid_txt/", file_save, "_station.txt"), df_txt, quotemark = '"', separator = '\t')

# Plot results using rcode

R"""
library(zoo, lib.loc = 'C:/Users/jmg/Documents/R/win-library/3.2')
library(hydroGOF, lib.loc = 'C:/Users/jmg/Documents/R/win-library/3.2')
library(labeling, lib.loc = 'C:/Users/jmg/Documents/R/win-library/3.2')
library(ggplot2, lib.loc = 'C:/Users/jmg/Documents/R/win-library/3.2')
"""

R"""
df <- $df_fig
df$q_obs[df$q_obs == -999] <- NA
kge <- KGE(df$q_sim, df$q_obs)
plot_title <- paste('KGE = ', round(kge, digits = 2), sep = '')
path_save <- $path_save
file_save <- $file_save
"""

R"""
p <- ggplot(df, aes(x))
p <- p + geom_line(aes(y = q_sim),colour = 'red', size = 0.5)
p <- p + geom_line(aes(y = q_obs),colour = 'blue', size = 0.5)
p <- p + theme_bw()
p <- p + labs(title = plot_title)
p <- p + labs(x = 'Index')
p <- p + labs(y = 'Discharge')
ggsave(file = paste(path_save,'/valid_png/',file_save,'_station.png', sep = ''), width = 30, height = 18, units = 'cm', dpi = 600)
"""

# Save model objects

st_snow = eval(Expr(:call, snow_choice, param_snow, frac));
st_hydro = eval(Expr(:call, hydro_choice, param_hydro, frac));

jldopen(path_save * "/model_data.jld", "w") do file
  addrequire(file, Vann)
  write(file, "st_snow", st_snow)
  write(file, "st_hydro", st_hydro)
end
