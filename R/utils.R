#' @importFrom utils capture.output str
mstr <- function(...) {
  message(paste(capture.output(str(...)), collapse = "\n"))
}

#' @importFrom utils capture.output
mprint <- function(...) {
  message(paste(capture.output(print(...)), collapse = "\n"))
}
