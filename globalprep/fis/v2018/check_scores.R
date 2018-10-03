### Checking fisheries stuff after adding to ohi-global

library(dplyr)
library(tidyr)

source('../../../src/R/common.R')

## Paths for intermediate and output data
#catch_raw <- read.csv(file.path(dir_M,'git-annex/globalprep/fis/v2018/int/stock_catch_by_rgn.csv'))
catch_raw <- read.csv(file.path(dir_M,'git-annex/globalprep/fis/v2018/int/stock_catch_by_rgn_taxa.csv'))
catch_raw_old <- read.csv(file.path(dir_M,'git-annex/globalprep/fis/v2017/int/stock_catch_by_rgn.csv'))

ram_processed <- read.csv("int/ram_bmsy.csv")

catch_mean <- read.csv("output/mean_catch.csv")
catch_mean_old <- read.csv("../v2017/data/mean_catch.csv")

## load old/new raw catch data

data_file <- list.files("/home/shares/ohi/git-annex/globalprep/fis/v2018/int/annual_catch", full.names = T)
data_file_old <- list.files("/home/shares/ohi/git-annex/globalprep/_raw_data/SAUP/d2017/annual_data", full.names = T)


## load raw RAM data 
load(file.path(dir_M, "git-annex/globalprep/_raw_data/RAM/d2018/RAM v4.40 (6-4-18)/DB Files With Assessment Data/DBdata.RData"))
ram_raw <- timeseries_values_views %>%
  dplyr::select(stockid, year, TBdivTBmsy, SSBdivSSBmsy) %>% 
  mutate(ram_bmsy = ifelse(!is.na(TBdivTBmsy), TBdivTBmsy, SSBdivSSBmsy)) %>% 
  dplyr::filter(year > 1979) %>%
  filter(!is.na(ram_bmsy)) %>% 
  dplyr::select(stockid, year, ram_bmsy)

## Read in final bbmsy data
bbmsy <- read.csv("output/fis_bbmsy.csv")
# bbmsy <- read.csv("../v2017/data/fis_bbmsy.csv")

alpha <- 0.5
beta <- 0.25
lowerBuffer <- 0.95
upperBuffer <- 1.05

bbmsy$score = ifelse(bbmsy$bbmsy < lowerBuffer, bbmsy$bbmsy,
                 ifelse (bbmsy$bbmsy >= lowerBuffer & bbmsy$bbmsy <= upperBuffer, 1, NA))
bbmsy$score = ifelse(!is.na(bbmsy$score), bbmsy$score,  
                 ifelse(1 - alpha*(bbmsy$bbmsy - upperBuffer) > beta,
                        1 - alpha*(bbmsy$bbmsy - upperBuffer), 
                        beta))

bbmsy$score2 = ifelse(bbmsy$bbmsy < lowerBuffer, bbmsy$bbmsy, 1)

bbmsy_new <- bbmsy
# bbmsy_old <- bbmsy

## Check mean catch table compared to raw catch

## Bouvet Island check (rgn id: 105)
## "Cumulative marine fisheries catches (including discards) around Bouvet Island from 2004 to 2010 were estimated to be 357 t, which is 1.1 times the estimated amount of reported landings taken from within the Bouvet EEZ (314 t)." (SAUP http://www.seaaroundus.org/doc/publications/chapters/2015/Padilla-et-al-Bouvet-Is.pdf)
tmp <- catch_mean %>% 
  filter(rgn_id==105 & year == 2014) %>%
  arrange(mean_catch)
tmp_old <- catch_mean_old %>% 
  filter(rgn_id==105 & year == 2014) %>%
  arrange(mean_catch)
summary(tmp); summary(tmp_old)

tmp <- filter(catch_raw, rgn_id == 105)

# Compare our cumulative catch total between 2004 and 2010 to that of SAUP's above. check v2018 and v2017
tmp <- catch_mean %>% 
  filter(year >= 2004 & year <= 2010, rgn_id==105) %>%  
  summarise(sum(mean_catch))
tmp # only 0.009 tons

tmp <- catch_mean_old %>% 
  filter(year >= 2004 & year <= 2010, rgn_id==105) %>%  
  summarise(sum(mean_catch))
