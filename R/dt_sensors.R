#' List all available LAM/TMS sensor types
#'
#' Fetches the catalogue of sensor types used across all LAM stations.
#' Each sensor has a unique id that matches the `sensor_id` column returned
#' by [dt_station_data()].
#'
#' @return A tibble with columns:
#'   \describe{
#'     \item{id}{Integer. Sensor identifier.}
#'     \item{name}{Character. Full Finnish sensor name, e.g.
#'       `"OHITUKSET_5MIN_KIINTEA_SUUNTA1"`.}
#'     \item{short_name}{Character. Abbreviated label.}
#'     \item{unit}{Character. Measurement unit (`"km/h"`, `"kpl/h"`, `"***"`).}
#'     \item{direction}{Character. `"INCREASING_DIRECTION"`,
#'       `"DECREASING_DIRECTION"`, or `"UNKNOWN"`.}
#'     \item{description_fi}{Character. Finnish description.}
#'     \item{description_en}{Character. English description (often `NA`).}
#'   }
#'
#' @export
#' @examples
#' \dontrun{
#' dt_sensors()
#'
#' # Speed sensors only
#' library(dplyr)
#' dt_sensors() |> filter(unit == "km/h")
#' }
dt_sensors <- function() {
  cached <- dt_cache_get("sensors")
  if (!is.null(cached)) return(cached)
  raw    <- dt_get_json("/api/tms/v1/sensors")
  result <- parse_sensors(raw)
  dt_cache_set("sensors", result, ttl = 300)
  result
}
