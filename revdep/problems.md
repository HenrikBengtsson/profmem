# DelayedMatrixStats

<details>

* Version: 1.12.1
* GitHub: https://github.com/PeteHaitch/DelayedMatrixStats
* Source code: https://github.com/cran/DelayedMatrixStats
* Date/Publication: 2020-11-24
* Number of recursive dependencies: 80

Run `revdep_details(, "DelayedMatrixStats")` for more info

</details>

## In both

*   checking dependencies in R code ... NOTE
    ```
    Namespaces in Imports field not imported from:
      ‘BiocParallel’ ‘HDF5Array’
      All declared Imports should be used.
    Unexported objects imported by ':::' calls:
      ‘DelayedArray:::.get_ans_type’
      ‘DelayedArray:::.reduce_array_dimensions’
      ‘DelayedArray:::RleArraySeed’ ‘DelayedArray:::get_Nindex_lengths’
      ‘DelayedArray:::set_dim’ ‘DelayedArray:::set_dimnames’
      ‘DelayedArray:::subset_by_Nindex’ ‘DelayedArray:::to_linear_index’
      See the note in ?`:::` about the use of this operator.
    ```

# mashr

<details>

* Version: 0.2.38
* GitHub: https://github.com/stephenslab/mashr
* Source code: https://github.com/cran/mashr
* Date/Publication: 2020-06-19 05:50:11 UTC
* Number of recursive dependencies: 84

Run `revdep_details(, "mashr")` for more info

</details>

## In both

*   checking tests ...
    ```
     ERROR
    Running the tests in ‘tests/testthat.R’ failed.
    Last 13 lines of output:
       4.     ├─base::all.equal(...)
       5.     └─base::all.equal.numeric(...)
      
      ── Skipped tests  ──────────────────────────────────────────────────────────────
      ● Cannot test it due to numerical differences between chol in armadillo and R ... (1)
      ● file.exists("estimate_null_cor.rds") is not TRUE (1)
      ● file.exists("estimate_null_cor_alpha.rds") is not TRUE (1)
      
      ══ testthat results  ═══════════════════════════════════════════════════════════
      ERROR (test_sampling.R:10:3): Samples from the posterior look right
      ERROR (test_sampling.R:21:3): Samples from the posterior with linear transformation look right
      
      [ FAIL 2 | WARN 0 | SKIP 3 | PASS 127 ]
      Error: Test failures
      Execution halted
    ```

*   checking installed package size ... NOTE
    ```
      installed size is  6.8Mb
      sub-directories of 1Mb or more:
        libs   5.8Mb
    ```

