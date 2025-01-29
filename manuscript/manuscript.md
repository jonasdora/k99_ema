Untitled
================
29 January, 2025

This manuscript uses the Workflow for Open Reproducible Code in Science
(Van Lissa et al. 2021) to ensure reproducibility and transparency. All
code <!--and data--> are available at <k99_ema>.

This is an example of a non-essential citation (@ Van Lissa et al.
2021). If you change the rendering function to `worcs::cite_essential`,
it will be removed.

``` r
tar_load(fl_tab_fits)
fit_tbl <- read.csv(fl_tab_fits, stringsAsFactors = FALSE)
knitr::kable(fit_tbl)
```

| model            | method |      rmse |
|:-----------------|:-------|----------:|
| choice_prop_raw  | forest | 0.1242782 |
| choice_prop_UMAP | forest | 0.1242570 |
| choice_prop_raw  | forest | 0.1140581 |
| choice_prop_raw  | tree   | 0.1503692 |
| choice_prop_UMAP | tree   | 0.1635244 |
| choice_prop_raw  | tree   | 0.1517872 |
| choice_prop_raw  | glmm   | 0.3715021 |
| choice_prop_UMAP | glmm   | 5.1819947 |
| choice_prop_raw  | glmm   | 0.3059119 |

<div id="refs" class="references csl-bib-body hanging-indent"
entry-spacing="0">

<div id="ref-vanlissaWORCSWorkflowOpen2021" class="csl-entry">

Van Lissa, Caspar J., Andreas M. Brandmaier, Loek Brinkman, Anna-Lena
Lamprecht, Aaron Peikert, Marijn E. Struiksma, and Barbara M. I. Vreede.
2021. “WORCS: A Workflow for Open Reproducible Code in Science.” *Data
Science* 4 (1): 29–49. <https://doi.org/10.3233/DS-210031>.

</div>

</div>
