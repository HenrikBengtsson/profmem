file <- system.file("extdata", "example.Rprofmem.out", package = "profmem")

raw <- readRprofmem(file, as = "raw")
cat(raw, sep = "\n")

profmem <- readRprofmem(file, as = "Rprofmem")
print(profmem)
