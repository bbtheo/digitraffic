# List all LAM/TMS measurement stations

Fetches metadata for all automatic traffic measurement (LAM/TMS)
stations from the Digitraffic API. Basic results are cached for 5
minutes per R session. Extended columns (`road_number`, `municipality`,
`province`) are always included in the output: `road_number` is parsed
from the station name (no extra API calls), while `municipality` and
`province` are joined from the bundled detailed cache (or a
user-refreshed disk cache — see
[`dt_stations_load_details()`](https://bbtheo.github.io/digitraffic/reference/dt_stations_load_details.md)).

## Usage

``` r
dt_stations(
  name = NULL,
  road_number = NULL,
  municipality = NULL,
  province = NULL,
  bbox = NULL
)
```

## Arguments

- name:

  `NULL` or a case-insensitive regular expression matched against
  station names, e.g. `"Espoo"` or `"^vt1_"`.

- road_number:

  `NULL` or a positive integer road number, e.g. `7` for valtatie 7.
  Parsed from the station name — fast, no extra API calls.

- municipality:

  `NULL` or a character string matched case-insensitively against the
  `municipality` column, e.g. `"Espoo"`. Supports regex, e.g.
  `"Helsinki|Espoo"`.

- province:

  `NULL` or a character string matched case-insensitively against the
  `province` column, e.g. `"Uusimaa"`. Supports regex.

- bbox:

  `NULL` or a length-4 numeric vector
  `c(lon_min, lat_min, lon_max, lat_max)` in WGS-84 degrees. Filters
  stations whose coordinates fall inside the bounding box.

## Value

A tibble with one row per matching station and columns:

- id:

  Integer. Internal API station identifier.

- tms_number:

  Integer. TMS system number (used for history CSV).

- name:

  Character. Station name.

- road_number:

  Integer. Road number parsed from the station name (e.g. `7` for
  `"vt7_Rita"`). `NA` for non-standard names.

- longitude:

  Double. WGS-84 longitude.

- latitude:

  Double. WGS-84 latitude.

- elevation:

  Double. Elevation in metres.

- bearing:

  Integer. Road bearing in degrees (0–360).

- municipality:

  Character. Municipality name from the detailed cache. `NA` for
  stations added after the cache was last built.

- province:

  Character. Province name from the detailed cache. `NA` for stations
  added after the cache was last built.

- collection_status:

  Character. `"GATHERING"` or `"REMOVED_TEMPORARILY"`.

- state:

  Character. Operational state, e.g. `"OK"`.

- data_updated_time:

  POSIXct (UTC). Time the record was last updated.

## Details

If the live station list has changed since the cache was built and you
filter by `municipality` or `province`, a warning is emitted with
instructions to refresh the cache.

## Examples

``` r
if (FALSE) { # \dontrun{
# All stations — road_number, municipality, province always present
dt_stations()

# By name (regex supported)
dt_stations(name = "Espoo")
dt_stations(name = "^vt1_")

# By road number
dt_stations(road_number = 7)

# By municipality (matches the municipality column you see in the output)
dt_stations(municipality = "Espoo")

# By province
dt_stations(province = "Uusimaa")

# By bounding box (Helsinki metropolitan area)
dt_stations(bbox = c(24.5, 60.1, 25.2, 60.4))

# Combine filters
dt_stations(road_number = 1, municipality = "Espoo")
} # }
```
