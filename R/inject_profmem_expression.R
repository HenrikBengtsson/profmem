inject_profmem_expression <- function(e, threshold = 0L) {
  atomic <- (e[[1]] != as.symbol("{"))
  if (atomic) {
    e2 <- e[c(1,1)]
    e2[[1]] <- as.symbol("{")
    e2[[2]] <- e
    e <- e2
  }

  n <- length(e)
  e <- e[c(1:2, 2:n, 1)]
  n <- length(e)
  e[[2]] <- quote({
    .profmem <- list()
    .profmem_expression <- get("profmem_expression", envir = getNamespace("profmem"), mode = "function")
  })
  e[[n]] <- quote({
    rm(list = ".profmem_expression", inherits = FALSE)
    .profmem
  })
  for (kk in 3:(n-1)) {
    e[[kk]] <- substitute(.profmem[[ii]] <- .profmem_expression(quote(e), threshold = t), list(ii = kk - 2, e = e[[kk]], t = threshold))
  }
  
  e
} ## inject_profmem_expression()
