# digitraffic <img src="man/figures/logo.png" align="right" height="139" alt="" />

<!-- badges: start -->
[![R-CMD-check](https://github.com/bbtheo/digitraffic/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/bbtheo/digitraffic/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/bbtheo/digitraffic/graph/badge.svg)](https://app.codecov.io/gh/bbtheo/digitraffic)
<!-- badges: end -->

**digitraffic** is an R client for the [Finntraffic Digitraffic](https://www.digitraffic.fi/) open API, giving you tidy access to Finland's automatic traffic measurement (LAM/TMS) network — over 450 road stations measuring vehicle speeds, volumes, and classifications in real time.

All data is returned as [tibbles](https://tibble.tidyverse.org/) with snake\_case column names, ready for analysis with dplyr, ggplot2, and the rest of the tidyverse.

## Installation

Install the development version from GitHub:

```r
# install.packages("pak")
pak::pak("bbtheo/digitraffic")
```

## Quick start

```r
library(digitraffic)

# List all measurement stations — road_number, municipality, province always included
dt_stations()
#> # A tibble: 489 x 13
#>       id tms_number name               road_number longitude latitude elevation
#>    <int>      <int> <chr>                    <int>     <dbl>    <dbl>     <dbl>
#>  1 20002      20002 vt1_Espoo_Hirvisuo           1      24.6     60.2        30
#>  2 23001          1 vt7_Rita                     7      25.7     60.4         0
#>  # … with 6 more variables: bearing <int>, municipality <chr>, province <chr>,
#>  #   collection_status <chr>, state <chr>, data_updated_time <dttm>

# Search by name (supports regex)
dt_stations(name = "Espoo")

# Detailed metadata for one station
dt_station(23001)
#> # A tibble: 1 x 32
#>      id tms_number name     municipality province road_number free_flow_speed1
#>   <int>      <int> <chr>    <chr>        <chr>          <int>            <dbl>
#> 1 23001          1 vt7_Rita Porvoo       Uusimaa            7              105

# Real-time speed and volume data
dt_station_data(23001)
#> # A tibble: 40 x 11
#>    station_id sensor_id name                            value unit  measured_time
#>         <int>     <int> <chr>                           <dbl> <chr> <dttm>
#>  1      23001      5016 OHITUKSET_5MIN_KIINTEA_SUUNTA1   216 kpl/h 2024-06-01 12:00:00
#>  2      23001      5057 KESKINOPEUS_60MIN_KIINTEA_SU…    107 km/h  2024-06-01 12:00:00
#>  …

# Historical per-vehicle data (one station, one day)
raw <- dt_history_raw(tms_number = 1, date = as.Date("2024-03-15"))
#> # A tibble: 28,472 x 17
#>    station_id speed_kmh vehicle_class_label datetime
#>         <int>     <int> <chr>               <dttm>
#>  1          1        97 Car / van           2024-03-15 08:00:12
#>  2          1        84 Truck (no trailer)  2024-03-15 08:00:15
#>  …
```

## Main functions

| Function | Description |
|---|---|
| `dt_stations()` | List stations — filter by name, road number, municipality, province, or bounding box |
| `dt_station()` | Detailed metadata for one station (municipality, road, province, …) |
| `dt_stations_load_details()` | Refresh the detailed station metadata cache |
| `dt_station_data()` | Real-time sensor values for one station |
| `dt_stations_data()` | Real-time sensor values for **all** stations |
| `dt_sensors()` | Catalogue of all sensor types (76 sensors) |
| `dt_sensor_constants()` | Calibration values: free-flow speed, max capacity, road bearing |
| `dt_history_raw()` | Historical per-vehicle data (one station, one day) |
| `dt_vehicle_classes()` | Vehicle class code lookup (1–7 → English/Finnish labels) |
| `dt_cache_clear()` | Clear the in-session metadata cache |

## Filtering stations

```r
# By road number (no extra API calls)
dt_stations(road_number = 7)

# By municipality or province (uses bundled metadata cache)
dt_stations(municipality = "Espoo")
dt_stations(province = "Uusimaa")

# By bounding box
dt_stations(bbox = c(24.5, 60.1, 25.2, 60.4))

# Combine freely
dt_stations(road_number = 4, province = "Pirkanmaa")

# Refresh the metadata cache when new stations are added
dt_stations_load_details()
```

## Common recipes

### Hourly traffic volume

```r
library(dplyr)

dt_history_raw(tms_number = 1, date = as.Date("2024-06-15")) |>
  filter(quality_flag == 0, direction == 1) |>
  count(hour, name = "vehicles") |>
  print(n = 24)
```

### Average speed across all stations

```r
dt_stations_data() |>
  filter(grepl("KESKINOPEUS_60MIN.*SUUNTA1", name)) |>
  summarise(mean_speed_kmh = mean(value, na.rm = TRUE))
```

### Free-flow speed comparison

```r
dt_sensor_constants() |>
  filter(name == "VVAPAAS1") |>
  arrange(desc(value)) |>
  head(20)
```

### Convert stations to sf for mapping

```r
library(sf)
stations <- dt_stations() |>
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326)
```

## API details

- **Base URL:** `https://tie.digitraffic.fi`
- **Authentication:** None required (open data)
- **Rate limiting:** The package throttles to 60 requests/minute (Digitraffic's default limit) and retries transient errors (429, 500, 503) automatically
- **Caching:** Station metadata is cached for 5 minutes per R session; call `dt_cache_clear()` to refresh
- **Historical data:** Available from December 2021 onwards; published the next day at 08:00–09:00 EET

## Data source

All data is provided by [Finntraffic / Digitraffic](https://www.digitraffic.fi/) under the [Creative Commons Attribution 4.0](https://creativecommons.org/licenses/by/4.0/) licence.

## License

MIT
