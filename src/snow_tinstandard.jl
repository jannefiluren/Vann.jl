

# Type definitions

type TinStandardType <: SnowType
  prec::Array{Float64,1}
  tair::Array{Float64,1}
  date::Date
  swe::Array{Float64,1}
  lw::Array{Float64,1}
  infilt::Float64
  param::Array{Float64,1}
  frac::Array{Float64,1}
end

# Outer constructors

function TinStandardType(frac)

  nzones = length(frac);
  prec   = zeros(Float64, nzones);
  tair   = zeros(Float64, nzones);
  date   = Date();
  swe    = zeros(Float64, nzones);
  lw     = zeros(Float64, nzones);
  infilt = 0.0;
  param  = zeros(Float64, 5);

  TinStandardType(prec, tair, date, swe, lw, infilt, param, frac)

end

function TinStandardType(param, frac)

  nzones = length(frac);
  prec   = zeros(Float64, nzones);
  tair   = zeros(Float64, nzones);
  date   = Date();
  swe    = zeros(Float64, nzones);
  lw     = zeros(Float64, nzones);
  infilt = 0.0;

  TinStandardType(prec, tair, date, swe, lw, infilt, param, frac)

end

# Parameter ranges for calibration

function get_param_range(States::TinStandardType)

  param_range_snow = [(-2.0, 2.0), (0.5, 3.0), (0.5, 4.0), (0.01, 0.10), (0.5, 2.0)];

end

# Initilize state variables

function init_states(States::TinStandardType)

  for i in eachindex(States.swe)
    States.swe[i] = 0.;
    States.lw[i] = 0.;
  end

end

# Assign parameter values

function assign_param(States::TinStandardType, param::Array{Float64,1})

  for i in eachindex(States.param)
    States.param[i] = param[i];
  end

end




# Temperature index snow model

function snow_model(States::TinStandardType)

  # Parameters

  tth     = States.param[1];
  ddf_min = States.param[2];
  ddf_max = States.param[3];
  whcap   = States.param[4];
  pcorr   = States.param[5];

  ddf = compute_ddf(States.date, ddf_min, ddf_max);

  States.infilt = 0.0;

  for i in eachindex(States.swe)

    swe = States.swe[i];
    lw = States.lw[i];

    # Compute solid and liquid precipitation

    psolid, pliquid = split_prec(States.prec[i], States.tair[i], tth);

    # Apply snowfall correction factor

    psolid = pcorr * psolid;

    # Compute frozen water in snowpack

    fw  = swe - lw;

    # Constrain fw and lw

    if fw < 0.
        fw = 0.;
    end

    if lw < 0.
        lw = 0.;
    end

    # Compute melt rates

    melt = compute_melt(States.tair[i], fw, ddf, tth);

    # Compute refreezing rates

    refr = compute_refreeze(States.tair[i], lw, ddf, tth);

    # Massbalance for frozen water in snowpack

    dfw = psolid + refr - melt;
    fw  = fw + dfw;

    # Massbalance for liquid water in snowpack

    dlw = pliquid + melt - refr;
    lw  = lw + dlw;

    lwmax = fw * whcap / (1 - whcap);

    infilt = lw - lwmax;

    if infilt < 0.
        infilt = 0.;
    end

    lw = lw - infilt;

    # Massbalance for snowpack

    swe = fw + lw;

    # Assign final results

    States.swe[i] = swe;
    States.lw[i] = lw;
    States.infilt += States.frac[i] * infilt;

    end

end


# Split precipitation into rainfall and snowfall

function split_prec(prec::Float64, tair::Float64, tth_phase::Float64)

    m_phase = 1.0;

    frac_snowfall = 1. / (1. + exp( (tair - tth_phase) / m_phase ));

    psolid = prec * frac_snowfall;
    pliquid = prec - psolid;

    return psolid, pliquid

end

# Compute snowmelt

function compute_melt(tair::Float64, fw::Float64, ddf::Float64, tth_melt::Float64)

    m_melt = 0.5;

    t_m = (tair - tth_melt) / m_melt;
    melt = ddf * m_melt * (t_m + log(1. + exp(-t_m)));

    melt = min(max(0.,fw), melt);

    return melt

end

# Compute refreeze

function compute_refreeze(tair::Float64, lw::Float64, ddf::Float64, tth_refr::Float64)

    m_refr = 0.5;

    t_m = (tth_refr - tair) / m_refr;
    refr = ddf * m_refr * (t_m + log(1. + exp(-t_m)));

    if refr > lw
        refr = lw;
    end

    refr = min(lw,refr);

end

# Compute degree day factor

function compute_ddf(date::Date, ddf_min::Float64, ddf_max::Float64)

    doy = Dates.dayofyear(date);

    ddf = (ddf_max - ddf_min) * (0.5*sin(2.0*pi*(Dates.dayofyear(date) - 80)/366) + 0.5) + ddf_min;

    return ddf

end
