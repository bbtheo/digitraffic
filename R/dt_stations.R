#' List all LAM/TMS measurement stations
#'
#' Fetches metadata for all automatic traffic measurement (LAM/TMS) stations
#' from the Digitraffic API.  Basic results are cached for 5 minutes per R
#' session.  Extended columns (`road_number`, `municipality`, `province`) are
#' always included in the output: `road_number` is parsed from the station name
#' (no extra API calls), while `municipality` and `province` are joined from the
#' bundled detailed cache (or a user-refreshed disk cache — see
#' [dt_stations_load_details()]).
#'
#' If the live station list has changed since the cache was built and you filter
#' by `municipality` or `province`, a warning is emitted with instructions to
#' refresh the cache.
#'
#' @param name `NULL` or a case-insensitive regular expression matched against
#'   station names, e.g. `"Espoo"` or `"^vt1_"`.
#' @param road_number `NULL` or a positive integer road number, e.g. `7` for
#'   valtatie 7.  Parsed from the station name — fast, no extra API calls.
#' @param municipality `NULL` or a character string matched
#'   case-insensitively against the `municipality` column, e.g. `"Espoo"`.
#'   Supports regex, e.g. `"Helsinki|Espoo"`.
#' @param province `NULL` or a character string matched case-insensitively
#'   against the `province` column, e.g. `"Uusimaa"`.  Supports regex.
#' @param bbox `NULL` or a length-4 numeric vector
#'   `c(lon_min, lat_min, lon_max, lat_max)` in WGS-84 degrees.  Filters
#'   stations whose coordinates fall inside the bounding box.
#'
#' @return A tibble with one row per matching station and columns:
#'   \describe{
#'     \item{id}{Integer. Internal API station identifier.}
#'     \item{tms_number}{Integer. TMS system number (used for history CSV).}
#'     \item{name}{Character. Station name.}
#'     \item{road_number}{Integer. Road number parsed from the station name
#'       (e.g. `7` for `"vt7_Rita"`). `NA` for non-standard names.}
#'     \item{longitude}{Double. WGS-84 longitude.}
#'     \item{latitude}{Double. WGS-84 latitude.}
#'     \item{elevation}{Double. Elevation in metres.}
#'     \item{bearing}{Integer. Road bearing in degrees (0–360).}
#'     \item{municipality}{Character. Municipality name from the detailed cache.
#'       `NA` for stations added after the cache was last built.}
#'     \item{province}{Character. Province name from the detailed cache.
#'       `NA` for stations added after the cache was last built.}
#'     \item{collection_status}{Character. `"GATHERING"` or `"REMOVED_TEMPORARILY"`.}
#'     \item{state}{Character. Operational state, e.g. `"OK"`.}
#'     \item{data_updated_time}{POSIXct (UTC). Time the record was last updated.}
#'   }
#'
#' @export
#' @examples
#' \dontrun{
#' # All stations — road_number, municipality, province always present
#' dt_stations()
#'
#' # By name (regex supported)
#' dt_stations(name = "Espoo")
#' dt_stations(name = "^vt1_")
#'
#' # By road number
#' dt_stations(road_number = 7)
#'
#' # By municipality (matches the municipality column you see in the output)
#' dt_stations(municipality = "Espoo")
#'
#' # By province
#' dt_stations(province = "Uusimaa")
#'
#' # By bounding box (Helsinki metropolitan area)
#' dt_stations(bbox = c(24.5, 60.1, 25.2, 60.4))
#'
#' # Combine filters
#' dt_stations(road_number = 1, municipality = "Espoo")
#' }
dt_stations <- function(name         = NULL,
                        road_number  = NULL,
                        municipality = NULL,
                        province     = NULL,
                        bbox         = NULL) {

  # --- Validate filter inputs up-front -------------------------------------
  if (!is.null(name) && !rlang::is_string(name)) {
    cli::cli_abort(
      "{.arg name} must be a single character string, not {.obj_type_friendly {name}}."
    )
  }
  if (!is.null(municipality) && !rlang::is_string(municipality)) {
    cli::cli_abort("{.arg municipality} must be a single character string.")
  }
  if (!is.null(province) && !rlang::is_string(province)) {
    cli::cli_abort("{.arg province} must be a single character string.")
  }

  # --- Fetch / use cached bulk station list --------------------------------
  stations <- dt_cache_get("stations")
  if (is.null(stations)) {
    raw      <- dt_get_json("/api/tms/v1/stations")
    stations <- parse_stations_response(raw)
    dt_cache_set("stations", stations, ttl = 300)
  }
  # Keep a reference to the full live list for the integrity check below.
  live_stations <- stations

  # --- Always enrich output with road_number, municipality, province -------
  #
  # road_number: parsed from the station name — always fresh, no cache needed.
  stations$road_number <- vapply(
    stations$name, parse_road_number_from_name, integer(1L)
  )

  # municipality + province: fast local read from the bundled/disk cache.
  # New stations not yet in the cache will show NA in these columns.
  detailed  <- dt_load_detailed_cache()
  extra     <- detailed[, c("id", "municipality", "province")]
  stations  <- dplyr::left_join(stations, extra, by = "id")

  # Reorder into a logical layout: identifiers → road → coordinates →
  # administrative geography → operational status.
  stations <- stations[, c(
    "id", "tms_number", "name", "road_number",
    "longitude", "latitude", "elevation", "bearing",
    "municipality", "province",
    "collection_status", "state", "data_updated_time"
  )]

  # --- name filter ---------------------------------------------------------
  if (!is.null(name)) {
    stations <- dplyr::filter(
      stations,
      grepl(.env$name, .data$name, ignore.case = TRUE, perl = TRUE)
    )
  }

  # --- road_number filter --------------------------------------------------
  if (!is.null(road_number)) {
    road_number <- check_id(road_number)
    stations <- dplyr::filter(
      stations,
      !is.na(.data$road_number) & .data$road_number == .env$road_number
    )
  }

  # --- bbox filter ---------------------------------------------------------
  if (!is.null(bbox)) {
    check_bbox(bbox)
    stations <- dplyr::filter(
      stations,
      .data$longitude >= bbox[1] & .data$longitude <= bbox[3] &
        .data$latitude  >= bbox[2] & .data$latitude  <= bbox[4]
    )
  }

  # --- municipality / province filters -------------------------------------
  # The staleness warning is only emitted when these filters are actually used:
  # that is the only time an out-of-date cache would silently affect results.
  # The full live station list (pre-filter) is used for the ID comparison.
  if (!is.null(municipality) || !is.null(province)) {
    dt_check_detailed_integrity(detailed, live_stations)

    if (!is.null(municipality)) {
      stations <- dplyr::filter(
        stations,
        grepl(.env$municipality, .data$municipality, ignore.case = TRUE, perl = TRUE)
      )
    }
    if (!is.null(province)) {
      stations <- dplyr::filter(
        stations,
        grepl(.env$province, .data$province, ignore.case = TRUE, perl = TRUE)
      )
    }
  }

  stations
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
