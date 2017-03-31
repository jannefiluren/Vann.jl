# Model wrapper for hydrological response model (e.g. Gr4j or HBV)

function run_model(st_hydro::Hydro, prec, epot)

  # Number of time steps

  ntimes = size(prec, 2)

  # Run model

  q_sim = zeros(Float64, ntimes)

  for itime in 1:ntimes

    get_input(st_hydro, prec, epot, itime)

    q_sim[itime] = hydro_model(st_hydro)

  end

  return(q_sim)

end


# Model wrapper for snow model and hydrological response model

function run_model(st_snow, st_hydro, date, tair, prec, epot)

  # Number of time steps

  ntimes = size(prec, 2)

  # Run model

  q_sim = zeros(Float64, ntimes)

  for itime in 1:ntimes

    get_input(st_snow, prec, tair, date, itime)

    snow_model(st_snow)

    get_input(st_snow, st_hydro, epot, itime)

    q_sim[itime] = hydro_model(st_hydro)

  end

  return(q_sim)

end


# Model wrapper for snow model

function run_model(st_snow, date, tair, prec)

  # Number of time steps

  ntimes = size(prec, 2)
  nzones = length(st_snow.swe)

  # Run model

  infilt_sim = zeros(ntimes)

  for itime in 1:ntimes

    get_input(st_snow, prec, tair, date, itime)

    snow_model(st_snow)

    infilt_sim[itime] = st_snow.infilt

  end

  return infilt_sim

end
