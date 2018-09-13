## Ocean Health Index: Lasting Special Places (LSP) 

See full data prep details [here](https://rawgit.com/OHI-Science/ohiprep_v2018/master/globalprep/lsp/v2018/lsp_data_prep.html).

If using these data, please see our [citation policy](http://ohi-science.org/citation-policy/).

### Layers Created

* Coastal protected marine areas (fishing preservation) (fp_mpa_coast)
* EEZ protected marine areas (fishing preservation) (fp_mpa_eez)
* Coastal protected marine areas (habitat preservation) (hd_mpa_coast)
* EEZ protected marine areas (habitat preservation) (hd_mpa_eez)
* Inland coastal protected areas (lsp_prot_area_inland1km)
* Offshore coastal protected areas (lsp_prot_area_offshore3nm)
* Inland area (rgn_area_inland1km)
* Offshore area (rgn_area_offshore3nm)

### Prep Files

* `1_prep_wdpa_rast.Rmd` converts the raw WDPA data into raster
* `lsp_data_prep.Rmd` prepares the raster so it's ready for processing into the ohi-global toolbox. Any gapfilling and resilience calculation is completed here as well.

### Data Check Files

* `check_updates.Rmd` is a script for additional data checking of score changes from last year's assessment
