# Plot Gr4j

function plot_sim{T<:Gr4j}(hydro_out::Array{T,1})

  st1   = [hydro_out[i].st[1] for i in 1:length(hydro_out)]
  st2   = [hydro_out[i].st[2] for i in 1:length(hydro_out)]
  q_sim = [hydro_out[i].q_sim for i in 1:length(hydro_out)]

  fig = plt[:figure](figsize = (12,7))

  plt[:style][:use]("ggplot")

  plt[:subplot](211)
  plt[:plot](q_sim, linewidth = 1.2, color = "r")
  plt[:title]("GR4J")
  plt[:ylabel]("Runoff")

  plt[:subplot](212)
  plt[:plot](st1, linewidth = 1.2, color = "k", label = "St1")
  plt[:plot](st2, linewidth = 1.2, color = "g", label = "St2")
  plt[:ylabel]("States (mm)")
  plt[:legend]()

end


# Plot Hbv

function plot_sim{T<:Hbv}(hydro_out::Array{T,1})

  sm  = [hydro_out[i].sm for i in 1:length(hydro_out)]
  suz = [hydro_out[i].suz for i in 1:length(hydro_out)]
  slz = [hydro_out[i].slz for i in 1:length(hydro_out)]

  fig = plt[:figure](figsize = (12,7))

  plt[:style][:use]("ggplot")

  plt[:subplot](211)
  plt[:plot](q_sim, linewidth = 1.2, color = "r")
  plt[:title]("HBV")
  plt[:ylabel]("Runoff")

  plt[:subplot](212)
  plt[:plot](sm, linewidth = 1.2, color = "k", label = "SM")
  plt[:plot](suz, linewidth = 1.2, color = "b", label = "SUZ")
  plt[:plot](slz, linewidth = 1.2, color = "g", label = "SLZ")
  plt[:ylabel]("States (mm)")
  plt[:legend]()

end


# Plot TinBasic

function plot_sim{T<:TinBasic}(snow_out::Array{T,1})

  swe = [mean(snow_out[i].swe) for i in 1:length(snow_out)]

  fig = plt[:figure](figsize = (12,7))

  plt[:style][:use]("ggplot")

  plt[:plot](swe, linewidth = 1.2, color = "b")
  plt[:title]("TinBasic")
  plt[:ylabel]("SWE (mm)")

end


# Plot TinStandard

function plot_sim{T<:TinStandard}(snow_out::Array{T,1})

  swe = [mean(snow_out[i].swe) for i in 1:length(snow_out)]
  lw  = [mean(snow_out[i].lw) for i in 1:length(snow_out)]

  fig = plt[:figure](figsize = (12,7))

  plt[:style][:use]("ggplot")

  plt[:plot](swe, linewidth = 1.2, color = "b", label = "SWE")
  plt[:plot](lw, linewidth = 1.2, color = "r", label = "LW")
  plt[:title]("TinStandard")
  plt[:ylabel]("States (mm)")
  plt[:lenged]()

end
