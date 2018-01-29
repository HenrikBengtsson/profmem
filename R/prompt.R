profmem_prompt <- local({
  .last_profmem <- NULL
  
  function(what = c("prompt", "begin", "end"), threshold = 10 * 1024) {
    what <- match.arg(what)

    if (what == "prompt") {
      if (is.null(.last_profmem)) return("")

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
        prompt <- sprintf("%s in 1 allocation >= %s", total, threshold)
      } else {
        prompt <- sprintf("%s in %d allocations >= %s", total, n, threshold)
      }
    
      return(prompt)
    }

    if (what == "end") {
      .last_profmem <<- tryCatch({
        profmem_end()
      }, error = function(ex) NULL)
    } else if (what == "begin") {
      tryCatch({
        profmem_begin(threshold = threshold)
      }, error = function(ex) NULL)
    }
  }
})
