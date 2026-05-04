## Tests for internal utility functions (R/utils.R)
## No HTTP calls needed — pure function tests.

# check_id() --------------------------------------------------------------

test_that("check_id() accepts valid positive integers", {
  expect_equal(check_id(1L),    1L)
  expect_equal(check_id(1),     1L)
  expect_equal(check_id(23001), 23001L)
})

test_that("check_id() rejects non-integer values", {
  expect_error(check_id(1.5),  class = "rlang_error")
  expect_error(check_id("1"),  class = "rlang_error")
  expect_error(check_id(NULL), class = "rlang_error")
  expect_error(check_id(NA),   class = "rlang_error")
})

test_that("check_id() rejects zero and negative values", {
  expect_error(check_id(0),  class = "rlang_error")
  expect_error(check_id(-1), class = "rlang_error")
})

test_that("check_id() rejects vectors with length > 1", {
  expect_error(check_id(c(1L, 2L)), class = "rlang_error")
})

# check_date() ------------------------------------------------------------

test_that("check_date() accepts a valid Date", {
  d <- as.Date("2024-03-15")
  expect_equal(check_date(d), d)
})

test_that("check_date() rejects non-Date inputs", {
  expect_error(check_date("2024-03-15"), class = "rlang_error")
  expect_error(check_date(20240315),     class = "rlang_error")
  expect_error(check_date(NULL),         class = "rlang_error")
  expect_error(check_date(NA),           class = "rlang_error")
})

test_that("check_date() rejects NA Date", {
  expect_error(check_date(as.Date(NA)), class = "rlang_error")
})

test_that("check_date() rejects Date vectors with length > 1", {
  expect_error(check_date(as.Date(c("2024-01-01", "2024-01-02"))), class = "rlang_error")
})

# date_to_lam_parts() -----------------------------------------------------

test_that("date_to_lam_parts() returns correct year_short and day_number", {
  parts <- date_to_lam_parts(as.Date("2024-01-01"))
  expect_equal(parts$year_short, "24")
  expect_equal(parts$day_number, 1L)
})

test_that("date_to_lam_parts() handles end of year correctly", {
  parts <- date_to_lam_parts(as.Date("2024-12-31"))
  expect_equal(parts$year_short, "24")
  expect_equal(parts$day_number, 366L)  # 2024 is a leap year
})

test_that("date_to_lam_parts() handles non-leap year Dec 31", {
  parts <- date_to_lam_parts(as.Date("2023-12-31"))
  expect_equal(parts$year_short, "23")
  expect_equal(parts$day_number, 365L)
})

test_that("date_to_lam_parts() rejects invalid input", {
  expect_error(date_to_lam_parts("2024-01-01"), class = "rlang_error")
})

# check_history_date() ----------------------------------------------------

test_that("check_history_date() accepts a valid historical date", {
  d <- as.Date("2023-06-15")
  expect_equal(check_history_date(d), d)
})

test_that("check_history_date() rejects dates before Dec 2021", {
  expect_error(
    check_history_date(as.Date("2021-11-30")),
    class = "rlang_error"
  )
})

test_that("check_history_date() rejects today's date", {
  expect_error(
    check_history_date(Sys.Date()),
    class = "rlang_error"
  )
})

test_that("check_history_date() rejects future dates", {
  expect_error(
    check_history_date(Sys.Date() + 1L),
    class = "rlang_error"
  )
})

# to_snake() --------------------------------------------------------------

test_that("to_snake() converts camelCase to snake_case", {
  expect_equal(to_snake("collectionStatus"), "collection_status")
  expect_equal(to_snake("tmsNumber"),        "tms_number")
  expect_equal(to_snake("roadNumber"),       "road_number")
  expect_equal(to_snake("dataUpdatedTime"),  "data_updated_time")
})

test_that("to_snake() handles already-lowercase strings", {
  expect_equal(to_snake("name"), "name")
  expect_equal(to_snake("id"),   "id")
})

test_that("to_snake() handles consecutive uppercase (acronyms)", {
  expect_equal(to_snake("tmsID"), "tms_id")
})
