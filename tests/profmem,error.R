library("profmem")

if (capabilities("profmem")) {

## Defaults to on_error = "ignore")
p <- profmem({
  x <- raw(1000)
  stop("Woops!")
})
print(p)


for (on_error in c("ignore", "warning", "error")) {
  message(sprintf("- profmem(..., on_error = \"%s\")", on_error))
  res <- tryCatch({
    profmem({
      x <- raw(1000)
      stop("Woops!")
    }, on_error = on_error)
  }, error = identity, warning = identity)
  if (on_error == "ignore") {
    stopifnot(inherits(res, "Rprofmem"))
  } else {
    stopifnot(inherits(res,  on_error))
  }
}

} ## if (capabilities("profmem"))
