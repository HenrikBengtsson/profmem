library("profmem")

if (capabilities("profmem")) {

  pathname <- tempfile()
  Rprofmem(pathname)
  x <- raw(1000)
  A <- matrix(rnorm(100), ncol=10)
  Rprofmem()

  bfr <- readLines(pathname)
  cat("readLines(...):\n")
  print(bfr)
  
  raw <- readRprofmem(pathname, as="raw")
  cat("readRprofmem(..., as='raw'):\n")
  print(raw)
  stopifnot(
    length(raw) == length(bfr),
    all(raw == bfr)
  )

  fixed <- readRprofmem(pathname, as="fixed")
  cat("readRprofmem(..., as='fixed'):\n")
  print(fixed)
  stopifnot(length(fixed) >= length(bfr))

  p <- readRprofmem(pathname, as="Rprofmem")
  cat("readRprofmem(..., as='Rprofmem'):\n")
  print(p)
  str(p)
  stopifnot(length(p) == length(fixed))

} ## if (capabilities("profmem"))
