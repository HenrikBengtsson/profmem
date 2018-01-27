library("profmem")

message("profmem() - nested ...")

if (capabilities("profmem")) {

p1 <- profmem({
  x <- integer(1000)
  p2 <- profmem({
    Y <- matrix(x, nrow = 100, ncol = 10)
  })
  z <- Y + (x + 1)
})

print(p1)
print(p2)

}

message("profmem() - nested ... DONE")
