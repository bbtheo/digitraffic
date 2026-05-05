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

# Sensor data (real-time) -------------------------------------------------

# Flatten one station's sensorValues list into a tibble.
# `data` is the full parsed response for one station.
parse_sensor_values <- function(data) {
  values <- data[["sensorValues"]]
  station_id  <- as.integer(data[["id"]] %||% NA_integer_)
  tms_number  <- as.integer(data[["tmsNumber"]] %||% NA_integer_)
  updated     <- parse_dt(data[["dataUpdatedTime"]])

  if (length(values) == 0L) {
    return(tibble::tibble(
      station_id        = integer(),
      tms_number        = integer(),
      data_updated_time = as.POSIXct(character()),
      sensor_id         = integer(),
      name              = character(),
      short_name        = character(),
      value             = double(),
      unit              = character(),
      measured_time     = as.POSIXct(character()),
      time_window_start = as.POSIXct(character()),
      time_window_end   = as.POSIXct(character())
    ))
  }

  rows <- lapply(values, function(v) {
    tibble::tibble(
      station_id        = station_id,
      tms_number        = tms_number,
      data_updated_time = updated,
      sensor_id         = as.integer(v[["id"]] %||% NA_integer_),
      name              = v[["name"]] %||% NA_character_,
      short_name        = v[["shortName"]] %||% NA_character_,
      value             = as.double(v[["value"]] %||% NA_real_),
      unit              = v[["unit"]] %||% NA_character_,
      measured_time     = parse_dt(v[["measuredTime"]]),
      time_window_start = parse_dt(v[["timeWindowStart"]]),
      time_window_end   = parse_dt(v[["timeWindowEnd"]])
    )
  })
  dplyr::bind_rows(rows)
}

# Flatten all stations' sensor data (bulk endpoint) into a single tibble.
parse_all_stations_data <- function(data) {
  stations <- data[["stations"]]
  if (length(stations) == 0L) return(parse_sensor_values(list(sensorValues = list())))
  dplyr::bind_rows(lapply(stations, parse_sensor_values))
}

# Sensor metadata ---------------------------------------------------------

# Flatten the sensors metadata response into a tibble.
parse_sensors <- function(data) {
  sensors <- data[["sensors"]]
  if (length(sensors) == 0L) {
    return(tibble::tibble(
      id             = integer(),
      name           = character(),
      short_name     = character(),
      unit           = character(),
      direction      = character(),
      description_fi = character(),
      description_en = character()
    ))
  }

  rows <- lapply(sensors, function(s) {
    desc <- s[["descriptions"]] %||% list()
    tibble::tibble(
      id             = as.integer(s[["id"]] %||% NA_integer_),
      name           = s[["name"]] %||% NA_character_,
      short_name     = s[["shortName"]] %||% NA_character_,
      unit           = s[["unit"]] %||% NA_character_,
      direction      = s[["direction"]] %||% NA_character_,
      description_fi = desc[["fi"]] %||% NA_character_,
      description_en = desc[["en"]] %||% NA_character_
    )
  })
  dplyr::bind_rows(rows)
}

# Sensor constants --------------------------------------------------------

# Flatten the sensor-constants response into a tidy tibble.
parse_sensor_constants <- function(data) {
  stations <- data[["stations"]]
  if (length(stations) == 0L) {
    return(tibble::tibble(
      station_id        = integer(),
      data_updated_time = as.POSIXct(character()),
      name              = character(),
      value             = double(),
      valid_from        = character(),
      valid_to          = character()
    ))
  }

  rows <- lapply(stations, function(st) {
    sid     <- as.integer(st[["id"]] %||% NA_integer_)
    updated <- parse_dt(st[["dataUpdatedTime"]])
    consts  <- st[["sensorConstantValues"]] %||% list()
    if (length(consts) == 0L) {
      return(tibble::tibble(
        station_id        = sid,
        data_updated_time = updated,
        name              = NA_character_,
        value             = NA_real_,
        valid_from        = NA_character_,
        valid_to          = NA_character_
      ))
    }
    dplyr::bind_rows(lapply(consts, function(c) {
      tibble::tibble(
        station_id        = sid,
        data_updated_time = updated,
        name              = c[["name"]]  %||% NA_character_,
        value             = as.double(c[["value"]] %||% NA_real_),
        valid_from        = c[["validFrom"]] %||% NA_character_,
        valid_to          = c[["validTo"]]   %||% NA_character_
      )
    }))
  })
  dplyr::bind_rows(rows)
}

# Historical raw CSV ------------------------------------------------------

# Column names for the LAM raw CSV format (semicolon-delimited, no header).
.lam_csv_col_names <- c(
  "station_id", "year_short", "day_of_year",
  "hour", "minute", "second", "centisecond",
  "vehicle_length_m", "lane", "direction",
  "vehicle_class", "speed_kmh", "quality_flag",
  "interval_ms", "time_in_loop_ms"
)

.lam_csv_col_types <- "iiiiiiididiiiii"

# Parse a LAM raw CSV text string into a tibble.
# Adds a full `datetime` (POSIXct UTC) and `vehicle_class_label` column.
parse_history_csv <- function(text, date) {
  if (!nzchar(trimws(text))) {
    cli::cli_abort(
      c("The CSV response is empty.",
        "i" = "No data may be available for this station and date.")
    )
  }

  df <- readr::read_delim(
    I(text),
    delim           = ";",
    col_names       = .lam_csv_col_names,
    col_types       = .lam_csv_col_types,
    show_col_types  = FALSE,
    progress        = FALSE
  )

  # Build a proper datetime from year + day-of-year + time components.
  # The CSV year_short is 2-digit; reconstruct the full year from the date arg.
  full_year <- as.integer(format(date, "%Y"))
  df$datetime <- as.POSIXct(
    sprintf(
      "%04d-%03d %02d:%02d:%02d.%02d",
      full_year, df$day_of_year,
      df$hour, df$minute, df$second, df$centisecond
    ),
    format = "%Y-%j %H:%M:%OS",
    tz = "Europe/Helsinki"
  )

  # Join vehicle class labels.
  vc <- dt_vehicle_classes()[, c("vehicle_class", "label_en")]
  df <- dplyr::left_join(df, vc, by = "vehicle_class")
  dplyr::rename(df, vehicle_class_label = "label_en")
}

# Shared helpers ----------------------------------------------------------

# Parse an ISO 8601 UTC timestamp string to POSIXct, returning NA on failure.
# Handles trailing "Z" (most common from Digitraffic) as well as numeric
# UTC offsets (+HH:MM / -HH:MM) and bare datetime strings.  All results are
# returned in UTC regardless of any stated offset.
parse_dt <- function(x) {
  if (is.null(x) || is.na(x)) return(as.POSIXct(NA_character_, tz = "UTC"))
  # Strip trailing Z (case-insensitive) or a numeric UTC offset (e.g. +03:00).
  x <- sub("[Zz]$", "", x)
  x <- sub("[+-][0-9]{2}:[0-9]{2}$", "", x)
  as.POSIXct(x, format = "%Y-%m-%dT%H:%M:%OS", tz = "UTC")
}
