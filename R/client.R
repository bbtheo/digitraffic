## Internal HTTP client helpers for the Digitraffic API
##
## These are not exported — all user-facing functions are in their own files.

.dt_base_url <- "https://tie.digitraffic.fi"

# Build the base httr2 request with shared settings:
#   - User-Agent identifying the package + version
#   - 30-second timeout so hung connections don't block the session forever
#   - Retry up to 5 times on transient failures (429, 500, 503, network errors)
#     with Retry-After header support for 429 and exponential back-off otherwise
#   - Throttle to 10 requests per minute to be a polite API client
dt_base_request <- function() {
  ua <- paste0(
    "digitraffic-r/", utils::packageVersion("digitraffic"),
    " (https://github.com/bbtheo/digitraffic)"
  )
  httr2::request(.dt_base_url) |>
    httr2::req_user_agent(ua) |>
    httr2::req_timeout(30) |>
    httr2::req_retry(
      max_tries    = 5,
      is_transient = \(resp) httr2::resp_status(resp) %in% c(429L, 500L, 503L),
      # For 429 respect the Retry-After header; fall back to 60 s.
      # Returning NULL for other transient errors lets httr2 use its default
      # exponential back-off.
      after = function(resp) {
        if (httr2::resp_status(resp) != 429L) return(NULL)
        ra <- suppressWarnings(
          as.numeric(httr2::resp_header(resp, "retry-after"))
        )
        if (!is.na(ra) && ra > 0) ra else 60
      }
    ) |>
    httr2::req_throttle(rate =  1/60)
}

# Perform a request and translate HTTP errors into informative cli messages.
# Returns the response on success; aborts with a classed condition on failure.
dt_perform <- function(req) {
  resp <- tryCatch(
    httr2::req_perform(req),
    httr2_http_404 = function(e) {
      cli::cli_abort(
        c(
          "Resource not found (HTTP 404).",
          "i" = "Check that the station {.code id} or date is valid.",
          "i" = "URL: {.url {req$url}}"
        ),
        class = "digitraffic_error_not_found",
        call = NULL
      )
    },
    httr2_http_429 = function(e) {
      cli::cli_abort(
        c(
          "Rate limit exceeded (HTTP 429).",
          "i" = "Please wait before retrying."
        ),
        class = "digitraffic_error_rate_limit",
        call = NULL
      )
    },
    httr2_failure = function(e) {
      cli::cli_abort(
        c(
          "Could not reach the Digitraffic API.",
          "i" = "Check your internet connection.",
          "x" = conditionMessage(e)
        ),
        class = "digitraffic_error_network",
        call = NULL
      )
    },
    httr2_http = function(e) {
      status <- tryCatch(
        httr2::resp_status(e$response),
        error = function(e2) "unknown"
      )
      cli::cli_abort(
        c(
          "Digitraffic API returned an error (HTTP {status}).",
          "i" = "Try again later or check {.url https://www.digitraffic.fi}."
        ),
        class = "digitraffic_error_http",
        call = NULL
      )
    }
  )
  resp
}

# GET a JSON endpoint, returning the parsed list.
dt_get_json <- function(path, query = list()) {
  req <- dt_base_request() |>
    httr2::req_url_path(path) |>
    httr2::req_url_query(!!!query) |>
    httr2::req_headers(Accept = "application/json")

  resp <- dt_perform(req)
  httr2::resp_body_json(resp, simplifyVector = FALSE)
}

# GET a CSV endpoint, returning the raw response body as a character string.
dt_get_csv <- function(path) {
  req <- dt_base_request() |>
    httr2::req_url_path(path) |>
    httr2::req_headers(Accept = "text/csv, text/plain, */*")

  resp <- dt_perform(req)
  httr2::resp_body_string(resp)
}
