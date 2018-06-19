#### A few updates to spatial files to make them easier to use
library(dplyr)
library(sf)
library(fasterize)

source('src/R/common.R')
source('src/R/spatial_common.R')
### 3nm offshore file

rgns_3nm <- sf::st_read(file.path(dir_M, "git-annex/globalprep/spatial/d2014/data"), "regions_offshore3nm_mol") 


rgns_3nm_final <- rgns_3nm %>%
  dplyr::filter(sp_type == "eez") %>%
  dplyr::group_by(rgn_id) %>%
  dplyr::summarise(geometry = st_union(geometry)) %>%
  dplyr::ungroup()


## get additional data to add to sf object
regions_df <- regions %>% st_set_geometry(NULL) %>%
  filter(type_w_ant == "eez") %>%
  select(rgn_id, rgn_name)

rgns_3nm_final_final <- rgns_3nm_final %>%
  left_join(regions_df, by="rgn_id")

# save simple feature object
st_write(rgns_3nm_final_final, dsn=file.path(dir_M, "git-annex/globalprep/spatial/v2018/rgns_3nm_mol.shp"), delete_layer = TRUE)


### create a raster of simple feature object
# first need to save geomtry type as a MULTIPOLYGON
sort(st_geometry_type(rgns_3nm_final_final))
rgns_3nm_final_final <- st_cast(rgns_3nm_final_final, "MULTIPOLYGON")

raster_3nm_rgns <- fasterize(rgns_3nm_final_final, ocean, field="rgn_id")
raster::writeRaster(raster_3nm_rgns, file.path(dir_M, "git-annex/globalprep/spatial/v2018/rgns_3nm_offshore_mol.tif"))

#save a generic version without region ID         
raster_3nm <- fasterize(rgns_3nm_final_final, ocean)
raster::writeRaster(raster_3nm, file.path(dir_M, "git-annex/globalprep/spatial/v2018/three_nm_offshore_mol.tif"))
