#' Memory profiles an R expression
#'
#' @param expr An R expression to be evaluated and profiled.
#' @param envir The environment in which the expression should be evaluated.
#' @param substitute Should `expr` be [base::substitute()]:d or not.
#' @param threshold The smallest memory allocation (in bytes) to log.
#' @param ... Not used.
#'
#' @return An object of class `Rprofmem`.
#'
#' @example incl/profmem.R
#'
#' @seealso
#' Internally [utils::Rprofmem()] is used.
#'
#' @export
#' @importFrom utils Rprofmem
profmem <- function(expr, envir = parent.frame(), substitute = TRUE, threshold = 0L, ...) {
  if (substitute) expr <- substitute(expr)

  profmem_begin(threshold = threshold)
  
  ## Profile memory
  error <- NULL
  value <- tryCatch({
    eval(expr, envir=envir)
  }, error = function(ex) {
    error <<- ex
    NULL
  })

  pm <-  profmem_end()

  ## Annotate
  attr(pm, "expression") <- expr
  attr(pm, "value") <- value
  attr(pm, "error") <- error

  pm
} ## profmem()



profmem_env <- new.env()

#' @rdname profmem
#' @importFrom utils Rprofmem
#' @export
profmem_begin <- function(threshold = 0L, ...) {
  ## Is memory profiling supported?
  if (!capableOfProfmem()) {
    msg <- "Profiling of memory allocations is not supported on this R system (capabilities('profmem') reports FALSE). See help('tracemem')."
    if (.Platform$OS.type == "unix") {
      msg <- paste(msg, "To enable memory profiling for R on Linux, R needs to be configured and built using './configure --enable-memory-profiling'.")
    }
    stop(msg)
  }

  pathname <- profmem_env$pathname
  if (!is.null(pathname)) {
    stop("An active profmem_begin() already exists, which can be terminated by profmem_end().")
  }
  
  pathname <- tempfile(pattern = "profmem", fileext = "Rprofmem.out")
  Rprofmem(filename = pathname, append = FALSE, threshold = threshold)
  profmem_env$pathname <- pathname
  invisible(pathname)
}

#' @rdname profmem
#' @importFrom utils Rprofmem
#' @export
profmem_end <- function() {
  pathname <- profmem_env$pathname
  if (is.null(pathname)) {
    stop("Did you forget to call profmem_begin()?")
  }

  Rprofmem("")
  
  on.exit({
    profmem_env$pathname <- NULL
    file.remove(pathname)
  })

  ## Import log
  drop <- length(sys.calls()) + 6L
  readRprofmem(pathname, as = "Rprofmem", drop = drop)
}
