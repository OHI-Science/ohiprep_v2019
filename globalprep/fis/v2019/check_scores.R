### Checking fisheries stuff after adding to ohi-global

library(dplyr)
library(tidyr)
library(here)
setwd(here::here("globalprep/fis/v2019"))
source('../../../workflow/R/common.R')

## Paths for intermediate and output data
#catch_raw <- read.csv(file.path(dir_M,'git-annex/globalprep/fis/v2018/int/stock_catch_by_rgn.csv'))
catch_raw <- read.csv(file.path(dir_M,'git-annex/globalprep/fis/v2019/int/stock_catch_by_rgn_taxa.csv'))
catch_raw_old <- read.csv(file.path(dir_M,'git-annex/globalprep/fis/v2018/int/stock_catch_by_rgn.csv'))

ram_processed <- read.csv("int/ram_bmsy.csv")

catch_mean <- read.csv("output/mean_catch.csv")
catch_mean_old <- read.csv("../v2018/output/mean_catch.csv")

## load old/new raw catch data

data_file <- list.files("/home/shares/ohi/git-annex/globalprep/fis/v2019/int/annual_catch", full.names = T)
data_file_old <- list.files("/home/shares/ohi/git-annex/globalprep/fis/v2018/int/annual_catch", full.names = T)


## load raw RAM data 
load(file.path(dir_M, "git-annex/globalprep/_raw_data/RAM/d2019/RLSADB v4.44/DB Files With Assessment Data/DBdata.RData"))
ram_raw <- timeseries_values_views %>%
  dplyr::select(stockid, year, TBdivTBmsy, SSBdivSSBmsy) %>% 
  mutate(ram_bmsy = ifelse(!is.na(TBdivTBmsy), TBdivTBmsy, SSBdivSSBmsy)) %>% 
  dplyr::filter(year > 1979) %>%
  filter(!is.na(ram_bmsy)) %>% 
  dplyr::select(stockid, year, ram_bmsy)

## Read in final bbmsy data
bbmsy <- read.csv("output/fis_bbmsy.csv")
 bbmsy_old <- read.csv("../v2018/output/fis_bbmsy.csv")

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

bbmsy_old$score = ifelse(bbmsy_old$bbmsy < lowerBuffer, bbmsy_old$bbmsy,
                     ifelse (bbmsy_old$bbmsy >= lowerBuffer & bbmsy_old$bbmsy <= upperBuffer, 1, NA))
bbmsy_old$score = ifelse(!is.na(bbmsy_old$score), bbmsy_old$score,  
                     ifelse(1 - alpha*(bbmsy_old$bbmsy - upperBuffer) > beta,
                            1 - alpha*(bbmsy_old$bbmsy - upperBuffer), 
                            beta))

bbmsy_old$score2 = ifelse(bbmsy_old$bbmsy < lowerBuffer, bbmsy_old$bbmsy, 1)

## Check mean catch table compared to raw catch

## Amsterdam Island and Saint Paul Island check (rgn id: 92)
tmp <- catch_mean %>% 
  filter(rgn_id==92 & year == 2014) %>%
  arrange(mean_catch)
tmp_old <- catch_mean_old %>% 
  filter(rgn_id==92 & year == 2014) %>%
  arrange(mean_catch)
summary(tmp); summary(tmp_old)

tmp <- filter(catch_raw, rgn_id == 92)

# Compare our cumulative catch total between 2004 and 2010 to that of SAUP's above. check v2019 and v2018
tmp <- catch_mean %>% 
  filter(year >= 2004 & year <= 2010, rgn_id==92) %>%  
  summarise(sum(mean_catch))
tmp # 8280.168 tonnes

tmp <- catch_mean_old %>% 
  filter(year >= 2004 & year <= 2010, rgn_id==92) %>%  
  summarise(sum(mean_catch))
tmp # 8699.168 tonnes

tmp <- catch_raw %>% 
  filter(rgn_id == 92)

tmp_old <- catch_raw_old %>% 
  filter(rgn_id == 92)

## Phoenix Islands check (rgn id: 157)
tmp <- filter(catch_mean, rgn_id==157 & year == 2014) %>%
  arrange(mean_catch)
head(tmp)
tmp_old <- filter(catch_mean_old, rgn_id==157 & year == 2014) %>%
  arrange(mean_catch)
head(tmp_old)

# check scores from bbmsy
bb <- bbmsy_new %>% 
  filter(rgn_id == 157 & year == 2014) %>% 
  dplyr::select(rgn_id, stock_id, year, score)
bb_old <- bbmsy_old %>% 
  filter(rgn_id == 157 & year == 2014) %>% 
  dplyr::select(rgn_id, stock_id, year, score_old = score)
compare <- bb %>% 
  left_join(bb_old, by = c("rgn_id", "stock_id", "year"))
plot(compare$score, compare$score_old)
abline(0,1,col="red")

## check mean catch
tmp <- catch_raw %>% 
  filter(rgn_id == 157 & year == 2014) 
tmp_old <- catch_raw_old %>% 
  filter(rgn_id == 157 & year == 2014) %>% 
  rename(tons_old = tons) 
compare <- tmp %>% 
  left_join(tmp_old, by = c("year", "rgn_id", "fao_rgn", "TaxonName", "CommonName", "stock_id"))
plot(compare$tons, compare$tons_old)
abline(0,1,col="red")

sum(compare$tons)
sum(compare$tons_old, na.rm = TRUE)
# results: catch in tons are significantly greater this year


## Crozet Islands check (rgn id: 91)
tmp <- filter(catch_mean, rgn_id==91 & year == 2015) %>%
  arrange(mean_catch)
tmp
tmp_old <- filter(catch_mean_old, rgn_id==91 & year == 2014) %>%
  arrange(mean_catch)
tmp_old

# check scores from bbmsy
bb <- bbmsy_new %>% 
  filter(rgn_id == 91 & year == 2014) %>% 
  dplyr::select(rgn_id, stock_id, year, score)
bb_old <- bbmsy_old %>% 
  filter(rgn_id == 91 & year == 2014) %>% 
  dplyr::select(rgn_id, stock_id, year, score_old = score)
compare <- bb %>% 
  left_join(bb_old, by = c("rgn_id", "stock_id", "year"))
plot(compare$score, compare$score_old)
abline(0,1,col="red")

## check mean catch
tmp <- catch_raw %>% 
  filter(rgn_id == 91 & year == 2014) 
tmp_old <- catch_raw_old %>% 
  filter(rgn_id == 91 & year == 2014) %>% 
  rename(tons_old = tons)
compare <- tmp %>% 
  left_join(tmp_old, by = c("year", "rgn_id", "fao_rgn", "TaxonName", "CommonName", "stock_id"))
plot(compare$tons, compare$tons_old)
abline(0,1,col="red")

sum(compare$tons)
sum(compare$tons_old, na.rm = TRUE)
## results: catch in tons looks like it's greater last year..


# check original source for v2019
file <- data_file[66]
catch_orig <- readRDS(file)
tmp <- catch_orig %>%
  filter(CountryName == "Crozet Is.")


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