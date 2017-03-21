

# Type definitions

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

# Outer constructors

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

# Parameter ranges for calibration

function get_param_range(mdata::TinStandard)

  param_range_snow = [(-0.5, 0.5), (0.5, 3.0), (0.5, 4.0), (0.01, 0.10), (0.5, 2.0)]

end

# Initilize state variables

function init_states(mdata::TinStandard)

  for i in eachindex(mdata.swe)
    mdata.swe[i] = 0.
    mdata.lw[i] = 0.
  end

end

# Assign parameter values

function assign_param(mdata::TinStandard, param::Array{Float64,1})

  for i in eachindex(mdata.param)
    mdata.param[i] = param[i]
  end

end




# Temperature index snow model

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
