test_that("package loads successfully", {
  expect_true("digitraffic" %in% loadedNamespaces())
})

# dt_cache_clear() --------------------------------------------------------

test_that("dt_cache_clear() removes all entries from the cache", {
  # Seed the cache with a known value.
  dt_cache_set("test_key", list(a = 1), ttl = 300)
  expect_false(is.null(dt_cache_get("test_key")))

  dt_cache_clear()

  expect_null(dt_cache_get("test_key"))
})

test_that("dt_cache_clear() returns NULL invisibly", {
  result <- dt_cache_clear()
  expect_null(result)
})

test_that("dt_cache_clear() is idempotent on an already-empty cache", {
  dt_cache_clear()
  expect_silent(dt_cache_clear())
})
