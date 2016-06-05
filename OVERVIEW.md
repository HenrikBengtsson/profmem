<% R.utils::use("R.utils") %>

## Example
```r
<%=withCapture({
library("profmem")
p <- profmem({
  x <- raw(1000)
  A <- matrix(rnorm(100), ncol=10)
})
})%>
```

