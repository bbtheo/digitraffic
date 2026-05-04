#' Get sensor calibration constants for LAM/TMS stations
#'
#' Fetches station-specific calibration values: free-flow speeds
#' (`VVAPAAS1`/`VVAPAAS2`), maximum hourly capacity (`MS1`/`MS2`), and road
#' direction (`Tien_suunta`).  Many stations have seasonal variants with
#' separate summer and winter values.
#'
#' @param id `NULL` (default) to return constants for all stations, or a
#'   single positive integer station `id` to filter to one station.
#'
#' @return A tibble with columns:
#'   \describe{
#'     \item{station_id}{Integer. Station id.}
#'     \item{data_updated_time}{POSIXct (UTC). When the constants were last updated.}
#'     \item{name}{Character. Constant name: `"VVAPAAS1"`, `"VVAPAAS2"`,
#'       `"MS1"`, `"MS2"`, or `"Tien_suunta"`.}
#'     \item{value}{Double. Constant value (speed in km/h, count in veh/h,
#'       or bearing in degrees).}
#'     \item{valid_from}{Character. Start of validity period, `"MM-DD"` format.}
#'     \item{valid_to}{Character. End of validity period, `"MM-DD"` format.}
#'   }
#'
#' @export
#' @examples
#' \dontrun{
#' # Constants for all stations
#' dt_sensor_constants()
#'
#' # Constants for a single station
#' dt_sensor_constants(id = 23001)
#'
#' # Free-flow speeds only
#' library(dplyr)
#' dt_sensor_constants() |>
#'   filter(grepl("^VVAPAAS", name))
#' }
dt_sensor_constants <- function(id = NULL) {
  raw    <- dt_get_json("/api/tms/v1/stations/sensor-constants")
  result <- parse_sensor_constants(raw)

  if (!is.null(id)) {
    id     <- check_id(id)
    result <- dplyr::filter(result, .data$station_id == .env$id)
    if (nrow(result) == 0L) {
      cli::cli_warn(
        "No sensor constants found for station {.val {id}}. Check the id with {.fn dt_stations}."
      )
    }
  }

  result
}
