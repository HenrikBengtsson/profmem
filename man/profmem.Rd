% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/profmem.R
\name{profmem}
\alias{profmem}
\alias{profmem_begin}
\alias{profmem_end}
\alias{profmem_suspend}
\alias{profmem_resume}
\alias{profmem_status}
\alias{profmem_depth}
\title{Memory profiling R}
\usage{
profmem(
  expr,
  envir = parent.frame(),
  substitute = TRUE,
  threshold = getOption("profmem.threshold", 0L),
  on_error = c("ignore", "warning", "error")
)

profmem_begin(threshold = getOption("profmem.threshold", 0L))

profmem_end()

profmem_suspend()

profmem_resume()

profmem_status()

profmem_depth()
}
\arguments{
\item{expr}{An \R expression to be evaluated and profiled.}

\item{envir}{The environment in which the expression should be evaluated.}

\item{substitute}{Should \code{expr} be \code{\link[base:substitute]{base::substitute()}}:d or not.}

\item{threshold}{The smallest memory allocation (in bytes) to log.}

\item{on_error}{(character) Controls whether evaluation errors should
signal an error (\code{"error"}), a warning (\verb{"warning"), or be ignored (}"ignore"`; default).}
}
\value{
\code{profmem()} and \code{profmem_end()} returns the collected allocation
data as an \code{Rprofmem} data.frame with additional attributes set.
An \code{Rprofmem} data.frame has columns \code{what}, \code{bytes}, and \code{trace}, with:
\itemize{
\item \code{what}:  (character) type of memory event;
either \code{"alloc"} or \code{"new page"}
\item \code{bytes}: (numeric) number of bytes allocated or \code{NA_real_}
(when \code{what} is \code{"new page"})
\item \code{trace}: (list of character vectors) zero or more function names
}

The attributes set are:
\itemize{
\item \code{threshold} : The threshold used (= argument \code{threshold})
\item \code{expression}: The expression profiled (= argument \code{expr})
\item \code{value}     : The value of the evaluated expression
(only set if there was no error)
\item \code{error}     : The error object in case the evaluation failed
(only set if there was an error)
}

\code{profmem_begin()} returns (invisibly) the number of nested profmem
session currently active.

\code{profmem_suspend()} and \code{profmem_resume()} returns nothing.

\code{profmem_status()} returns \code{"inactive"}, \code{"active"},
or \code{"suspended"}.

\code{promem_depth()} returns a non-negative integer.
}
\description{
\code{profmem()} evaluates and memory profiles an \R expression.

\code{profmem_begin()} starts the memory profiling of all the following \R
evaluations until \code{profmem_end()} is called.
}
\details{
In order for memory profiling to work, \R must have been \emph{built} with memory
profiling enabled.  Function
\code{\link[base:capabilities]{base::capabilities("profmem")}} will
return \code{TRUE} of it is enabled, otherwise \code{FALSE}.
If memory profiling is \emph{not} supported, \code{profmem()} and \code{profmem_begin()}
will produce an informative error.  The pre-built \R binaries on
\href{https://cran.r-project.org/}{CRAN} support memory profiling.

What is logged?  The \code{profmem()} function uses \code{\link[utils:Rprofmem]{utils::Rprofmem()}} for
logging memory, which logs all memory \emph{allocations} that are done via the
\R framework.  Specifically, the logger is tied to \code{allocVector3()} part
of \R's native API.  This means that nearly all memory allocations done
in \R are logged. \emph{Neither} memory deallocations \emph{nor} garbage collection
events are logged.  Furthermore, allocations done by non-\R native libraries
or \R packages that use native code \code{Calloc() / Free()} for internal objects
are also \emph{not} logged.

Any memory events that would occur due to calling any of the \pkg{profmem}
functions themselves will \emph{not} be logged and \emph{not} be part of the returned
profile data (regardless whether memory profiling is active or not).
This is intentional.

If a profmem profiling is already active, \code{profmem()} and \code{profmem_begin()}
performs an \emph{independent}, \emph{nested} profiling, which does not affect the
already active one.  When the active one completes, it will contain all
memory events also collected by the nested profiling as if the nested one
never occurred.

Profiling gathered by \pkg{profmem} \emph{will} be corrupted if the code profiled
calls \code{\link[utils:Rprofmem]{utils::Rprofmem()}}, with the exception of such calls done via the
\pkg{profmem} package itself.
}
\examples{
if (capabilities("profmem")) {

## Memory profile an R expression
p <- profmem({
  x <- raw(1000)
  A <- matrix(rnorm(100), ncol = 10)
})

## Display the results
print(p)

## Total amount of memory allocation
total(p)

## Allocations greater than 1 kB
p2 <- subset(p, bytes > 1000)
print(p2)

## The expression is evaluated in the calling environment
str(x)
str(A)

}
}
