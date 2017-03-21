

"""
Gr4j represents the states, parameters and inputs to the GR4J model.
"""

type Gr4j <: Hydro

  st::Array{Float64,1}
  st_uh1::Array{Float64,1}
  st_uh2::Array{Float64,1}
  ord_uh1::Array{Float64,1}
  ord_uh2::Array{Float64,1}
  epot::Float64
  infilt::Float64
  param::Array{Float64,1}
  tstep::Float64

end


"""
    Gr4j(tstep)

Construct a Gr4j type with states, parameters and inputs preset.
"""

function Gr4j(tstep)

  n_ord = ceil(Int64, 20.0 / tstep)

  st      = zeros(Float64, 2)
  st_uh1  = zeros(Float64, n_ord)
  st_uh2  = zeros(Float64, 2 * n_ord)
  ord_uh1 = zeros(Float64, n_ord)
  ord_uh2 = zeros(Float64, 2 * n_ord)

  epot   = 0.0
  infilt = 0.0
  param  = [257.238, 1.012, 88.235, 2.208]

  st[1] = 0.3 * param[1]
  st[2] = 0.5 * param[3]

  UH1(ord_uh1, param[4]/tstep, 2.5)
  UH2(ord_uh2, param[4]/tstep, 2.5)

  Gr4j(st, st_uh1, st_uh2, ord_uh1, ord_uh2, epot, infilt, param, tstep)

end


"""
    Gr4j(tstep, param)


Construct a Gr4j type with parameters as input.
"""

function Gr4j(tstep, param)

  n_ord = ceil(Int64, 20.0 / tstep)

  st      = zeros(Float64, 2)
  st_uh1  = zeros(Float64, n_ord)
  st_uh2  = zeros(Float64, 2 * n_ord)
  ord_uh1 = zeros(Float64, n_ord)
  ord_uh2 = zeros(Float64, 2 * n_ord)

  st[1] = 0.3 * param[1]
  st[2] = 0.5 * param[3]

  UH1(ord_uh1, param[4]/tstep, 2.5)
  UH2(ord_uh2, param[4]/tstep, 2.5)

  epot   = 0.0
  infilt = 0.0

  Gr4j(st, st_uh1, st_uh2, ord_uh1, ord_uh2, epot, infilt, param, tstep)

end


"""
    get_param_range(mdata::Gr4j)

Get parameter ranges for calibration for the GR4J model.
"""

function get_param_range(mdata::Gr4j)

  param_range_hydro = [(1.0, 1000.0), (-10.0, 10.0), (1.0, 500.0), (0.5, 10.0)]

end


"""
    init_states(mdata::Gr4j)

Initilize state variables for the GR4J model.
"""

function init_states(mdata::Gr4j)

  mdata.st[1] = 0.3 * mdata.param[1]
  mdata.st[2] = 0.5 * mdata.param[3]

  for i in eachindex(mdata.st_uh1)
    mdata.st_uh1[i] = 0.
  end

  for i in eachindex(mdata.st_uh2)
    mdata.st_uh2[i] = 0.
  end

end


"""
    assign_param(mdata::Gr4j, param::Array{Float64,1})

# Assign parameter values for GR4J model.
"""

function assign_param(mdata::Gr4j, param::Array{Float64,1})

  for i in eachindex(mdata.param)
    mdata.param[i] = param[i]
  end

  UH1(mdata.ord_uh1, param[4]/mdata.tstep, 2.5)
  UH2(mdata.ord_uh2, param[4]/mdata.tstep, 2.5)

end


"""
    hydro_model(mdata::Gr4j)

Run one time step for the GR4J model.
"""