tmp # 452 tons

tmp <- catch_raw %>% 
  filter(rgn_id == 105)

tmp_old <- catch_raw_old %>% 
  filter(rgn_id == 105)

# Compare Watson 2018 to SAUP 2017, 1988 data for Bouvet
# Difficult to check because file formats are different for the two data sources
# file <- data_file[39]
# file_old <- data_file_old[39]
# catch <- readRDS(file)
# catch_old <- readRDS(file_old)
# tmp <- catch %>% 
#   filter(CountryName == "Bouvet Island")
# tmp_old <- catch_old[which(str_detect(catch_old$fishing_entity_name, "Bouvet")),]

## Wake Island check (rgn id: 12)
tmp <- filter(catch_mean, rgn_id==12 & year == 2014) %>%
  arrange(mean_catch)
head(tmp)
tmp_old <- filter(catch_mean_old, rgn_id==12 & year == 2014) %>%
  arrange(mean_catch)
head(tmp_old)

# check scores from bbmsy
bb <- bbmsy_new %>% 
  filter(rgn_id == 12 & year == 2014) %>% 
  dplyr::select(rgn_id, stock_id, year, score)
bb_old <- bbmsy_old %>% 
  filter(rgn_id == 12 & year == 2014) %>% 
  dplyr::select(rgn_id, stock_id, year, score_old = score)
compare <- bb %>% 
  left_join(bb_old, by = c("rgn_id", "stock_id", "year"))
plot(compare$score, compare$score_old)
abline(0,1,col="red")

## check mean catch
tmp <- catch_raw %>% 
  filter(rgn_id == 12 & Year == 2014) %>% 
  rename(year = Year)
tmp_old <- catch_raw_old %>% 
  filter(rgn_id == 12 & year == 2014) %>% 
  rename(tons_old = tons, TaxonName = taxon_scientific_name, CommonName = taxon_common_name) %>% 
  dplyr::select(-taxon_key)
compare <- tmp %>% 
  left_join(tmp_old, by = c("year", "rgn_id", "fao_rgn", "TaxonName", "CommonName", "stock_id"))
plot(compare$tons, compare$tons_old)
abline(0,1,col="red")

# results: catch in tons are significantly greater this year


## Turks and Caicos check (rgn id: 111)
tmp <- filter(catch_mean, rgn_id==111 & year == 2015) %>%
  arrange(mean_catch)
tmp
tmp_old <- filter(catch_mean_old, rgn_id==111 & year == 2014) %>%
  arrange(mean_catch)
tmp_old

# check scores from bbmsy
bb <- bbmsy_new %>% 
  filter(rgn_id == 111 & year == 2014) %>% 
  dplyr::select(rgn_id, stock_id, year, score)
bb_old <- bbmsy_old %>% 
  filter(rgn_id == 111 & year == 2014) %>% 
  dplyr::select(rgn_id, stock_id, year, score_old = score)
compare <- bb %>% 
  left_join(bb_old, by = c("rgn_id", "stock_id", "year"))
plot(compare$score, compare$score_old)
abline(0,1,col="red")

## check mean catch
tmp <- catch_raw %>% 
  filter(rgn_id == 111 & Year == 2014) %>% 
  rename(year = Year)
tmp_old <- catch_raw_old %>% 
  filter(rgn_id == 111 & year == 2014) %>% 
  rename(tons_old = tons, TaxonName = taxon_scientific_name, CommonName = taxon_common_name) %>% 
  dplyr::select(-taxon_key)
compare <- tmp %>% 
  left_join(tmp_old, by = c("year", "rgn_id", "fao_rgn", "TaxonName", "CommonName", "stock_id"))
plot(compare$tons, compare$tons_old)
abline(0,1,col="red")

## results: catch in tons looks like it's greater last year..


## Jan Mayen check (rgn id: 144)
## check scores from bbmsy
bb <- bbmsy_new %>% 
  filter(rgn_id == 144 & year == 2014) %>% 
  dplyr::select(rgn_id, stock_id, year, score)
bb_old <- bbmsy_old %>% 
  filter(rgn_id == 144 & year == 2014) %>% 
  dplyr::select(rgn_id, stock_id, year, score_old = score)
