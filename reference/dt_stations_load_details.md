# Fetch and cache detailed metadata for all LAM/TMS stations

Downloads extended metadata (municipality, province, road number, …) for
every station using parallel HTTP requests and saves the result to the
user cache directory (`tools::R_user_dir("digitraffic", "cache")`).

## Usage

``` r
dt_stations_load_details(max_active = 10L)
```

## Arguments

- max_active:

  Integer. Maximum number of concurrent HTTP requests. Default is `10`.
  Increase for faster fetching on a fast connection; decrease to be more
  polite to the API.

## Value

Invisibly returns the detailed stations tibble.

## Details

After running this function the new filters in
[`dt_stations()`](https://bbtheo.github.io/digitraffic/reference/dt_stations.md)
— `road_number`, `municipality`, `province`, and `bbox` — will use the
refreshed data. You only need to re-run this when the package warns that
the cache is out of date (i.e., new stations have been added to the
network).

## Examples

``` r
if (FALSE) { # \dontrun{
dt_stations_load_details()
} # }
```
