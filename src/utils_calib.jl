

"""

    calib_wrapper(param, st_hydro, prec, epot, q_obs, q_sim)

Wrapper function required for calibrating hydrological routing model.

"""

function calib_wrapper(param, st_hydro, prec, epot, q_obs, q_sim)

    # Assign parameter values

    assign_param(st_hydro, param)

    # Initilize model states

    init_states(st_hydro)

    # Run model

    ntimes = size(prec, 2)

    for itime in 1:ntimes

        get_input(st_hydro, prec, epot, itime)

        run_timestep(st_hydro)

        q_sim[itime] = st_hydro.q_sim

    end

    return(1.0 - kge(q_sim, q_obs))

end




"""

    calib_wrapper(param, st_snow, st_hydro, date, tair, prec, epot, q_obs)

Wrapper function required for calibrating snow and hydrological routing model.

"""

function calib_wrapper(param, st_snow, st_hydro, date, tair, prec, epot, q_obs, q_sim)

    # Assign parameter values

    assign_param(st_snow, param[1:length(st_snow.param)])
    assign_param(st_hydro, param[length(st_snow.param)+1:end])

    # Initilize model states

    init_states(st_snow)
    init_states(st_hydro)

    # Run model

    ntimes = size(prec, 2)

    for itime in 1:ntimes

        get_input(st_snow, prec, tair, date, itime)

        run_timestep(st_snow)

        get_input(st_snow, st_hydro, epot, itime)

        run_timestep(st_hydro)

        q_sim[itime] = st_hydro.q_sim

    end

    return(1.0 - kge(q_sim, q_obs))

end



"""

    run_model_calib(st_hydro::Hydro, prec, epot, q_obs)

Run calibration of hydrological routing model, for example HBV.

"""

function run_model_calib(st_hydro::Hydro, prec, epot, q_obs)

    # Get parameter range

    param_range = get_param_range(st_hydro)

    # Allocate output array

    ntimes = size(prec, 2)

    q_sim = zeros(Float64, ntimes)

    # Run calibration

    calib_wrapper_tmp(param) = calib_wrapper(param, st_hydro, prec, epot, q_obs, q_sim)

    res = bboptimize(calib_wrapper_tmp; SearchRange = param_range, TraceMode = :silent)

    param_hydro = best_candidate(res)

    return param_hydro

end



"""

    run_model_calib(st_snow::Snow, st_hydro::Hydro, date, tair, prec, epot, q_obs)

Run calibration of snow and hydrological routing model.

"""

function run_model_calib(st_snow::Snow, st_hydro::Hydro, date, tair, prec, epot, q_obs)

    # Get parameter range

    param_range_snow  = get_param_range(st_snow)
    param_range_hydro = get_param_range(st_hydro)

    param_range = vcat(param_range_snow, param_range_hydro)

    # Allocate output array

    ntimes = size(prec, 2)

    q_sim = zeros(Float64, ntimes)

    # Run calibration

    calib_wrapper_tmp(param) = calib_wrapper(param, st_snow, st_hydro, date, tair, prec, epot, q_obs, q_sim)

    res = bboptimize(calib_wrapper_tmp; SearchRange = param_range, TraceMode = :silent)

    # Extract parameters for snow and hydrological routing model

    param = best_candidate(res)

    param_snow = param[1:length(st_snow.param)]
    param_hydro = param[length(st_snow.param)+1:end]

    return param_snow, param_hydro

end



"""

    kge(q_sim, q_obs)

Compute modified Kling-Gupta efficiency

"""

function kge(q_sim, q_obs)

    # ikeep = q_obs .!= -999.

    if all(isnan, q_sim) || all(isnan, q_obs)

        kge = NaN

    else

        ikeep = !isnan(q_obs)

        q_sim = q_sim[ikeep]
        q_obs = q_obs[ikeep]

        r = cor(q_sim, q_obs)

        beta = mean(q_sim) / mean(q_obs)

        gamma = (std(q_sim) / mean(q_sim)) / (std(q_obs) / mean(q_obs))

        kge = 1 - sqrt( (r-1)^2 + (beta-1)^2 + (gamma-1)^2 )

    end

    return kge

end




"""

    nse(q_sim, q_obs)

Compute Nash-Sutcliffe efficiency

"""

function nse(q_sim, q_obs)

  # ikeep = q_obs .!= -999.

  ikeep = !isnan(q_obs)

    q_sim = q_sim[ikeep]
    q_obs = q_obs[ikeep]

    ns = 1 - sum((q_sim - q_obs).^2) / sum((q_obs - mean(q_obs)).^2)

end

















# ### Snow and hydrological model

# # Run model and compute performance measure

# function calib_wrapper(param::Vector, grad::Vector, st_snow, st_hydro, date, tair, prec, epot, q_obs)

#   # Assign parameter values

#   assign_param(st_snow, param[1:length(st_snow.param)]);
#   assign_param(st_hydro, param[length(st_snow.param)+1:end]);

#   # Initilize model states

#   init_states(st_snow);
#   init_states(st_hydro);

#   # Run model

#   ntimes = size(prec, 2);

#   q_sim = zeros(Float64, ntimes);

#   for itime in 1:ntimes

#     get_input(st_snow, prec, tair, date, itime);

#     run_timestep(st_snow);

#     get_input(st_snow, st_hydro, epot, itime);

#     q_sim[itime] = run_timestep(st_hydro);

#   end

#   return(kge(q_sim, q_obs));

# end


# # Run calibration

# function run_model_calib(st_snow::Snow, st_hydro::Hydro, date, tair, prec, epot, q_obs)

#   # Get parameter range

