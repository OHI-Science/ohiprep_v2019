##May 2016- sept 2016
######code to aproximate country level production
########regression inputs from VBGF_Fish.r

# This is a heavily modified script from KNB:
# https://knb.ecoinformatics.org/view/doi:10.5063/F1CF9N69

# From this paper:
# https://www.nature.org/content/dam/tnc/nature/en/documents/Mapping_the_global_potential_for_marine_aquaculture.pdf


### libraries useful for data wrangling
library(dplyr)
library(tidyr)

## libraries useful for spatial data
library(raster)       
library(rgdal)        
library(sf)         
library(fasterize)

## data visualization
library(RColorBrewer)
library(ggplot2)
library(rasterVis)    
library(maps)

## path management
library(here)


## some OHI files
source('http://ohi-science.org/ohiprep_v2019/workflow/R/common.R')

## MRF: is this extra stuff...if unnecessary cut from script
###this it output file that corresponds to this analysis (from the original paper)
# takes all constraints into consideration
PhiAreaChlDF<-read.csv(here("globalprep/mar/v2019/reference_point/TableDataOutputs/FinalNoHypox/CountryProdPotentialLT12.csv"))
head(PhiAreaChlDF)
str(PhiAreaChlDF)



## Variables needed to get from PHI to tonnes of production
## MRF: assumes 1 farm is 1km2  ##
# (seems easier to just units of km2, rather than farm)

F_estCoef <- c(7.6792, (-5.8198)) #from regression estimated in VBGF_Fish_Final.r
B_estCoef <- c(2.9959,(-1.6659)) #from regression estimate in VBGF_Bivalves.r
density <- 20 #juveniles per m3
cagesize <- 9000 #m3
cagesperfarm <- 24 #located atleast 1 km apart...MRF: seems like units should be cagesperkm2
bivperfarm <- 130000000 #MRF: again, should units should be bivperkm2?
weight35cm <- 554.8  ## in grams see VBGF_Fish_Final  


## Global tiff file of PHI estimates

FishPhiALLConstraints <- raster(file.path(dir_M, "git-annex/globalprep/mar/v2019/Spatial_Data/NewLayersWOHypoxia/FishPhiALLConstraints95LT2.tiff"))
plot(FishPhiALLConstraints)
FishPhiVector=getValues(FishPhiALLConstraints)


## Convert PHI raster to number of years it takes to grow a 35 cm fish

LogFishYears <- calc(FishPhiALLConstraints, fun=function(x){F_estCoef[1]+F_estCoef[2]*log(x)})
LogFishYears
plot(LogFishYears)

FishYears <- calc(LogFishYears, fun=function(x){exp(x)})

FishYears
plot(FishYears)
writeRaster(FishYears,file.path(dir_M, "git-annex/globalprep/mar/v2019/Spatial_Data/NewLayersWOHypoxia/FishYearsbyCell.tif"), overwrite=TRUE)

FishYearsVector=getValues(FishYears)



#OHI 2018 regions (original analysis used older regions file)

## call spatial file from sourced file
regions_shape()

OHIcountries <- regions %>%
  filter(type_w_ant == "eez")

OHIcountries <- st_transform(OHIcountries, crs(FishPhiALLConstraints))

OHIcountries_raster <- fasterize(OHIcountries, FishPhiALLConstraints, field="rgn_id")  

CountryVector=getValues(OHIcountries_raster)




### area of each cell (each cell is different given lat/long coordinate reference system)
areaPerCell <- area(FishPhiALLConstraints, weights=FALSE, na.rm=TRUE)

areaPerCellVector <- getValues(areaPerCell)



### Make a dataframe with raster values that includes cells: Country, area, Phi, and Years to Harvest
productionDF <- data.frame(CellID = 1:933120000,
                           Country = CountryVector,
                           AreaKM2 = areaPerCellVector,
                           PhiPrime = FishPhiVector, 
                           YearsToHarvest = FishYearsVector)

head(productionDF)

summary(FishYearsVector)
summary(areaPerCellVector) ##they seem to match




## calculate production for each cell
productionDFFishCells <- productionDF %>%
  filter(!is.na(YearsToHarvest)) %>%
  mutate(F_yieldperfarmMT = (weight35cm * density * cagesize * cagesperfarm)/1000000) %>%  # MRF: units fieldperkm2?
  mutate(F_yieldpercellperyear = (F_yieldperfarmMT/YearsToHarvest) * AreaKM2) %>%
  arrange(YearsToHarvest) %>%
  mutate(YieldCumSum = cumsum(F_yieldpercellperyear)) %>%
  mutate(AreaCumSum = cumsum(AreaKM2))


