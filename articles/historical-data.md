# Working with historical raw data

## Overview

The Digitraffic API stores raw vehicle-level observations as daily CSV
files for every LAM station. Each row represents a single vehicle
passing over the measurement loop, capturing its speed, length, lane,
direction, and vehicle class — down to the centisecond.

The
[`dt_history_raw()`](https://bbtheo.github.io/digitraffic/reference/dt_history_raw.md)
function downloads and parses these files into tidy tibbles, enriched
with a proper `datetime` column and human-readable vehicle class labels.

**Coverage:**

- Available from **December 2021** onwards
- Published the following day between 08:00-09:00 EET
- Typically 10,000-50,000 rows per station per day (busy highways)

## Setup

``` r

library(digitraffic)
library(dplyr)
library(ggplot2)
```

## Finding the right station

Before fetching history, you need the station’s `tms_number` (not the
`id`!). These two identifiers are different:

- **`id`** — used by
  [`dt_station_data()`](https://bbtheo.github.io/digitraffic/reference/dt_station_data.md)
  and
  [`dt_station()`](https://bbtheo.github.io/digitraffic/reference/dt_station.md)
  for real-time data
- **`tms_number`** — used by
  [`dt_history_raw()`](https://bbtheo.github.io/digitraffic/reference/dt_history_raw.md)
  for historical CSV files

``` r

# Find stations in Helsinki area
dt_stations(name = "Helsinki") |>
  select(id, tms_number, name)
#> # A tibble: 12 x 3
#>       id tms_number name
#>    <int>      <int> <chr>
#>  1 23101        101 vt4_Helsinki_Tattarisuo
#>  2 23102        102 vt3_Helsinki_Haaga
#>  …
```

## Fetching one day of data

``` r

raw <- dt_history_raw(tms_number = 1, date = as.Date("2024-06-15"))
raw
```

The result has 17 columns:

| Column | Type | Description |
|----|----|----|
| `station_id` | int | Station TMS number |
| `year_short` | int | 2-digit year |
| `day_of_year` | int | Day number (1-366) |
| `hour`, `minute`, `second`, `centisecond` | int | Passage time components |
| `vehicle_length_m` | dbl | Vehicle length in metres |
| `lane` | int | Lane number |
| `direction` | int | 1 = increasing direction, 2 = decreasing |
| `vehicle_class` | int | Class code 1-7 |
| `speed_kmh` | int | Speed in km/h |
| `quality_flag` | int | 0 = valid, 1 = outside valid range |
| `interval_ms` | int | Time since previous vehicle (ms) |
| `time_in_loop_ms` | int | Time spent over the detection loop (ms) |
| `datetime` | POSIXct | Full timestamp (Europe/Helsinki timezone) |
| `vehicle_class_label` | chr | English label for the vehicle class |

## Understanding vehicle classes

The `vehicle_class` column uses integer codes 1-7. The full mapping is
available via
[`dt_vehicle_classes()`](https://bbtheo.github.io/digitraffic/reference/dt_vehicle_classes.md):

``` r

dt_vehicle_classes()
#> # A tibble: 7 x 3
#>   vehicle_class label_en                   label_fi
#>           <int> <chr>                      <chr>
#> 1             1 Car / van                  ...
#> 2             2 Truck (no trailer)         ...
#> 3             3 Bus                        ...
#> 4             4 Truck + semitrailer        ...
#> 5             5 Truck + full trailer       ...
#> 6             6 Car + caravan / motorhome  ...
#> 7             7 Motorcycle / moped         ...
```

The `vehicle_class_label` column in
[`dt_history_raw()`](https://bbtheo.github.io/digitraffic/reference/dt_history_raw.md)
output already joins these labels for you.

## Data quality filtering

Always filter on `quality_flag == 0` for analysis. A flag of 1 indicates
the observation fell outside valid measurement ranges:

- Speed: 2-199 km/h
- Vehicle length: 1-39.8 m
- Hour: 0-23
- Direction: 1-2
- Vehicle class: 1-7
- Lane: \>= 1

``` r

# Remove faulty observations
clean <- raw |>
  filter(quality_flag == 0)

# Check how many were removed
nrow(raw) - nrow(clean)
```

## Common analyses

### Hourly traffic volume

``` r

hourly <- raw |>
  filter(quality_flag == 0) |>
  count(hour, direction, name = "vehicles")

ggplot(hourly, aes(x = hour, y = vehicles, colour = factor(direction))) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_x_continuous(breaks = 0:23) +
  labs(
    title = "Hourly traffic volume",
    x = "Hour of day",
    y = "Number of vehicles",
    colour = "Direction"
  ) +
  theme_minimal()
```

### Speed distribution

``` r

raw |>
  filter(quality_flag == 0, vehicle_class == 1) |>
  ggplot(aes(x = speed_kmh)) +
  geom_histogram(binwidth = 5, fill = "steelblue", colour = "white") +
  facet_wrap(~direction, labeller = labeller(direction = c(
    "1" = "Direction 1", "2" = "Direction 2"
  ))) +
  labs(
    title = "Speed distribution (cars/vans only)",
    x = "Speed (km/h)",
    y = "Count"
  ) +
  theme_minimal()
```

### Vehicle class breakdown

``` r

raw |>
  filter(quality_flag == 0) |>
  count(vehicle_class_label, sort = TRUE) |>
  mutate(pct = round(n / sum(n) * 100, 1))
#> # A tibble: 7 x 3
#>   vehicle_class_label          n   pct
#>   <chr>                    <int> <dbl>
#> 1 Car / van                24891  87.3
#> 2 Truck + full trailer      1532   5.4
#> 3 Truck + semitrailer        982   3.4
#> …
```

### Average speed by hour and vehicle type

``` r

raw |>
  filter(quality_flag == 0) |>
  mutate(type = if_else(vehicle_class == 1, "Passenger", "Heavy")) |>
  group_by(hour, type) |>
  summarise(mean_speed = mean(speed_kmh), .groups = "drop") |>
  ggplot(aes(x = hour, y = mean_speed, colour = type)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_x_continuous(breaks = 0:23) +
  labs(
    title = "Average speed by hour: passenger vs heavy vehicles",
    x = "Hour of day",
    y = "Mean speed (km/h)",
    colour = "Vehicle type"
  ) +
  theme_minimal()
```

### Headway analysis

The `interval_ms` column records the time gap between consecutive
vehicles in the same lane. This is useful for studying congestion and
following distances:

``` r

raw |>
  filter(quality_flag == 0, interval_ms > 0, interval_ms < 60000) |>
  ggplot(aes(x = interval_ms / 1000)) +
  geom_histogram(binwidth = 1, fill = "darkorange", colour = "white") +
  scale_x_continuous(limits = c(0, 30)) +
  labs(
    title = "Headway distribution (time gap to previous vehicle)",
    x = "Headway (seconds)",
    y = "Count"
  ) +
  theme_minimal()
```

## Multi-day analysis

To analyse multiple days, loop over dates with
[`lapply()`](https://rdrr.io/r/base/lapply.html) or
[`purrr::map()`](https://purrr.tidyverse.org/reference/map.html):

``` r

dates <- seq(as.Date("2024-06-10"), as.Date("2024-06-14"), by = "day")

week_data <- lapply(dates, function(d) {
  dt_history_raw(tms_number = 1, date = d) |>
    mutate(date = d)
}) |>
  bind_rows()

# Daily volume comparison
week_data |>
  filter(quality_flag == 0) |>
  count(date, name = "daily_total") |>
  mutate(weekday = format(date, "%A"))
```

### Performance note

Each day’s CSV file is a separate API request, typically 1-5 MB. For
large date ranges:

- Consider spacing requests to stay under the 60 req/min throttle
- Store intermediate results locally with
  [`saveRDS()`](https://rdrr.io/r/base/readRDS.html) /
  [`readRDS()`](https://rdrr.io/r/base/readRDS.html)
- For bulk analysis (months or years), consider using the pre-computed
  statistical reports at `https://tie.digitraffic.fi/ui/tms/history/`

## Comparing speed to free-flow baseline

Combine real-time or historical data with sensor constants to detect
congestion — i.e., when observed speeds drop significantly below the
free-flow reference:

``` r

# Get the free-flow speed for direction 1
consts <- dt_sensor_constants(id = 23001)
freeflow <- consts |>
  filter(name == "VVAPAAS1") |>
  pull(value)

# Compute hourly mean speed and compare to free flow
raw |>
  filter(quality_flag == 0, direction == 1) |>
  group_by(hour) |>
  summarise(mean_speed = mean(speed_kmh)) |>
  mutate(
    freeflow_speed = freeflow,
    speed_pct = round(mean_speed / freeflow_speed * 100, 1),
    congested = speed_pct < 70
  )
```

## Combining station metadata with history

A common workflow is to look up station details, then fetch historical
data:

``` r

# 1. Find a station
station <- dt_stations(name = "Espoo") |>
  slice(1)

# 2. Get its detailed metadata
detail <- dt_station(station$id)
cat("Station:", detail$name, "\n")
cat("Road:", detail$road_number, "\n")
cat("Municipality:", detail$municipality, "\n")
cat("Province:", detail$province, "\n")

# 3. Fetch yesterday's raw data using tms_number
raw <- dt_history_raw(
  tms_number = station$tms_number,
  date = Sys.Date() - 1
)

# 4. Summarise
raw |>
  filter(quality_flag == 0) |>
  summarise(
    total_vehicles = n(),
    mean_speed     = round(mean(speed_kmh), 1),
    pct_heavy      = round(mean(vehicle_class >= 2) * 100, 1)
  )
```

## Further resources

- [Digitraffic road traffic
  documentation](https://www.digitraffic.fi/tieliikenne/)
  (Finnish/English)
- [Digitraffic LAM
  documentation](https://www.digitraffic.fi/tieliikenne/lam/) — detailed
  sensor descriptions
- [API Swagger documentation](https://tie.digitraffic.fi/swagger/) —
  full endpoint reference
- [Getting started
  vignette](https://bbtheo.github.io/digitraffic/articles/digitraffic.md)
  — real-time data, sensors, and station metadata
- [Station filtering
  vignette](https://bbtheo.github.io/digitraffic/articles/station-filtering.md)
  — filtering by road, municipality, province, and bounding box
