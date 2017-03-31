

"""
The TinBasic type contains the state variables (swe), the inputs
(prec, tair) for one time step, the parameters (param) and the time step
length (tstep) for a basic temperature index model.
"""
type TinBasic <: Snow

  prec::Array{Float64,1}
  tair::Array{Float64,1}
  swe::Array{Float64,1}
  infilt::Float64
  param::Array{Float64,1}
  frac::Array{Float64,1}
  tstep::Float64

end


"""
    TinBasic(tstep, frac)

Constructor for TinBasic with predefined state variables, parameters and inputs.
The time step (tstep) is given as a fraction of one day. Thus, for hourly input
data tstep should be set to 1/24. The fraction of elevation bands should sum
up to unity.
"""
function TinBasic(tstep, frac)

  nzones = length(frac)
  prec   = zeros(Float64, nzones)
  tair   = zeros(Float64, nzones)
  swe    = zeros(Float64, nzones)
  infilt = 0.0
  param  = [0.0, 3.0, 1.0]

  TinBasic(prec, tair, swe, infilt, param, frac, tstep)

end


"""
    TinBasic(tstep, param, frac)

Constructor for TinBasic with predefined state variables and inputs.
The time step (tstep) is given as a fraction of one day. Thus, for hourly input
data tstep should be set to 1/24. The fraction of elevation bands should sum
up to unity.
"""
function TinBasic(tstep, param, frac)

  nzones = length(frac)
  prec   = zeros(Float64, nzones)
  tair   = zeros(Float64, nzones)
  swe    = zeros(Float64, nzones)
  infilt = 0.0

  TinBasic(prec, tair, swe, infilt, param, frac, tstep)

end


"""
    init_states(mdata::TinBasic)

Initilize the state variables of the model.
"""
function init_states(mdata::TinBasic)

  for i in eachindex(mdata.swe)
    mdata.swe[i] = 0.0
  end

end


"""
    get_param_range(mdata::TinBasic)

Get allowed parameter ranges for the calibration of the model.
"""
function get_param_range(mdata::TinBasic)

  param_range_snow = [(-3.0, 3.0), (0.1, 10.0), (0.5, 2.0)]

end


"""
    assign_param(mdata::TinBasic, param::Array{Float64,1})

Assign parameter values to the TinBasic type.
"""
function assign_param(mdata::TinBasic, param::Array{Float64,1})

  for i in eachindex(mdata.param)
    mdata.param[i] = param[i]
  end

end


"""
    enkf_snow(mdata::Array{TinBasic}, obs_ens, q_sim)

Implementation of the ensemble Kalman filter for the basic temperature index
snow model.
"""
function enkf_snow(mdata::Array{TinBasic}, obs_ens, q_sim)

  nens = length(mdata)

  # Allocate arrays

  swe = zeros(Float64, length(mdata[1].swe), nens)

  # Add states to arrays

  for iens = 1:nens

    swe[:, iens]    = mdata[iens].swe

  end

  # Run ensemble kalman filter

  swe = enkf(swe, obs_ens, q_sim)

  # Check limits of states

  swe[swe .< 0] = 0.

  # Add arrays to states

  for iens = 1:nens

    mdata[iens].swe = swe[:, iens]

  end

  nothing

end


"""
    snow_model(mdata::TinBasic)

Propagate the model one time step and compute simulated snowpack dischage.
"""
function snow_model(mdata::TinBasic)

  # Parameters

  tth   = mdata.param[1]
  ddf   = mdata.param[2] * mdata.tstep
  pcorr = mdata.param[3]

  mdata.infilt = 0.0

  for i in eachindex(mdata.swe)

    # Compute solid and liquid precipitation

    psolid, pliquid = split_prec(mdata.prec[i], mdata.tair[i], tth)

    psolid  = psolid * pcorr

    # Compute snow melt

    M = pot_melt(mdata.tair[i], ddf, tth)

    M = min(mdata.swe[i],M)

    # Update snow water equivalents

    mdata.swe[i] += psolid
    mdata.swe[i] -= M

    # Compute infiltration

    mdata.infilt += mdata.frac[i]*(M + pliquid)

  end

end
