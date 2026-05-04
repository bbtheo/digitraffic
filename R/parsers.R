## Internal response flatteners: API nested lists/CSV → tibbles.
##
## None of these are exported.  Each function takes the parsed JSON list
## returned by dt_get_json() (or raw text from dt_get_csv()) and returns
## a tibble with snake_case column names.

# Station metadata (bulk) -------------------------------------------------

# Flatten a stations FeatureCollection (list from resp_body_json) into a tibble.
# Each feature has geometry$coordinates [lon, lat, elev] and a properties list.
parse_stations_response <- function(data) {
  features <- data[["features"]]
  if (length(features) == 0L) {
    return(tibble::tibble(
      id                = integer(),
      tms_number        = integer(),
      name              = character(),
      longitude         = double(),
      latitude          = double(),
      elevation         = double(),
      bearing           = integer(),
      collection_status = character(),
      state             = character(),
      data_updated_time = as.POSIXct(character())
    ))
  }

  rows <- lapply(features, function(f) {
    coords <- f[["geometry"]][["coordinates"]]
    p      <- f[["properties"]]
    tibble::tibble(
      id                = as.integer(p[["id"]] %||% NA_integer_),
      tms_number        = as.integer(p[["tmsNumber"]] %||% NA_integer_),
      name              = p[["name"]] %||% NA_character_,
      longitude         = as.double(coords[[1L]] %||% NA_real_),
      latitude          = as.double(coords[[2L]] %||% NA_real_),
      elevation         = as.double(coords[[3L]] %||% NA_real_),
      bearing           = as.integer(p[["bearing"]] %||% NA_integer_),
      collection_status = p[["collectionStatus"]] %||% NA_character_,
      state             = p[["state"]] %||% NA_character_,
      data_updated_time = parse_dt(p[["dataUpdatedTime"]])
    )
  })

  dplyr::bind_rows(rows)
}

# Station metadata (single) -----------------------------------------------

# Flatten a single-station Feature into a one-row tibble with extended fields.
parse_station_detail <- function(data) {
  coords <- data[["geometry"]][["coordinates"]]
  p      <- data[["properties"]]
  ra     <- p[["roadAddress"]] %||% list()
  nm     <- p[["names"]]      %||% list()

  tibble::tibble(
    id                              = as.integer(p[["id"]] %||% NA_integer_),
    tms_number                      = as.integer(p[["tmsNumber"]] %||% NA_integer_),
    name                            = p[["name"]] %||% NA_character_,
    name_fi                         = nm[["fi"]] %||% NA_character_,
    name_sv                         = nm[["sv"]] %||% NA_character_,
    name_en                         = nm[["en"]] %||% NA_character_,
    longitude                       = as.double(coords[[1L]] %||% NA_real_),
    latitude                        = as.double(coords[[2L]] %||% NA_real_),
    elevation                       = as.double(coords[[3L]] %||% NA_real_),
    bearing                         = as.integer(p[["bearing"]] %||% NA_integer_),
    collection_status               = p[["collectionStatus"]] %||% NA_character_,
    collection_interval             = as.integer(p[["collectionInterval"]] %||% NA_integer_),
    state                           = p[["state"]] %||% NA_character_,
    station_type                    = p[["stationType"]] %||% NA_character_,
    municipality                    = p[["municipality"]] %||% NA_character_,
    municipality_code               = as.integer(p[["municipalityCode"]] %||% NA_integer_),
    province                        = p[["province"]] %||% NA_character_,
    province_code                   = as.integer(p[["provinceCode"]] %||% NA_integer_),
    direction1_municipality         = p[["direction1Municipality"]] %||% NA_character_,
    direction1_municipality_code    = as.integer(p[["direction1MunicipalityCode"]] %||% NA_integer_),
    direction2_municipality         = p[["direction2Municipality"]] %||% NA_character_,
    direction2_municipality_code    = as.integer(p[["direction2MunicipalityCode"]] %||% NA_integer_),
    road_number                     = as.integer(ra[["roadNumber"]] %||% NA_integer_),
    road_section                    = as.integer(ra[["roadSection"]] %||% NA_integer_),
    distance_from_section_start     = as.integer(ra[["distanceFromRoadSectionStart"]] %||% NA_integer_),
    carriageway                     = ra[["carriageway"]] %||% NA_character_,
    free_flow_speed1                = as.double(p[["freeFlowSpeed1"]] %||% NA_real_),
    free_flow_speed2                = as.double(p[["freeFlowSpeed2"]] %||% NA_real_),
    livi_id                         = p[["liviId"]] %||% NA_character_,
    purpose                         = p[["purpose"]] %||% NA_character_,
    start_time                      = parse_dt(p[["startTime"]]),
    data_updated_time               = parse_dt(p[["dataUpdatedTime"]])
  )
}

# Shared helpers ----------------------------------------------------------

# Parse an ISO 8601 UTC timestamp string to POSIXct, returning NA on failure.
parse_dt <- function(x) {
  if (is.null(x) || is.na(x)) return(as.POSIXct(NA))
  as.POSIXct(x, format = "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC")
}
