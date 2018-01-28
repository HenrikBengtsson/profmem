profmem_pathname <- local({
  pathname <- NULL
  function() {
    if (!is.null(pathname)) return(pathname)
    pathname <<- tempfile(pattern = "profmem.", fileext = ".Rprofmem.out")
    pathname
  }
})

profmem_stack <- local({
  empty <- data.frame(bytes = NULL, trace = NULL, stringsAsFactors = FALSE)
  empty <- structure(empty, class = c("Rprofmem", "data.frame"), threshold = 0L)
  
  stack <- list()
  
  function(action = c("depth", "threshold", "push", "pop", "append"),
           data = empty, threshold = 0L) {
    action <- match.arg(action)
    if (action == "depth") return(length(stack))

    if (action == "threshold") {
      if (length(stack) == 0) return(NA_integer_)
      threshold <- attr(stack[[1]], "threshold")
      return(threshold)
    }
    
    if (action == "push") {
      stopifnot(inherits(data, "Rprofmem"),
                length(threshold) == 1, is.finite(threshold),
                is.integer(threshold), threshold >= 0L)
      attr(data, "threshold") <- threshold
      stack <<- c(stack, list(data))
#      message("PUSH: stack depth: ", length(stack))
      return(length(stack))
    }
    
    if (action == "pop") {
      depth <- length(stack)
      if (depth == 0) stop("Cannot 'pop' - profmem stack is empty")
      value <- stack[[depth]]
      stack <<- stack[-depth]
      depth <- length(stack)
      if (depth >= 1) {
        tmp <- stack[[depth]]
        tmp <- if (is.null(tmp)) value else c(tmp, value)
        stack[[depth]] <<- tmp
      }
#      message("POP: stack depth: ", length(stack))
      return(value)
    }

    if (action == "append") {
      depth <- length(stack)
      if (depth == 0) stop("Cannot 'append' - profmem stack is empty")
      stopifnot(inherits(data, "Rprofmem"),
                length(threshold) == 1, is.finite(threshold),
                is.integer(threshold), threshold >= 0L)
      attr(data, "threshold") <- threshold
      value <- stack[[depth]]
      value <- if (is.null(value)) data else c(value, data)
      stack[[depth]] <<- value
#      message("APPEND: stack depth: ", length(stack))
      return(invisible(value))
    }
  }
})


#' Memory profiling R
#'
#' `profmem()` evaluates and memory profiles an \R expression.
#'
#' @param expr An R expression to be evaluated and profiled.
#' 
#' @param envir The environment in which the expression should be evaluated.
#' 
#' @param substitute Should `expr` be [base::substitute()]:d or not.
#' 
#' @param threshold The smallest memory allocation (in bytes) to log.
#'
#' @return
#' `profmem()` and `profmem_end()` returns the collected `Rprofmem` data.
#' `profmem_begin()` returns (invisibly) the number of nested profmem
#' session currently active.
#' `profmem_suspend()` and `profmem_resume()` returns nothing.
#'
#' @details
#' Profiling gathered by \pkg{profmem} _will_ be corrupted if the code profiled
#' calls [utils::Rprofmem()], with the exception of such calls done via the
#' \pkg{profmem} package itself.
#'
#' Any memory events that would occur due to calling any of the \pkg{profmem}
#' functions themselves will _not_ be logged and _not_ be part of the returned
#' profile data (regardless whether memory profiling is active or not).
#'
#' If a profmem profiling is already active, `profmem()` and `profmem_begin()`
#' performs an _independent_, _nested_ profiling, which has no affect on the
#' already active one.  When the active one completes, it will contain all
#' memory events also collected by the nested profiling as if the nested one
#' never occurred.
#'
#' @example incl/profmem.R
#'
#' @seealso
#' Internally [utils::Rprofmem()] is used.
#'
#' @export
#' @importFrom utils Rprofmem
profmem <- function(expr, envir = parent.frame(), substitute = TRUE, threshold = 0L) {
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


#' `profmem_begin()` starts the memory profiling of all the following \R
#' evaluations until `profmem_end()` is called.
#'
#' @rdname profmem
#' @export
profmem_begin <- function(threshold = 0L) {
  ## Is memory profiling supported?
  if (!capableOfProfmem()) {
    msg <- "Profiling of memory allocations is not supported on this R system (capabilities('profmem') reports FALSE). See help('tracemem')."
    if (.Platform$OS.type == "unix") {
      msg <- paste(msg, "To enable memory profiling for R on Linux, R needs to be configured and built using './configure --enable-memory-profiling'.")
    }
    stop(msg)
  }

  threshold <- as.integer(threshold)
  stopifnot(length(threshold) == 1, is.finite(threshold), threshold >= 0L)

  depth <- profmem_stack("depth")
  if (depth > 0) {
    threshold_parent <- profmem_stack("threshold")
    if (threshold > threshold_parent) {
      threshold <- threshold_parent
      warning(sprintf("Nested profmem threshold (%d bytes) cannot be greater than the threshold (%d bytes) of an active profmem session. Will use the active threshold instead.", threshold, threshold_parent))
    }
  }
  
  profmem_suspend()
   
  ## Push new level
  depth <- profmem_stack("push", threshold = threshold)
 
  profmem_resume()
 
  invisible(depth)
}

#' @rdname profmem
#' @export
profmem_end <- function() {
  profmem_suspend()

  depth <- profmem_stack("depth")
  if (depth == 0) {
    stop("Did you forget to call profmem_begin()?")
  }

  data <- profmem_stack("pop")

  profmem_resume()
  
  data
}

#' `profmem_suspend()` suspends an active profiling until resumed by
#' `profmem_resume()` or ended by `profmem_end()`.
#' Calling `profmem_begin()` or `profmem()` will resume any suspended
#' profiling; _nested_ resuming and suspending is _not_ supported.
#' 
#' @rdname profmem
#' @importFrom utils Rprofmem
#' @export
profmem_suspend <- function() {
  ## Works regardless of active Rprofmem exists or not
  Rprofmem("")

  ## Nothing more to do?
  if (profmem_stack("depth") == 0) return()
  
  ## Import current log
  drop <- length(sys.calls()) + 4L
  pathname <- profmem_pathname()
  data <- readRprofmem(pathname, drop = drop, as = "profmem")
  attr(data, "threshold") <- profmem_stack("threshold")
  profmem_stack("append", data)

  invisible()
}

#' @rdname profmem
#' @importFrom utils Rprofmem
#' @export
profmem_resume <- function() {
  threshold <- profmem_stack("threshold")
  pathname <- profmem_pathname()
  Rprofmem(filename = pathname, threshold = threshold)
  invisible()
}


### TODO:
###
### profmem_add_string <- function(msg, ...) {
###   pathname <- profmem_pathname()
###   cat(msg, file = pathname, append = file_test("-f", pathname))
### }
### 
### ## FIXME: This produces lots of extra memory allocations, which
### ## we don't want to inject.
### profmem_add_note <- function(..., timestamp = TRUE) {
###   msg <- sprintf(...)
###   if (timestamp) {
###     msg <- sprintf("[%s] %s", format(Sys.time(), "%Y%m%d-%H%M%S"), msg)
###   }
###   msg <- sprintf("# %s\n", msg)
###   profmem_add_string(msg)
### }
