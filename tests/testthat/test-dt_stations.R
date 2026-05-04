## Tests for dt_stations() and dt_station() (R/dt_stations.R)
## Uses httptest2::with_mock_dir() to serve fixture JSON files.

# dt_stations() -----------------------------------------------------------

test_that("dt_stations() returns a tibble with expected columns", {
  httptest2::with_mock_dir("fixtures", {
    result <- dt_stations()
    expect_s3_class(result, "tbl_df")
    expect_named(result, c(
      "id", "tms_number", "name", "longitude", "latitude", "elevation",
      "bearing", "collection_status", "state", "data_updated_time"
    ))
  })
})

test_that("dt_stations() returns all stations from the fixture", {
  httptest2::with_mock_dir("fixtures", {
    result <- dt_stations()
    expect_equal(nrow(result), 3L)
  })
})

test_that("dt_stations() columns have correct types", {
  httptest2::with_mock_dir("fixtures", {
    result <- dt_stations()
    expect_type(result$id,                "integer")
    expect_type(result$tms_number,        "integer")
    expect_type(result$name,              "character")
    expect_type(result$longitude,         "double")
    expect_type(result$latitude,          "double")
    expect_type(result$elevation,         "double")
    expect_type(result$bearing,           "integer")
    expect_type(result$collection_status, "character")
    expect_s3_class(result$data_updated_time, "POSIXct")
  })
})

test_that("dt_stations() name filter works (case-insensitive)", {
  httptest2::with_mock_dir("fixtures", {
    result <- dt_stations(name = "espoo")
    expect_equal(nrow(result), 1L)
    expect_equal(result$name, "vt1_Espoo_Hirvisuo")
  })
})

test_that("dt_stations() name filter supports regex", {
  httptest2::with_mock_dir("fixtures", {
    result <- dt_stations(name = "^vt[13]_")
    expect_equal(nrow(result), 2L)
  })
})

test_that("dt_stations() returns zero rows (not error) for no matches", {
  httptest2::with_mock_dir("fixtures", {
    result <- dt_stations(name = "zzz_no_match")
    expect_s3_class(result, "tbl_df")
    expect_equal(nrow(result), 0L)
  })
})

test_that("dt_stations() rejects non-string name argument", {
  httptest2::with_mock_dir("fixtures", {
    expect_error(dt_stations(name = 123), class = "rlang_error")
    expect_error(dt_stations(name = c("a", "b")), class = "rlang_error")
  })
})

test_that("dt_stations() caches results within session", {
  dt_cache_clear()
  httptest2::with_mock_dir("fixtures", {
    r1 <- dt_stations()
    # Second call should use cache — if it tried to make a request outside
    # the mock context it would error, so this proves the cache was used.
  })
  r2 <- dt_stations()  # outside mock dir — must come from cache
  expect_equal(nrow(r2), 3L)
  dt_cache_clear()
})

# dt_station() ------------------------------------------------------------

test_that("dt_station() returns a single-row tibble", {
  httptest2::with_mock_dir("fixtures", {
    result <- dt_station(23001)
    expect_s3_class(result, "tbl_df")
    expect_equal(nrow(result), 1L)
  })
})

test_that("dt_station() returns all extended columns", {
  httptest2::with_mock_dir("fixtures", {
    result <- dt_station(23001)
    expected_cols <- c(
      "id", "tms_number", "name", "name_fi", "name_sv", "name_en",
      "longitude", "latitude", "elevation", "bearing",
      "collection_status", "collection_interval", "state", "station_type",
      "municipality", "municipality_code", "province", "province_code",
      "direction1_municipality", "direction1_municipality_code",
      "direction2_municipality", "direction2_municipality_code",
      "road_number", "road_section", "distance_from_section_start",
      "carriageway", "free_flow_speed1", "free_flow_speed2",
      "livi_id", "purpose", "start_time", "data_updated_time"
    )
    expect_named(result, expected_cols)
  })
})

test_that("dt_station() returns correct values for station 23001", {
  httptest2::with_mock_dir("fixtures", {
    result <- dt_station(23001)
    expect_equal(result$id,           23001L)
    expect_equal(result$tms_number,   1L)
    expect_equal(result$name,         "vt7_Rita")
    expect_equal(result$road_number,  7L)
    expect_equal(result$municipality, "Porvoo")
    expect_equal(result$province,     "Uusimaa")
    expect_equal(result$free_flow_speed1, 105.0)
    expect_equal(result$free_flow_speed2, 95.0)
  })
})

test_that("dt_station() raises digitraffic_error_not_found for unknown id", {
  mock_404 <- httr2::response(
    status_code = 404L,
    headers = list(`Content-Type` = "application/json"),
    body = charToRaw('{"message":"Not Found"}')
  )
  httr2::with_mocked_responses(list(mock_404), {
    expect_error(dt_station(99999), class = "digitraffic_error_not_found")
  })
})

test_that("dt_station() rejects non-integer id", {
  expect_error(dt_station("abc"), class = "rlang_error")
  expect_error(dt_station(1.5),   class = "rlang_error")
  expect_error(dt_station(-1),    class = "rlang_error")
})

# parse_stations_response() edge cases ------------------------------------

test_that("parse_stations_response() handles empty features list", {
  empty <- list(type = "FeatureCollection", features = list())
  result <- parse_stations_response(empty)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0L)
  expect_named(result, c(
    "id", "tms_number", "name", "longitude", "latitude", "elevation",
    "bearing", "collection_status", "state", "data_updated_time"
  ))
})

test_that("parse_stations_response() handles NULL state gracefully", {
  data <- list(
    type = "FeatureCollection",
    features = list(list(
      type = "Feature",
      id   = 1L,
      geometry = list(type = "Point", coordinates = list(25.0, 60.0, 10.0)),
      properties = list(
        id = 1L, tmsNumber = 1L, name = "test", bearing = 90L,
        collectionStatus = "GATHERING", dataUpdatedTime = NULL, state = NULL
      )
    ))
  )
  result <- parse_stations_response(data)
  expect_equal(nrow(result), 1L)
  expect_true(is.na(result$state))
})
