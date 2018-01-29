#' Produce a prompt-compatible string with profmem information
#'
#' @param what Action to take.
#'
#' @param threshold The profmem threshold to be used.
#'
#' @export
#' @keywords internal
profmem_prompt <- local({
  .depth <- NULL
  .last_profmem <- NULL

  ## TODO:
  ## * Allow user change threshold of the profmem prompt
  ## * Allow user to suspend/resume the profmem prompt
  ## * Add support for custom prompt(profmem, depth, ...) function
  ## * Have built-in prompt() function return args as attributes
  function(what = c("update", "suspend", "resume", "prompt", "begin", "end"), threshold = 10 * 1024) {
    what <- match.arg(what)

    if (what == "prompt") {
      if (is.null(.last_profmem)) return("")

      depth <- profmem_stack("depth")
      if (!is.null(.depth) && .depth != depth) {
        return("waiting for active profmem to close")
      }
      
      ## Don't report on 'new page' entries
      pm <- subset(.last_profmem, what != "new page")
      threshold <- attr(pm, "threshold")
      threshold <- structure(threshold, class = "object_size")
      threshold <- format(threshold, units = "auto", standard = "IEC")
      
      total <- total(pm)
      total <- structure(total, class = "object_size")
      total <- format(total, units = "auto", standard = "IEC")

      n <- nrow(pm)
      if (n == 1) {
        prompt <- sprintf("%s in 1 allocation >= %s",
                          total, threshold, depth)
      } else {
        prompt <- sprintf("%s in %d allocations >= %s",
                          total, n, threshold, depth)
      }
    
      return(prompt)
    }

    if (what == "end") {
      if (!is.null(.depth) && .depth == profmem_stack("depth")) {
        .last_profmem <<- tryCatch({
          p <- profmem_end()
          .depth <<- NULL
          p
        }, error = function(ex) NULL)
      }
    } else if (what == "begin") {
      if (is.null(.depth)) {
        tryCatch({
          profmem_begin(threshold = threshold)
          .depth <<- profmem_stack("depth")
        }, error = function(ex) NULL)
      }
    }
  }
})
