## Internal utility functions

# Input validators --------------------------------------------------------

# Validate that `id` is a single non-NA positive integer-ish value.
check_id <- function(id, arg = rlang::caller_arg(id), call = rlang::caller_env()) {
  if (!rlang::is_scalar_integerish(id) || is.na(id) || id <= 0L) {
    cli::cli_abort(
      "{.arg {arg}} must be a single positive integer, not {.obj_type_friendly {id}}.",
      call = call
    )
  }
  invisible(as.integer(id))
}

# Validate that `date` is a single non-NA Date.
check_date <- function(date, arg = rlang::caller_arg(date), call = rlang::caller_env()) {
  if (!inherits(date, "Date") || length(date) != 1L || is.na(date)) {
    cli::cli_abort(
      "{.arg {arg}} must be a single {.cls Date} value (e.g. {.code as.Date('2024-01-15')}), not {.obj_type_friendly {date}}.",
      call = call
    )
  }
  invisible(date)
}

# Date helpers ------------------------------------------------------------

# Convert a Date into the two components used in the LAM history CSV URL:
#   year_short  — 2-digit year, e.g. "24" for 2024
#   day_number  — day of year, 1-366 (no leading zeros)
#
# Example:
#   date_to_lam_parts(as.Date("2024-01-15"))
#   #> list(year_short = "24", day_number = 15)
date_to_lam_parts <- function(date) {
  check_date(date)
  year_short <- format(date, "%y")              # "24"
  day_number <- as.integer(format(date, "%j"))  # 1–366
  list(year_short = year_short, day_number = day_number)
}

# Validate that a requested date has data available (raw data starts Dec 2021).
check_history_date <- function(date, call = rlang::caller_env()) {
  check_date(date, call = call)
  earliest <- as.Date("2021-12-01")
  if (date < earliest) {
    cli::cli_abort(
      c(
        "Raw history data is only available from {.val {earliest}} onwards.",
        "x" = "Requested date {.val {date}} is too early."
      ),
      call = call
    )
  }
  # Raw files are published the following day at 08:00-09:00 EET (Europe/Helsinki).
  # Compare against today in Finnish time so the check is correct regardless of
  # the user's system timezone.
  today_hki <- as.Date(Sys.time(), tz = "Europe/Helsinki")
  if (date >= today_hki) {
    cli::cli_abort(
      c(
        "Raw history data is published the following day between 08:00-09:00 EET.",
        "x" = "Requested date {.val {date}} is today or in the future (Finnish time)."
      ),
      call = call
    )
  }
  invisible(date)
}

# Spatial helpers ---------------------------------------------------------

# Validate a bbox argument: must be a length-4 numeric c(lon_min, lat_min, lon_max, lat_max).
check_bbox <- function(bbox, arg = rlang::caller_arg(bbox), call = rlang::caller_env()) {
  if (!is.numeric(bbox) || length(bbox) != 4L || anyNA(bbox)) {
    cli::cli_abort(
      "{.arg {arg}} must be a length-4 numeric vector {.code c(lon_min, lat_min, lon_max, lat_max)}.",
      call = call
    )
  }
  if (bbox[1] >= bbox[3] || bbox[2] >= bbox[4]) {
    cli::cli_abort(
      c(
        "{.arg {arg}} min values must be less than max values.",
        "i" = "Expected {.code c(lon_min, lat_min, lon_max, lat_max)}, got {.val {bbox}}."
      ),
      call = call
    )
  }
  # Sanity-check that values are plausible WGS-84 coordinates.
  if (bbox[1] < -180 || bbox[3] > 180 || bbox[2] < -90 || bbox[4] > 90) {
    cli::cli_abort(
      c(
        "{.arg {arg}} contains out-of-range WGS-84 coordinates.",
        "i" = "Longitude must be in [-180, 180] and latitude in [-90, 90].",
        "i" = "Got {.val {bbox}}."
      ),
      call = call
    )
  }
  invisible(bbox)
}

# Parse the road number from a station name string.
# Station names follow the convention "<type><number>_<location>", e.g.:
#   "vt7_Rita"          -> 7   (valtatie)
#   "kt51_Kehä"   -> 51  (kantatie)
#   "st140_Sipoo"       -> 140 (seututie)
#   "mt123_Muu"         -> 123 (maantie)
# Returns NA_integer_ for names that don't match the pattern.
parse_road_number_from_name <- function(name) {
  m <- regmatches(name, regexpr("^[a-z]+([0-9]+)_", name, perl = TRUE))
  if (length(m) == 0L || !nzchar(m)) return(NA_integer_)
  as.integer(sub("^[a-z]+([0-9]+)_.*", "\\1", m))
}
