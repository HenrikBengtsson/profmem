# profmem: Simple Memory Profiling for R

## Introduction

The `profmem()` function of the [profmem] package provides an easy way to profile the memory usage of an R expression.  It logs all memory allocations done within R (also by native code of R).  For example,

```r
> library("profmem")
> p <- profmem({
+     x <- raw(1000)
+     A <- matrix(rnorm(100), ncol = 10)
+ })
> p
Rprofmem memory profiling of:
{
    x <- raw(1000)
    A <- matrix(rnorm(100), ncol = 10)
}
Memory allocations:
      bytes               calls
1      1040               raw()
2       208            matrix()
3       416            matrix()
4       416            matrix()
5      1064            matrix()
6       840 matrix() -> rnorm()
7      2544 matrix() -> rnorm()
8       840            matrix()
total  7368                    
```



## Allocations that are logged

The `profmem()` function uses the `utils::Rprofmem()` function for logging memory allocation events to a temporary file.  The logged events are parsed and returned as an in-memory R object in a format that is convenient to work with.  All memory allocations that are done via the native `allocVector3()` part of R's native API are logged, which means that nearly all memory allocations are logged.  Any objects allocated this way are automatically deallocated by R's garbage collector at some point.  Garbage collection events are _not_ logged by `profmem()`.
Allocations _not_ logged are those done by non-R native libraries or R packages that use native code `Calloc() / Free()` for internal objects.  Such objects are _not_ handled by the R garbage collector.


## Requirements

In order for `profmem()` to work, R must have been built with memory profiling enabled.  If not, `profmem()` will produce an error with an informative message.  To manually check whether an R binary was built with this enable or not, do:
```r
> capabilities("profmem")
profmem 
   TRUE 
```

To enable memory profiling (only if the above reports `FALSE`), R needs to be _configured_ and _built_ from source using:
```sh
$ ./configure --enable-memory-profiling
$ make
```
For more information, please see the 'R Installation and Administration' documentation that comes with all R installations.



[profmem]: https://github.com/HenrikBengtsson/profmem


## Installation
R package profmem is only available via [GitHub](https://github.com/HenrikBengtsson/profmem) and can be installed in R as:
```r
source('http://callr.org/install#HenrikBengtsson/profmem')
```




## Software status

| Resource:     | GitHub        | Travis CI      | Appveyor         |
| ------------- | ------------------- | -------------- | ---------------- |
| _Platforms:_  | _Multiple_          | _Linux & OS X_ | _Windows_        |
| R CMD check   |  | <a href="https://travis-ci.org/HenrikBengtsson/profmem"><img src="https://travis-ci.org/HenrikBengtsson/profmem.svg" alt="Build status"></a>  | <a href="https://ci.appveyor.com/project/HenrikBengtsson/profmem"><img src="https://ci.appveyor.com/api/projects/status/github/HenrikBengtsson/profmem?svg=true" alt="Build status"></a> |
| Test coverage |                     | <a href="https://codecov.io/gh/HenrikBengtsson/profmem"><img src="https://codecov.io/gh/HenrikBengtsson/profmem/branch/develop/graph/badge.svg" alt="Coverage Status"/></a>    |                  |
