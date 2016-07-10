# profmem: A Simple Memory Profiling API for R


## Example
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


## Installation
R package profmem is only available via [GitHub](https://github.com/HenrikBengtsson/profmem) and can be installed in R as:
```r
source('http://callr.org/install#HenrikBengtsson/profmem')
```




## Software status

| Resource:     | GitHub        | Travis CI     | Appveyor         |
| ------------- | ------------------- | ------------- | ---------------- |
| _Platforms:_  | _Multiple_          | _Linux_       | _Windows_        |
| R CMD check   |  |  |  |
| Test coverage |                     |    |                  |
