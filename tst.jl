
import Vann

filename = Pkg.dir("Vann", "data/atnasjo")

date, tair, prec, q_obs, frac = Vann.load_data(filename, "Q_ref.txt")

tstep = 24.0

time = date[1]

# Compute potential evapotranspiration

epot = Vann.epot_monthly(date)

# Select model

st_snow  = Vann.TinBasic(tstep, time, frac)
st_hydro = Vann.Hbv(tstep, time)

q_sim, res_snow, res_hydro = Vann.run_model(st_snow, st_hydro, date, tair, prec, epot; return_all = true)

Vann.plot_sim(res_snow)
Vann.plot_sim(res_hydro)