compare <- bb %>% 
  left_join(bb_old, by = c("rgn_id", "stock_id", "year"))
plot(compare$score, compare$score_old)
abline(0,1,col="red")

## check mean catch
tmp <- catch_raw %>% 
  filter(rgn_id == 144 & Year == 2014) %>% 
  rename(year = Year)
tmp_old <- catch_raw_old %>% 
  filter(rgn_id == 144 & year == 2014) %>% 
  rename(tons_old = tons, TaxonName = taxon_scientific_name, CommonName = taxon_common_name) %>% 
  dplyr::select(-taxon_key)
compare <- tmp %>% 
  left_join(tmp_old, by = c("year", "rgn_id", "fao_rgn", "TaxonName", "CommonName", "stock_id"))
plot(compare$tons, compare$tons_old)
abline(0,1,col="red")

# Results: greater catch this year


## Pitcairn check (rgn id: 146)
# check scores from bbmsy
bb <- bbmsy_new %>% 
  filter(rgn_id == 146 & year == 2014) %>% 
  dplyr::select(rgn_id, stock_id, year, score)
bb_old <- bbmsy_old %>% 
  filter(rgn_id == 146 & year == 2014) %>% 
  dplyr::select(rgn_id, stock_id, year, score_old = score)
compare <- bb %>% 
  left_join(bb_old, by = c("rgn_id", "stock_id", "year"))
plot(compare$score, compare$score_old)
abline(0,1,col="red")

## check mean catch
tmp <- catch_raw %>% 
  filter(rgn_id == 146 & Year == 2014) %>% 
  rename(year = Year)
tmp_old <- catch_raw_old %>% 
  filter(rgn_id == 146 & year == 2014) %>% 
  rename(tons_old = tons, TaxonName = taxon_scientific_name, CommonName = taxon_common_name) %>% 
  dplyr::select(-taxon_key)
compare <- tmp %>% 
  left_join(tmp_old, by = c("year", "rgn_id", "fao_rgn", "TaxonName", "CommonName", "stock_id"))
plot(compare$tons, compare$tons_old)
abline(0,1,col="red")

# results: unclear.. greater catch this year for several comparisons

# check original source for v2018
file <- data_file[66]
catch_orig <- readRDS(file)
tmp <- catch_orig %>%
  filter(CountryName == "Pitcairn")


## Vietnam check (rgn id: 207)
# check scores from bbmsy
bb <- bbmsy_new %>% 
  filter(rgn_id == 207 & year == 2014) %>% 
  dplyr::select(rgn_id, stock_id, year, score)
bb_old <- bbmsy_old %>% 
  filter(rgn_id == 207 & year == 2014) %>% 
  dplyr::select(rgn_id, stock_id, year, score_old = score)
compare <- bb %>% 
  left_join(bb_old, by = c("rgn_id", "stock_id", "year"))
plot(compare$score, compare$score_old)
abline(0,1,col="red")

# check mean catch
tmp <- catch_raw %>% 
  filter(rgn_id == 207 & Year == 2014) %>% 
  rename(year = Year)
tmp_old <- catch_raw_old %>% 
  filter(rgn_id == 207 & year == 2014) %>% 
  rename(tons_old = tons, TaxonName = taxon_scientific_name, CommonName = taxon_common_name) %>% 
  dplyr::select(-taxon_key)
compare <- tmp %>% 
  left_join(tmp_old, by = c("year", "rgn_id", "fao_rgn", "TaxonName", "CommonName", "stock_id"))
plot(compare$tons, compare$tons_old)
abline(0,1,col="red")

# results: looks like last yera greater tons?


## Samoa check (rgn id: 152)
# check scores from bbmsy
bb <- bbmsy_new %>% 
  filter(rgn_id == 152 & year == 2014) %>% 
  dplyr::select(rgn_id, stock_id, year, score)
bb_old <- bbmsy_old %>% 
  filter(rgn_id == 152 & year == 2014) %>% 
  dplyr::select(rgn_id, stock_id, year, score_old = score)
compare <- bb %>% 
  left_join(bb_old, by = c("rgn_id", "stock_id", "year"))
