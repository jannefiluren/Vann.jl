# water to soil routine
# snow pack
# water content in snow
# meltwater
# refreezing meltwater
# boolean (snow at start of timestep?)

# Q_box0, Q_box1, Q_box2 - Q from box1 och box2
# SUZ, SLZ - storage in box1 och box2
# Q_gen - Q before MAXBAS

# Packages

using Distributions
using PyPlot
using CSV

# Function for computing ordinates of unit hydrograph

function compute_hbv_ord(maxbas, tstep)

  maxbas = maxbas / tstep

  triang = Distributions.TriangularDist(0, maxbas)

  triang_cdf = Distributions.cdf(triang, 0:ceil(Int64, maxbas + 2))

  hbv_ord = diff(triang_cdf)

  return(hbv_ord)

end

# Compute monthly potential evapotranspiration

function epot_monthly(datevec)

    # Monthly values of potential evapotranspiration (mm/day)

    epot_month = [0.05, 0.14, 0.46, 1.5, 3.01, 4.15, 3.66, 2.72, 1.42, 0.43, 0.03, 0.0]

    # Assign montly values to days

    epot = zeros(Float64, length(datevec))

    for i in eachindex(datevec)

        imonth = Dates.month(datevec[i])

        epot[i] = epot_month[imonth]

    end

    return(epot)

end

# Input data


data = CSV.read("C:\\Work\\Studies\\vann\\hbv_light\\ptq.txt",
                types = [DateTime, Float64, Float64, Float64],
                delim = "\t", dateformat = "yyyymmdd", header = true)

date = Array(data[:date])
Prec = Array(data[:Prec])
temp = Array(data[:Temp])
Qobs = Array(data[:Qsim])

Prec = transpose(Prec)
temp = transpose(temp)

pET = epot_monthly(date)

# Settings

UseOldSUZ = true

# Elevation and vegetation zones

lake = 0.0
nelev = size(Prec, 1)
nveg = 1
area = ones(nveg, nelev)
area = area / sum(area)

# Parameter values

PERC = 0.7
K0 = 0.2
K1 = 0.08
K2 = 0.03
UZL = 20.0

par_TT = [-1.0]
par_CFMAX = [5.0]
par_SFCF = [0.8]
par_CFR = [0.05]
par_CWH = [0.1]
par_FC = [250.0]
par_LP = [0.7]
par_BETA = [3.0]

par_MAXBAS = 2.5*24.0
tstep = 24.0

maxTS = size(Prec,2)

# Initilize state variables

state_SP = zeros(nveg, nelev)
state_WC = zeros(nveg, nelev)
state_SM = zeros(nveg, nelev)

# Temporary

runoff_sim = zeros(size(Prec,2))
snow_sim = zeros(size(Prec,2))
SM_sim = zeros(size(Prec,2))
SUZ_sim = zeros(size(Prec,2))
SLZ_sim = zeros(size(Prec,2))
aET_sim = zeros(size(Prec,2))
recharge_sim = zeros(size(Prec,2))
Q_com = zeros(size(Prec,2))

# Compute maxbas weights

maxbas_w = compute_hbv_ord(par_MAXBAS, tstep)

# Initilize state variables

SUZ = 0.0
SLZ = min(PERC / K2, Qobs[1] / K2)
Q_box0 = 0.0

