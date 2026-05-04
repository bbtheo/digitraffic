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
  year_full  <- as.integer(format(date, "%Y"))
  year_short <- format(date, "%y")          # "24"
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
  if (date >= Sys.Date()) {
    cli::cli_abort(
      c(
        "Raw history data is published the following day between 08:00-09:00 EET.",
        "x" = "Requested date {.val {date}} is today or in the future."
      ),
      call = call
    )
  }
  invisible(date)
}

# String helpers ----------------------------------------------------------

# Convert camelCase or PascalCase strings to snake_case.
#
# Examples:
#   to_snake("collectionStatus") #> "collection_status"
#   to_snake("tmsNumber")        #> "tms_number"
#   to_snake("roadNumber")       #> "road_number"
to_snake <- function(x) {
  # Insert underscore before sequences of uppercase letters followed by lowercase
  x <- gsub("([A-Z]+)([A-Z][a-z])", "\\1_\\2", x)
  # Insert underscore between lowercase/digit and uppercase
  x <- gsub("([a-z0-9])([A-Z])", "\\1_\\2", x)
  tolower(x)
}
