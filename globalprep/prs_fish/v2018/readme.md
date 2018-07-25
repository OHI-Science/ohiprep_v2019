# Commercial Fishing Stressors Data Prep

- `prs_fish_dataprep.Rmd` main data prep file
- `data_download.R` downloads new data from the Watson website
- `explore_watson_data.Rmd` explores the Watson data


- `watson_gear_matching.Rmd` takes the raw data from Watson (2018) and assigns gear & species specific information to each record to allow mapping of the five commercial fishing stressors.
- `annual_catch.Rmd` creates annual rasters of catch for each of the 5 fishing categories
- `npp.Rmd` sources `vgpm_fun.R` to create annual net primary production rasters
- `create_layers.Rmd` takes each of the annual catch rasters and divides by npp.