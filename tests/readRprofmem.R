library("profmem")

message("readRprofmem() ...")

message(" - corrupt file")

broken <- system.file("extdata", "broken.Rprofile.out", package = "profmem")

bfr <- readLines(broken)
cat("readLines(broken):\n")
print(bfr)

raw <- readRprofmem(broken, as = "raw")
cat("readRprofmem(broken, as = 'raw'):\n")
print(raw)
stopifnot(
  length(raw) == length(bfr),
  all(raw == bfr)
)

message("readRprofmem(broken, as = 'fixed'):\n")
fixed <- readRprofmem(broken, as = "fixed")
print(fixed)
stopifnot(length(fixed) >= length(bfr))

p <- readRprofmem(broken, as = "Rprofmem")
cat("readRprofmem(broken, as = 'Rprofmem'):\n")
print(p)
str(p)
stopifnot(nrow(p) == length(fixed))


message(" - empty file")

options(profmem.debug = TRUE)

empty <- tempfile()
writeLines(character(0L), con = empty)

bfr <- readLines(empty)
stopifnot(length(bfr) == 0)

raw <- readRprofmem(empty, as = "raw")
stopifnot(is.character(raw), length(raw) == 0)

fixed <- readRprofmem(empty, as = "fixed")
stopifnot(is.character(raw), length(raw) == 0)

p <- readRprofmem(empty, as = "Rprofmem")
stopifnot(nrow(p) == 0L)

options(profmem.debug = FALSE)


if (capabilities("profmem")) {
  
  live <- tempfile()
  Rprofmem(live)
  x <- raw(1000)
  A <- matrix(rnorm(100), ncol=10)
  Rprofmem()

  bfr <- readLines(live)
  cat("readLines(live):\n")
  print(bfr)
  
  raw <- readRprofmem(live, as = "raw")
  cat("readRprofmem(live, as = 'raw'):\n")
  print(raw)
  stopifnot(
    length(raw) == length(bfr),
    all(raw == bfr)
  )

  fixed <- readRprofmem(live, as = "fixed")
  cat("readRprofmem(live, as = 'fixed'):\n")
  print(fixed)
  stopifnot(length(fixed) >= length(bfr))

  p <- readRprofmem(live, as = "Rprofmem")
  cat("readRprofmem(live, as = 'Rprofmem'):\n")
  print(p)
  str(p)
  stopifnot(nrow(p) == length(fixed))
  
} ## if (capabilities("profmem"))

message("readRprofmem() ... DONE")

