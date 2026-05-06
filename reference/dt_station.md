# Get detailed metadata for a single LAM/TMS station

Fetches extended metadata for one station by its internal API `id`. To
look up the id first, use
[`dt_stations()`](https://bbtheo.github.io/digitraffic/reference/dt_stations.md).

## Usage

``` r
dt_station(id)
```

## Arguments

- id:

  A single positive integer: the station's `id` as returned by
  [`dt_stations()`](https://bbtheo.github.io/digitraffic/reference/dt_stations.md).
  Note: this is **not** the same as `tms_number` (which is used for
  historical CSV downloads via
  [`dt_history_raw()`](https://bbtheo.github.io/digitraffic/reference/dt_history_raw.md)).

## Value

A one-row tibble with columns:

- id, tms_number, name, name_fi, name_sv, name_en:

  Identifiers and multilingual names.

- longitude, latitude, elevation:

  WGS-84 coordinates.

- bearing:

  Road bearing in degrees.

- collection_status, collection_interval, state:

  Operational status.

- station_type:

  Hardware type, e.g. `"DSL_6"`.

- municipality, municipality_code:

  Municipality name and code.

- province, province_code:

  Province name and code.

- direction1_municipality, direction1_municipality_code:

  Municipality in direction 1.

- direction2_municipality, direction2_municipality_code:

  Municipality in direction 2.

- road_number, road_section, distance_from_section_start:

  Road address.

- carriageway:

  Carriageway descriptor.

- free_flow_speed1, free_flow_speed2:

  Free-flow speed (km/h) per direction.

- livi_id:

  LIVI system identifier.

- purpose:

  Measurement purpose.

- start_time, data_updated_time:

  POSIXct (UTC) timestamps.

## Examples

``` r
if (FALSE) { # \dontrun{
# Look up a station id first
stations <- dt_stations(name = "Espoo")
dt_station(stations$id[[1]])
} # }
```
