library("profmem")

message("profmem() - nested ...")

p1 <- profmem({
  x <- integer(1000)
  z <- Y + (x + 1)
})

print(p1)
print(p2)

message("profmem() - nested ... DONE")
