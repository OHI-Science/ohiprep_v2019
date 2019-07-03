##May 2016- sept 2016
######code to aproximate country level production
########regression inputs from VBGF_Fish.r

# https://knb.ecoinformatics.org/view/doi:10.5063/F1CF9N69
# https://www.nature.org/content/dam/tnc/nature/en/documents/Mapping_the_global_potential_for_marine_aquaculture.pdf


###librarys useful for data wrangling
library(dplyr)
library(tidyr)
##libraries useful for raster analysis

library(raster)       
library(rgdal)        
library(rasterVis)    
library(maps)         

library(RColorBrewer)
library(ggplot2)

library(here)

#set tmp directory
tmpdir='Big'
dir.create(tmpdir, showWarnings=F)
rasterOptions(tmpdir=tmpdir)

###this it output from final spatial analysis taking into consideration all constraints
##sorted by OHI country
PhiAreaChlDF<-read.csv(here("TableDataOutputs/FinalNoHypox/CountryProdPotentialLT12.csv"))

## MRF: Can't find this specific file...ignore for now, probably separate files
###this is 2013 FAO marine production fixed so that it matches OHI countries.  see FAOCountriesMarineProd2013.xlsx doc
OHIProdDF<-read.csv("/Spatial_Data/country data/FAOCountriesMarineProd2013OHI.csv")

head(PhiAreaChlDF)
str(PhiAreaChlDF)
head(OHIProdDF)
str(OHIProdDF)

##get rid of extra columns in OHIProdDF
#OHIProdDF= OHIProdDF %>% select(OHI_Countries, ID, MarFishProdMT,MarMolluscProdMT)
#head(OHIProdDF)

##join the datasets by ID
ProdPhiAreaChlDFALL= full_join(PhiAreaChlDF,OHIProdDF,by="ID")
head(ProdPhiAreaChlDFALL)
str(ProdPhiAreaChlDFALL)
write.csv(ProdPhiAreaChlDFALL,"TableDataOutputs/FinalNoHypox/CountryProdPhiFAOLT12.csv")



####read in data

CountryProdPhiFAO= read.csv("~/TableDataOutputs/FinalNoHypox/CountryProdPhiFAOLT12.csv")
head(CountryProdPhiFAO)
F_estCoef=c(7.6792, (-5.8198)) #from regression estimated in VBGF_Fish_Final.r
B_estCoef=c(2.9959,(-1.6659)) #from regression estimate in VBGF_Bivalves.r
density=20 #juveniles per m3
cagesize=9000 #m3
cagesperfarm=24 #located atleast 1 km apart
bivperfarm=130000000
weight35cm= 554.8  ## in grams see VBGF_Fish_Final  

FishPhiALLConstraints=raster(here("Spatial_Data/NewLayersWOHypoxia/FishPhiALLConstraints95LT2.tiff"))
plot(FishPhiALLConstraints)
FishPhiVector=getValues(FishPhiALLConstraints)
#make the value of each cell the years it takes to grow a 35 cm fish

#OHI2012 Countries
OHIcountries=raster("~/Spatial_Data/country data/OHI2012/regions.tif")
OHIcountries
OHIcountriesLatLong = projectRaster(OHIcountries,FishPhiALLConstraints,
                                    filename="~/Spatial_Data/MiddleFiles/OHICountriesLatLong.tif")

#OHIcountriesLatLong=raster("~/Spatial_Data/MiddleFiles/OHICountriesLatLong.tif")
OHIcountriesLatLong

CountryVector=getValues(OHIcountriesLatLong)


LogFishYears=calc(FishPhiALLConstraints, fun=function(x){F_estCoef[1]+F_estCoef[2]*log(x)})
LogFishYears
plot(LogFishYears)

FishYears=calc(LogFishYears,fun=function(x){exp(x)})

FishYears
plot(FishYears)
writeRaster(FishYears,'Spatial_Data/NewLayersWOHypoxia/production data/FishYearsbyCell.tif', overwrite=TRUE)

#FishYears=raster('Spatial_Data/NewLayersWOHypoxia/production data/FishYearsbyCell.tif')


##dims of raster are 21600, 43200, 933120000  (nrow, ncol, ncell); lets try to get it in chunks
FishYearsVector=getValues(FishYears)


###now load in area values for each cell
areaPerCell=raster("Spatial_Data/NewLayersWOHypoxia/MiddleLayers/AreaFishLT2.tif")
areaPerCell

areaPerCellVector=getValues(areaPerCell)


productionDF=data.frame(CellID=1:933120000,Country=CountryVector,AreaKM2=areaPerCellVector,PhiPrime=FishPhiVector, YearsToHarvest=FishYearsVector)

summary(FishYearsVector)
summary(areaPerCellVector)##they seem to match

head(productionDF)