head(productionDFFishCells)
summary(productionDFFishCells)
str(productionDFFishCells)
##cumsum area is 11,402,629 km2 -  
##cumprod is 15,950,000,000MT -  

### how many of these cells are not in a country?
sum(is.na(productionDFFishCells$Country))
dim(productionDFFishCells)

##293,702 are not in a country out of 15,639,851 total.  that is 1.9%
## MRF: with new OHI regions: 544,569 are not in a country..probably a lot are in conflicted areas


## Calculate production if 1% of top production area is used:
productionByCountryFishDF <- productionDFFishCells %>%
  filter(!is.na(Country)) %>%
  dplyr::select(-YieldCumSum, -AreaCumSum) %>%
  arrange(YearsToHarvest) %>%
  mutate(ID = Country) %>%
  dplyr::arrange(ID) %>%
  group_by(ID) %>%
  mutate(CountryYieldCumSum = cumsum(F_yieldpercellperyear)) %>%
  mutate(CountryAreaCumSum = cumsum(AreaKM2)) %>%
  mutate(MaxProdPerCountry = max(CountryYieldCumSum)) %>% 
  mutate(OnePercentDevPerCountry = .01*max(CountryAreaCumSum)) #calculating 1 percent of area


## MRF: For each area identify amount of area that corresponds to 1% of production area, 
## MRF: assume maximum production within the country for the 1% of area
CountryProdSummary <- productionByCountryFishDF %>%
  dplyr::arrange(YearsToHarvest) %>%
  dplyr::arrange(ID) %>%
  group_by(ID) %>%
  filter(CountryAreaCumSum <= OnePercentDevPerCountry) %>%
  mutate(ProdPerCountryOnePercent = max(CountryYieldCumSum)) %>%
  slice(1)

# MRF: get fasted YearsToHarvest for each country
CountryProdSummaryNop <- productionByCountryFishDF %>%
  dplyr::arrange(YearsToHarvest) %>%
  dplyr::arrange(ID) %>%
  group_by(ID) %>%
  slice(1)



# Add country names

region_data()
CountryLabel <- rgns_eez %>%
  dplyr::select(ID = rgn_id, rgn_name)


## Final data
## I think the relevant value we want for the reference point is in this table:  ProdPerCountryOnePercent
CountryProdSummaryFAO <- CountryProdSummary %>%
  ungroup %>%
  dplyr::select(ID:ProdPerCountryOnePercent) %>%
  full_join(CountryLabel, by= "ID")


###how much space would be needed to replace all capture fisheries 2014
###(93.4 million tonnes according to the SWFA 2016)

spaceFishRep <- productionDFFishCells %>%
  filter(YieldCumSum>93400000)

#area sum is 53,135 km2
## ocean area is  361.9 million square kilometers

53135/361900000
#= less than 0.015% of ocean area to produce the amount captured by wild capture fisheries




## MRF: didn't run the bivalve portion, but this needs to be done.....
##Now for Bivalves 
BivalvePhiALLConstraints=raster("~/Spatial_Data/LayerStacks/BivalvePhiALLConstraints95LT1.tif")

plot(BivalvePhiALLConstraints)
BivalvePhiVector=getValues(BivalvePhiALLConstraints)



#OHI2012 Countries
OHIcountries=raster("~/Spatial_Data/country data/OHI2012/regions.tif")
OHIcountries
OHIcountriesLatLong = projectRaster(OHIcountries,FishPhiALLConstraints)

OHIcountriesLatLong

CountryVector=getValues(OHIcountriesLatLong)

mutate(B_estLogyears4cm=B_estCoef[1]+B_estCoef[2]*bivalvephiavg)%>%
  mutate(B_estyears4cm=exp(B_estLogyears4cm))
#make the value of each cell the years it takes to grow a 4 cm bivlave
LogBivalveYears=calc(BivalvePhiALLConstraints, fun=function(x){B_estCoef[1]+B_estCoef[2]*(x)})
LogBivalveYears
plot(LogBivalveYears)

BivalveYears=calc(LogBivalveYears,fun=function(x){exp(x)})