for t = 1:size(Prec, 2)

    pot_E = pET[t] * (1 - lake)

    till_Qsum = 0.0
    avg_act_E = 0.0

    for elevzone = 1:nelev

        P_zone = Prec[elevzone, t]
        T_zone = temp[elevzone, t]

        for vegzone = 1:nveg

            if area[vegzone, elevzone] > 0.0

                SP = state_SP[vegzone, elevzone]
                WC = state_WC[vegzone, elevzone]
                SM = state_SM[vegzone, elevzone]

                tt = par_TT[vegzone]
                CFMAX = par_CFMAX[vegzone]
                SFCF = par_SFCF[vegzone]
                CFR = par_CFR[vegzone]
                CWH = par_CWH[vegzone]
                FC = par_FC[vegzone]
                LP = par_LP[vegzone]
                BETA = par_BETA[vegzone]

                snow = (SP > 0)

                #snow routine

                insoil = 0.0
                if SP > 0.0

                    if P_zone > 0.0
                        if T_zone > tt
                            WC = WC + P_zone
                        else
                            SP = SP + P_zone * SFCF
                        end
                    end # if P_zone

                    if T_zone > tt
                        melt = CFMAX * (T_zone - tt)
                        if melt > SP
                            insoil = SP + WC
                            WC = 0.0
                            SP = 0.0
                        else
                            SP = SP - melt
                            WC = WC + melt
                            if WC >= CWH * SP
                                insoil = WC - CWH * SP
                                WC = CWH * SP
                            end
                        end
                    else
                        refrez = CFR * CFMAX * (tt - T_zone)
                        if refrez > WC
                            refrez = WC
                        end
                        SP = SP + refrez
                        WC = WC - refrez
                    end # if T_zone
                else
                    if T_zone > tt
                        insoil = P_zone
                    else
                        SP = P_zone * SFCF
                    end # if T_zone
                end # if SP

                #soil routine

                till_Q = 0.0
                old_SM = SM
                if insoil > 0.0
                    if insoil < 1.0
                        y = insoil
                    else
                        m = floor(insoil)   # IS THIS CORRECT
                        y = insoil - m
                        for i in 1:m
                            dQdP = (SM / FC) ^ BETA
                            if dQdP > 1.0
                                dQdP = 1.0
                            end
                            SM = SM + 1.0 - dQdP
                            till_Q = till_Q + dQdP
                        end
                    end
                    dQdP = (SM / FC) ^ BETA
                    if dQdP > 1.0
                        dQdP = 1.0
                    end
                    SM = SM + (1 - dQdP) * y
                    till_Q = till_Q + dQdP * y
                end # if insoil

                mean_SM = (SM + old_SM) / 2.0
                if mean_SM < (LP * FC)
                    act_E = pot_E * mean_SM / (LP * FC)
                else
                    act_E = pot_E
                end
                if snow
                    act_E = 0.0
                end
                SM = SM - act_E
                if SM < 0.0
                    SM = 0.0
                end

                avg_act_E = avg_act_E + act_E * area[vegzone, elevzone]
                till_Qsum = till_Qsum + till_Q * area[vegzone, elevzone]
                state_SP[vegzone, elevzone] = SP
                state_WC[vegzone, elevzone] = WC
                state_SM[vegzone, elevzone] = SM

            end # if area

        end # veg loop

    end # elev loop

    till_box1 = till_Qsum

    # generation of runoff
    SUZ = SUZ + till_box1
    if ( SUZ - PERC / (1 - lake) ) < 0.0
        SLZ = SLZ + SUZ * (1.0 - lake)
        SUZ = 0.0
    else
        SLZ = SLZ + PERC
        SUZ = SUZ - PERC / (1.0 - lake)
    end

    tt = mean(par_TT)   # CHECK WITH JAN WHAT THIS MEANS
    SFCF = mean(SFCF)   # CHECK WITH JAN WHAT THIS MEANS

    if mean(temp[:,t]) > tt   # CHECK WITH JAN WHAT THIS MEANS
        SLZ = max(SLZ - pET[t] * lake, 0.0)
        avg_act_E = avg_act_E + min(SLZ, pET[t] * lake)
    end
    if mean(temp[:,t]) <= tt   # CHECK WITH JAN WHAT THIS MEANS
        SLZ = SLZ + SFCF * mean(Prec[:,t]) * lake   # CHECK WITH JAN WHAT THIS MEANS
    else
        SLZ = SLZ + mean(Prec[:,t]) * lake   # CHECK WITH JAN WHAT THIS MEANS
    end
    if UseOldSUZ
        Q_box1 = K1 * SUZ
        if SUZ < UZL
            Q_box0 = 0.0
        else
            Q_box0 = K0 * (SUZ - UZL)
        end
    else
        Q_box1 = min(K1 * SUZ ^ (1 + UZL), SUZ)
    end
    Q_box2 = K2 * SLZ
    SUZ = SUZ - Q_box1 - Q_box0
    SLZ = SLZ - Q_box2
    Q_gen = Q_box1 + Q_box2 + Q_box0

    # transformation of runoff

    for i = 0:(length(maxbas_w)-1)
        if t + i <= maxTS
            Q_com[t + i] = Q_com[t + i] + Q_gen * maxbas_w[i+1]
        end
    end

    avg_SP = 0.0
    avg_SM = 0.0
    avg_WC = 0.0
    for elevzone = 1:nelev
        for vegzone = 1:nveg
            avg_SP = avg_SP + state_SP[vegzone, elevzone] * area[vegzone, elevzone]
            avg_WC = avg_WC + state_WC[vegzone, elevzone] * area[vegzone, elevzone]
            avg_SM = avg_SM + state_SM[vegzone, elevzone] * area[vegzone, elevzone]
        end
    end

    runoff_sim[t] = Q_gen
    snow_sim[t] = (avg_SP + avg_WC) / (1 - lake)
    SM_sim[t] = avg_SM / (1 - lake)
    SUZ_sim[t] = SUZ
    SLZ_sim[t] = SLZ
    aET_sim[t] = avg_act_E
    recharge_sim[t] = till_Qsum

end  # t loop

plot(date, Q_com, label = "Julia code")
plot(date, Qobs, label = "Original code")
ylabel("Runoff (mm/day)")

@show runoff_sim

#=plot(snow_sim)
plot(SM_sim)
plot(SUZ_sim)
plot(SLZ_sim)
plot(aET_sim)
plot(recharge_sim)=#
