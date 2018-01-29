library("profmem")

status <- profmem_status()
message("status: ", status)

depth <- profmem_depth()
message("depth: ", depth)

if (capabilities("profmem")) {

  p <- profmem({
    x <- raw(1000)
    A <- matrix(rnorm(100), ncol=10)
    status_2 <- profmem_status()
    depth_2 <- profmem_depth()
    message("depth_2: ", depth_2)
    stopifnot(depth2 == depth_+ 1)
  })
  print(p)

  data <- as.data.frame(p)
  print(data)

  t <- total(p)
  print(t)
  stopifnot(t == sum(data$bytes, na.rm=TRUE))


  foo <- function(n) {
    matrix(rnorm(n^2), ncol=n)
  }

  p <- profmem({
    A <- matrix(rnorm(100^2), ncol=100)
    B <- foo(100)
  })
  print(p)

  p2 <- subset(p, bytes >= 40000)
  print(p2)

  p <- profmem({
    A <- matrix(rnorm(100^2), ncol=100)
    B <- foo(100)
  }, threshold = 40000)
  d <- as.data.frame(p)
  print(d)

  p1 <- subset(p, !is.na(bytes))
  d1 <- as.data.frame(p1)
  
  p2 <- subset(p, bytes >= 40000)
  d2 <- as.data.frame(p2)
  print(d2)
  stopifnot(identical(d2, d1))

  print(dim(p))
  stopifnot(identical(dim(p), dim(d)))
  
} ## if (capabilities("profmem"))

