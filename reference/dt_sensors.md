# List all available LAM/TMS sensor types

Fetches the catalogue of sensor types used across all LAM stations. Each
sensor has a unique id that matches the `sensor_id` column returned by
[`dt_station_data()`](https://bbtheo.github.io/digitraffic/reference/dt_station_data.md).

## Usage

``` r
dt_sensors()
```

## Value

A tibble with columns:

- id:

  Integer. Sensor identifier.

- name:

  Character. Full Finnish sensor name, e.g.
  `"OHITUKSET_5MIN_KIINTEA_SUUNTA1"`.

- short_name:

  Character. Abbreviated label.

- unit:

  Character. Measurement unit (`"km/h"`, `"kpl/h"`, `"***"`).

- direction:

  Character. `"INCREASING_DIRECTION"`, `"DECREASING_DIRECTION"`, or
  `"UNKNOWN"`.

- description_fi:

  Character. Finnish description.

- description_en:

  Character. English description (often `NA`).

## Examples

``` r
if (FALSE) { # \dontrun{
dt_sensors()

# Speed sensors only
library(dplyr)
dt_sensors() |> filter(unit == "km/h")
} # }
```
