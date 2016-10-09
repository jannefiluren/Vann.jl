
### Snow and hydrological model

# Run model and compute performance measure

function calib_wrapper(param, st_snow, st_hydro, date, tair, prec, q_obs)

  # Assign parameter values

  assign_param(st_snow, param[1:length(st_snow.param)]);
  assign_param(st_hydro, param[length(st_snow.param)+1:end]);

  # Initilize model states

  init_states(st_snow);
  init_states(st_hydro);

  # Run model

  ntimes = size(prec, 2);

  q_sim = zeros(Float64, ntimes);

  for itime in 1:ntimes

    get_input(st_snow, prec, tair, date, itime);

    snow_model(st_snow);

    get_input(st_snow, st_hydro);

    q_sim[itime] = hydro_model(st_hydro);

  end

  ikeep = q_obs .!= -999.;

  q_sim = q_sim[ikeep];
  q_obs = q_obs[ikeep];

  return(sum((q_sim - q_obs).^2));

end


# Run calibration

function run_model_calib(st_snow::SnowType, st_hydro::HydroType, date, tair, prec, q_obs)

  param_range_snow  = get_param_range(st_snow);
  param_range_hydro = get_param_range(st_hydro);

  param_range = vcat(param_range_snow, param_range_hydro);

  calib_wrapper_tmp(param) = calib_wrapper(param, st_snow, st_hydro, date, tair, prec, q_obs);

  res = bboptimize(calib_wrapper_tmp; SearchRange = param_range);

end


### Hydrological model

# Run model and compute performance measure

function calib_wrapper(param, st_hydro, prec, epot, q_obs)

  # Assign parameter values

  assign_param(st_hydro, param);

  # Initilize model states

  init_states(st_hydro);

  # Run model

  ntimes = size(prec, 2);

  q_sim = zeros(Float64, ntimes);

  for itime in 1:ntimes

    get_input(st_hydro, prec, epot, itime);

    q_sim[itime] = hydro_model(st_hydro);

  end

  ikeep = q_obs .!= -999.;

  q_sim = q_sim[ikeep];
  q_obs = q_obs[ikeep];

  return(sum((q_sim - q_obs).^2));

end

# Run calibration

function run_model_calib(st_hydro::HydroType, prec, epot, q_obs)

  param_range = get_param_range(st_hydro);

  calib_wrapper_tmp(param) = calib_wrapper(param, st_hydro, prec, epot, q_obs);

  res = bboptimize(calib_wrapper_tmp; SearchRange = param_range);

end
