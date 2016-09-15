truth <- capabilities("profmem")
print(truth)

cache <- profmem:::capableOfProfmem()
print(cache)
stopifnot(identical(cache, truth))

cache <- profmem:::capableOfProfmem()
print(cache)
stopifnot(identical(cache, truth))

## Fake calling profmem() when memory profiling is disabled
## and assert that profmem() throws an error
f <- profmem:::capableOfProfmem
environment(f)$res <- FALSE
t <- profmem:::capableOfProfmem()
print(t)
stopifnot(identical(t, FALSE))
res <- tryCatch({
  p <- profmem::profmem(x <- 1:1000)
}, error = identity)
stopifnot(inherits(res, "simpleError"))
environment(f)$res <- cache  ## Undo



