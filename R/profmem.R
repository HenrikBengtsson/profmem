#' Memory profiles an R expression
#'
#' @param expr An R expression to be evaluated.
#' @param envir The environment in which the expression should be evaluated.
#' @param substitute Should \code{expr} be \code{substitute()}:d or not.
#' @param ... Not used.
#'
#' @return An object of class \code{Rprofmem}.
#'
#' @example incl/profmem.R
#'
#' @export
#' @importFrom utils Rprofmem
profmem <- function(expr, envir=parent.frame(), substitute=TRUE, ...) {
  if (substitute) expr <- substitute(expr)

  pathname <- tempfile(pattern="profmem", fileext="Rprofmem.out")
  on.exit(file.remove(pathname))

  ## Profile memory
  error <- NULL
  value <- tryCatch({
    Rprofmem(filename=pathname, append=FALSE, threshold=0)
    eval(expr, envir=envir)
  }, error = function(ex) {
    error <<- ex
    NULL
  }, finally = {
    Rprofmem("")
  })

  ## Import log
  drop <- length(sys.calls()) + 6L
  bfr <-  readRprofmem(pathname, as="Rprofmem", drop=drop)

  ## Annotate
  attr(bfr, "expression") <- expr
  attr(bfr, "value") <- value
  attr(bfr, "error") <- error

  bfr
} ## profmem()
