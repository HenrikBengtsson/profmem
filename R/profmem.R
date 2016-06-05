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

  ## Record size of call stack this far
  ncalls <- length(sys.calls())
  ndrop <- ncalls + 6L

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

  ## Load results
  bfr <- readLines(pathname, warn=FALSE)

  ## WORKAROUND: Add newlines for entries with empty call stacks
  ## https://github.com/HenrikBengtsson/Wishlist-for-R/issues/25
  pattern <- "^([0-9]+) :([0-9]+) :"
  while(any(grepl(pattern, bfr))) {
    bfr <- gsub(pattern, "\\1 :\n\\2 :", bfr)
    bfr <- unlist(strsplit(bfr, split="\n", fixed=TRUE))
  }

  ## Parse Rprofmem results
  pattern <- "^([0-9]+ |new page):(.*)"
  bfr <- lapply(bfr, FUN=function(x) {
    bytes <- gsub(pattern, "\\1", x)
    bytes[bytes == "new page"] <- ""  # Will become NA below w/out warning
    bytes <- as.numeric(bytes)

    trace <- gsub(pattern, "\\2", x)
    trace <- gsub('" "', '", "', trace, fixed=TRUE)
    trace <- sprintf("c(%s)", trace)
    trace <- eval(parse(text=trace))
    trace <- trace[seq_len(max(0L, length(trace)-ndrop))]

    list(bytes=bytes, trace=trace)
  })

  attr(bfr, "expression") <- expr
  attr(bfr, "value") <- value
  attr(bfr, "error") <- error
  class(bfr) <- c("Rprofmem", class(bfr))

  bfr
} ## profmem()
