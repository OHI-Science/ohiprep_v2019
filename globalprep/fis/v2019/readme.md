## Ocean Health Index: Fisheries Sub-goal (FIS)

See full details for how the Watson catch data was prepped [here](https://raw.githack.com/OHI-Science/ohiprep_v2019/gh-pages/globalprep/fis/v2019/catch_data_prep.html).

See full details for how BBmsy was calculated [here](https://raw.githack.com/OHI-Science/ohiprep_v2019/gh-pages/globalprep/fis/v2019/calculate_bbmsy.html).

See full details for how RAM data was prepped
[here RAM dataprep](https://raw.githack.com/OHI-Science/ohiprep_v2019/gh-pages/globalprep/fis/v2019/RAM_data_prep.html)
[here RAM_CMSY](https://raw.githack.com/OHI-Science/ohiprep_v2019/gh-pages/globalprep/fis/v2019/RAM_CMSY_combine.html)


If using these data, please see our [citation policy](http://ohi-science.org/citation-policy/).

### Layers Created

* B/Bmsy estimates (fis_b_bmsy)
* Fishery catch data (fis_meancatch)

### Additional information
A description of files:

* clean_cells.Rmd: cleans up the half-degree cell data, removing overlaps between land and oceanic regions, and calculates the total proportion of each cell within each OHI region. The output of this script is `cells.csv`

* catch_data_prep.Rmd: Preps the spatialized catch data (at half degree cells) for use in goal weighting and stock status calculations. Auxiliary prep file, **species_resilience_lookup_table.Rmd**: Uses FishBase to find the Resilience for each of the species in the Watson database. The Resilience information is needed for running catch-MSY to estimate B/Bmsy. Outputs:
  
   - `git-annex/globalprep/fis/v2019/int/stock_catch_by_rgn.csv`
   - `int/watson_taxon_key_v2019.csv`
   - `output/stock_catch.csv`
   - `output/mean_catch.csv`
   - `output/FP_fis_catch.csv`
   - `output/taxon_resilience_lookup.csv`
   

* calculate_bbmsy.Rmd: Calculates B/Bmsy estimates for all stocks using catch-MSY (CMSY) developed by Martell and Froese (2012). Outputs:
  
  - `output/cmsy_bbmsy.csv`
   
    
* RAM_data_prep.Rmd: Prepares the RAM B/Bmsy data by gapfilling RAM data and identifying which FAO/OHI regions each RAM stock is present. Auxiliary prep file, **fao_ohi_rgns.Rmd**: adds FAO and OHI region IDs to newly added stocks with no spatial information (creates `int/RAM_fao_ohi_rgns.csv`). Outputs:

  - `int/ram_stock_bmsy_gf.csv`
  - `int/RAM_fao_ohi_rgns.csv`
  - `int/ram_bmsy.csv`


* RAM_CMSY_combine.Rmd: Combines the B/Bmsy values from the RAM and CMSY data, with preference given to RAM data.
 
   - `int/cmsy_b_bmsy_mean5yrs.csv`
   - `output/fis_bbmsy_gf.csv`
   - `output/fis_bbmsy.csv`


A description of data check files:

* data_check.Rmd: Checks data discrepancies after completing data preparation scripts. All the files in `datacheck` folder are created in this script.


* check_scores.R: Checks discrepancies in scores after adding FIS layers to ohi-global