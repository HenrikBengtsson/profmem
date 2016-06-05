# profmem: A Simple Memory Profiling API for R


## Example
```r
> library("profmem")
> p <- profmem({
+     x <- raw(1000)
+     A <- matrix(rnorm(100), ncol = 10)
+ })

```


## Installation
R package profmem is only available via [GitHub](https://github.com/) and can be installed in R as:
```r
source('http://callr.org/install#')
```




## Software status

| Resource:     | GitHub        | Travis CI     | Appveyor         |
| ------------- | ------------------- | ------------- | ---------------- |
| _Platforms:_  | _Multiple_          | _Linux_       | _Windows_        |
| R CMD check   |  |  |  |
| Test coverage |                     |    |                  |
