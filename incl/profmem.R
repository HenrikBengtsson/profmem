if (capabilities("profmem")) {

## Memory profile an R expression
p <- profmem({
  x <- raw(1000)
  A <- matrix(rnorm(100), ncol=10)
})

## Display the results
print(p)

## Total amount of memory allocation
total(p)

## The expression is evaluated in the calling environment
str(x)
str(A)

}
