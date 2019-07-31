## created by Ellie Campbell on Jul 24, 2018
## script for downloading uv_data; same code as in 'download the data' section of uv_dataprep.Rmd
## see the uv_dataprep.Rmd for more details about the EarthData Archive, access info, where to get the 'file_list.txt' etc

library(dplyr)
library(readr)
library(stringr)
library(httr)
library(ncdf4)

## need username and password for earthdata, just define in console or read from secure file, don't save them here!!
usrname <- readline("Type earthdata username:")
pass <- readline("Type earthdata password:")

## update to reflect current assessment year, or whichever year data is being used!!!
data_yr <- "d2018"
raw_data_dir <- file.path("Desktop/uv_data_download") # created local 'uv_data_download' folder on Desktop

## read in links list
file_list_raw <- read_delim(file.path(raw_data_dir, "file_list.txt"), delim = "\n", col_names = FALSE)
file_list <- file_list_raw %>% 
  mutate(url_str = as.character(X1)) %>% 
  mutate(check_netcdf = str_match(url_str, pattern = "http.*OMI-Aura_L3-OMUVBd.*nc")) %>%
  filter(!is.na(check_netcdf)) %>% 
  select(url_str)

## set up timekeeping for data download
t0 = Sys.time()
n.pym = length(file_list$url_str)
i.pym = 0

## download the data
for(i in 1:length(file_list$url_str)){
  url = as.character(file_list[i,])
  name_raw_file = substr(url, 88, 144)
  
  x = httr::GET(url, authenticate(usrname, pass, type = "basic"))
  bin = content(x, "raw")
  writeBin(bin, file.path(raw_data_dir, "data", name_raw_file)) # need 'data' folder in 'uv_data_download'
  
  ## rough estimate of time remaining for data download
  i.pym <- i.pym + 1 
  min.done <- as.numeric(difftime(Sys.time(), t0, units="mins"))
  min.togo <- (n.pym - i.pym) * min.done/i.pym
  print(sprintf("Retrieving %s of %s. Minutes done=%0.1f, to go=%0.1f",
                i.pym, n.pym, min.done, min.togo))
}