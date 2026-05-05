## Script to generate the bundled detailed station cache (R/sysdata.rda).
##
## Run this script manually whenever a new version of the package is released
## to bake a fresh snapshot of all LAM station details into the package.
##
## Usage:
##   source("data-raw/stations_detailed.R")

library(digitraffic)
library(httr2)

message("Fetching bulk station list...")
stations <- dt_stations()
ids <- stations$id
message("Found ", length(ids), " stations.")

# Build one request per station — no throttle so parallelism can run freely.
ua <- paste0(
  "digitraffic-r/", packageVersion("digitraffic"),
  " (https://github.com/bbtheo/digitraffic)"
)

reqs <- lapply(ids, function(id) {
  request("https://tie.digitraffic.fi") |>
    req_user_agent(ua) |>
    req_url_path(paste0("/api/tms/v1/stations/", id)) |>
    req_headers(Accept = "application/json")
})

message("Fetching details for ", length(reqs), " stations in parallel (max_active = 10)...")
resps <- req_perform_parallel(reqs, max_active = 10, on_error = "continue")

# Parse each successful response; silently skip failures.
rows <- lapply(resps, function(resp) {
  if (inherits(resp, "error")) return(NULL)
  tryCatch(
    digitraffic:::parse_station_detail(resp_body_json(resp, simplifyVector = FALSE)),
    error = function(e) NULL
  )
})
rows <- Filter(Negate(is.null), rows)

stations_detailed_cache <- dplyr::bind_rows(rows)
message("Parsed ", nrow(stations_detailed_cache), " station details.")

# Save as internal package data (R/sysdata.rda).
usethis::use_data(stations_detailed_cache, internal = TRUE, overwrite = TRUE)
message("Saved to R/sysdata.rda.")
