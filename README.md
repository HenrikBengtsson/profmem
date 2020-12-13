


# profmem: Simple Memory Profiling for R

## Introduction

The `profmem()` function of the [profmem] package provides an easy way to profile the memory usage of an R expression.  It logs all memory allocations done in R.  Profiling memory allocations is helpful when we, for instance, try to understand why a certain piece of R code consumes more memory than expected.

The `profmem()` function builds upon existing memory profiling features available in R.  It logs _every_ memory allocation done by plain R code as well as those done by native code such as C and Fortran.  For each entry, it records the size (in bytes) and the name of the functions on the call stack.
For example,

```r
> library("profmem")
> options(profmem.threshold = 2000)
> p <- profmem({
+     x <- integer(1000)
+     Y <- matrix(rnorm(n = 10000), nrow = 100)
+ })
> p
Rprofmem memory profiling of:
{
    x <- integer(1000)
    Y <- matrix(rnorm(n = 10000), nrow = 100)
}
Memory allocations (>= 2000 bytes):
       what  bytes               calls
1     alloc   4048           integer()
2     alloc  80048 matrix() -> rnorm()
3     alloc   2552 matrix() -> rnorm()
4     alloc  80048            matrix()
total       166696                    
```
From this, we find that 4048 bytes are allocated for integer vector `x`, which is because each integer value occupies 4 bytes of memory.  The additional 40 bytes are due to the internal data structure used for each variable R.  The size of this allocation can also be confirmed by the value of `object.size(x)`.
We also see that `rnorm()`, which is called via `matrix()`, allocates 80048 + 2552 bytes, where the first one reflects the 10000 double values each occupying 8 bytes.  The second one reflects some unknown allocation done internally by the native code that `rnorm()` uses.
Finally, the following entry reflects the memory allocation of 80048 bytes done by `matrix()` itself.


## An example where memory profiling can make a difference

Assume we want to set a 100-by-100 matrix with missing values except for element (1,1) that we assign to be zero.  This can be done as:
```r
> x <- matrix(nrow = 100, ncol = 100)
> x[1, 1] <- 0
> x[1:3, 1:3]
     [,1] [,2] [,3]
[1,]    0   NA   NA
[2,]   NA   NA   NA
[3,]   NA   NA   NA
```
This looks fairly innocent, but it turns out that it is very inefficient - both when it comes to memory and speed.  The reason is that the default value used by `matrix()` is `NA`, which is of type _logical_.  This means that initially `x` is a _logical_ matrix not a _numeric_ matrix.  When we the assign the (1,1) element the value `0`, which is a _numeric_, the matrix first has to be coerced to _numeric_ internally and then the zero is assigned.  Profiling the memory will reveal this;


```r
> p <- profmem({
+     x <- matrix(nrow = 100, ncol = 100)
+     x[1, 1] <- 0
+ })
> print(p, expr = FALSE)
Memory allocations (>= 2000 bytes):
       what  bytes      calls
1     alloc  40048   matrix()
2     alloc  80048 <internal>
total       120096           
```
The first entry is for the logical matrix with 10,000 elements (= 4 \* 10,000 bytes + small header) that we allocate.  The second entry reveals the coercion of this matrix to a numeric matrix (= 8 \* 10,000 elements + small header).

To avoid this, we make sure to create a numeric matrix upfront as:
```r
> p <- profmem({
+     x <- matrix(NA_real_, nrow = 100, ncol = 100)
+     x[1, 1] <- 0
+ })
> print(p, expr = FALSE)
Memory allocations (>= 2000 bytes):
       what bytes    calls
1     alloc 80048 matrix()
total       80048         
```

Using the [microbenchmark] package, we can also quantify the extra overhead in processing time that is introduced due to the logical-to-numeric coercion;
```r
> library("microbenchmark")
> stats <- microbenchmark(bad = {
+     x <- matrix(nrow = 100, ncol = 100)
+     x[1, 1] <- 0
+ }, good = {
+     x <- matrix(NA_real_, nrow = 100, ncol = 100)
+     x[1, 1] <- 0
+ }, times = 100, unit = "ms")
> stats
Unit: milliseconds
 expr    min    lq  mean median    uq   max neval
  bad 0.0268 0.028 0.029  0.029 0.029 0.060   100
 good 0.0095 0.010 0.012  0.011 0.014 0.038   100
```
The inefficient approach is 1.5-2 times slower than the efficient one.


The above illustrates the value of profiling your R code's memory usage and thanks to `profmem()` we can compare the amount of memory allocated of two alternative implementations.  Being able to write memory-efficient R code becomes particularly important when working with large data sets, where an inefficient implementation may even prevent us from performing an analysis because we end up running out of memory.  Moreover, each memory allocation will eventually have to be deallocated and in R this is done automatically by the garbage collector, which runs in the background and recovers any blocks of memory that are allocated but no longer in use.  Garbage collection takes time and therefore slows down the overall processing in R even further.

The above illustrates the value of profiling your R code's memory usage and thanks to `profmem()` we can compare the amount of memory allocated of two alternative implementations.  Being able to write memory-efficient R code becomes particularly important when working with large data sets, where an inefficient implementation may even prevent us from performing an analysis because we end up running out of memory.  Moreover, each memory allocation will eventually have to be deallocated and in R this is done automatically by the garbage collector, which runs in the background and recovers any blocks of memory that are allocated but no longer in use.  Garbage collection takes time and therefore slows down the overall processing in R even further.




## What is logged?

