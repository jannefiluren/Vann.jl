
using DataFrames
using CSV

data = readdlm("55.4_roykenes_ptq.txt")

date = [DateTime(data[i,1], data[i,2], data[i,3], data[i,4]) for i in 1:size(data, 1)]

prec = data[:, 5:14]
tair = data[:, 15:24]
qobs = data[:, end]

qobs = qobs * (3 * 3600 * 1000) / (50.09 * 1e6)

qobs = round(qobs, 2)

df_prec = DataFrame(hcat(date, prec))
df_tair = DataFrame(hcat(date, tair))
df_qobs = DataFrame(hcat(date, qobs))

CSV.write("Prec.txt", df_prec, delim = ';', header = false, dateformat = "yyyy-mm-dd HH:MM")
CSV.write("Tair.txt", df_tair, delim = ';', header = false, dateformat = "yyyy-mm-dd HH:MM")
CSV.write("Q_obs.txt", df_qobs, delim = ';', header = false, dateformat = "yyyy-mm-dd HH:MM")
