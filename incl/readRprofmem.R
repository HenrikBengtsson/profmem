file <- system.file("extdata", "example.Rprofmem.out", package = "profmem")

raw <- readRprofmem(file, as = "raw")
cat(sprintf("*** %s (raw):\n", basename(file)))
cat(raw, sep = "\n")

profmem <- readRprofmem(file, as = "Rprofmem")
cat(sprintf("\n*** %s (Rprofmem):\n", basename(file)))
print(profmem)
