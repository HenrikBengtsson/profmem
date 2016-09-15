# A lookup-only-once version of capabilities("profmem")
# Benchmarking shows it's 8-10 times faster this way.
capableOfProfmem <- local({
  res <- NA
  function() {
    if (is.na(res)) {
      res <<- capabilities("profmem")
    }
    res
  }
})
