using Documenter, Vann

makedocs(
  format = :html,
  sitename = "Vann.jl",
  authors = "Jan Magnusson",
  pages = [
      "Home" => "index.md",
      "Hydrological models" => "hyd_models.md",
      "Snow models" => "snow_models.md",
      "Data assimilation" => "data_assim.md"
  ]
)

deploydocs(
  repo  = "github.com/jmgnve/Vann.jl.git",
  target = "build",
  deps = nothing,
  make = nothing,
  julia = "0.5"
)
