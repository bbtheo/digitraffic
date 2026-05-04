# Clear the in-session digitraffic cache

Station metadata is cached for 5 minutes within an R session to avoid
redundant API calls. Call this function to force the next
[`dt_stations()`](https://theo-maon.github.io/digitraffic/reference/dt_stations.md)
or
[`dt_station()`](https://theo-maon.github.io/digitraffic/reference/dt_station.md)
call to fetch fresh data.

## Usage

``` r
dt_cache_clear()
```

## Value

Invisibly returns `NULL`.

## Examples

``` r
dt_cache_clear()
#> digitraffic cache cleared.
```
