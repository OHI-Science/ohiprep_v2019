###############################
## downloading fisheries data
###############################

# paper url: https://www.nature.com/articles/sdata201739
# data url: http://metadata.imas.utas.edu.au/geonetwork/srv/eng/metadata.show?uuid=c1fefb3d-7e37-4171-b9ce-4ce4721bbc78
# V2.0 of the data, downloaded 4/20/2017
# issue: #776

# Note 7/19/2017: server appears to have changed
# http://data.imas.utas.edu.au/attachments/c1fefb3d-7e37-4171-b9ce-4ce4721bbc78/CatchPublic5054.csv
source("src/R/common.R")

web_years <- c("0004", "0509", "1014", "5054", 
               "5559", "6064", "6569", "7074",
               "7579", "8084", "8589", "9094", "9599")

for(web_year in web_years){ #web_year <- "0004"

data <- read.csv(sprintf("http://data.imas.utas.edu.au/attachments/c1fefb3d-7e37-4171-b9ce-4ce4721bbc78/CatchPublic%s.csv", web_year))
saveRDS(data, 
        file.path(dir_M, sprintf("git-annex/globalprep/_raw_data/IMAS_GlobalFisheriesLandings/CatchPublic%s.rds", web_year)))
}


## exploring data
data <- readRDS(file.path(dir_M, "git-annex/globalprep/_raw_data/IMAS_GlobalFisheriesLandings/d2018/CatchPublic0004.rds"))
head(data)
