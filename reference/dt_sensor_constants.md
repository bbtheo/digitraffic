# Get sensor calibration constants for LAM/TMS stations

Fetches station-specific calibration values: free-flow speeds
(`VVAPAAS1`/`VVAPAAS2`), maximum hourly capacity (`MS1`/`MS2`), and road
direction (`Tien_suunta`). Many stations have seasonal variants with
separate summer and winter values.

## Usage

``` r
dt_sensor_constants(id = NULL)
```

## Arguments

- id:

  `NULL` (default) to return constants for all stations, or a single
  positive integer station `id` to filter to one station.

## Value

A tibble with columns:

- station_id:

  Integer. Station id.

- data_updated_time:

  POSIXct (UTC). When the constants were last updated.

- name:

  Character. Constant name: `"VVAPAAS1"`, `"VVAPAAS2"`, `"MS1"`,
  `"MS2"`, or `"Tien_suunta"`.

- value:

  Double. Constant value (speed in km/h, count in veh/h, or bearing in
  degrees).

- valid_from:

  Character. Start of validity period, `"MM-DD"` format.

- valid_to:

  Character. End of validity period, `"MM-DD"` format.

## Examples

``` r
if (FALSE) { # \dontrun{
# Constants for all stations
dt_sensor_constants()

# Constants for a single station
dt_sensor_constants(id = 23001)

# Free-flow speeds only
library(dplyr)
dt_sensor_constants() |>
  filter(grepl("^VVAPAAS", name))
} # }
```
