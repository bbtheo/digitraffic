## Detailed station cache: load, integrity-check, and user-facing refresh.
##
## Priority order for detailed data:
##   1. User disk cache  — tools::R_user_dir("digitraffic", "cache")
##   2. Bundled snapshot — R/sysdata.rda (baked in at package build time)
##
## The bundled snapshot is always present but may be stale if stations have
## been added or removed since the package was built.  An integrity check
## compares cached station IDs to the live dt_stations() result and warns
## the user to call dt_stations_load_details() when a mismatch is found.

.dt_disk_cache_path <- function() {
  file.path(
    tools::R_user_dir("digitraffic", which = "cache"),
    "stations_detailed.rds"
  )
}

# Load the detailed cache: disk takes priority over bundled sysdata.
dt_load_detailed_cache <- function() {
  path <- .dt_disk_cache_path()
  if (file.exists(path)) {
    return(readRDS(path))
  }
  stations_detailed_cache   # bundled in R/sysdata.rda
}

# Compare cached station IDs to the live bulk list.
# Emits a warning (not an error) when they differ so filtering still works.
dt_check_detailed_integrity <- function(detailed) {
  current    <- dt_stations()
  current_ids <- sort(current$id)
  cached_ids  <- sort(detailed$id)

  if (identical(current_ids, cached_ids)) return(invisible(NULL))

  n_new     <- length(setdiff(current_ids, cached_ids))
  n_removed <- length(setdiff(cached_ids, current_ids))

  parts <- character(0)
  if (n_new     > 0) parts <- c(parts, "{n_new} new station{?s} detected")
  if (n_removed > 0) parts <- c(parts, "{n_removed} station{?s} no longer active")

  cli::cli_warn(c(
    "Detailed station cache is out of date: {paste(parts, collapse = ', ')}.",
    "i" = "Run {.fn dt_stations_load_details} to refresh."
  ))
}

#' Fetch and cache detailed metadata for all LAM/TMS stations
#'
#' Downloads extended metadata (municipality, province, road number, …) for
#' every station using parallel HTTP requests and saves the result to the
#' user cache directory (`tools::R_user_dir("digitraffic", "cache")`).
#'
#' After running this function the new filters in [dt_stations()] —
#' `road_number`, `municipality`, `province`, and `bbox` — will use the
#' refreshed data.  You only need to re-run this when the package warns that
#' the cache is out of date (i.e., new stations have been added to the network).
#'
#' @param max_active Integer. Maximum number of concurrent HTTP requests.
#'   Default is `10`.  Increase for faster fetching on a fast connection;
#'   decrease to be more polite to the API.
#'
#' @return Invisibly returns the detailed stations tibble.
#' @export
#' @examples
#' \dontrun{
#' dt_stations_load_details()
#' }
dt_stations_load_details <- function(max_active = 10L) {
  if (!rlang::is_scalar_integerish(max_active) || max_active < 1L) {
    cli::cli_abort("{.arg max_active} must be a single positive integer.")
  }
  stations <- dt_stations()
  ids      <- stations$id
  n        <- length(ids)

  cli::cli_inform("Fetching detailed metadata for {n} station{?s}...")

  ua <- paste0(
    "digitraffic-r/", utils::packageVersion("digitraffic"),
    " (https://github.com/bbtheo/digitraffic)"
  )

  reqs <- lapply(ids, function(id) {
    httr2::request(.dt_base_url) |>
      httr2::req_user_agent(ua) |>
      httr2::req_url_path(paste0("/api/tms/v1/stations/", id)) |>
      httr2::req_headers(Accept = "application/json")
  })

  resps <- httr2::req_perform_parallel(
    reqs,
    max_active = max_active,
    on_error   = "continue",
    progress   = TRUE
  )

  rows <- lapply(resps, function(resp) {
    if (inherits(resp, "error")) return(NULL)
    tryCatch(
      parse_station_detail(httr2::resp_body_json(resp, simplifyVector = FALSE)),
      error = function(e) NULL
    )
  })
  rows    <- Filter(Negate(is.null), rows)
  details <- dplyr::bind_rows(rows)

  cache_dir <- tools::R_user_dir("digitraffic", which = "cache")
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  path <- .dt_disk_cache_path()
  saveRDS(details, path)

  cli::cli_inform(c(
    "v" = "Saved detailed metadata for {nrow(details)} station{?s}.",
    "i" = "Cache location: {.path {path}}"
  ))
  invisible(details)
}
