#' Memory profiles an R expression
#'
#' @param expr An R expression to be evaluated and profiled.
#' @param envir The environment in which the expression should be evaluated.
#' @param substitute Should \code{expr} be \code{substitute()}:d or not.
#' @param stepwise Should each subsexpression of \code{expr} be profiled
#'        seperately or not.
#' @param threshold The smallest memory allocation (in bytes) to log.
#' @param ... Not used.
#'
#' @return An object of class \code{Rprofmem}.
#'
#' @example incl/profmem.R
#'
#' @seealso
#' Internally \code{\link[utils]{Rprofmem}()} is used.
#'
#' @aliases profmem_stepwise
#' @export
#' @importFrom utils Rprofmem
profmem <- function(expr, envir=parent.frame(), substitute=TRUE, stepwise=FALSE, threshold=0L, ...) {
  if (substitute) expr <- substitute(expr)

  ## Is memory profiling supported?
  if (!capableOfProfmem()) {
    msg <- "Profiling of memory allocations is not supported on this R system (capabilities('profmem') reports FALSE). See help('tracemem')."
    if (.Platform$OS.type == "unix") {
      msg <- paste(msg, "To enable memory profiling for R on Linux, R needs to be configured and built using './configure --enable-memory-profiling'.")
    }
    stop(msg)
  }

  if (stepwise) {
    expr2 <- inject_profmem_expression(expr, threshold = threshold)
    res <- eval(expr2, envir = envir)
    rm(list = ".profmem", envir = envir, inherits = FALSE)

    ## Annotate
    attr(res, "expression") <- expr
    attr(res, "value") <- attr(res[[length(res)]], "value")
    error <- NULL
    for (kk in seq_along(res)) {
      error_kk <- attr(res[[kk]], "error")
      if (!is.null(error_kk)) {
        error <- error_kk
	break
      }
    }
    attr(res, "error") <- error
  } else {
    res <- profmem_expression(expr, envir = envir, threshold = threshold)
  }

  res
} ## profmem()



profmem_expression <- function(expr, envir=parent.frame(), threshold=0L) {
  pathname <- tempfile(pattern="profmem", fileext="Rprofmem.out")
  on.exit(file.remove(pathname))

  ## Profile memory
  error <- NULL
  value <- tryCatch({
    Rprofmem(filename=pathname, append=FALSE, threshold=threshold)
    eval(expr, envir=envir)
  }, error = function(ex) {
    error <<- ex
    NULL
  }, finally = {
    Rprofmem("")
  })

  ## Import log
  drop <- length(sys.calls()) + 6L
  res <-  readRprofmem(pathname, as="Rprofmem", drop=drop)

  ## Annotate
  attr(res, "expression") <- expr
  attr(res, "value") <- value
  attr(res, "error") <- error

  res
} ## profmem_expression()
