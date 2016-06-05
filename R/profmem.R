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


#' Reads and parses an Rprofmem log file
#'
#' @param pathname The Rprofmem log file to be read.
#' @param as Specifies in what format data should be returned.
#' @param drop Number of levels to drop from the top of the call stack.
#' @param ... Not used
#'
#' @return An object of class \code{Rprofmem} (or a character vector)
#'
#' @export
#' @importFrom utils file_test
readRprofmem <- function(pathname, as=c("Rprofmem", "fixed", "raw"), drop=0L, ...) {
  stopifnot(file_test("-f", pathname))
  as <- match.arg(as)
  drop <- as.integer(drop)
  stopifnot(length(drop) == 1, drop >= 0)

  ## Read raw
  bfr <- readLines(pathname, warn=FALSE)
  if (as == "raw") return(bfr)


  ## WORKAROUND: Add newlines for entries with empty call stacks
  ## https://github.com/HenrikBengtsson/Wishlist-for-R/issues/25
  pattern <- "^([0-9]+) :([0-9]+) :"
  while(any(grepl(pattern, bfr))) {
    bfr <- gsub(pattern, "\\1 :\n\\2 :", bfr)
    bfr <- unlist(strsplit(bfr, split="\n", fixed=TRUE))
  }
  if (as == "fixed") return(bfr)


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
    trace <- trace[seq_len(max(0L, length(trace)-drop))]

    list(bytes=bytes, trace=trace)
  })

  class(bfr) <- c("Rprofmem", class(bfr))

  bfr
} ## readRprofmem()

