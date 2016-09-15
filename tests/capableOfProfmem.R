truth <- capabilities("profmem")
print(truth)

cache <- profmem:::capableOfProfmem()
print(cache)
stopifnot(identical(cache, truth))

cache <- profmem:::capableOfProfmem()
print(cache)
stopifnot(identical(cache, truth))