plot(compare$score, compare$score_old)
abline(0,1,col="red")

# check mean catch
tmp <- catch_raw %>% 
  filter(rgn_id == 152 & Year == 2014) %>% 
  rename(year = Year)
tmp_old <- catch_raw_old %>% 
  filter(rgn_id == 152 & year == 2014) %>% 
  rename(tons_old = tons, TaxonName = taxon_scientific_name, CommonName = taxon_common_name) %>% 
  dplyr::select(-taxon_key)
compare <- tmp %>% 
  left_join(tmp_old, by = c("year", "rgn_id", "fao_rgn", "TaxonName", "CommonName", "stock_id"))
plot(compare$tons, compare$tons_old)
abline(0,1,col="red")

# results: greater tons last year


## Cambodia check (rgn id: 24)
# check scores from bbmsy
bb <- bbmsy_new %>% 
  filter(rgn_id == 24 & year == 2014) %>% 
  dplyr::select(rgn_id, stock_id, year, score)
bb_old <- bbmsy_old %>% 
  filter(rgn_id == 24 & year == 2014) %>% 
  dplyr::select(rgn_id, stock_id, year, score_old = score)
compare <- bb %>% 
  left_join(bb_old, by = c("rgn_id", "stock_id", "year"))
plot(compare$score, compare$score_old)
abline(0,1,col="red")

# check mean catch
tmp <- catch_raw %>% 
  filter(rgn_id == 24 & Year == 2014) %>% 
  rename(year = Year)
tmp_old <- catch_raw_old %>% 
  filter(rgn_id == 24 & year == 2014) %>% 
  rename(tons_old = tons, TaxonName = taxon_scientific_name, CommonName = taxon_common_name) %>% 
  dplyr::select(-taxon_key)
compare <- tmp %>% 
  left_join(tmp_old, by = c("year", "rgn_id", "fao_rgn", "TaxonName", "CommonName", "stock_id"))
plot(compare$tons, compare$tons_old)
abline(0,1,col="red")

# results: greater tons last year


## Solomon Island check (rgn id: 7)
# check scores from bbmsy
bb <- bbmsy_new %>% 
  filter(rgn_id == 7 & year == 2014) %>% 
  dplyr::select(rgn_id, stock_id, year, score)
bb_old <- bbmsy_old %>% 
  filter(rgn_id ==7 & year == 2014) %>% 
  dplyr::select(rgn_id, stock_id, year, score_old = score)
compare <- bb %>% 
  left_join(bb_old, by = c("rgn_id", "stock_id", "year"))
plot(compare$score, compare$score_old)
abline(0,1,col="red")

# check mean catch
tmp <- catch_raw %>% 
  filter(rgn_id == 7 & Year == 2014) %>% 
  rename(year = Year)
tmp_old <- catch_raw_old %>% 
  filter(rgn_id == 7 & year == 2014) %>% 
  rename(tons_old = tons, TaxonName = taxon_scientific_name, CommonName = taxon_common_name) %>% 
  dplyr::select(-taxon_key)
compare <- tmp %>% 
  left_join(tmp_old, by = c("year", "rgn_id", "fao_rgn", "TaxonName", "CommonName", "stock_id"))
plot(compare$tons, compare$tons_old)
abline(0,1,col="red")

# results: greater tons last year


#################################################

## From last year's (v2017) data check
tmp <- filter(catch_mean, rgn_id==162 & year == 2014) %>%
arrange(mean_catch)
tmp


filter(catch_mean, rgn_id==105 & stock_id_taxonkey == 'Patagonotothen_brevicauda_brevicauda-48_607052') # these should all be the same

filter(bbmsy, rgn_id == 162 & year == 2014)
9.370719e+04/(sum(tmp$mean_catch))
1.739980e+05/(sum(tmp$mean_catch))
5.480903e+04/(sum(tmp$mean_catch))
(5.329995e+04 + 4.207865e+04)/(sum(tmp$mean_catch))

tmp <- filter(catch_raw, rgn_id == 162)
no_fao <- filter(tmp, is.na(fao_rgn))
head(no_fao)
sum(no_fao$tons)
sum(tmp$tons)