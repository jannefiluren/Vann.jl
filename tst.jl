
import Vann

filename = Pkg.dir("Vann", "data/airgr/test_data.txt")

data = readdlm(filename, ',', header = true)

prec  = data[1][:,1]
epot  = data[1][:,2]
q_obs = data[1][:,3]

prec = transpose(prec)
epot = transpose(epot)

frac = zeros(Float64, 1)

param  = [257.238, 1.012, 88.235, 2.208]

tstep = 24.0

time = DateTime(2000,1,1)

# Select model

st_gr4j = Vann.Gr4j(tstep, time, param)

# Run model

q_sim, res_all = Vann.run_model(st_gr4j, prec, epot; return_all = true)

Vann.plot_sim(res_all)
