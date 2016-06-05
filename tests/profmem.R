library("profmem")

p <- profmem({
  x <- raw(1000)
  A <- matrix(rnorm(100), ncol=10)
})
print(p)
