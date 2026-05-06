# Clear the in-session digitraffic cache

Station metadata
([`dt_stations()`](https://bbtheo.github.io/digitraffic/reference/dt_stations.md))
and sensor metadata
([`dt_sensors()`](https://bbtheo.github.io/digitraffic/reference/dt_sensors.md))
are cached for 5 minutes within an R session to avoid redundant API
calls. Call this function to force the next call to either function to
fetch fresh data from the API.

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
