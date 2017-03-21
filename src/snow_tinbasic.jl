

# Type definitions

type TinBasic <: Snow

  prec::Array{Float64,1}
  tair::Array{Float64,1}
  swe::Array{Float64,1}
  infilt::Float64
  param::Array{Float64,1}
  frac::Array{Float64,1}
  tstep::Float64

end

# Outer constructors

function TinBasic(tstep, frac)

  nzones = length(frac)
  prec   = zeros(Float64, nzones)
  tair   = zeros(Float64, nzones)
  swe    = zeros(Float64, nzones)
  infilt = 0.0
  param  = [0.0, 3.0, 1.0]

  TinBasic(prec, tair, swe, infilt, param, frac, tstep)

end

function TinBasic(tstep, param, frac)

  nzones = length(frac)
  prec   = zeros(Float64, nzones)
  tair   = zeros(Float64, nzones)
  swe    = zeros(Float64, nzones)
  infilt = 0.0

  TinBasic(prec, tair, swe, infilt, param, frac, tstep)

end

# Parameter ranges for calibration

function get_param_range(mdata::TinBasic)

  param_range_snow = [(-0.5, 0.5), (1.0, 8.0), (0.5, 2.0)]

end

# Initilize state variables

function init_states(mdata::TinBasic)

  for i in eachindex(mdata.swe)
    mdata.swe[i] = 0.
  end

end

# Assign parameter values

function assign_param(mdata::TinBasic, param::Array{Float64,1})

  for i in eachindex(mdata.param)
    mdata.param[i] = param[i]
  end

end



# Temperature index snow model

function snow_model(mdata::TinBasic)

  # Parameters

  tth   = mdata.param[1]
  ddf   = mdata.param[2] * mdata.tstep
  pcorr = mdata.param[3]

  mdata.infilt = 0.0

  for i in eachindex(mdata.swe)

    # Compute solid and liquid precipitation

    psolid  = mdata.prec[i] * pcorr
    pliquid = mdata.prec[i] * pcorr

    mdata.tair[i] > tth ? psolid = 0.0 : pliquid = 0.0

    # Compute snow melt

    mdata.tair[i] < tth ? M = 0.0 : M = ddf * mdata.tair[i]

    M = min(mdata.swe[i],M)

    # Update snow water equivalents

    mdata.swe[i] += psolid
    mdata.swe[i] -= M

    # Compute infiltration

    mdata.infilt += mdata.frac[i]*(M + pliquid)

  end

end
