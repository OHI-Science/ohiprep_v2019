######################################################################################################################
## Describes preparation of spatial files
######################################################################################################################

pkgs <- c("maptools","gridExtra","maps","gpclib","animation","plyr","reshape2","sf")
new_pkg <- pkgs[!pkgs %in% installed.packages()]
if (length(new_pkg)){install.packages(new_pkg)}
lapply(pkgs, require, character.only = TRUE)

source("../../../src/R/common.R") # directory locations (dir_M)
source("../../../src/R/spatial_common.R")

######################################################################################################################
## ArcGIS processes:
##
## For the North pole: transformed this file: N:/model/GL-NCEAS-OceanRegions_v2013a/data/rgn_fao_gcs
## to the coordinate systems used in the shp files located in the "Testing old data" 
## and saved in folder: n_type_rgns_pts to get N:/git-annex/globalprep/_raw_data/NSIDC_SeaIc/v2015/raw/New_n_rgn_fao

n_rgn_crs <- ## testing old data shape files crs.../
## from hab_seaice_dataprep (v2018)  
prj_n = "+proj=stere +lat_0=90 +lat_ts=70 +lon_0=-45 +k=1 +x_0=0 +y_0=0 +a=6378273 +b=6356889.449 +units=m +no_defs"
prj_s = "+proj=stere +lat_0=-90 +lat_ts=-70 +lon_0=0 +k=1 +x_0=0 +y_0=0 +a=6378273 +b=6356889.449 +units=m +no_defs"
prj_mol = "+proj=moll +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs"

oceanregions_fao_gcs <- st_read(file.path(dir_M, "../model/GL-NCEAS-OceanRegions_v2013a/data/rgn_fao_gcs.shp"))
st_transform()



## The South pole (to get CCAMLR regions) was based on: ohi/git-annex/Global/NCEAS-Regions_v2014/data/sp_gcs

## The south pole was updated to reflect the CCAMLR regions, but the North pole should be the same, hence the
## two different starting spatial datasets.
######################################################################################################################

## Preparing the south pole data from the Antarctica project
s_pole <- st_read(file.path(dir_M, "model/GL-AQ-SeaIce_v2014/raw/sp_s")) %>% 
  dplyr::filter(sp_type %in% c("eez", "eez-ccamlr", "fao"))

# s_pole <- readOGR(file.path(dir_neptune_data, "model/GL-AQ-SeaIce_v2014/raw"), layer="sp_s")
# s_pole <- s_pole[s_pole$sp_type %in% c("eez", "eez-ccamlr", "fao"), ]

head(s_pole) # feel for naming protocols
s_pole %>% dplyr::filter(sp_type == "eez-ccamlr")
s_pole %>% dplyr::filter(sp_type == "fao")
s_pole %>% duplicated(rgn_id)

# s_pole@data[s_pole$sp_type == "eez-ccamlr",]
# s_pole@data[s_pole$sp_type == "fao",]
# s_pole@data[duplicated(s_pole$rgn_id),]

## in general, use rgn_id, but use the sp_id for ccamlr regions
s_pole <- s_pole %>% dplyr::mutate(rgn_id = ifelse("eez-ccamlr", sp_id, rgn_id))
# s_pole@data$rgn_id <- ifelse(s_pole@data$sp_type == "eez-ccamlr", s_pole@data$sp_id, s_pole@data$rgn_id)

## need to merge matching polygons so the same id is only repeated once
s_pole_union <- s_pole %>% dplyr::group_by(rgn_id) %>% st_union()
s_pole_data <- s_pole %>% 
  dplyr::select(sp_type, rgn_id, rgn_name, rgn_key, area_km2) %>% 
  dplyr::group_by(sp_type, rgn_id, rgn_name, rgn_key) %>%
  dplyr::summarise(area_km2 = sum(area_km2)) %>% data.frame()

# s_pole_union <- unionSpatialPolygons(s_pole, s_pole$rgn_id)
# s_pole_data <- s_pole@data %>%
#   select(sp_type, rgn_id, rgn_name, rgn_key, area_km2) %>%
#   group_by(sp_type, rgn_id, rgn_name, rgn_key) %>%
#   summarize(area_km2=sum(area_km2))
row.names(s_pole_data) <- as.character(s_pole_data$rgn_id)
s_pole_data <- data.frame(s_pole_data)

s_pole_union <- SpatialPolygonsDataFrame(s_pole_union, s_pole_data)
s_pole_union@data <- s_pole_union@data %>%
  select(rgn_typ=sp_type, rgn_id, rgn_nam=rgn_name, rgn_key) # realized the area might be deceptive because I think some of the northern regions are not included.

#writeOGR(s_pole_union, file.path(dir_M, "git-annex/globalprep/_raw_data/NSIDC_SeaIce/v2015/raw"), layer="New_s_rgn_fao", driver="ESRI Shapefile")
# new_s_pole <- readOGR(file.path(dir_M, "git-annex/globalprep/_raw_data/NSIDC_SeaIce/v2015/raw"), layer="New_s_rgn_fao")

st_write(s_pole_union, layer=file.path(dir_M, "git-annex/globalprep/_raw_data/NSIDC_SeaIce/v2015/raw/New_s_rgn_fao.shp"), 
         driver="ESRI Shapefile")
new_s_pole <- st_read(file.path(dir_M, "git-annex/globalprep/_raw_data/NSIDC_SeaIce/v2015/raw"), 
                      layer="New_s_rgn_fao.shp")

######################################################################################################################
## Next steps:

## The next step is actually embedded in the "ObtainingData.R" script.  If the spatial points file is not there, it creates one.
## This would make more sense in this file, but it requires loading a lot of the NSDIC data first to use as a template.\
##
## I think the best bet is to do this in a step-wise fashion: 
##     1) walk through the script and check the output spatial file
##     2) then run the sea ice collection
##
######################################################################################################################
