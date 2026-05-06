#' Fetch raw historical vehicle-level data for a LAM/TMS station
#'
#' Downloads and parses the raw CSV for one station on one day.  Each row
#' represents a single vehicle passage through the measurement loop.
#' Raw data is available from **December 2021** onwards and is published
#' the following day between 08:00–09:00 EET.
#'
#' @param tms_number A single positive integer: the station's `tms_number`
#'   (not the `id`).  Use [dt_stations()] and read the `tms_number` column.
#'   This is different from the `id` used by [dt_station_data()].
#' @param date A single `Date` object for the day to retrieve, e.g.
#'   `as.Date("2024-03-15")`.  Must be at least one day in the past and no
#'   earlier than 2021-12-01.
#'
#' @return A tibble with one row per vehicle passage and columns:
#'   \describe{
#'     \item{station_id}{Integer. TMS station number from the file.}
#'     \item{year_short}{Integer. 2-digit year.}
#'     \item{day_of_year}{Integer. Day number (1–366).}
#'     \item{hour, minute, second, centisecond}{Integer. Passage time components.}
#'     \item{vehicle_length_m}{Double. Vehicle length in metres.}
#'     \item{lane}{Integer. Lane number.}
#'     \item{direction}{Integer. 1 = increasing direction, 2 = decreasing.}
#'     \item{vehicle_class}{Integer. Class code 1–9 (see [dt_vehicle_classes()]).}
#'     \item{speed_kmh}{Integer. Speed in km/h.}
#'     \item{quality_flag}{Integer. 0 = valid, 1 = outside valid range.}
#'     \item{interval_ms}{Integer. Time since previous vehicle (ms).}
#'     \item{time_in_loop_ms}{Integer. Time vehicle spent over the loop (ms).}
#'     \item{datetime}{POSIXct (Europe/Helsinki). Full passage timestamp.}
#'     \item{vehicle_class_label}{Character. English label for the vehicle class.}
#'     \item{vehicle_class_category}{Character. Broad category: "Car", "Truck", "Bus", or "Motorcycle".}
#'   }
#'
#' @export
#' @examples
#' \dontrun{
#' # One day of data for station with tms_number = 1
#' raw <- dt_history_raw(tms_number = 1, date = as.Date("2024-03-15"))
#'
#' # Hourly traffic volume by direction
#' library(dplyr)
#' raw |>
#'   filter(quality_flag == 0) |>
#'   mutate(hour_of_day = hour) |>
#'   count(hour_of_day, direction)
#' }
dt_history_raw <- function(tms_number, date) {
  tms_number <- check_id(tms_number)
  date       <- check_history_date(date)
  parts      <- date_to_lam_parts(date)

  path <- sprintf(
    "/api/tms/v1/history/raw/lamraw_%d_%s_%d.csv",
    tms_number,
    parts$year_short,
    parts$day_number
  )

  raw <- dt_get_csv(path)
  parse_history_csv(raw, date = date)
}
