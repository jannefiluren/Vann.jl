

"""
The TinStandard type contains the state variables (swe), the inputs
(prec, tair) for one time step, the parameters (param) and the time step
length (tstep) for a standard temperature index model.
"""
type TinStandard <: Snow

  prec::Array{Float64,1}
  tair::Array{Float64,1}
  date::Date
  swe::Array{Float64,1}
  lw::Array{Float64,1}
  infilt::Float64
  param::Array{Float64,1}
  frac::Array{Float64,1}
  tstep::Float64

end


"""
    TinStandard(tstep, frac)

Constructor for TinStandard with predefined state variables, parameters and inputs.
The time step (tstep) is given as a fraction of one day. Thus, for hourly input
data tstep should be set to 1/24. The fraction of elevation bands should sum
up to unity.
"""
function TinStandard(tstep, frac)

  nzones = length(frac)
  prec   = zeros(Float64, nzones)
  tair   = zeros(Float64, nzones)
  date   = Date()
  swe    = zeros(Float64, nzones)
  lw     = zeros(Float64, nzones)
  infilt = 0.0
  param  = zeros(Float64, 5)

  TinStandard(prec, tair, date, swe, lw, infilt, param, frac, tstep)

end


"""
    TinStandard(tstep, param, frac)

Constructor for TinStandard with predefined state variables and inputs.
The time step (tstep) is given as a fraction of one day. Thus, for hourly input
data tstep should be set to 1/24. The fraction of elevation bands should sum
up to unity.
"""
function TinStandard(tstep, param, frac)

  nzones = length(frac)
  prec   = zeros(Float64, nzones)
  tair   = zeros(Float64, nzones)
  date   = Date()
  swe    = zeros(Float64, nzones)
  lw     = zeros(Float64, nzones)
  infilt = 0.0

  TinStandard(prec, tair, date, swe, lw, infilt, param, frac, tstep)

end


"""
    init_states(mdata::TinStandard)

Initilize the state variables of the model.
"""
function init_states(mdata::TinStandard)

  for i in eachindex(mdata.swe)
    mdata.swe[i] = 0.
    mdata.lw[i] = 0.
  end

end


"""
    get_param_range(mdata::TinStandard)

Get allowed parameter ranges for the calibration of the model.
"""
function get_param_range(mdata::TinStandard)

  param_range_snow = [(-0.5, 0.5), (0.5, 3.0), (0.5, 4.0), (0.01, 0.10), (0.5, 2.0)]

end


"""
    assign_param(mdata::TinStandard, param::Array{Float64,1})

Assign parameter values to the TinBasic type.
"""
function assign_param(mdata::TinStandard, param::Array{Float64,1})

  for i in eachindex(mdata.param)
    mdata.param[i] = param[i]
  end

end


"""
    enkf_snow(mdata::Array{TinStandard}, obs_ens, q_sim)

Implementation of the ensemble Kalman filter for the standard temperature index
snow model.
"""
function enkf_snow(mdata::Array{TinStandard}, obs_ens, q_sim)

  nens = length(mdata)

  # Allocate arrays

  swe = zeros(Float64, length(mdata[1].swe), nens)
  lw = zeros(Float64, length(mdata[1].lw), nens)

  # Add states to arrays

  for iens = 1:nens

    swe[:, iens] = mdata[iens].swe
    lw[:, iens] = mdata[iens].lw

  end

  # Run ensemble kalman filter

  swe = enkf(swe, obs_ens, q_sim)
  lw = enkf(lw, obs_ens, q_sim)

  # Check limits of states

  swe[swe .< 0] = 0.

  lwmax = swe * mdata[1].param[4]

  lw[lw .< 0] = 0.
  lw[lw .> lwmax] = 0.

  # Add arrays to states

  for iens = 1:nens

    mdata[iens].swe = swe[:, iens]
    mdata[iens].lw = lw[:, iens]

  end

  nothing

end


"""
    snow_model(mdata::TinStandard)

Propagate the model one time step and compute simulated snowpack dischage.
"""
function snow_model(mdata::TinStandard)

  # Parameters

  tth     = mdata.param[1]
  ddf_min = mdata.param[2] * mdata.tstep
  ddf_max = mdata.param[3] * mdata.tstep
  whcap   = mdata.param[4]
  pcorr   = mdata.param[5]

  ddf = compute_ddf(mdata.date, ddf_min, ddf_max)

  mdata.infilt = 0.0

  for i in eachindex(mdata.swe)

    swe = mdata.swe[i]
    lw = mdata.lw[i]

    # Compute solid and liquid precipitation

    psolid, pliquid = split_prec(mdata.prec[i], mdata.tair[i], tth)

    # Apply snowfall correction factor

    psolid = pcorr * psolid

    # Compute frozen water in snowpack

    fw  = swe - lw

    # Constrain fw and lw

    if fw < 0.
        fw = 0.
    end

    if lw < 0.
        lw = 0.
    end

    # Compute melt rates

    melt = compute_melt(mdata.tair[i], fw, ddf, tth)

    # Compute refreezing rates

    refr = compute_refreeze(mdata.tair[i], lw, ddf, tth)

    # Massbalance for frozen water in snowpack

    dfw = psolid + refr - melt
    fw  = fw + dfw

    # Massbalance for liquid water in snowpack

    dlw = pliquid + melt - refr
    lw  = lw + dlw

    lwmax = fw * whcap / (1 - whcap)

    infilt = lw - lwmax

    if infilt < 0.
        infilt = 0.
    end

    lw = lw - infilt

    # Massbalance for snowpack

    swe = fw + lw

    # Assign final results

    mdata.swe[i] = swe
    mdata.lw[i] = lw
    mdata.infilt += mdata.frac[i] * infilt

    end

end


# Split precipitation into rainfall and snowfall

function split_prec(prec::Float64, tair::Float64, tth_phase::Float64)

    m_phase = 1.0

    frac_snowfall = 1. / (1. + exp( (tair - tth_phase) / m_phase ))

    psolid = prec * frac_snowfall
    pliquid = prec - psolid

    return psolid, pliquid

end

# Compute snowmelt

function compute_melt(tair::Float64, fw::Float64, ddf::Float64, tth_melt::Float64)

    m_melt = 0.5

    t_m = (tair - tth_melt) / m_melt
    melt = ddf * m_melt * (t_m + log(1. + exp(-t_m)))

    melt = min(max(0.,fw), melt)

    return melt

end

# Compute refreeze

function compute_refreeze(tair::Float64, lw::Float64, ddf::Float64, tth_refr::Float64)

    m_refr = 0.5

    t_m = (tth_refr - tair) / m_refr
    refr = ddf * m_refr * (t_m + log(1. + exp(-t_m)))

    if refr > lw
        refr = lw
    end

    refr = min(lw,refr)

end

# Compute degree day factor

function compute_ddf(date::Date, ddf_min::Float64, ddf_max::Float64)

    doy = Dates.dayofyear(date)

    ddf = (ddf_max - ddf_min) * (0.5*sin(2.0*pi*(Dates.dayofyear(date) - 80)/366) + 0.5) + ddf_min

    return ddf

end
