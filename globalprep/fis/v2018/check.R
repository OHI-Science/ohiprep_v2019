## catch is 2015 watson catch data - lack of taxon key this year, trying to figure out way to filter for species-specific values

catch_key <- catch %>% 
  mutate(TaxonLength = str_length(TaxonName)) %>% 
  arrange(TaxonLength)


head(catch_key)


saup_cells <- getcells("POLYGON ((-180 90,-180 -90, 180 -90, 180 90, -180 90))")
saup_rast <- raster(ncol=720, nrow=360)
saup_rast[] <- saup_cells
plot(saup_rast)

plot(watson_rast)

diff <- overlay(saup_rast, watson_rast, fun=function(x,y){x-y})
diff_values <- getValues(diff)
## rasters are the same, all values are 0 after subtracting



## Check old cells.csv v new cells.csv

# First check the creation of ohi region matching - new all_df has more rows 446 more

all_df <- read.csv(file.path(dir_M, "git-annex/globalprep/fis/v2018/raw/watson_rasters_to_ohi_rgns.csv"))
old_all_df <- read.csv(file.path(dir_M, "git-annex/globalprep/fis/v2015/raw/saup_rasters_to_ohi_rgns.csv"))
dim(all_df) 
dim(old_all_df)