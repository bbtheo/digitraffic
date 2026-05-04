## Tests for the new dt_stations() filters and dt_stations_load_details()

# parse_road_number_from_name() -------------------------------------------

test_that("parse_road_number_from_name() extracts valtatie numbers", {
  expect_equal(parse_road_number_from_name("vt7_Rita"),         7L)
  expect_equal(parse_road_number_from_name("vt1_Espoo_Test"),   1L)
  expect_equal(parse_road_number_from_name("vt18_Jyvaskyla"),  18L)
})

test_that("parse_road_number_from_name() extracts kantatie numbers", {
  expect_equal(parse_road_number_from_name("kt51_Keha"),  51L)
  expect_equal(parse_road_number_from_name("kt45_Test"),  45L)
})

test_that("parse_road_number_from_name() returns NA for non-standard names", {
  expect_true(is.na(parse_road_number_from_name("DSL6L")))
  expect_true(is.na(parse_road_number_from_name("unknown")))
  expect_true(is.na(parse_road_number_from_name("")))
})

# check_bbox() ------------------------------------------------------------

test_that("check_bbox() accepts a valid bounding box", {
  expect_silent(check_bbox(c(24.5, 60.1, 25.2, 60.4)))
})

test_that("check_bbox() rejects wrong length", {
  expect_error(check_bbox(c(24.5, 60.1, 25.2)),         class = "rlang_error")
  expect_error(check_bbox(c(24.5, 60.1, 25.2, 60.4, 0)), class = "rlang_error")
})

test_that("check_bbox() rejects inverted min/max", {
  expect_error(check_bbox(c(25.2, 60.1, 24.5, 60.4)), class = "rlang_error")
  expect_error(check_bbox(c(24.5, 60.4, 25.2, 60.1)), class = "rlang_error")
})

test_that("check_bbox() rejects NAs", {
  expect_error(check_bbox(c(NA, 60.1, 25.2, 60.4)), class = "rlang_error")
})

# dt_stations() — road_number filter --------------------------------------

test_that("dt_stations(road_number) returns only matching stations", {
  httptest2::with_mock_dir("fixtures", {
    result <- dt_stations(road_number = 7)
    expect_s3_class(result, "tbl_df")
    # fixture has vt7_Rita -> road 7
    expect_equal(nrow(result), 1L)
    expect_equal(result$name, "vt7_Rita")
  })
})

test_that("dt_stations(road_number) returns zero rows for no match", {
  httptest2::with_mock_dir("fixtures", {
    result <- dt_stations(road_number = 999)
    expect_equal(nrow(result), 0L)
  })
})

test_that("dt_stations(road_number) rejects invalid input", {
  expect_error(dt_stations(road_number = -1),    class = "rlang_error")
  expect_error(dt_stations(road_number = "vt7"), class = "rlang_error")
})

# dt_stations() — bbox filter ---------------------------------------------

test_that("dt_stations(bbox) filters by bounding box", {
  httptest2::with_mock_dir("fixtures", {
    # tight box around vt7_Rita [25.689529, 60.417002]
    result <- dt_stations(bbox = c(25.5, 60.3, 25.9, 60.6))
    expect_equal(nrow(result), 1L)
    expect_equal(result$name, "vt7_Rita")
  })
})

test_that("dt_stations(bbox) returns all stations inside box", {
  httptest2::with_mock_dir("fixtures", {
    # wide box covering all fixtures
    result <- dt_stations(bbox = c(23.0, 59.0, 27.0, 62.0))
    expect_equal(nrow(result), 3L)
  })
})

test_that("dt_stations(bbox) rejects invalid bbox", {
  expect_error(
    dt_stations(bbox = c(25.9, 60.3, 25.5, 60.6)),
    class = "rlang_error"
  )
})

# dt_stations() — municipality / province filter --------------------------

test_that("dt_stations(municipality) returns matching stations using bundled cache", {
  httptest2::with_mock_dir("fixtures", {
    result <- suppressWarnings(dt_stations(municipality = "Porvoo"))
    expect_s3_class(result, "tbl_df")
    expect_equal(result$name, "vt7_Rita")
  })
})

test_that("dt_stations(province) returns matching stations using bundled cache", {
  httptest2::with_mock_dir("fixtures", {
    result <- suppressWarnings(dt_stations(province = "Uusimaa"))
    expect_s3_class(result, "tbl_df")
    expect_gte(nrow(result), 1L)
  })
})

test_that("dt_stations(municipality) is case-insensitive", {
  httptest2::with_mock_dir("fixtures", {
    r1 <- suppressWarnings(dt_stations(municipality = "porvoo"))
    r2 <- suppressWarnings(dt_stations(municipality = "PORVOO"))
    expect_equal(nrow(r1), nrow(r2))
  })
})

test_that("dt_stations(municipality) rejects non-string input", {
  expect_error(dt_stations(municipality = 123), class = "rlang_error")
})

# dt_stations() — combined filters ----------------------------------------

test_that("dt_stations() combines road_number and bbox correctly", {
  httptest2::with_mock_dir("fixtures", {
    # road 1 within loose bbox -> only vt1_Espoo_Hirvisuo
    result <- dt_stations(
      road_number = 1,
      bbox        = c(23.0, 59.0, 27.0, 62.0)
    )
    expect_equal(nrow(result), 1L)
    expect_equal(result$name, "vt1_Espoo_Hirvisuo")
  })
})

# dt_stations_load_details() — input validation ---------------------------

test_that("dt_stations_load_details() rejects non-integer max_active", {
  expect_error(
    dt_stations_load_details(max_active = "fast"),
    class = "rlang_error"
  )
})
