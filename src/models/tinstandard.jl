

"""
The TinStandard type contains the state variables (swe), the inputs
(prec, tair) for one time step, the parameters (param) and the time step
length (tstep) for a standard temperature index model.
"""
type TinStandard <: Snow

  swe::Array{Float64,1}
  lw::Array{Float64,1}
  prec::Array{Float64,1}
  tair::Array{Float64,1}
  q_sim::Array{Float64,1}
  param::Array{Float64,1}
  frac::Array{Float64,1}
  tstep::Float64
  time::DateTime

end


"""
    TinStandard(tstep, time, frac)

Constructor for TinStandard with predefined state variables, parameters and inputs.
The time step (tstep) is given as a fraction of one day. Thus, for hourly input
data tstep should be set to 1/24. The fraction of elevation bands should sum
up to unity.
"""
function TinStandard(tstep::Float64, time::DateTime, frac::Array{Float64,1})

  nzones = length(frac)
  swe    = zeros(Float64, nzones)
  lw     = zeros(Float64, nzones)
  prec   = zeros(Float64, nzones)
  tair   = zeros(Float64, nzones)
  q_sim  = zeros(Float64, nzones)
  param  = zeros(Float64, 5)

  TinStandard(swe, lw, prec, tair, q_sim, param, frac, tstep, time)

end


"""
    TinStandard(tstep, time, param, frac)

Constructor for TinStandard with predefined state variables and inputs.
The time step (tstep) is given as a fraction of one day. Thus, for hourly input
data tstep should be set to 1/24. The fraction of elevation bands should sum
up to unity.
"""
function TinStandard(tstep::Float64, time::DateTime, param::Array{Float64,1}, frac::Array{Float64,1})

  nzones = length(frac)
  swe    = zeros(Float64, nzones)
  lw     = zeros(Float64, nzones)
  prec   = zeros(Float64, nzones)
  tair   = zeros(Float64, nzones)
  q_sim  = zeros(Float64, nzones)

  TinStandard(swe, lw, prec, tair, q_sim, param, frac, tstep, time)

end


"""
    init_states(mdata::TinStandard)

Initilize the state variables of the model.
"""
function init_states(mdata::TinStandard)

  for ireg in eachindex(mdata.swe)
    mdata.swe[ireg] = 0.
    mdata.lw[ireg] = 0.
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
    get_states(mdata::TinStandard)

Get state variables for computing penelty during calibration.

"""
function get_states(mdata::TinStandard)

  return [mean(mdata.swe); mean(mdata.lw)]

end



"""
    assign_param(mdata::TinStandard, param::Array{Float64,1})

Assign parameter values to the TinBasic type.
"""
function assign_param(mdata::TinStandard, param::Array{Float64,1})

  for ireg in eachindex(mdata.param)
    mdata.param[ireg] = param[ireg]
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
    run_timestep(mdata::TinStandard)

Propagate the model one time step and compute simulated snowpack dischage.
"""
function run_timestep(mdata::TinStandard)

    # Parameters

    tth     = mdata.param[1]
    ddf_min = mdata.param[2]
    ddf_max = mdata.param[3]
    whcap   = mdata.param[4]
    pcorr   = mdata.param[5]

    ddf = compute_ddf(mdata.time, ddf_min, ddf_max)

    for ireg in eachindex(mdata.swe)

        swe = mdata.swe[ireg]
        lw = mdata.lw[ireg]

        # Compute solid and liquid precipitation

        psolid, pliquid = split_prec(mdata.prec[ireg], mdata.tair[ireg], tth)

        # Apply snowfall correction factor

        psolid = pcorr * psolid

        # Compute frozen water in snowpack

        fw  = swe - lw

        # Constrain fw and lw

        if fw < 0.0
            fw = 0.0
        end

        if lw < 0.0
            lw = 0.0
        end

        # Compute melt rates

        melt = compute_melt(mdata.tair[ireg], fw, ddf, tth)

        # Compute refreezing rates

        refr = compute_refreeze(mdata.tair[ireg], lw, ddf, tth)

        # Massbalance for frozen water in snowpack

        dfw = psolid + refr - melt
        fw  = fw + dfw

        # Massbalance for liquid water in snowpack

        dlw = pliquid + melt - refr
        lw  = lw + dlw

        lwmax = fw * whcap / (1 - whcap)

        q_sim = lw - lwmax

        if q_sim < 0.
            q_sim = 0.
        end

        lw = lw - q_sim

        # Massbalance for snowpack

        swe = fw + lw

        # Assign final results

        mdata.swe[ireg] = swe
        mdata.lw[ireg] = lw
        mdata.q_sim[ireg] = q_sim

    end

    mdata.time += Dates.Hour(mdata.tstep)

    return nothing

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
