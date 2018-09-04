## Ocean Health Index 2017: Fisheries Sub-goal

See full details for how the SAUP catch data was prepped [here](https://cdn.rawgit.com/OHI-Science/ohiprep/master/globalprep/fis/v2017/catch_data_prep.html).

See full details for how BBmsy was calculated [here](https://cdn.rawgit.com/OHI-Science/ohiprep/master/globalprep/fis/v2017/calculate_bbmsy.html).

If using these data, please see our [citation policy](http://ohi-science.org/citation-policy/).



### Additional information
A description of files:

* clean_cells.Rmd: cleans up the half-degree cell data, removing overlaps between land and oceanic regions, and calculates the total proportion of each cell within each OHI region. The output of this script is `cells.csv`

* catch_data_prep.Rmd: Preps the spatialized catch data (at half degree cells) for use in goal weighting and stock status calculations. Auxiliary prep file, **catch_taxon_key.Rmd** (below). Outputs:
  
   - `git-annex/globalprep/fis/v2017/int/stock_catch_by_rgn.csv`
   - `data/stock_catch.csv`
   - `data/mean_catch.csv`
   - `data/FP_fis_catch.csv`

* catch_taxon_key.Rmd: Adds taxon key information from 2017 Watson data into 2018 Watson data so we can prepare catch for B/Bmsy calculations in main prep file, **catch_data_prep.Rmd** (above).
 
   - `int/watson_taxon_key.csv`: unique taxon key extracted from 2017 Watson data

* calculate_bbmsy.Rmd: Calculates B/Bmsy estimates for all stocks using catch-MSY. Outputs:
  
  - `data/cmsy_bbmsy.csv`
    
* RAM_data_prep.Rmd: Prepares the RAM B/Bmsy data by gapfilling RAM data and identifying which FAO/OHI regions each RAM stock is present. Auxiliary prep file, **fao_ohi_rgns.Rmd** (below). Outputs:

  - `int/ram_stock_bmsy_gf.csv`
  - `int/RAM_fao_ohi_rgns.csv`
  - `int/ram_bmsy.csv`

* fao_ohi_rgns.Rmd: Adds FAO and OHI region IDs to newly added stocks with no spatial information. Serves as documentation and only needed if adding new stocks without existing region identification. Main prep file, **RAM_data_prep.Rmd** (above).

  - `int/RAM_fao_ohi_rgns.csv`
  

* RAM_CMSY_combine.Rmd: Combines the B/Bmsy values from the RAM and CMSY data, with preference given to RAM data.
 
   - `int/cmsy_b_bmsy_mean5yrs.csv`
   - `data/fis_bbmsy_gf.csv`
   - `data/fis_bbmsy.csv`

