## Tests for dt_history_raw() and parse_history_csv() (Phases 6)

# dt_history_raw() --------------------------------------------------------

test_that("dt_history_raw() returns a tibble with expected columns", {
  httptest2::with_mock_dir("fixtures", {
    result <- dt_history_raw(tms_number = 1, date = as.Date("2024-01-15"))
    expect_s3_class(result, "tbl_df")
    expect_named(result, c(
      "station_id", "year_short", "day_of_year",
      "hour", "minute", "second", "centisecond",
      "vehicle_length_m", "lane", "direction",
      "vehicle_class", "speed_kmh", "quality_flag",
      "interval_ms", "time_in_loop_ms",
      "datetime", "vehicle_class_label"
    ))
  })
})

test_that("dt_history_raw() returns correct row count", {
  httptest2::with_mock_dir("fixtures", {
    result <- dt_history_raw(tms_number = 1, date = as.Date("2024-01-15"))
    expect_equal(nrow(result), 7L)
  })
})

test_that("dt_history_raw() datetime column is POSIXct in Helsinki timezone", {
  httptest2::with_mock_dir("fixtures", {
    result <- dt_history_raw(tms_number = 1, date = as.Date("2024-01-15"))
    expect_s3_class(result$datetime, "POSIXct")
    expect_equal(attr(result$datetime, "tzone"), "Europe/Helsinki")
  })
})

test_that("dt_history_raw() vehicle_class_label is populated correctly", {
  httptest2::with_mock_dir("fixtures", {
    result <- dt_history_raw(tms_number = 1, date = as.Date("2024-01-15"))
    expect_type(result$vehicle_class_label, "character")
    # class 1 = "Car / van"
    car_rows <- result[result$vehicle_class == 1L, ]
    expect_true(all(car_rows$vehicle_class_label == "Car / van"))
    # class 8 = "Motorcycle / moped"
    moto_row <- result[result$vehicle_class == 8L, ]
    expect_equal(moto_row$vehicle_class_label, "Motorcycle / moped")
  })
})

test_that("dt_history_raw() speed_kmh is integer", {
  httptest2::with_mock_dir("fixtures", {
    result <- dt_history_raw(tms_number = 1, date = as.Date("2024-01-15"))
    expect_type(result$speed_kmh, "integer")
  })
})

test_that("dt_history_raw() rejects invalid tms_number", {
  expect_error(dt_history_raw(tms_number = -1, date = as.Date("2024-01-15")), class = "rlang_error")
  expect_error(dt_history_raw(tms_number = "x", date = as.Date("2024-01-15")), class = "rlang_error")
})

test_that("dt_history_raw() rejects invalid date", {
  expect_error(dt_history_raw(tms_number = 1, date = "2024-01-15"), class = "rlang_error")
  expect_error(dt_history_raw(tms_number = 1, date = as.Date("2021-11-30")), class = "rlang_error")
  expect_error(dt_history_raw(tms_number = 1, date = Sys.Date()), class = "rlang_error")
})

# parse_history_csv() -----------------------------------------------------

test_that("parse_history_csv() errors on empty string", {
  expect_error(
    parse_history_csv("", date = as.Date("2024-01-15")),
    class = "rlang_error"
  )
})

test_that("parse_history_csv() errors on whitespace-only string", {
  expect_error(
    parse_history_csv("   \n  ", date = as.Date("2024-01-15")),
    class = "rlang_error"
  )
})

test_that("parse_history_csv() parses a minimal valid row", {
  csv <- "1;24;15;8;0;12;34;5.2;1;1;1;97;0;3240;456\n"
  result <- parse_history_csv(csv, date = as.Date("2024-01-15"))
  expect_equal(nrow(result), 1L)
  expect_equal(result$station_id,      1L)
  expect_equal(result$vehicle_length_m, 5.2)
  expect_equal(result$speed_kmh,       97L)
  expect_equal(result$vehicle_class,   1L)
  expect_equal(result$quality_flag,    0L)
})

# dt_vehicle_classes() ----------------------------------------------------

test_that("dt_vehicle_classes() returns 9 rows", {
  result <- dt_vehicle_classes()
  expect_equal(nrow(result), 9L)
})

test_that("dt_vehicle_classes() has correct column names", {
  result <- dt_vehicle_classes()
  expect_named(result, c("vehicle_class", "label_en", "label_fi"))
})

test_that("dt_vehicle_classes() vehicle_class is 1:9", {
  result <- dt_vehicle_classes()
  expect_equal(result$vehicle_class, 1L:9L)
})

test_that("dt_vehicle_classes() has no NA labels", {
  result <- dt_vehicle_classes()
  expect_false(anyNA(result$label_en))
  expect_false(anyNA(result$label_fi))
})
