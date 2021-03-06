#' Read an Rprofmem log file
#'
#' Reads and parses an Rprofmem log file that was created by
#' [utils::Rprofmem()].
#'
#' @param pathname The Rprofmem log file to be read.
#' 
#' @param as Specifies in what format data should be returned.
#' If `"raw"`, the line content of the file is returned as is
#' (as a character vector).
#' If `"fixed"`, as `"raw"` but with missing newlines added to lines with empty
#' stack calls that may be introduced in R (< 3.5.0) (see Ref. 1).
#' If `"Rprofmem"`, the collected Rprofmem data is fully
#' parsed into bytes and call stack information.
#' 
#' @param drop Number of levels to drop from the top of the call stack.
#' 
#' @param ... Not used
#'
#' @return An `Rprofmem` data.frame or a character vector (if `as` is `"raw"`
#' or `"fixed"`).
#' An `Rprofmem` data.frame has columns `what`, `bytes`, and `trace`, with:
#'
#'  * `what`:  (character) type of memory event;
#'             either `"alloc"` or `"new page"`
#'  * `bytes`: (numeric) number of bytes allocated or `NA_real_`
#'             (when `what` is `"new page"`)
#'  * `trace`: (list of character vectors) zero or more function names
#'
#' @example incl/readRprofmem.R
#'
#' @references
#' Ref. 1: \url{https://github.com/HenrikBengtsson/Wishlist-for-R/issues/25}
#'
#' @export
#' @importFrom utils file_test
readRprofmem <- function(pathname, as = c("Rprofmem", "fixed", "raw"), drop = 0L, ...) {
  stop_if_not(file_test("-f", pathname))
  as <- match.arg(as)
  drop <- as.integer(drop)
  stop_if_not(length(drop) == 1, drop >= 0)

  ## Read raw
  bfr <- readLines(pathname, warn=FALSE)
  if (as == "raw") return(bfr)


  ## WORKAROUND: Add newlines for entries with empty call stacks
  ## https://github.com/HenrikBengtsson/Wishlist-for-R/issues/25
  pattern <- "^(new page|[0-9]+)[ ]?:(new page|[0-9]+)[ ]?:"
  while(any(grepl(pattern, bfr))) {
    bfr <- gsub(pattern, "\\1 :\n\\2 :", bfr)
    bfr <- unlist(strsplit(bfr, split="\n", fixed=TRUE))
  }

  if (as == "fixed") return(bfr)

  if (getOption("profmem.debug", FALSE)) print(bfr)
  
  ## Parse Rprofmem results
  pattern <- "^([0-9]+|new page)[ ]?:(.*)"
  res <- lapply(bfr, FUN=function(x) {
    bytes <- gsub(pattern, "\\1", x)
    what <- rep("alloc", times = length(x))
    idxs <- which(bytes == "new page")
    if (length(idxs) > 0) {
      what[idxs] <- "new page"
      bytes[idxs] <- ""  # Will become NA below w/out warning
    }
    bytes <- as.numeric(bytes)

    trace <- gsub(pattern, "\\2", x)
    trace <- gsub('" "', '", "', trace, fixed=TRUE)
    trace <- sprintf("c(%s)", trace)
  
    trace <- eval(parse(text=trace), enclos = baseenv())
    trace <- trace[seq_len(max(0L, length(trace)-drop))]

    list(what = what, bytes = bytes, trace = trace)
  })

  if (length(res) == 0) {
    what <- character(0L)
    bytes <- numeric(0L)
    traces <- list()
  } else {
    what <- unlist(lapply(res, FUN=function(x) x$what), use.names=FALSE)
    bytes <- unlist(lapply(res, FUN=function(x) x$bytes), use.names=FALSE)
    traces <- lapply(res, FUN=function(x) x$trace)
  }
  res <- data.frame(what = what, bytes = bytes, stringsAsFactors = FALSE)
  res$trace <- traces
  bfr <- bytes <- traces <- NULL
  
  class(res) <- c("Rprofmem", class(res))

  ## Sanity check
  stop_if_not(all(c("what", "bytes", "trace") %in% names(res)))
  
  res
} ## readRprofmem()
