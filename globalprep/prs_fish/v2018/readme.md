# Commercial Fishing Stressors
- `data_download.R` downloads the data from the Watson website
- `watson_gear_matching.Rmd` takes the raw data from Watson (2017) and assigns gear & species specific information to each record to allow mapping of the five commercial fishing stressors.
- `annual_catch.Rmd` creates annual rasters of catch for each of the 5 fishing categories
- `npp.Rmd` sources `vgpm_fun.R` to create annual net primary production rasters
- `create_layers.Rmd` takes each of hte annual catch rasters and divides by npp.