###########################################
## Template for downloading fisheries data
###########################################

## paper url: https://www.sciencedirect.com/science/article/pii/S0308597X18300605
## metadata url: http://metadata.imas.utas.edu.au/geonetwork/srv/eng/metadata.show?uuid=ff1274e1-c0ab-411b-a8a2-5a12eb27f2c0
## data url: http://data.imas.utas.edu.au/portal/search?uuid=ff1274e1-c0ab-411b-a8a2-5a12eb27f2c0
## Global Fisheries Landings V3.0, downloaded 7/17/2018
## OHI issue: #13

source("src/R/common.R")

## Save download url suffixes 
web_years <- c("Ind_1950_1954", "Ind_1955_1959", "Ind_1960_1964", "Ind_1965_1969", 
               "Ind_1970_1974", "Ind_1975_1979", "Ind_1980_1984", "Ind_1985_1989",
               "Ind_1990_1994", "Ind_1995_1999", "Ind_2000_2004", "Ind_2005_2009", 
               "Ind_2010_2014", "Ind_2015_2019", "NInd_1950_1954", "NInd_1955_1959",
               "NInd_1960_1964", "NInd_1965_1969", "NInd_1970_1974", "NInd_1975_1979",
               "NInd_1980_1984", "NInd_1985_1989", "NInd_1990_1994", "NInd_1995_1999", 
               "NInd_2000_2004", "NInd_2005_2009", "NInd_2010_2014", "NInd_2015_2019")

reference <- c("Cells", "Index")

## Download reference data from web and save into mazu
for(ref in reference){ # ref <- "Ind_1950_1954"
  
  data <- read.csv(sprintf("http://data.imas.utas.edu.au/attachments/ff1274e1-c0ab-411b-a8a2-5a12eb27f2c0/%s.csv", ref))
  
  write.csv(data, file.path(dir_M, sprintf("git-annex/globalprep/_raw_data/IMAS_GlobalFisheriesLandings/d2018/%s.csv", ref)), row.names=F)
  
}

## Download catch data from web and save into mazu
for(web_year in web_years){ # web_year <- "Ind_1950_1954"

data <- read.csv(sprintf("http://data.imas.utas.edu.au/attachments/ff1274e1-c0ab-411b-a8a2-5a12eb27f2c0/Catch%s.csv", web_year))

saveRDS(data, file.path(dir_M, sprintf("git-annex/globalprep/_raw_data/IMAS_GlobalFisheriesLandings/d2018/Catch%s.rds", web_year)))

}


## exploring data
data <- readRDS(file.path(dir_M, "git-annex/globalprep/_raw_data/IMAS_GlobalFisheriesLandings/d2018/CatchInd_1950_1954.rds"))
head(data)

# Spatial cells reference
ref1 <- read.csv(file.path(dir_M, "git-annex/globalprep/_raw_data/IMAS_GlobalFisheriesLandings/d2018/Cells.csv"))

## Master index file
ref2 <- read.csv(file.path(dir_M, "git-annex/globalprep/_raw_data/IMAS_GlobalFisheriesLandings/d2018/Index.csv"))

