


# Type definitions

type HbvType <: HydroType

  sm::Array{Float64,1}
  suz::Array{Float64,1}
  slz::Array{Float64,1}
  st_uh::Array{Float64,1}
  epot::Float64
  infilt::Float64
  param::Array{Float64,1}
  frac::Array{Float64,1}

end


# Outer constructors

function Gr4jType(frac)

  nzones  = length(frac);

  st      = zeros(Float64, 2);
  st_uh1  = zeros(Float64, 20);
  st_uh2  = zeros(Float64, 40);
  ord_uh1 = zeros(Float64, 20);
  ord_uh2 = zeros(Float64, 40);

  epot   = 0.0;
  infilt = 0.0;
  param  = [257.238, 1.012, 88.235, 2.208];

  st[1] = 0.3 * param[1];
  st[2] = 0.5 * param[3];

  UH1(ord_uh1, param[4], 2.5);
  UH2(ord_uh2, param[4], 2.5);

  Gr4jType(st, st_uh1, st_uh2, ord_uh1, ord_uh2, epot, infilt, param, frac);

end










# Loop over time

for i in eachindex(prec)

  # Input for current time step

  prec_now = prec[i]
  epot_now = epot[i]

  # Soil moisture zone (assume no evaporation during rainfall)

  if prec_now > 0.

    # Beta function

    f_recharge = (sm / fc) ^ beta;

    # Groundwater recharge

    recharge = f_recharge * prec_now;

    # Update soil moisture zone

    sm = sm + prec_now - recharge;

    # Add excess soil moisture to groundwater recharge

    if sm > fc
      recharge += sm - fc;
      sm = fc;
    end

    # No evapotranspiration

    eact = 0.;

  else

    # Compute actual evapotranspiration

    eact = epot_now * min(sm/(fc*lp), 1.)

    # Update soil moisture zone

    sm = sm - eact;

    # Check limits for soil moisture zone

    if sm < 0.
      eact = max(eact + sm, 0.);
      sm = 0.;
    end

    # No groundwater recharge

    recharge = 0.;

  end

  # Add recharge to upper groundwater box

  suz = suz + recharge;

  # Remove percolation from upper groundwater box

  perc_now = min(perc, suz);

  suz = suz - perc_now;

  # Compute runoff from upper groundwater box and update storage

  q_suz = k1 * suz + k0 * max(suz-ulz, 0);

  suz = suz - q_suz;

  if suz < 0.
    q_suz = max(q_suz + suz, 0.);
    suz = 0.
  end

  # Add precolation to lower groundwater box

  slz = slz + perc_now;

  # Compute runoff from lower groundwater box and update storage

  q_slz = k2 * slz;

  slz = slz - q_slz;

  # Convolution of unit hydrograph

  q_tmp = q_suz + q_slz;

  nh = length(hbv_ord);

  for k = 1:nh-1
    st_uh[k] = st_uh[k+1] + hbv_ord[k]*q_tmp;
  end

  st_uh[nh] = hbv_ord[nh] * q_tmp;

  # Compute total runoff

  q_tot = st_uh[1];

  # Store results

  q_out[i]   = q_tot;
  sm_out[i]  = sm;
  suz_out[i] = suz;
  slz_out[i] = slz;

end
