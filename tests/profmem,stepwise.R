library("profmem")

if (capabilities("profmem")) {

  expr <- list(
    a = quote(a <- 1:3),
    b = quote({
      a <- integer(1000) + 1
      b <- integer(1000) + c(1,2)
      c <- c(1,2,3,4) + integer(1000)
    })
  )

  p <- lapply(expr, FUN = profmem, substitute = FALSE, stepwise = TRUE)
  print(p)

} ## if (capabilities("profmem"))
