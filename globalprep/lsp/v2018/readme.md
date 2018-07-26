## Ocean Health Index: Lasting Special Places (LSP) v2016

See full data prep details [here](https://rawgit.com/OHI-Science/ohiprep/master/globalprep/lsp/v2017/lsp_data_prep.html).

If using these data, please see our [citation policy](http://ohi-science.org/citation-policy/).

Data preparation:
* `1_prep_wdpa_rast.Rmd` converts the raw WDPA data into raster
* `lsp_data_prep.Rmd` prepares the raster so it's ready for processing into the ohi-global toolbox. Any gapfilling and resilience calculation is completed here as well.

Data checking:
* `check_updates.Rmd` is a script for additional data checking of score changes from last year's assessment
* `datacheck` folder contains intermediate shapefiles or data tables for viewing in ArcGIS after completing data prep