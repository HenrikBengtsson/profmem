#' Memory profiles an R expression
#'
#' @param expr An R expression to be evaluated and profiled.
#' @param envir The environment in which the expression should be evaluated.
#' @param substitute Should \code{expr} be \code{substitute()}:d or not.
#' @param ... Not used.
#'
#' @return An object of class \code{Rprofmem}.
#'
#' @example incl/profmem.R
#'
#' @seealso
#' Internally \code{\link[utils]{Rprofmem}()} is used.
#'
#' @export
#' @importFrom utils Rprofmem
profmem <- function(expr, envir=parent.frame(), substitute=TRUE, ...) {
  if (substitute) expr <- substitute(expr)

  ## Is memory profiling supported?
  if (!capableOfProfmem()) {
    msg <- "Profiling of memory allocations is not supported on this R system (capabilities('profmem') reports FALSE). See help('tracemem')."
    if (.Platform$OS.type == "unix") {
      msg <- paste(msg, "To enable memory profiling for R on Linux, R needs to be configured and built using './configure --enable-memory-profiling'.")
    }
    stop(msg)
  }


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