#   param_range_snow  = get_param_range(st_snow);
#   param_range_hydro = get_param_range(st_hydro);

#   param_range = vcat(param_range_snow, param_range_hydro);

#   # Lower and upper bounds for parameters

#   param_lower = [param_range[i][1] for i in eachindex(param_range)];
#   param_upper = [param_range[i][2] for i in eachindex(param_range)];

#   # Starting point

#   param_start = (param_lower + param_upper) / 2;

#   # Wrapper function

#   calib_wrapper_tmp(param::Vector, grad::Vector) = calib_wrapper(param::Vector, grad::Vector, st_snow, st_hydro, date, tair, prec, epot, q_obs);

#   # Perform global optimization

#   opt_global = Opt(:GN_ESCH, length(param_start));

#   max_objective!(opt_global, calib_wrapper_tmp);

#   maxeval!(opt_global, 5000);

#   lower_bounds!(opt_global, param_lower);
#   upper_bounds!(opt_global, param_upper);

#   (min_func, best_global, ret_nlopt) = optimize(opt_global, param_start);

#   # Check that optimal value is inside bounds

#   for iparam = 1:length(best_global)

#     if best_global[iparam] < param_lower[iparam] + 0.2*(param_upper[iparam] - param_lower[iparam])
#       best_global[iparam] = param_lower[iparam] + 0.2*(param_upper[iparam] - param_lower[iparam]);
#     end

#     if best_global[iparam] > param_upper[iparam] - 0.2*(param_upper[iparam] - param_lower[iparam]);
#       best_global[iparam] = param_upper[iparam] - 0.2*(param_upper[iparam] - param_lower[iparam]);
#     end

#   end

#   # Perform local optimization

#   opt_local = Opt(:LN_NELDERMEAD, length(param_start));

#   max_objective!(opt_local, calib_wrapper_tmp);

#   lower_bounds!(opt_local, param_lower);
#   upper_bounds!(opt_local, param_upper);

#   (min_func, best_local, ret_nlopt) = optimize(opt_local, best_global);

#   # Return best parameter values

#   return(best_local)

# end


# ### Hydrological model

# # Run model and compute performance measure

# function calib_wrapper(param::Vector, grad::Vector, st_hydro, prec, epot, q_obs)

#   # Assign parameter values

#   assign_param(st_hydro, param);

#   # Initilize model states

#   init_states(st_hydro);

#   # Run model

#   ntimes = size(prec, 2);

#   q_sim = zeros(Float64, ntimes);

#   for itime in 1:ntimes

#     get_input(st_hydro, prec, epot, itime);

#     q_sim[itime] = run_timestep(st_hydro);

#   end

#   return(kge(q_sim, q_obs));

# end

# # Run calibration

# function run_model_calib(st_hydro::Hydro, prec, epot, q_obs)

#   # Get parameter range

#   param_range = get_param_range(st_hydro);

#   # Lower and upper bounds for parameters

#   param_lower = [param_range[i][1] for i in eachindex(param_range)];
#   param_upper = [param_range[i][2] for i in eachindex(param_range)];

#   # Starting point

#   param_start = (param_lower + param_upper) / 2;

#   # Wrapper function

#   calib_wrapper_tmp(param::Vector, grad::Vector) = calib_wrapper(param::Vector, grad::Vector, st_hydro, prec, epot, q_obs);

#   # Perform global optimization

#   opt_global = Opt(:GN_ESCH, length(param_start));

#   max_objective!(opt_global, calib_wrapper_tmp);

#   maxeval!(opt_global, 5000);

#   lower_bounds!(opt_global, param_lower);
#   upper_bounds!(opt_global, param_upper);

#   (min_func, best_global, ret_nlopt) = optimize(opt_global, param_start);

#   # Check that optimal value is inside bounds

#   for iparam = 1:length(best_global)

#     if best_global[iparam] < param_lower[iparam] + 0.2*(param_upper[iparam] - param_lower[iparam])
#       best_global[iparam] = param_lower[iparam] + 0.2*(param_upper[iparam] - param_lower[iparam]);
#     end

#     if best_global[iparam] > param_upper[iparam] - 0.2*(param_upper[iparam] - param_lower[iparam]);
#       best_global[iparam] = param_upper[iparam] - 0.2*(param_upper[iparam] - param_lower[iparam]);
#     end

#   end

#   # Perform local optimization

#   opt_local = Opt(:LN_NELDERMEAD, length(param_start));

#   max_objective!(opt_local, calib_wrapper_tmp);

#   lower_bounds!(opt_local, param_lower);
#   upper_bounds!(opt_local, param_upper);

#   (min_func, best_local, ret_nlopt) = optimize(opt_local, best_global);

#   # Return best parameter values

#   return(best_local)

# end


# # Modified Kling-Gupta efficiency

# function kge(q_sim, q_obs)

#   ikeep = q_obs .!= -999.;

#   q_sim = q_sim[ikeep];
#   q_obs = q_obs[ikeep];

#   r = cor(q_sim, q_obs);

#   beta = mean(q_sim) / mean(q_obs);

#   gamma = (std(q_sim) / mean(q_sim)) / (std(q_obs) / mean(q_obs));

#   kge = 1 - sqrt( (r-1)^2 + (beta-1)^2 + (gamma-1)^2 );

# end


# # Nash-Sutcliffe efficiency

# function nse(q_sim, q_obs)

#   ikeep = q_obs .!= -999.;

#   q_sim = q_sim[ikeep];
#   q_obs = q_obs[ikeep];

#   ns = 1 - sum((q_sim - q_obs).^2) / sum((q_obs - mean(q_obs)).^2);

# end
