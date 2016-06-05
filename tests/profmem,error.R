library("profmem")

p <- profmem({
  x <- raw(1000)
  stop("Woops!")
})
print(p)
