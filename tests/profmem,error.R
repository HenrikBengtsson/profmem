library("profmem")

if (capabilities("profmem")) {

p <- profmem({
  x <- raw(1000)
  stop("Woops!")
})
print(p)

} ## if (capabilities("profmem"))
