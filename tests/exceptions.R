library("profmem")

profmem_stack <- profmem:::profmem_stack

## In case there are active profmem session in the current R session
## (shouldn't happen during 'R CMD check' though)
while (profmem_stack("depth") > 0) profmem_stack("pop")

## Trying to pop from empty stack
res <- tryCatch({
  p <- profmem_stack("pop")
}, error = identity)
print(res)
stopifnot(inherits(res, "error"))

## Trying non-existing stack action
res <- tryCatch({
  p <- profmem_stack("non-existing")
}, error = identity)
print(res)
stopifnot(inherits(res, "error"))


if (capabilities("profmem")) {

## Trying to end existing profmem session
res <- tryCatch({
  p <- profmem_end()
}, error = identity)
print(res)
stopifnot(inherits(res, "error"))

} ## if (capabilities("profmem"))