function hydro_model(mdata::Gr4j)

  St     = mdata.st
  StUH1  = mdata.st_uh1
  StUH2  = mdata.st_uh2
  OrdUH1 = mdata.ord_uh1
  OrdUH2 = mdata.ord_uh2
  Param  = mdata.param
  P1     = mdata.infilt
  E      = mdata.epot

  Param[3] = Param[3] * mdata.tstep

  A = Param[1]
  B = 0.9

  # Interception and production store

  if P1 <= E
    EN = E - P1
    PN = 0.0
    WS = EN / A
    if WS > 13.0
      WS = 13.0
    end
    TWS = tanh(WS)
    Sr = St[1] / A
    ER = St[1] * (2.0-Sr)*TWS/(1.0+(1.0-Sr)*TWS)
    AE = ER + P1
    St[1] = St[1] - ER
    PR = 0.0
  else
    EN = 0.0
    AE = E
    PN = P1 - E
    WS = PN / A
    if WS > 13.0
      WS = 13.0
    end
    TWS = tanh(WS)
    Sr = St[1] / A
    PS = A*(1.0-Sr*Sr)*TWS/(1.0+Sr*TWS)
    PR = PN - PS
    St[1] = St[1] + PS
  end

  # Percolation from production store

  if St[1] < 0.0
    St[1] = 0.0
  end

  Sr = St[1] / Param[1]
  Sr = Sr * Sr
  Sr = Sr * Sr
  PERC = St[1] * (1.0-1.0/sqrt(sqrt(1.0 + Sr/25.62891)))

  St[1] = St[1] - PERC

  PR = PR + PERC

  # Split of effective rainfall into the two routing components

  PRHU1 = PR * B
  PRHU2 = PR * (1.0-B)

  # Convolution of unit hydrograph UH1

  NH = length(OrdUH1)

  for K = 1:NH-1
    StUH1[K] = StUH1[K+1] + OrdUH1[K]*PRHU1
  end

  StUH1[NH] = OrdUH1[NH] * PRHU1

  # Convolution of unit hydrograph UH2

  NH = length(OrdUH2)

  for K = 1:NH-1
    StUH2[K] = StUH2[K+1] + OrdUH2[K]*PRHU2
  end

  StUH2[NH] = OrdUH2[NH] * PRHU2

  # Potential intercatchment semi-exchange

  Rr = St[2]/Param[3]
  EXCH = Param[2]*Rr*Rr*Rr*sqrt(Rr)

  # Routing store

  AEXCH1 = EXCH

  if (St[2]+StUH1[1]+EXCH) < 0.0
    AEXCH1 = -St[2] - StUH1[1]
  end

  St[2] = St[2] + StUH1[1] + EXCH

  if St[2] < 0.0
    St[2] = 0.0
  end

  Rr = St[2] / Param[3]
  Rr = Rr * Rr
  Rr = Rr * Rr
  QR = St[2] * (1.0-1.0/sqrt(sqrt(1.0+Rr)))

  St[2] = St[2] - QR

  # Runoff from direct branch QD

  AEXCH2 = EXCH

  if (StUH2[1]+EXCH) < 0.0
    AEXCH2 = -StUH2[1]
  end

  QD = max(0.0,StUH2[1]+EXCH)

  # Total runoff

  Q = QR + QD

  if Q < 0.0
    Q = 0.0
  end

  mdata.st      = St
  mdata.st_uh1  = StUH1
  mdata.st_uh2  = StUH2
  mdata.ord_uh1 = OrdUH1
  mdata.ord_uh2 = OrdUH2

  return(Q)

end


function SS1(I,C,D)

  FI = I
  if FI <= 0.0
    SS1 = 0.0
  elseif FI < C
    SS1 = (FI/C)^D
  else
    SS1 = 1.0
  end

end


function SS2(I,C,D)

  FI = I
  if FI <= 0.0
    SS2 = 0.0
  elseif FI <= C
    SS2 = 0.5*(FI/C)^D
  elseif FI < 2.0*C
    SS2 = 1.0-0.5*(2.0-FI/C)^D
  else
    SS2=1.0
  end

end


function UH1(OrdUH1,C,D)

  NH = length(OrdUH1)

  for I in 1:NH

    OrdUH1[I] = SS1(I,C,D)-SS1(I-1,C,D)

  end

end


function UH2(OrdUH2,C,D)

  NH = length(OrdUH2)

  for I in 1:NH

    OrdUH2[I] = SS2(I,C,D)-SS2(I-1,C,D)

  end

end



#**********************************************************************
#     SUBROUTINE MOD_GR4J(St,StUH1,StUH2,OrdUH1,OrdUH2,Param,P1,E,Q)
# Run on a single time step with the GR4J model
# Inputs:
#       St     Vector of model states in stores at the beginning of the time step [mm]
#       StUH1  Vector of model states in Unit Hydrograph 1 at the beginning of the time step [mm]
#       StUH2  Vector of model states in Unit Hydrograph 2 at the beginning of the time step [mm]
#       OrdUH1 Vector of ordinates in UH1 [-]
#       OrdUH2 Vector of ordinates in UH2 [-]
#       Param  Vector of model parameters [various units]
#       P1     Value of rainfall during the time step [mm/day]
#       E      Value of potential evapotranspiration during the time step [mm/day]
# Outputs:
#       St     Vector of model states in stores at the end of the time step [mm]
#       StUH1  Vector of model states in Unit Hydrograph 1 at the end of the time step [mm]
#       StUH2  Vector of model states in Unit Hydrograph 2 at the end of the time step [mm]
#       Q      Value of simulated flow at the catchment outlet for the time step [mm]
#**********************************************************************

#**********************************************************************
#     FUNCTION SS1(I,C,D)
# Values of the S curve (cumulative HU curve) of GR unit hydrograph UH1
# Inputs:
#    C: time constant
#    D: exponent
#    I: time-step
# Outputs:
#    SS1: Values of the S curve for I
#**********************************************************************

#**********************************************************************
#     FUNCTION SS2(I,C,D)
# Values of the S curve (cumulative HU curve) of GR unit hydrograph UH2
# Inputs:
#    C: time constant
#    D: exponent
#    I: time-step
# Outputs:
#    SS2: Values of the S curve for I
#**********************************************************************

#**********************************************************************
#     SUBROUTINE UH1(OrdUH1,C,D)
# Computation of ordinates of GR unit hydrograph UH1 using successive differences on the S curve SS1
# Inputs:
#    C: time constant
#    D: exponent
# Outputs:
#    OrdUH1: NH ordinates of discrete hydrograph
#**********************************************************************

#**********************************************************************
#     SUBROUTINE UH2(OrdUH2,C,D)
# Computation of ordinates of GR unit hydrograph HU2 using successive differences on the S curve SS2
# Inputs:
#    C: time constant
#    D: exponent
# Outputs:
#    OrdUH2: 2*NH ordinates of discrete hydrograph
#**********************************************************************
