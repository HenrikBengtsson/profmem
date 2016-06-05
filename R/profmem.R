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
  ndrop <- ncalls + 2L

  ## Memory profile
  Rprofmem(filename=pathname, append=FALSE, threshold=0)
  eval(expr, envir=envir)
  Rprofmem("")

  ## Load results
  bfr0 <- readLines(pathname, warn=FALSE)

  ## WORKAROUND: Add newlines for entries with empty call stacks
  ## https://github.com/HenrikBengtsson/Wishlist-for-R/issues/25
  bfr <- bfr0
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
    trace <- trace[seq_len(length(trace)-ndrop)]

    list(bytes=bytes, trace=trace)
  })

  attr(bfr, "expression") <- expr
  class(bfr) <- c("Rprofmem", class(bfr))

  bfr
} ## profmem()

#' @export
as.data.frame.Rprofmem <- function(x, ...) {
  bytes <- unlist(lapply(x, FUN=function(x) x$bytes))
  traces <- unlist(lapply(x, FUN=function(x) {
    trace <- rev(x$trace)
    trace <- sprintf("%s()", trace)
    paste(trace, collapse=" -> ")
  }))
  data.frame(bytes=bytes, calls=traces, stringsAsFactors=FALSE)
} ## as.data.frame()


#' @export
print.Rprofmem <- function(x, ...) {
  cat("Rprofmem memory profiling of:\n")
  print(attr(x, "expression"))

  cat("\nMemory allocations:\n")
  data <- as.data.frame(x)
  n <- nrow(data)
  total <- sum(data$bytes, na.rm=TRUE)

  ## Number of digits for indices
  widx <- floor(log10(n)+1)

  ## Number of digits for bytes
  wbytes <- floor(log10(total)+1)

  ## Report empty call stack as "internal"
  data$calls[!nzchar(data$calls)] <- "<internal>"

  data <- rbind(data, list(bytes=total, calls=""))
  rownames(data)[n+1] <- "total"

  print(data, ...)
} ## print()
