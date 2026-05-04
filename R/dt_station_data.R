#' Get real-time sensor data for a single LAM/TMS station
#'
#' Fetches the current sensor values for one station.  Data is updated
#' approximately every minute.
#'
#' @param id A single positive integer: the station's `id` (not `tms_number`).
#'   Use [dt_stations()] to look up station ids.
#'
#' @return A tibble with one row per sensor reading and columns:
#'   \describe{
#'     \item{station_id}{Integer. Station id.}
#'     \item{tms_number}{Integer. TMS system number.}
#'     \item{data_updated_time}{POSIXct (UTC). When the station data was updated.}
#'     \item{sensor_id}{Integer. Sensor identifier (see [dt_sensors()]).}
#'     \item{name}{Character. Full Finnish sensor name.}
#'     \item{short_name}{Character. Abbreviated label.}
#'     \item{value}{Double. Measured value.}
#'     \item{unit}{Character. Unit, e.g. `"km/h"`, `"kpl/h"`, or `"***"`.}
#'     \item{measured_time}{POSIXct (UTC). When the measurement was taken.}
#'     \item{time_window_start, time_window_end}{POSIXct (UTC). Aggregation window.}
#'   }
#'
#' @export
#' @examples
#' \dontrun{
#' # Real-time speeds and counts for station 23001
#' dt_station_data(23001)
#'
#' # Filter to speed sensors only
#' library(dplyr)
#' dt_station_data(23001) |> filter(unit == "km/h")
#' }
dt_station_data <- function(id) {
  id  <- check_id(id)
  raw <- dt_get_json(paste0("/api/tms/v1/stations/", id, "/data"))
  parse_sensor_values(raw)
}

#' Get real-time sensor data for all LAM/TMS stations
#'
#' Fetches current sensor values for every station in a single request.
#' The response is typically several MB and may take a few seconds.
#' Data is updated approximately every minute.
#'
#' @return A tibble with the same columns as [dt_station_data()], with one
#'   row per sensor per station.
#'
#' @export
#' @examples
#' \dontrun{
#' all_data <- dt_stations_data()
#'
#' # Average speed across all stations, direction 1
#' library(dplyr)
#' all_data |>
#'   filter(grepl("KESKINOPEUS_60MIN.*SUUNTA1", name)) |>
#'   summarise(mean_speed = mean(value, na.rm = TRUE))
#' }
dt_stations_data <- function() {
  raw <- dt_get_json("/api/tms/v1/stations/data")
  parse_all_stations_data(raw)
}
