# Version 0.7.0 [2025-05-02]

## New Features

 * `profmem()` gained argument `on_error` to control what should
   happen when there is a run-time error during profiling.  Known
   actions are `"error"`, `"warning"`, and `"ignore"` (default).

 * `print()` for Rprofmem objects now report on any run-time errors
   that occurred while profiling the R expression.

 * `print()` for Rprofmem objects gained logical argument `calls' to
   control whether calls ("traces") are outputted.


# Version 0.6.0 [2020-12-13]

## New Features

 * The defaults of arguments `expr` and `newpage` of `print()` for
   Rprofmem can now be set via options `profmem.print.expr` and
   `profmem.print.newpage`.

## Documentation

 * Added documentation on what an 'Rprofmem' data.frame contains.

 * Added example for `readRprofmem()`.

## Consistency

 * The `bytes` column returned by `readRprofmem()` would be of type
   integer when zero allocation events where read, whereas otherwise
   it would be of type numeric.

 * `print(x)` for Rprofmem now uses an explicit `stringsAsFactors =
   FALSE` when internally coercing `x` to a data frame.


# Version 0.5.0 [2018-01-30]

## Significant Changes

 * Nested `profmem()` calls are now supported, such that inner
   `profmem()` calls will not affect outer ones.  This allows, for
   instance, a package to use profmem internally without having to
   worry about profmem already being active when its functions are
   called.

## New Features
 
 * Added `profmem_begin()` and `profmem_end()` as an alternative to
   `profmem()`.

 * Added `profmem_suspend()` and `profmem_resume()` for suspending and
   resuming an active profmem session.

 * Added `profmem_status()` for checking whether profmem is inactive,
   active, or suspended.
   
 * Added `profmem_depth()` to get the current depth of nested profmem
   sessions.

 * `print()` for Rprofmem now reports on the threshold used, if known.

 * `print()` for Rprofmem gained arguments `expr = TRUE` and `newpage
   = FALSE`, controlling whether the profiled R expression and 'new
   page' entries should be displayed or not.

 * Added option `profmem.threshold` for controlling the default
   threshold level for `profmem()` and `profmem_begin()`.

## Documentation

 * Vignette: Updated the example in Section 'An example where memory
   profiling can make a difference' due to improvements in R (>=
   3.4.0), which made the previous example no longer valid.

 * `help("profmem")` how provide much more details previously only
   available in the vignette.

## Bug Fixes

 * `readRprofmem()` failed to "workaround" another buggy `Rprofmem()`
   output.
   
 
# Version 0.4.0 [2016-09-14]

## New Features

 * `profmem()` now returns a data.frame of class Rprofmem.
 
 * `profmem()` gained argument threshold.

## Code Quality

 * 100% test coverage.
 
 
# Version 0.3.0 [2016-08-06]

## Documentation

 * Added vignette.
 
 
# Version 0.2.1 [2016-07-11]

## New Features

 * Added `readRprofmem()`.
 
 
# Version 0.2.0 [2016-06-05]

## New Features

 * Added `total()` to get the total number of bytes allocated.
 
 * `profmem()` returns also when evaluating the expression gives an
   error.
 
 
# Version 0.1.0 [2016-06-04]

## Significant Changes

 * Added `profmem()`.
 
 * Package created.