productionDFFishCells=productionDF%>%
  filter(!is.na(YearsToHarvest))%>%
  mutate(F_yieldperfarmMT=(weight35cm*density*cagesize*cagesperfarm)/1000000)%>%
  mutate(F_yieldpercellperyear=(F_yieldperfarmMT/YearsToHarvest)*AreaKM2)%>%
  arrange(YearsToHarvest)%>%
  mutate(YieldCumSum=cumsum(F_yieldpercellperyear))%>%
  mutate(AreaCumSum=cumsum(AreaKM2))


head(productionDFFishCells)
write.csv(productionDFFishCells,file="~/TableDataOutputs/FinalNoHypox/FishProdByCellHDen.csv")          

productionDFFishCells=read.csv("~/TableDataOutputs/FinalNoHypox/FishProdByCellHDen.csv")
productionDFFishCellsOld=read.csv("~/TableDataOutputs/FinalNoHypox/FishProdByCell.csv")


head(productionDFFishCells)
summary(productionDFFishCells)
str(productionDFFishCells)
##cumsum area is 11,402,629 km2 -  
##cumprod is 15,950,000,000MT -  

### how many of these cells are not in a country?
sum(is.na(productionDFFishCells$Country))
dim(productionDFFishCells)

##293,702 are not in a country out of 15,639,851 total.  that is 1.9%



productionByCountryFishDF=productionDFFishCells%>%
  filter(!is.na(Country))%>%
  dplyr::select(-YieldCumSum)%>%
  dplyr::select(-AreaCumSum)%>%
  arrange(YearsToHarvest)%>%
  mutate(ID=Country)%>%
  dplyr::arrange(ID)%>%
  group_by(ID)%>%
  mutate(CountryYieldCumSum=cumsum(F_yieldpercellperyear))%>%
  mutate(CountryAreaCumSum=cumsum(AreaKM2))%>%
  mutate(MaxPhi=max(PhiPrime))%>%
  mutate(averagePhi=mean(PhiPrime))%>%
  mutate(averageWeightedPhi=sum(PhiPrime*AreaKM2)/(max(CountryAreaCumSum)))%>%
  mutate(MaxDevPerCountry=max(CountryAreaCumSum)) %>%
  mutate(MaxProdPerCountry=max(CountryYieldCumSum))%>%
  mutate(OnePercentDevPerCountry=.01*max(CountryAreaCumSum))


head(productionByCountryFishDF)
write.csv(productionByCountryFishDF,file="~/TableDataOutputs/FinalNoHypox/FishProdByCountryByCellHDen.csv")
productionByCountryFishDF=read.csv("~/TableDataOutputs/FinalNoHypox/FishProdByCountryByCellHDen.csv")


productionByCountryFishDFOld=read.csv("~/TableDataOutputs/FinalNoHypox/FishProdByCountryByCell.csv")
#full_join(CountryLabel, by= "Country")%>%

CountryProdSummary=productionByCountryFishDF%>%
  arrange(YearsToHarvest)%>%
  dplyr::arrange(ID)%>%
  group_by(ID)%>%
  filter(CountryAreaCumSum<=OnePercentDevPerCountry) %>%
  mutate(ProdPerCountryOnePercent=max(CountryYieldCumSum)) %>%
  slice(1)

CountryProdSummaryNop=productionByCountryFishDF%>%
  dplyr::arrange(YearsToHarvest)%>%
  dplyr::arrange(ID)%>%
  group_by(ID)%>%
  slice(1)

CountryProdSummaryOld=productionByCountryFishDFOld%>%
  arrange(YearsToHarvest)%>%
  dplyr::arrange(ID)%>%
  group_by(ID)%>%
  filter(CountryAreaCumSum<=OnePercentDevPerCountry) %>%
  mutate(ProdPerCountryOnePercent=max(CountryYieldCumSum)) %>%
  slice(1)

write.csv(CountryProdSummary,file="~/TableDataOutputs/FinalNoHypox/FishProdByCountrySummaryHDen.csv")


CountryProdPhiFAO= read.csv("~/TableDataOutputs/FinalNoHypox/CountryProdPhiFAOLT12.csv")
head(CountryProdPhiFAO)

CountryLabel=CountryProdPhiFAO%>%
  dplyr::select(ID:LABEL, MarFishProdMT, MarMolluscProdMT)

head(CountryLabel)

CountryProdSummaryFAO=CountryProdSummary%>%
  ungroup%>%
  dplyr::select(ID:ProdPerCountryOnePercent)%>%
  full_join(CountryLabel, by= "ID")

write.csv(CountryProdSummaryFAO,file="~/TableDataOutputs/FinalNoHypox/FishProdByCountryFAOSummaryHDen.csv")

###how much space would be needed to replace all capture fisheries 2014
###(93.4 million tonnes according to the SWFA 2016)

spaceFishRep=productionDFFishCells%>%
  filter(YieldCumSum>93400000)

#area sum is 53,135 km2
## ocean area is  361.9 million square kilometers

53135/361900000
#= less than 0.015% of ocean area to produce the amount captured by wild capture fisheries





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