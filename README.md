# profmem: Simple Memory Profiling for R

## Introduction

The `profmem()` function of the [profmem] package provides an easy way to profile the memory usage of an R expression.  It logs all memory allocations done in R.  Profiling memory allocations is helpful when we, for instance, try to understand why a certain piece of R code consumes more memory than expected.

The `profmem()` function builds upon existing memory profiling features available in R.  It logs _every_ memory allocation done by plain R code as well as those done by native code such as C and Fortran.  For each entry, it records the size (in bytes) and the name of the functions on the call stack.
For example,

```r
> library("profmem")
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
Memory allocations:
       bytes               calls
1       4040           integer()
2        312          <internal>
3      80040 matrix() -> rnorm()
4       2544 matrix() -> rnorm()
5      80040            matrix()
total 166976                    
```
From this, we find that 4040 bytes are allocated for integer vector `x`, which is because each integer value occupies 4 bytes of memory.  The additional 40 bytes are due to the internal data structure used for each variable R.  The size of this allocation can also be confirmed by the value of `object.size(x)`.
We also see that `rnorm()`, which is called via `matrix()`, allocates 312 + 80040 bytes, where the first one reflects the 10000 double values each occupying 8 bytes.  The second one reflects some unknown allocation done internally by the native code that `rnorm()` uses.
Finally, the last entry reflects the memory allocation of 2544 bytes done by `matrix()` itself.


## An example where memory profiling can make a difference

Assume we have an integer vector
```r
> x <- sample(1:10000, size = 10000)
> str(x)
 int [1:10000] 7148 9595 741 1573 4829 4405 1459 17 2857 9193 ...
```
and we would like to identify all elements less than 5000.  Then we can use
```r
> small <- (x < 5000)
> str(small)
 logi [1:10000] FALSE FALSE TRUE TRUE TRUE TRUE ...
```
This looks fairly innocent, but it turns out that it is unnecessarily inefficient - both when it comes to memory and speed.  The reason is that `5000` is of data type double whereas `x` is of type integer;
```r
> typeof(x)
[1] "integer"
> typeof(5000)
[1] "double"
```
Because of this difference in types, R chooses to first coerce `x` into a double vector before comparing with another double (here `5000`).  Having to coerce to another data type consumes extra memory, which we can see if we profile the memory:
```r
> p <- profmem({
+     small <- (x < 5000)
+ })
> p
Rprofmem memory profiling of:
{
    small <- (x < 5000)
}
Memory allocations:
       bytes      calls
1      80040 <internal>
2      40040 <internal>
total 120080           
```
But before anything else, the sizes of `x` and `small` are:
```r
> object.size(x)
40040 bytes
> object.size(small)
40040 bytes
```
which is because `x` is of type integer (4 bytes per element) and `small` is of type logical (also 4 bytes per element).

Now, due the coercion of `x` to double, an internal double vector of the same length as `x` is temporarily created (and populated with values from `x`).  This is what is reported in the first row of `p`.  Since each double value occupies 8 bytes of memory, the size of this internal object is 80040 bytes.
At this point, R is ready to compare the internal double vector against the double value `5000`.  The result of this comparison will be stored in a logical vector of length 10000.  This is what is reported in the second row of `p`.  This logical vector is assigned to variable `small` at the end.

We can avoid the coercion to double if we compare `x` to an integer value (`5000L`) instead of a double value (`5000`), which is also confirmed if we profile memory allocations;
```r
> p2 <- profmem({
+     small <- (x < 5000L)
+ })
> p2
Rprofmem memory profiling of:
{
    small <- (x < 5000L)
}
Memory allocations:
      bytes      calls
1     40040 <internal>
total 40040           
```
In this case, all that is allocated is the memory for holding the logical result that is later assigned to `small`.

Using the [microbenchmark] package, we can also quantify the extra overhead in processing time that is introduced due to the coercion of `x` to double;
```r
> library("microbenchmark")
> stats <- microbenchmark(double = (x < 5000), integer = (x < 
+     5000), times = 100, unit = "ms")
> stats
Unit: milliseconds
    expr   min    lq  mean median    uq   max neval
  double 0.035 0.036 0.049  0.037 0.065 0.072   100
 integer 0.017 0.017 0.030  0.017 0.027 0.872   100
```
Comparing integer vector `x` to an integer is in this case approximately twice as fast as comparing to a double.  This is also true for vectors with many more elements than 10000.


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

Volunteers of the R Project provide pre-built binaries of the R software available via CRAN at https://cran.r-project.org/.  Among these, [it has been confirmed](https://github.com/HenrikBengtsson/profmem/issues/2) that the R binaries for Windows, the ones from the Ubuntu Linux distribution, and the nightly builds for macOS by the AT&T Research Lab have all been built with memory profiling enabled.  It is possible that it is also enabled by default for the other Linux distributions as well as the other macOS binaries, but this has to be confirmed.


To enable memory profiling, which is _only_ needed if `capabilities("profmem")` returns `FALSE`, R needs to be _configured_ and _built_ from source using:
```sh
$ ./configure --enable-memory-profiling
$ make
```
For more information, please see the 'R Installation and Administration' documentation that comes with all R installations.



[profmem]: https://cran.r-project.org/package=profmem
[microbenchmark]: https://cran.r-project.org/package=microbenchmark


## Installation
R package profmem is available on [CRAN](http://cran.r-project.org/package=profmem) and can be installed in R as:
```r
install.packages('profmem')
```

### Pre-release version

To install the pre-release version that is available in branch `develop`, use:
```r
source('http://callr.org/install#HenrikBengtsson/profmem@develop')
```
This will install the package from source.  



## Software status

| Resource:     | CRAN        | Travis CI      | Appveyor         |
| ------------- | ------------------- | -------------- | ---------------- |
| _Platforms:_  | _Multiple_          | _Linux & OS X_ | _Windows_        |
| R CMD check   | <a href="http://cran.r-project.org/web/checks/check_results_profmem.html"><img border="0" src="http://www.r-pkg.org/badges/version/profmem" alt="CRAN version"></a> | <a href="https://travis-ci.org/HenrikBengtsson/profmem"><img src="https://travis-ci.org/HenrikBengtsson/profmem.svg" alt="Build status"></a>  | <a href="https://ci.appveyor.com/project/HenrikBengtsson/profmem"><img src="https://ci.appveyor.com/api/projects/status/github/HenrikBengtsson/profmem?svg=true" alt="Build status"></a> |
| Test coverage |                     | <a href="https://codecov.io/gh/HenrikBengtsson/profmem"><img src="https://codecov.io/gh/HenrikBengtsson/profmem/branch/develop/graph/badge.svg" alt="Coverage Status"/></a>    |                  |
