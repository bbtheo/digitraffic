# Fetch raw historical vehicle-level data for a LAM/TMS station

Downloads and parses the raw CSV for one station on one day. Each row
represents a single vehicle passage through the measurement loop. Raw
data is available from **December 2021** onwards and is published the
following day between 08:00–09:00 EET.

## Usage

``` r
dt_history_raw(tms_number, date)
```

## Arguments

- tms_number:

  A single positive integer: the station's `tms_number` (not the `id`).
  Use
  [`dt_stations()`](https://bbtheo.github.io/digitraffic/reference/dt_stations.md)
  and read the `tms_number` column. This is different from the `id` used
  by
  [`dt_station_data()`](https://bbtheo.github.io/digitraffic/reference/dt_station_data.md).

- date:

  A single `Date` object for the day to retrieve, e.g.
  `as.Date("2024-03-15")`. Must be at least one day in the past and no
  earlier than 2021-12-01.

## Value

A tibble with one row per vehicle passage and columns:

- station_id:

  Integer. TMS station number from the file.

- year_short:

  Integer. 2-digit year.

- day_of_year:

  Integer. Day number (1–366).

- hour, minute, second, centisecond:

  Integer. Passage time components.

- vehicle_length_m:

  Double. Vehicle length in metres.

- lane:

  Integer. Lane number.

- direction:

  Integer. 1 = increasing direction, 2 = decreasing.

- vehicle_class:

  Integer. Class code 1–9 (see
  [`dt_vehicle_classes()`](https://bbtheo.github.io/digitraffic/reference/dt_vehicle_classes.md)).

- speed_kmh:

  Integer. Speed in km/h.

- quality_flag:

  Integer. 0 = valid, 1 = outside valid range.

- interval_ms:

  Integer. Time since previous vehicle (ms).

- time_in_loop_ms:

  Integer. Time vehicle spent over the loop (ms).

- datetime:

  POSIXct (Europe/Helsinki). Full passage timestamp.

- vehicle_class_label:

  Character. English label for the vehicle class.

## Examples

``` r
if (FALSE) { # \dontrun{
# One day of data for station with tms_number = 1
raw <- dt_history_raw(tms_number = 1, date = as.Date("2024-03-15"))

# Hourly traffic volume by direction
library(dplyr)
raw |>
  filter(quality_flag == 0) |>
  mutate(hour_of_day = hour) |>
  count(hour_of_day, direction)
} # }
```
