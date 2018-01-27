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
#' If `"fixed"`, as `"raw"` but with missing newlines
#' added to lines with empty stack calls (see Ref. 1).
#' If `"Rprofmem"`, the collected Rprofmem data is fully
#' parsed into bytes and call stack information.
#' If `"profmem"`, then also \pkg{profmem}-specific entries injected into
#' the Rprofmem log file by \pkg{profmem} are also parsed.
#' 
#' @param drop Number of levels to drop from the top of the call stack.
#' 
#' @param ... Not used
#'
#' @return An `Rprofmem` data.frame (or a character vector)
#'
#' @references
#' Ref. 1: \url{https://github.com/HenrikBengtsson/Wishlist-for-R/issues/25}
#'
#' @export
#' @importFrom utils file_test
readRprofmem <- function(pathname, as = c("profmem", "Rprofmem", "fixed", "raw"), drop = 0L, ...) {
  stopifnot(file_test("-f", pathname))
  as <- match.arg(as)
  drop <- as.integer(drop)
  stopifnot(length(drop) == 1, drop >= 0)

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

  if (getOption("profmem.debug", FALSE)) writeLines(bfr)
  
  ## Drop comments
  if (as == "profmem") {
    bfr <- grep("^#", bfr, value = TRUE, invert = TRUE)
  }

  ## Parse Rprofmem results
  pattern <- "^([0-9]+|new page)[ ]?:(.*)"
  bfr <- lapply(bfr, FUN=function(x) {
    bytes <- gsub(pattern, "\\1", x)
    bytes[bytes == "new page"] <- ""  # Will become NA below w/out warning
    bytes <- as.numeric(bytes)

    trace <- gsub(pattern, "\\2", x)
    trace <- gsub('" "', '", "', trace, fixed=TRUE)
    trace <- sprintf("c(%s)", trace)
  
    if (getOption("profmem.debug", FALSE)) {
      message(bytes, ": ", trace)
      message("drop: ", drop)
    }
    
    trace <- eval(parse(text=trace))
    trace <- trace[seq_len(max(0L, length(trace)-drop))]

    list(bytes=bytes, trace=trace)
  })

  bytes <- unlist(lapply(bfr, FUN=function(x) x$bytes), use.names=FALSE)
  traces <- lapply(bfr, FUN=function(x) x$trace)
  res <- data.frame(bytes=bytes, stringsAsFactors=FALSE)
  res$trace <- traces
  bfr <- bytes <- traces <- NULL
  
  class(res) <- c("Rprofmem", class(res))

  res
} ## readRprofmem()
