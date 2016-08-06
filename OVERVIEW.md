<% R.utils::use("R.utils") %>

The `profmem()` function of the [profmem] package provides an easy way to profile the memory usage of an R expression.  More precisely, it logs _all_ memory allocations done when creating new R objects.

## Example

<% if (capabilities('profmem')) { %>
```r
<%=withCapture({
library("profmem")

p <- profmem({
  x <- raw(1000)
  A <- matrix(rnorm(100), ncol=10)
})

p
})%>
```

<% } else { %>

**WARNING: This vignette was compiled with an R version that was built with memory profiling disabled, cf. `capabilities('profmem')`.  Please redo!**

<% } ## if (capabilities('profmem')) %>



## Requirements

In order for `profmem()` to work, R must have been built with memory profiling enabled.  If not, `profmem()` will produce an error with an informative message.  To manually check whether an R binary was built with this enable or not, do:
```r
<%=withCapture({
capabilities('profmem')
})%>
```

To enable memory profiling, R needs to be _configured_ and _built_ from source using:
```sh
$ ./configure --enable-memory-profiling
$ make
```


## What is logged?
The `profmem()` function uses the `utils::Rprofmem()` function for logging memory allocation events to a temporary file.  The logged events are parsed and returned as an in-memory R object in a format that is convenient to work with.

All memory allocations that are done via the native `allocVector3()` part of R's native API are logged.  This means that nearly all memory allocations are logged.  Allocations _not_ logged are those done by non-R native libraries or R packages that uses `Calloc() / Free()` for internal objects.
