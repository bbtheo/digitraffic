## Script to generate the bundled detailed station cache (R/sysdata.rda).
##
## Run this script manually whenever a new version of the package is released
## to bake a fresh snapshot of all LAM station details into the package.
##
## Usage:
##   source("data-raw/stations_detailed.R")

library(digitraffic)

# dt_stations_load_details() fetches every station in parallel with retry,
# throttle, and the shared User-Agent, then saves to the user disk cache.
# We re-use that logic here and then bake the result into sysdata.rda so
# it is available as a bundled fallback even without a disk cache.
message("Fetching and caching detailed station metadata...")
stations_detailed_cache <- dt_stations_load_details()

if (is.null(stations_detailed_cache) || nrow(stations_detailed_cache) == 0L) {
  stop("No station details fetched — aborting. Check your internet connection.")
}

message("Parsed ", nrow(stations_detailed_cache), " station details.")

# Save as internal package data (R/sysdata.rda).
usethis::use_data(stations_detailed_cache, internal = TRUE, overwrite = TRUE)
message("Saved to R/sysdata.rda.")
