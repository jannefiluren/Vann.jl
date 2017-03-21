################################################################################

# Add packages

using RCall
using Distributions
using DataFrames
using Vann
using DataAssim


################################################################################

# Perturb input data for snow model

function perturb_input(st_snow, prec, tair, itime)

  n = Uniform(0.5, 1.5);
  prec_noise = rand(n, 1);

  n = Normal(0.0, 2);
  tair_noise = rand(n, 1);

  # Assign inputs to snow model

  for izone in eachindex(st_snow.prec)

    st_snow.prec[izone] = prec[izone, itime] * prec_noise[1];
    st_snow.tair[izone] = tair[izone, itime] + tair_noise[1];

  end

end


################################################################################

# Ensemble Kalman filter

function run_filter(prec, tair, epot, q_obs, param_snow, param_hydro, frac, nens)

  srand(1);

  # Number of elevation bands (rows) and time steps (cols)

  nzones = size(prec, 1);
  ntimes = size(prec, 2);

  # Initilize state variables

  tstep = 1.0

  st_snow  = [TinBasic(tstep, param_snow, frac) for i in 1:nens];
  st_hydro = [Gr4j(tstep, param_hydro) for i in 1:nens];

  # Allocate arrays

  q_res  = zeros(Float64, ntimes, 3);
  q_sim  = zeros(Float64, 1, nens);
  swe    = zeros(Float64, nzones, nens);
  st     = zeros(Float64, 2, nens);
  st_uh1 = zeros(Float64, 20, nens);
  st_uh2 = zeros(Float64, 40, nens);

  # Start time Loop

  for itime = 1:ntimes

    # Perturb inputs and run models

    for iens = 1:nens

      perturb_input(st_snow[iens], prec, tair, itime);

      snow_model(st_snow[iens]);

      get_input(st_snow[iens], st_hydro[iens], epot, itime);

      q_sim[iens] = hydro_model(st_hydro[iens]);

    end

    # Run filter part

    if q_obs[itime] >= 0

      # Add states to arrays

      for iens = 1:nens

        swe[:, iens]    = st_snow[iens].swe;
        st[:, iens]     = st_hydro[iens].st;
        st_uh1[:, iens] = st_hydro[iens].st_uh1;
        st_uh2[:, iens] = st_hydro[iens].st_uh2;

      end

      # Perturb observations

      sigma = max(0.1 * q_obs[itime], 0.1);

      obs_ens = q_obs[itime] + sigma * randn(Float64, 1, 100);

      # Run ensemble kalman filter

      swe    = enkf(swe, obs_ens, q_sim);
      st     = enkf(st, obs_ens, q_sim);
      st_uh1 = enkf(st_uh1, obs_ens, q_sim);
      st_uh2 = enkf(st_uh2, obs_ens, q_sim);
      q_sim  = enkf(q_sim, obs_ens, q_sim);

      # Check limits of states

      swe[swe .< 0] = 0.;
      st[st .< 0] = 0.;
      st_uh1[st_uh1 .< 0] = 0.;
      st_uh2[st_uh2 .< 0] = 0.;
      q_sim[q_sim .< 0] = 0.

      st[1, st[1, :] .> param_hydro[1]] = param_hydro[1];
      st[2, st[2, :] .> param_hydro[3]] = param_hydro[3];

      # Add arrays to states

      for iens = 1:nens

        st_snow[iens].swe = swe[:, iens];
        st_hydro[iens].st = st[:, iens];
        st_hydro[iens].st_uh1 = st_uh1[:, iens];
        st_hydro[iens].st_uh2 = st_uh2[:, iens];

      end

    end

    # Store results

    q_res[itime, 1] = mean(q_sim);
    q_res[itime, 2] = minimum(q_sim);
    q_res[itime, 3] = maximum(q_sim);

  end

  return(q_res);

end


################################################################################


# Model choices

snow_choice = TinBasic;
hydro_choice = Gr4j;

# Load data

path_inputs = Pkg.dir("Vann", "data_atnasjo");

date, tair, prec, q_obs, frac = load_data(path_inputs);

# Compute potential evapotranspiration

epot = epot_zero(date)

# Initilize model

tstep = 1.0

st_snow = eval(Expr(:call, snow_choice, tstep, frac));
st_hydro = eval(Expr(:call, hydro_choice, tstep));

# Run calibration

param_snow, param_hydro = run_model_calib(st_snow, st_hydro, date, tair, prec, epot, q_obs);

# Run model and filter

nens = 100;

q_res = run_filter(prec, tair, epot, q_obs, param_snow, param_hydro, frac, nens);

# Add results to dataframe

x_data = collect(1:size(q_res,1));
q_sim  = q_res[:, 1];
q_min  = q_res[:, 2];
q_max  = q_res[:, 3];

q_obs = round(q_obs, 2);
q_sim = round(q_sim, 2);
q_min = round(q_min, 2);
q_max = round(q_max, 2);

df_res = DataFrame(date = Dates.format(date,"yyyy-mm-dd"), q_obs = q_obs, q_sim = q_sim, q_min = q_min, q_max = q_max);

# Plot results

days_warmup = 3*365;

df_res = df_res[days_warmup:end, :];

R"""
library(zoo, lib.loc = "C:/Users/jmg/Documents/R/win-library/3.2")
library(hydroGOF, lib.loc = "C:/Users/jmg/Documents/R/win-library/3.2")
library(labeling, lib.loc = "C:/Users/jmg/Documents/R/win-library/3.2")
library(ggplot2, lib.loc = "C:/Users/jmg/Documents/R/win-library/3.2")

df <- $df_res
df$date <- as.Date(df$date)
df$q_obs[df$q_obs == -999] <- NA

kge <- round(KGE(df$q_sim, df$q_obs), digits = 2)
nse <- round(NSE(df$q_sim, df$q_obs), digits = 2)

plot_title <- paste('KGE = ', kge, ' NSE = ', nse, sep = '')

p <- ggplot(df, aes(date))
p <- p + geom_ribbon(aes(ymin = q_min, ymax = q_max), fill = "deepskyblue1")
p <- p + geom_line(aes(y = q_obs), colour = "black", size = 1)
p <- p + geom_line(aes(y = q_sim), colour = "red", size = 0.5)
p <- p + theme_bw()
p <- p + labs(title = plot_title)
p <- p + labs(x = 'Date')
p <- p + labs(y = 'Discharge')
"""
