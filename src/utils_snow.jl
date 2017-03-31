"""
    compute_ddf(date, ddf_min, ddf_max)

Compute a time-varying degree-day factor depending on the date and a minimum
`ddf_min` and maximum `ddf_max` degree-day factor.
"""
function compute_ddf(date::DateTime, ddf_min::Float64, ddf_max::Float64)

    doy = Dates.dayofyear(date)

    ddf = (ddf_max - ddf_min) * (0.5*sin(2.0*pi*(doy - 80)/366) + 0.5) + ddf_min

    return ddf

end


"""
    split_prec(prec, tair, tth_phase = 0.0; m_phase = 0.5)

Split precipitation into solid and liquid precipitation from precipitation
`prec` and air temperature `tair` using temperature threshold parameter
`tth_phase` and smoothing parameter `m_phase` which needs to be greater
than zero.
"""
function split_prec(prec, tair, tth_phase = 0.0; m_phase = 0.5)

    frac_snowfall = 1. / (1. + exp( (tair - tth_phase) / m_phase ))

    psolid = prec * frac_snowfall
    pliquid = prec - psolid

    return psolid, pliquid

end


"""
    pot_melt(tair, ddf = 3.0, tth_melt = 0.0; m_melt = 0.5)

Compute potential snowmelt from air temperature `tair` using a degree-day factor
`ddf`, a temperature threshold `tth_melt`, and a smoothing parameter `m_melt`
which needs to be greater than zero.
"""
function pot_melt(tair, ddf = 3.0, tth_melt = 0.0; m_melt = 0.5)

    t_m = (tair - tth_melt) / m_melt
    pot_melt = ddf * m_melt * (t_m + log(1. + exp(-t_m)))

    return pot_melt

end
