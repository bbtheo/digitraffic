## Tests for internal HTTP client helpers (R/client.R)
## Uses httr2::with_mocked_responses() to avoid hitting the live API.

# dt_base_request() -------------------------------------------------------

test_that("dt_base_request() returns an httr2 request object", {
  req <- dt_base_request()
  expect_s3_class(req, "httr2_request")
})

test_that("dt_base_request() targets the correct base URL", {
  req <- dt_base_request()
  expect_equal(req$url, "https://tie.digitraffic.fi")
})

test_that("dt_base_request() sets a digitraffic User-Agent", {
  req <- dt_base_request()
  # httr2 stores req_user_agent() in req$options$useragent
  expect_match(req$options$useragent, "^digitraffic-r/")
})

test_that("dt_base_request() defaults to a 120-second timeout", {
  withr::with_options(list(digitraffic.timeout = NULL), {
    req <- dt_base_request()
    # httr2 stores req_timeout() in req$options$timeout_ms (milliseconds)
    expect_equal(req$options$timeout_ms, 120 * 1000)
  })
})

test_that("dt_base_request() respects the digitraffic.timeout option", {
  withr::with_options(list(digitraffic.timeout = 60), {
    req <- dt_base_request()
    expect_equal(req$options$timeout_ms, 60 * 1000)
  })
})

# dt_perform() — success --------------------------------------------------

test_that("dt_perform() returns the response on 200 OK", {
  mock_resp <- httr2::response(
    status_code = 200L,
    headers = list(`Content-Type` = "application/json"),
    body = charToRaw('{"type":"FeatureCollection","features":[]}')
  )
  httr2::with_mocked_responses(list(mock_resp), {
    req <- dt_base_request() |>
      httr2::req_url_path("/api/tms/v1/stations")
    resp <- dt_perform(req)
    expect_equal(httr2::resp_status(resp), 200L)
  })
})

# dt_perform() — error handling -------------------------------------------

test_that("dt_perform() raises digitraffic_error_not_found on 404", {
  mock_resp <- httr2::response(
    status_code = 404L,
    headers = list(`Content-Type` = "application/json"),
    body = charToRaw('{"message":"Not found"}')
  )
  httr2::with_mocked_responses(list(mock_resp), {
    req <- dt_base_request() |>
      httr2::req_url_path("/api/tms/v1/stations/999999999")
    expect_error(dt_perform(req), class = "digitraffic_error_not_found")
  })
})

test_that("dt_perform() raises digitraffic_error_http on 500", {
  # 500 is transient, so it is retried.  max_tries = 5 means 5 total attempts
  # (1 initial + 4 retries), so we need exactly 5 mock responses to exhaust
  # all tries and trigger the error.
  # req_retry() replaces the full policy, so pass every argument explicitly to
  # keep max_tries = 5 and zero out inter-retry sleep for test speed.
  mock_500 <- httr2::response(
    status_code = 500L,
    headers = list(`Content-Type` = "application/json"),
    body = charToRaw('{"message":"Internal server error"}')
  )
  httr2::with_mocked_responses(
    list(mock_500, mock_500, mock_500, mock_500, mock_500),
    {
      req <- dt_base_request() |>
        httr2::req_url_path("/api/tms/v1/stations") |>
        httr2::req_retry(
          max_tries        = 5,
          retry_on_failure = TRUE,
          is_transient     = \(resp) httr2::resp_status(resp) %in% c(429L, 500L, 503L),
          backoff          = \(n) 0
        )
      expect_error(dt_perform(req), class = "digitraffic_error_http")
    }
  )
})

test_that("dt_base_request() enables retry_on_failure for network errors", {
  # with_mocked_responses bypasses httr2's retry layer, so we can't drive
  # actual retry behaviour in unit tests.  Verify that the policy flag is set;
  # the real curl path will honour it at runtime.
  req <- dt_base_request()
  expect_true(req$policies$retry_on_failure)
})

test_that("dt_perform() raises digitraffic_error_network on httr2_failure", {
  # A network error (httr2_failure) must surface as digitraffic_error_network
  # regardless of whether retries are exhausted or disabled in mock context.
  mock_fn <- function(req) {
    rlang::abort("timed out", class = c("httr2_failure", "error"))
  }
  httr2::with_mocked_responses(mock_fn, {
    req <- dt_base_request() |>
      httr2::req_url_path("/api/tms/v1/stations")
    expect_error(dt_perform(req), class = "digitraffic_error_network")
  })
})

# dt_get_json() -----------------------------------------------------------

test_that("dt_get_json() returns a list from a JSON response", {
  body <- '{"type":"FeatureCollection","features":[]}'
  mock_resp <- httr2::response(
    status_code = 200L,
    headers = list(`Content-Type` = "application/json"),
    body = charToRaw(body)
  )
  httr2::with_mocked_responses(list(mock_resp), {
    result <- dt_get_json("/api/tms/v1/stations")
    expect_type(result, "list")
    expect_equal(result$type, "FeatureCollection")
  })
})

# dt_get_csv() ------------------------------------------------------------

test_that("dt_get_csv() returns a character string from a CSV response", {
  csv_body <- "1;24;15;8;30;45;12;5.2;1;1;1;97;0;1234;5678\n"
  mock_resp <- httr2::response(
    status_code = 200L,
    headers = list(`Content-Type` = "text/csv"),
    body = charToRaw(csv_body)
  )
  httr2::with_mocked_responses(list(mock_resp), {
    result <- dt_get_csv("/api/tms/v1/history/raw/lamraw_1_24_15.csv")
    expect_type(result, "character")
    expect_length(result, 1L)
    expect_match(result, "^1;24;15")
  })
})
