

using PyPlot

slope = -0.3:0.0001:0.3
penalty = 2 ./ (1  + exp(-(10 * slope).^2)) - 1

fig = plt[:figure]

plt[:plot](365 * slope, penalty)
plt[:xlabel]("Trend (mm/year)")
plt[:ylabel]("Penalty")


