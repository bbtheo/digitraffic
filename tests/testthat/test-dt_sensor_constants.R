## Tests for dt_sensor_constants() (R/dt_sensor_constants.R)

test_that("dt_sensor_constants() returns a tibble with expected columns", {
  httptest2::with_mock_dir("fixtures", {
    result <- dt_sensor_constants()
    expect_s3_class(result, "tbl_df")
    expect_named(result, c(
      "station_id", "data_updated_time",
      "name", "value", "valid_from", "valid_to"
    ))
  })
})

test_that("dt_sensor_constants() returns data for all stations", {
  httptest2::with_mock_dir("fixtures", {
    result <- dt_sensor_constants()
    expect_setequal(unique(result$station_id), c(20002L, 23001L))
  })
})

test_that("dt_sensor_constants() value column is numeric", {
  httptest2::with_mock_dir("fixtures", {
    result <- dt_sensor_constants()
    expect_type(result$value, "double")
  })
})

test_that("dt_sensor_constants() valid_from/valid_to are MM-DD strings", {
  httptest2::with_mock_dir("fixtures", {
    result <- dt_sensor_constants()
    expect_match(result$valid_from, "^\\d{2}-\\d{2}$")
    expect_match(result$valid_to,   "^\\d{2}-\\d{2}$")
  })
})

test_that("dt_sensor_constants(id) filters to a single station", {
  httptest2::with_mock_dir("fixtures", {
    result <- dt_sensor_constants(id = 23001)
    expect_true(all(result$station_id == 23001L))
    expect_gt(nrow(result), 0L)
  })
})

test_that("dt_sensor_constants(id) returns correct values for station 23001", {
  httptest2::with_mock_dir("fixtures", {
    result <- dt_sensor_constants(id = 23001)
    vvapaas1 <- result[result$name == "VVAPAAS1", ]
    expect_equal(vvapaas1$value, 105.0)
    road_dir <- result[result$name == "Tien_suunta", ]
    expect_equal(road_dir$value, 60.0)
  })
})

test_that("dt_sensor_constants(id) warns for unknown station id", {
  httptest2::with_mock_dir("fixtures", {
    expect_warning(
      dt_sensor_constants(id = 99999),
      class = "rlang_warning"
    )
  })
})

test_that("dt_sensor_constants() rejects non-integer id", {
  expect_error(dt_sensor_constants(id = "abc"), class = "rlang_error")
})
