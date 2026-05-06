# Get real-time sensor data for a single LAM/TMS station

Fetches the current sensor values for one station. Data is updated
approximately every minute.

## Usage

``` r
dt_station_data(id)
```

## Arguments

- id:

  A single positive integer: the station's `id` (not `tms_number`). Use
  [`dt_stations()`](https://bbtheo.github.io/digitraffic/reference/dt_stations.md)
  to look up station ids.

## Value

A tibble with one row per sensor reading and columns:

- station_id:

  Integer. Station id.

- tms_number:

  Integer. TMS system number.

- data_updated_time:

  POSIXct (UTC). When the station data was updated.

- sensor_id:

  Integer. Sensor identifier (see
  [`dt_sensors()`](https://bbtheo.github.io/digitraffic/reference/dt_sensors.md)).

- name:

  Character. Full Finnish sensor name.

- short_name:

  Character. Abbreviated label.

- value:

  Double. Measured value.

- unit:

  Character. Unit, e.g. `"km/h"`, `"kpl/h"`, or `"***"`.

- measured_time:

  POSIXct (UTC). When the measurement was taken.

- time_window_start, time_window_end:

  POSIXct (UTC). Aggregation window.

## Examples

``` r
if (FALSE) { # \dontrun{
# Real-time speeds and counts for station 23001
dt_station_data(23001)

# Filter to speed sensors only
library(dplyr)
dt_station_data(23001) |> filter(unit == "km/h")
} # }
```
