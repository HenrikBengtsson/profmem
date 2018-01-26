#' Total number of bytes allocated
#'
#' @param x An `Rprofmem` object.
#' @param ... Not used.
#'
#' @return A non-negative numeric.
#'
#' @aliases total.Rprofmem subset.Rprofmem
#' @export
#' @keywords internal
total <- function(x, ...) UseMethod("total")

#' @export
total.Rprofmem <- function(x, ...) {
  sum(x$bytes, na.rm=TRUE)
}

#' @export
subset.Rprofmem <- function(x, ...) {
  res <- NextMethod("subset")
  attr(res, "expression") <- attr(x, "expression")
  res
}

#' @export
as.data.frame.Rprofmem <- function(x, ...) {
  bytes <- x$bytes
  traces <- unlist(lapply(x$trace, FUN=function(x) {
    trace <- rev(x)
    hasName <- !grepl("^<[^>]*>$", trace)
    trace[hasName] <- sprintf("%s()", trace[hasName])
    paste(trace, collapse=" -> ")
  }))
  
  res <- data.frame(bytes=bytes, calls=traces, stringsAsFactors=FALSE)

  ## Preserve row names
  rownames(res) <- rownames(x)
  
  res
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
