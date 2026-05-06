# Get real-time sensor data for all LAM/TMS stations

Fetches current sensor values for every station in a single request. The
response is typically several MB and may take a few seconds. Data is
updated approximately every minute.

## Usage

``` r
dt_stations_data()
```

## Value

A tibble with the same columns as
[`dt_station_data()`](https://bbtheo.github.io/digitraffic/reference/dt_station_data.md),
with one row per sensor per station.

## Examples

``` r
if (FALSE) { # \dontrun{
all_data <- dt_stations_data()

# Average speed across all stations, direction 1
library(dplyr)
all_data |>
  filter(grepl("KESKINOPEUS_60MIN.*SUUNTA1", name)) |>
  summarise(mean_speed = mean(value, na.rm = TRUE))
} # }
```
