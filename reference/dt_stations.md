# List all LAM/TMS measurement stations

Fetches metadata for all automatic traffic measurement (LAM/TMS)
stations from the Digitraffic API. Results are cached for 5 minutes
within the current R session; call
[`dt_cache_clear()`](https://theo-maon.github.io/digitraffic/reference/dt_cache_clear.md)
to force a fresh fetch.

## Usage

``` r
dt_stations(name = NULL)
```

## Arguments

- name:

  `NULL` (default) or a character string used as a case-insensitive
  regular expression to filter stations by name. Station names typically
  encode the road and location, e.g. `"vt1_Espoo_Hirvisuo"`.

## Value

A tibble with one row per station and columns:

- id:

  Integer. Internal API station identifier.

- tms_number:

  Integer. TMS system number (used for history CSV).

- name:

  Character. Station name.

- longitude:

  Double. WGS-84 longitude.

- latitude:

  Double. WGS-84 latitude.

- elevation:

  Double. Elevation in metres.

- bearing:

  Integer. Road bearing in degrees (0–360).

- collection_status:

  Character. `"GATHERING"` or `"REMOVED_TEMPORARILY"`.

- state:

  Character. Operational state, e.g. `"OK"`.

- data_updated_time:

  POSIXct (UTC). Time the record was last updated.

## Examples

``` r
if (FALSE) { # \dontrun{
# All stations
dt_stations()

# Stations whose name contains "Espoo"
dt_stations(name = "Espoo")

# Stations on valtatie 1 (road E18)
dt_stations(name = "^vt1_")
} # }
```
