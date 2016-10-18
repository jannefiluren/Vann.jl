

# Type definitions

type TinBasicType <: SnowType
  prec::Array{Float64,1}
  tair::Array{Float64,1}
  swe::Array{Float64,1}
  infilt::Float64
  param::Array{Float64,1}
  frac::Array{Float64,1}
end

# Outer constructors

function TinBasicType(frac)

  nzones = length(frac);
  prec   = zeros(Float64, nzones);
  tair   = zeros(Float64, nzones);
  swe    = zeros(Float64, nzones);
  infilt = 0.0;
  param  = zeros(Float64, 3);

  TinBasicType(swe, prec, tair, infilt, param, frac);

end

function TinBasicType(param, frac)

  nzones = length(frac);
  prec   = zeros(Float64, nzones);
  tair   = zeros(Float64, nzones);
  swe    = zeros(Float64, nzones);
  infilt = 0.0;

  TinBasicType(swe, prec, tair, infilt, param, frac);

end

# Parameter ranges for calibration

function get_param_range(States::TinBasicType)

  param_range_snow = [(-0.5, 0.5), (1.0, 8.0), (0.5, 2.0)];

end

# Initilize state variables

function init_states(States::TinBasicType)

  for i in eachindex(States.swe)
    States.swe[i] = 0.;
  end

end

# Assign parameter values

function assign_param(States::TinBasicType, param::Array{Float64,1})

  for i in eachindex(States.param)
    States.param[i] = param[i];
  end

end



# Temperature index snow model

function snow_model(States::TinBasicType)

  # parameters

  tth   = States.param[1];
  ddf   = States.param[2];
  pcorr = States.param[3];

  States.infilt = 0.0;

  for i in eachindex(States.swe)

    # Compute solid and liquid precipitation

    psolid  = States.prec[i] * pcorr;
    pliquid = States.prec[i] * pcorr;

    States.tair[i] > tth ? psolid = 0.0 : pliquid = 0.0;

    # Compute snow melt

    States.tair[i] < tth ? M = 0.0 : M = ddf * States.tair[i];

    M = min(States.swe[i],M);

    # Update snow water equivalents

    States.swe[i] += psolid;
    States.swe[i] -= M;

    # Compute infiltration

    States.infilt += States.frac[i]*(M + pliquid)

  end

end
