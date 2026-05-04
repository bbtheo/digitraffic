#' List all LAM/TMS measurement stations
#'
#' Fetches metadata for all automatic traffic measurement (LAM/TMS) stations
#' from the Digitraffic API.  Results are cached for 5 minutes within the
#' current R session; call [dt_cache_clear()] to force a fresh fetch.
#'
#' @param name `NULL` (default) or a character string used as a
#'   case-insensitive regular expression to filter stations by name.
#'   Station names typically encode the road and location, e.g.
#'   `"vt1_Espoo_Hirvisuo"`.
#'
#' @return A tibble with one row per station and columns:
#'   \describe{
#'     \item{id}{Integer. Internal API station identifier.}
#'     \item{tms_number}{Integer. TMS system number (used for history CSV).}
#'     \item{name}{Character. Station name.}
#'     \item{longitude}{Double. WGS-84 longitude.}
#'     \item{latitude}{Double. WGS-84 latitude.}
#'     \item{elevation}{Double. Elevation in metres.}
#'     \item{bearing}{Integer. Road bearing in degrees (0–360).}
#'     \item{collection_status}{Character. `"GATHERING"` or `"REMOVED_TEMPORARILY"`.}
#'     \item{state}{Character. Operational state, e.g. `"OK"`.}
#'     \item{data_updated_time}{POSIXct (UTC). Time the record was last updated.}
#'   }
#'
#' @export
#' @examples
#' \dontrun{
#' # All stations
#' dt_stations()
#'
#' # Stations whose name contains "Espoo"
#' dt_stations(name = "Espoo")
#'
#' # Stations on valtatie 1 (road E18)
#' dt_stations(name = "^vt1_")
#' }
dt_stations <- function(name = NULL) {
  cached <- dt_cache_get("stations")
  if (is.null(cached)) {
    raw    <- dt_get_json("/api/tms/v1/stations")
    cached <- parse_stations_response(raw)
    dt_cache_set("stations", cached, ttl = 300)
  }

  if (!is.null(name)) {
    if (!rlang::is_string(name)) {
      cli::cli_abort(
        "{.arg name} must be a single character string, not {.obj_type_friendly {name}}."
      )
    }
    cached <- dplyr::filter(
      cached,
      grepl(.env$name, .data$name, ignore.case = TRUE, perl = TRUE)
    )
  }

  cached
}

#' Get detailed metadata for a single LAM/TMS station
#'
#' Fetches extended metadata for one station by its internal API `id`.
#' To look up the id first, use [dt_stations()].
#'
#' @param id A single positive integer: the station's `id` as returned by
#'   [dt_stations()].  Note: this is **not** the same as `tms_number` (which
#'   is used for historical CSV downloads via `dt_history_raw()`).
#'
#' @return A one-row tibble with columns:
#'   \describe{
#'     \item{id, tms_number, name, name_fi, name_sv, name_en}{Identifiers and multilingual names.}
#'     \item{longitude, latitude, elevation}{WGS-84 coordinates.}
#'     \item{bearing}{Road bearing in degrees.}
#'     \item{collection_status, collection_interval, state}{Operational status.}
#'     \item{station_type}{Hardware type, e.g. `"DSL_6"`.}
#'     \item{municipality, municipality_code}{Municipality name and code.}
#'     \item{province, province_code}{Province name and code.}
#'     \item{direction1_municipality, direction1_municipality_code}{Municipality in direction 1.}
#'     \item{direction2_municipality, direction2_municipality_code}{Municipality in direction 2.}
#'     \item{road_number, road_section, distance_from_section_start}{Road address.}
#'     \item{carriageway}{Carriageway descriptor.}
#'     \item{free_flow_speed1, free_flow_speed2}{Free-flow speed (km/h) per direction.}
#'     \item{livi_id}{LIVI system identifier.}
#'     \item{purpose}{Measurement purpose.}
#'     \item{start_time, data_updated_time}{POSIXct (UTC) timestamps.}
#'   }
#'
#' @export
#' @examples
#' \dontrun{
#' # Look up a station id first
#' stations <- dt_stations(name = "Espoo")
#' dt_station(stations$id[[1]])
#' }
dt_station <- function(id) {
  id <- check_id(id)
  raw <- dt_get_json(paste0("/api/tms/v1/stations/", id))
  parse_station_detail(raw)
}
