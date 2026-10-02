# Fail on missing packages even when install.packages() only emitted warnings.
packages <- c(
  "pak", "hwriter", "TeachingDemos", "htmltools", "hwriterPlus", "Rserve",
  "data.table", "sparklyr", "sf", "tidyverse", "brms", "arcgisutils", "httr2",
  "tinyplot", "osrm", "osrm.backend", "mirai", "carrier", "nanoparquet", "cmdstanr"
)
for (package in packages) {
  library(package, character.only = TRUE)
  message(package, " ", packageVersion(package))
}

# Validate the actual interpreter, not just the r-base metapackage.
stopifnot(as.character(getRversion()) == "4.6.1")
print(sessionInfo())

# Exercise linked GDAL/GEOS/PROJ libraries without external services.
print(sf::sf_extSoftVersion())
point <- sf::st_sfc(sf::st_point(c(-77, 39)), crs = 4326)
projected <- sf::st_transform(point, 3857)
stopifnot(all(is.finite(sf::st_coordinates(projected))))
stopifnot(as.numeric(sf::st_area(sf::st_buffer(projected, 100))) > 0)

# Check CmdStan discovery in a fresh R session, compilation, and execution.
message("CmdStan: ", cmdstanr::cmdstan_path())
stopifnot(!is.null(cmdstanr::cmdstan_version()))
cmdstanr::check_cmdstan_toolchain(fix = FALSE, quiet = FALSE)
model_file <- cmdstanr::write_stan_file(
  "parameters { real y; } model { y ~ normal(0, 1); }",
  dir = tempdir()
)
model <- cmdstanr::cmdstan_model(model_file, cpp_options = list(stan_threads = FALSE))
fit <- model$sample(
  chains = 1, parallel_chains = 1, seed = 123,
  iter_warmup = 50, iter_sampling = 50, refresh = 0,
  output_dir = tempdir()
)
stopifnot(all(fit$return_codes() == 0L))
stopifnot(all(is.finite(fit$draws("y", format = "matrix"))))
message("Bayesian image smoke checks passed")
