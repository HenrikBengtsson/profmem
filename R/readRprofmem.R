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
