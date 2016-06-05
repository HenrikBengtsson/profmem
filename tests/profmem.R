library("profmem")

p <- profmem({
  x <- raw(1000)
  A <- matrix(rnorm(100), ncol=10)
})
print(p)

data <- as.data.frame(p)
print(data)

t <- total(p)
print(t)
stopifnot(t == sum(data$bytes, na.rm=TRUE))