The `profmem()` function uses the `utils::Rprofmem()` function for logging memory allocation events to a temporary file.  The logged events are parsed and returned as an in-memory R object in a format that is convenient to work with.  All memory allocations that are done via the native `allocVector3()` part of R's native API are logged, which means that nearly all memory allocations are logged.  Any objects allocated this way are automatically deallocated by R's garbage collector at some point.  Garbage collection events are _not_ logged by `profmem()`.
Allocations _not_ logged are those done by non-R native libraries or R packages that use native code `Calloc() / Free()` for internal objects.  Such objects are _not_ handled by the R garbage collector.

### Difference between `utils::Rprofmem()` and `utils::Rprof(memory.profiling = TRUE)`
In addition to `utils::Rprofmem()`, R also provides `utils::Rprof(memory.profiling = TRUE)`.  Despite the close similarity of their names, they use completely different approaches for profiling the memory usage.  As explained above, the former logs _all individual_ (`allocVector3()`) memory allocation whereas the latter probes the _total_ memory usage of R at regular time intervals.  If memory is allocated and deallocated between two such probing time points, `utils::Rprof(memory.profiling = TRUE)` will not log that memory whereas `utils::Rprofmem()` will pick it up.  On the other hand, with `utils::Rprofmem()` it is not possible to quantify the total memory _usage_ at a given time because it only logs _allocations_ and does therefore not reflect deallocations done by the garbage collector.


## Requirements

In order for `profmem()` to work, R must have been built with memory profiling enabled.  If not, `profmem()` will produce an error with an informative message.  To manually check whether an R binary was built with this enable or not, do:
```r
> capabilities("profmem")
profmem 
   TRUE 
```
The overhead of running an R installation with memory profiling enabled compared to one without is neglectable / non-measurable.

Volunteers of the R Project provide and distribute pre-built binaries of the R software for all the major operating system via [CRAN].  [It has been confirmed](https://github.com/HenrikBengtsson/profmem/issues/2) that the R binaries for Windows, macOS (both by CRAN and by the AT&T Research Lab), and for Linux (\*) all have been built with memory profiling enabled.  (\*) For Linux, this has been confirmed for the Debian/Ubuntu distribution but yet not for the other Linux distributions.


In all other cases, to enable memory profiling, which is _only_ needed if `capabilities("profmem")` returns `FALSE`, R needs to be _configured_ and _built from source_ using:
```sh
$ ./configure --enable-memory-profiling
$ make
```
For more information, please see the 'R Installation and Administration' documentation that comes with all R installations.



[CRAN]: https://cran.r-project.org/
[profmem]: https://cran.r-project.org/package=profmem
[microbenchmark]: https://cran.r-project.org/package=microbenchmark


## Installation
R package profmem is available on [CRAN](https://cran.r-project.org/package=profmem) and can be installed in R as:
```r
install.packages("profmem")
```


### Pre-release version

To install the pre-release version that is available in Git branch `develop` on GitHub, use:
```r
remotes::install_github("HenrikBengtsson/profmem", ref="develop")
```
This will install the package from source.  

## Contributions

This Git repository uses the [Git Flow](https://nvie.com/posts/a-successful-git-branching-model/) branching model (the [`git flow`](https://github.com/petervanderdoes/gitflow-avh) extension is useful for this).  The [`develop`](https://github.com/HenrikBengtsson/profmem/tree/develop) branch contains the latest contributions and other code that will appear in the next release, and the [`master`](https://github.com/HenrikBengtsson/profmem) branch contains the code of the latest release, which is exactly what is currently on [CRAN](https://cran.r-project.org/package=profmem).

Contributing to this package is easy.  Just send a [pull request](https://help.github.com/articles/using-pull-requests/).  When you send your PR, make sure `develop` is the destination branch on the [profmem repository](https://github.com/HenrikBengtsson/profmem).  Your PR should pass `R CMD check --as-cran`, which will also be checked by <a href="https://travis-ci.org/HenrikBengtsson/profmem">Travis CI</a> and <a href="https://ci.appveyor.com/project/HenrikBengtsson/profmem">AppVeyor CI</a> when the PR is submitted.

We abide to the [Code of Conduct](https://www.contributor-covenant.org/version/2/0/code_of_conduct/) of Contributor Covenant.


## Software status

| Resource      | CRAN        | GitHub Actions      | Travis CI       | AppVeyor CI      |
| ------------- | ------------------- | ------------------- | --------------- | ---------------- |
| _Platforms:_  | _Multiple_          | _Multiple_          | _Linux & macOS_ | _Windows_        |
| R CMD check   | <a href="https://cran.r-project.org/web/checks/check_results_profmem.html"><img border="0" src="http://www.r-pkg.org/badges/version/profmem" alt="CRAN version"></a> | <a href="https://github.com/HenrikBengtsson/profmem/actions?query=workflow%3AR-CMD-check"><img src="https://github.com/HenrikBengtsson/profmem/workflows/R-CMD-check/badge.svg?branch=develop" alt="Build status"></a>       | <a href="https://travis-ci.org/HenrikBengtsson/profmem"><img src="https://travis-ci.org/HenrikBengtsson/profmem.svg" alt="Build status"></a>   | <a href="https://ci.appveyor.com/project/HenrikBengtsson/profmem"><img src="https://ci.appveyor.com/api/projects/status/github/HenrikBengtsson/profmem?svg=true" alt="Build status"></a> |
| Test coverage |                     |                     | <a href="https://codecov.io/gh/HenrikBengtsson/profmem"><img src="https://codecov.io/gh/HenrikBengtsson/profmem/branch/develop/graph/badge.svg" alt="Coverage Status"/></a>     |                  |
