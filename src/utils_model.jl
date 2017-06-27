# Model wrapper for hydrological response model (e.g. Gr4j or HBV)

function run_model(mdata_hydro::Hydro, prec, epot; return_all = false)

  # Number of time steps

  ntimes = size(prec, 2)

  # Allocate output arrays

  q_sim = zeros(Float64, ntimes)

  if return_all == true
    hydro_out = [mdata_hydro for i in 1:ntimes]
  end

  # Run time loop

  for itime in 1:ntimes

    get_input(mdata_hydro, prec, epot, itime)

    run_timestep(mdata_hydro)

    q_sim[itime] = mdata_hydro.q_sim

    if return_all == true
      hydro_out[itime] = deepcopy(mdata_hydro)
    end

  end

  # Return outputs

  if return_all == false
    return q_sim
  else
    return q_sim, hydro_out
  end

end


# Model wrapper for snow model and hydrological response model

function run_model(mdata_snow, mdata_hydro, tair, prec, epot; return_all = false)

  # Number of time steps

  ntimes = size(prec, 2)

  # Allocate output arrays

  q_sim = zeros(Float64, ntimes)

  if return_all == true
    snow_out  = [mdata_snow for i in 1:ntimes]
    hydro_out = [mdata_hydro for i in 1:ntimes]
  end

  # Run time loop

  for itime in 1:ntimes

    get_input(mdata_snow, prec, tair, itime)

    run_timestep(mdata_snow)

    get_input(mdata_snow, mdata_hydro, epot, itime)

    run_timestep(mdata_hydro)

    q_sim[itime] = mdata_hydro.q_sim

    if return_all == true
      snow_out[itime]  = deepcopy(mdata_snow)
      hydro_out[itime] = deepcopy(mdata_hydro)
    end

  end

  # Return outputs

  if return_all == false
    return q_sim
  else
    return q_sim, snow_out, hydro_out
  end

end


# Model wrapper for snow model

function run_model(mdata_snow, tair, prec; return_all = false)

  # Number of time steps

  ntimes = size(prec, 2)

  # Allocate output arrays

  q_sim = zeros(Float64, ntimes)

  if return_all == true
    snow_out  = [mdata_snow for i in 1:ntimes]
  end

  # Run time loop

  for itime in 1:ntimes

    get_input(mdata_snow, prec, tair, itime)

    run_timestep(mdata_snow)

    q_sim[itime] = mdata_snow.q_sim

    if return_all == true
      snow_out[itime]  = deepcopy(mdata_snow)
    end

  end

  # Return outputs

  if return_all == false
    return q_sim
  else
    return q_sim, snow_out
  end

end
