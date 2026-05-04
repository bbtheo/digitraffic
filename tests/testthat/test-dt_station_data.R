## Tests for dt_station_data(), dt_stations_data(), and dt_sensors()

# dt_station_data() -------------------------------------------------------

test_that("dt_station_data() returns a tibble with expected columns", {
  httptest2::with_mock_dir("fixtures", {
    result <- dt_station_data(23001)
    expect_s3_class(result, "tbl_df")
    expect_named(result, c(
      "station_id", "tms_number", "data_updated_time",
      "sensor_id", "name", "short_name",
      "value", "unit", "measured_time",
      "time_window_start", "time_window_end"
    ))
  })
})

test_that("dt_station_data() returns correct number of rows", {
  httptest2::with_mock_dir("fixtures", {
    result <- dt_station_data(23001)
    expect_equal(nrow(result), 3L)
  })
})

test_that("dt_station_data() columns have correct types", {
  httptest2::with_mock_dir("fixtures", {
    result <- dt_station_data(23001)
    expect_type(result$station_id,  "integer")
    expect_type(result$tms_number,  "integer")
    expect_type(result$sensor_id,   "integer")
    expect_type(result$name,        "character")
    expect_type(result$value,       "double")
    expect_type(result$unit,        "character")
    expect_s3_class(result$measured_time,     "POSIXct")
    expect_s3_class(result$data_updated_time, "POSIXct")
  })
})

test_that("dt_station_data() station_id matches the requested id", {
  httptest2::with_mock_dir("fixtures", {
    result <- dt_station_data(23001)
    expect_true(all(result$station_id == 23001L))
  })
})

test_that("dt_station_data() handles null timeWindowStart/End as NA POSIXct", {
  httptest2::with_mock_dir("fixtures", {
    result <- dt_station_data(23001)
    status_row <- result[result$name == "TILA", ]
    expect_true(is.na(status_row$time_window_start))
    expect_true(is.na(status_row$time_window_end))
  })
})

test_that("dt_station_data() rejects invalid id", {
  expect_error(dt_station_data("abc"), class = "rlang_error")
  expect_error(dt_station_data(-1),    class = "rlang_error")
})

test_that("dt_station_data() raises not-found error on 404", {
  mock_404 <- httr2::response(
    status_code = 404L,
    headers = list(`Content-Type` = "application/json"),
    body = charToRaw('{"message":"Not Found"}')
  )
  httr2::with_mocked_responses(list(mock_404), {
    expect_error(dt_station_data(99999), class = "digitraffic_error_not_found")
  })
})

# dt_stations_data() ------------------------------------------------------

test_that("dt_stations_data() returns a tibble with data from all stations", {
  httptest2::with_mock_dir("fixtures", {
    result <- dt_stations_data()
    expect_s3_class(result, "tbl_df")
    expect_equal(sort(unique(result$station_id)), c(20002L, 23001L))
  })
})

test_that("dt_stations_data() has the same columns as dt_station_data()", {
  httptest2::with_mock_dir("fixtures", {
    result <- dt_stations_data()
    expect_named(result, c(
      "station_id", "tms_number", "data_updated_time",
      "sensor_id", "name", "short_name",
      "value", "unit", "measured_time",
      "time_window_start", "time_window_end"
    ))
  })
})

# dt_sensors() ------------------------------------------------------------

test_that("dt_sensors() returns a tibble with expected columns", {
  httptest2::with_mock_dir("fixtures", {
    result <- dt_sensors()
    expect_s3_class(result, "tbl_df")
    expect_named(result, c(
      "id", "name", "short_name", "unit",
      "direction", "description_fi", "description_en"
    ))
  })
})

test_that("dt_sensors() returns correct number of sensors", {
  httptest2::with_mock_dir("fixtures", {
    result <- dt_sensors()
    expect_equal(nrow(result), 3L)
  })
})

test_that("dt_sensors() returns correct values", {
  httptest2::with_mock_dir("fixtures", {
    result <- dt_sensors()
    speed_sensor <- result[result$id == 5057, ]
    expect_equal(speed_sensor$unit,      "km/h")
    expect_equal(speed_sensor$direction, "INCREASING_DIRECTION")
    expect_equal(speed_sensor$description_en, "Average speed direction 1 (60 min)")
  })
})

test_that("dt_sensors() sensor with no English description returns NA", {
  httptest2::with_mock_dir("fixtures", {
    result <- dt_sensors()
    count_sensor <- result[result$id == 5016, ]
    expect_true(is.na(count_sensor$description_en))
  })
})
