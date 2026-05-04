## Session-level TTL cache for station metadata.
##
## Station data changes rarely (a few additions per year), so caching the
## list within an R session avoids redundant API calls.  Users can call
## dt_cache_clear() to force a fresh fetch.

.dt_cache <- new.env(parent = emptyenv())

# Store a value with an expiry timestamp.
dt_cache_set <- function(key, value, ttl = 300) {
  .dt_cache[[key]] <- list(
    value   = value,
    expires = Sys.time() + ttl
  )
  invisible(value)
}

# Retrieve a cached value, or NULL if missing / expired.
dt_cache_get <- function(key) {
  entry <- .dt_cache[[key]]
  if (is.null(entry)) return(NULL)
  if (Sys.time() > entry$expires) {
    rm(list = key, envir = .dt_cache)
    return(NULL)
  }
  entry$value
}

#' Clear the in-session digitraffic cache
#'
#' Station metadata is cached for 5 minutes within an R session to avoid
#' redundant API calls.  Call this function to force the next
#' [dt_stations()] or [dt_station()] call to fetch fresh data.
#'
#' @return Invisibly returns `NULL`.
#' @export
#' @examples
#' dt_cache_clear()
dt_cache_clear <- function() {
  rm(list = ls(.dt_cache), envir = .dt_cache)
  cli::cli_inform("digitraffic cache cleared.")
  invisible(NULL)
}