BivalveYears
plot(BivalveYears)
writeRaster(BivalveYears,'Spatial_Data/production data/BivalveYearsbyCell.tif', overwrite=TRUE)

BivalveYears=raster('Spatial_Data/production data/FishYearsbyCell.tif')

BivalveYearsVector=getValues(BivalveYears)


###now load in area values for each cell
areaPerCell=raster("Spatial_Data/MiddleFiles/AreaBivalveLT1.grd")
areaPerCell

areaPerCellVector=getValues(areaPerCell)


productionDFBiv=data.frame(CellID=1:933120000,Country=CountryVector,AreaKM2=areaPerCellVector,PhiPrime=BivalvePhiVector, YearsToHarvest=BivalveYearsVector)

head(productionDFBiv)

productionDFBivCells=productionDFBiv%>%
  filter(!is.na(YearsToHarvest))%>%
  mutate(B_yieldperfarmInd=bivperfarm)%>%
  mutate(B_yieldpercellperyear=(B_yieldperfarmInd/YearsToHarvest)*AreaKM2)%>%
  arrange(YearsToHarvest)%>%
  mutate(YieldCumSum=cumsum(B_yieldpercellperyear))%>%
  mutate(AreaCumSum=cumsum(AreaKM2))

head(productionDFBivCells)
write.csv(productionDFBivCells,file="~/TableDataOutputs/BivProdByCell.csv")          
productionDFBivCells=read.csv("~/TableDataOutputs/BivProdByCell")

head(productionDFBivCells)
summary(productionDFBivCells)
str(productionDFBivCells)

productionByCountryBivDF=productionDFBivCells%>%
  filter(!is.na(Country))%>%
  dplyr::select(-YieldCumSum)%>%
  dplyr::select(-AreaCumSum)%>%
  arrange(YearsToHarvest)%>%
  mutate(ID=Country)%>%
  dplyr::arrange(ID)%>%
  group_by(ID)%>%
  mutate(CountryYieldCumSum=cumsum(B_yieldpercellperyear))%>%
  mutate(CountryAreaCumSum=cumsum(AreaKM2))%>%
  mutate(MaxPhi=max(PhiPrime))%>%
  mutate(averagePhi=mean(PhiPrime))%>%
  mutate(averageWeightedPhi=sum(PhiPrime*AreaKM2)/(max(CountryAreaCumSum)))%>%
  mutate(MaxDevPerCountry=max(CountryAreaCumSum)) %>%
  mutate(MaxProdPerCountry=max(CountryYieldCumSum))%>%
  mutate(OnePercentDevPerCountry=.01*max(CountryAreaCumSum))


head(productionByCountryBivDF)
write.csv(productionByCountryBivDF,file="~/TableDataOutputs/BivProdByCountryByCell.csv")



CountryProdSummary=productionByCountryBivDF%>%
  filter(CountryAreaCumSum<=OnePercentDevPerCountry) %>%
  mutate(ProdPerCountryOnePercent=max(CountryYieldCumSum)) %>%
  slice(1)

write.csv(CountryProdSummary,file="~/TableDataOutputs/Final/BivalveProdByCountrySummary.csv")


CountryProdPhiFAO= read.csv("~/TableDataOutputs/FinalNoHypox/CountryProdPhiFAOLT12.csv")
head(CountryProdPhiFAO)

CountryLabel=CountryProdPhiFAO%>%
  dplyr::select(ID:LABEL, MarFishProdMT, MarMolluscProdMT)

head(CountryLabel)

CountryProdSummaryFAO=CountryProdSummary%>%
  ungroup%>%
  dplyr::select(ID:ProdPerCountryOnePercent)%>%
  full_join(CountryLabel, by= "ID")

write.csv(CountryProdSummaryFAO,file="~/TableDataOutputs/Final/BivalveProdByCountryFAOSummary.csv")


###making stats for paper.
#ocean area is 360 million square kilometers
#current wild landings (including both sea and fresh water and 93.4 million MT)




#Calculate Average years for each country
#FishYearsAveragebyCountry=zonal(FishYears,OHIcountriesLatLong,fun='mean',na.rm=TRUE)
#head(FishYearsAveragebyCountry)
#colnames(FishYearsAveragebyCountry)= c("ID", "fishyearsavg")
###this doesnt make sense because each cell is not the same size