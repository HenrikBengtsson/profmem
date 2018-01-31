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
c.Rprofmem <- function(...) {
  args <- list(...)
  
  what <- NULL
  bytes <- NULL
  trace <- NULL
  threshold <- NULL
  
  for (arg in args) {
    stopifnot(inherits(arg, "Rprofmem"))
    what <- c(what, arg$what)
    bytes <- c(bytes, arg$bytes)
    trace <- c(trace, arg$trace)
    threshold <- c(threshold, attr(arg, "threshold"))
  }
  threshold <- max(threshold)
  stopifnot(length(threshold) == 1, is.finite(threshold),
            is.integer(threshold), threshold >= 0L)
  
  res <- data.frame(what = what, bytes = bytes, stringsAsFactors = FALSE)
  res$trace <- trace
  if (threshold > 0L) {
    keep <- is.na(bytes) | (bytes >= threshold)
    stopifnot(all(is.finite(keep)))
    res <- res[keep, ]
  }
  attr(res, "threshold") <- threshold
  class(res) <- c("Rprofmem", class(res))
  ## Sanity check
  stopifnot(c("what", "bytes", "trace") %in% names(res))
  
  res
}

#' @export
subset.Rprofmem <- function(x, ...) {
  res <- NextMethod("subset")
  attr(res, "expression") <- attr(x, "expression")
  attr(res, "threshold") <- attr(x, "threshold")
  res
}

#' @export
as.data.frame.Rprofmem <- function(x, ...) {
  what <- x$what
  bytes <- x$bytes
  traces <- unlist(lapply(x$trace, FUN=function(x) {
    trace <- rev(x)
    hasName <- !grepl("^<[^>]*>$", trace)
    trace[hasName] <- sprintf("%s()", trace[hasName])
    paste(trace, collapse=" -> ")
  }))
  
  res <- data.frame(what = what, bytes = bytes, calls = traces,
                    stringsAsFactors = FALSE)

  ## Preserve row names
  rownames(res) <- rownames(x)
  
  res
} ## as.data.frame()


#' @export
print.Rprofmem <- function(x, expr = TRUE, newpage = FALSE, ...) {
  if (expr && "expression" %in% names(attributes(x))) {
    cat("Rprofmem memory profiling of:\n")
    print(attr(x, "expression"))
    cat("\n")
  }

  threshold <- attr(x, "threshold")
  if (is.null(threshold) || threshold == 0L) {
    cat("Memory allocations:\n")
  } else {
    cat(sprintf("Memory allocations (>= %g bytes):\n", threshold))
  }

  data <- as.data.frame(x, ...)
  
  if (!newpage) {
    drop <- which(x$what == "new page")
    if (length(drop) > 0) {
      cat(sprintf("Number of 'new page' entries not displayed: %d\n",
                  length(drop)))
      data <- data[-drop, ]
    }
  }
  
  n <- nrow(data)
  total <- sum(data$bytes, na.rm=TRUE)

  ## Number of digits for indices
  widx <- floor(log10(n)+1)

  ## Number of digits for bytes
  wbytes <- floor(log10(total)+1)

  ## Report empty call stack as "internal"
  data$calls[!nzchar(data$calls)] <- "<internal>"

  data <- rbind(data, list(what = "", bytes = total, calls = ""))
  rownames(data)[n+1] <- "total"

  print(data, ...)
  
  invisible(x)
} ## print()
