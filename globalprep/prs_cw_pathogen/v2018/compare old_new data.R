###########################################
#Sanitation data comparison between old (used in 2015 assesment) and new (downloaded for 2018 assesment)
#Camila Vargas
# 06/01/2018
################################################


#Diving into old data - preparing the data

old_raw <- read.csv('https://raw.githubusercontent.com/OHI-Science/ohiprep_v2018/master/globalprep/prs_cw_pathogen/v2015/raw/whounicef_sanitation_1990-2015.csv',  header = T, sep = ",", na.strings = c(NA, ''), skip = 3, stringsAsFactors = FALSE, strip.white = TRUE)

old_raw <- old_raw %>%
  select(country,
         year           = Year,
         pop            = x1000,
         imp_tot_ct     = Total.Improved..x1000. ,
         imp_tot_pct    = Total.Improved.... ,
         unimp_tot_ct   = Total.Unimproved..x1000. ,
         unimp_tot_pct  = Total.Unimproved....) %>%
  mutate(pop            = pop          * 1000,
         imp_tot_ct     = imp_tot_ct   * 1000,
         unimp_tot_ct   = unimp_tot_ct * 1000,
         country        = na.locf(country))      # use na.locf() function from zoo package to fill down for country names

### select and scale percent of population with access to improved sanitation
old <- old_raw %>%
  select(country, year, access_pct = imp_tot_pct) %>%
  mutate(access_pct = access_pct/100) %>% 
  select(country, year,  access_pct )
summary(old); head(old)


old_improved <- old %>%
  mutate(country = ifelse(str_detect(country,"Cura\\Sao"), "Curacao", country))%>% 
  mutate(country = ifelse(str_detect(country,"R\\Sunion"), "Reunion", country)) %>% 
  mutate(country = ifelse(str_detect(country, "C\\Ste d\\SIvoire"), "Ivory Coast", country)) %>% 
  mutate(country=ifelse(str_detect(country,"Hong Kong"), "Hong Kong", country)) %>% 
  mutate(country=ifelse(str_detect(country,"Macao"), "Macao", country))


# NethAnt <- old %>% 
#   filter(country=='Netherlands Antilles') #no data so ist filter out
# 
# old_improved <- old_improved %>% 
#   filter(country !='Netherlands Antilles')


CI_old <- filter(old_improved, country=="Channel Islands") %>%
  rename(country_old = country)
CI_subregions_old <- data.frame(country_old = "Channel Islands",
                            country = c("Guernsey", "Jersey")) %>%
  left_join(CI_old) %>%
  select(-country_old)

old_improved <- old_improved %>%
  filter(country != "Channel Islands") %>%
  rbind(CI_subregions_old)  


#Add rgn id

old_rgn_id <- name_2_rgn(old_improved, 
                       fld_name     = 'country',
                       flds_unique  = c('country','year')) 

old_final <- old_rgn_id %>% 
  select(rgn_id, rgn_name, year, old_prop=access_pct) %>% 
  group_by(rgn_id) %>% 
  filter(year >= 2000) %>% 
  ungroup() %>% 
  arrange(rgn_id)
  
## COMPARING INITIAL NAs

#Count NA in old data
old_na <- old_final %>% 
  group_by(rgn_id) %>% 
  mutate(na_count=sum(is.na(old_prop)))

old_count_na <- old_na %>% 
  filter(na_count>0) %>% 
  select(rgn_id, rgn_name, na_count_old = na_count) %>% 
  unique() %>%
  data.frame()
  
#Count new data NA
new <- sani_final %>% 
  select(rgn_id, rgn_name, year, new_prop=basic_sani_prop)


new_na <- new %>% 
  group_by(rgn_id, rgn_name) %>%
  mutate(na_count = sum(is.na(new_prop))) %>% 
  ungroup()

summary(new_na)

new_count_na <- new_na %>% 
  filter(na_count>0) %>% 
  select(rgn_id, rgn_name, na_count_new = na_count) %>% 
  unique() %>%
  data.frame()

na_compare_raw <- new_count_na %>% 
  full_join(old_count_na, by= c('rgn_id', 'rgn_name')) %>% 
  mutate(na_count_old= ifelse(is.na(na_count_old), 0, na_count_old)) %>%
  mutate(na_count_new= ifelse(is.na(na_count_new), 0, na_count_new)) %>% 
  arrange(rgn_id)

#Conclusion: there are differences in several countries. Overall there are more NAs in the old data than the new (total NAs for new data = 137, total NAs for old data = 228).
sum(na_compare_raw$na_count_new)
sum(na_compare_raw$na_count_old)

#rgn_id 60, Gibraltar is no included in the raw old data set so there is no old data for this rgn (na_count_old should be 16)

filter(na_compare_raw, na_count_new==16)

filter(na_compare_raw, na_count_old==0) #several countries that have 0 here should have 16 because they are actually not included in the old raw data (rgn_id=60, 86,161, 219, 220)

#COMPARING GEOREGION GAPFILL

#identify regions that were gapfilled with georegions in old data

##Bring from ohicore packege georegions and georegions lables as variables
georegions       <- georegions
georegion_labels <- georegion_labels

#mising regionsin the old
old_georgn_gf <- georegions %>%
  expand(year, georegions) %>%
  left_join(old_final, by = c('rgn_id', 'year')) %>%
  left_join(georegion_labels, by = 'rgn_id') %>%
  select(rgn_id, rgn_name, year, r1, r2, old_prop) %>% 
  arrange(rgn_id)

## count missing regions in old data
old_rgn_na <- old_georgn_gf %>% 
  group_by(rgn_id) %>%
  mutate(na_count = sum(is.na(rgn_name))) %>% 
  ungroup()


old_count_na_rgn <- old_rgn_na %>% 
  filter(na_count>0) %>% 
  select(rgn_id, rgn_name, na_count_rgn_old = na_count) %>% 
  unique() %>%
  data.frame()


#missing regions in the new data
new_georgn_gf <- sani_georgn_gf %>% 
  select(rgn_id, rgn_name, year, r1, r2, new_prop=basic_sani_prop) %>% 
  arrange(rgn_id)

## count missing regions in new data
new_rgn_na <- new_georgn_gf %>% 
  group_by(rgn_id) %>%
  mutate(na_count = sum(is.na(rgn_name)))


#This counts the rgn do not have any data (there were not in the raw data base but are part of the ohi rgn) and will be gapfilled by georegions
new_count_na_rgn <- new_rgn_na %>% 
  filter(na_count>0) %>% 
  select(rgn_id, rgn_name, na_count_rgn_new = na_count) %>% 
  unique() %>%
  data.frame()

#comparing missing regions in old and new
na_compare_rgn <- old_count_na_rgn %>% 
  full_join(new_count_na_rgn, by= c('rgn_id', 'rgn_name')) %>% 
  mutate(na_count_rgn_old= ifelse(is.na(na_count_rgn_old), 0, na_count_rgn_old)) %>%
  mutate(na_count_rgn_new= ifelse(is.na(na_count_rgn_new), 0, na_count_rgn_new)) %>%
  select(-rgn_name) %>% 
  arrange(rgn_id)

#Summary: the new data has data for more regions (new data includeds rgn_id: 86 161 219 220 244) but is missing data for rgn_id 63 (wich is included in old data)


#COMPARING POPULATION DATA

old_pop_density <- read_csv("/home/shares/ohi/model/GL-NCEAS-CoastalPopulation_v2013/data/rgn_popsum_area_density_2005to2015_inland25mi.csv") %>% 
  arrange(rgn_id)

#differences in area!!
old_area <- old_pop_density %>% 
  mutate(area_km2_old=area_km2) %>% 
  select(rgn_id, area_km2_old) %>%
  unique() %>% 
  data.frame()

#note: this dataset does not include inhabited areas:4  12  30  33  34  35  36  38  89  90  91  92  93  94 105 107 144 150 159

area_compare <- old_area %>% 
  left_join(area, by='rgn_id') %>% 
  mutate(area_km2_new=area_km2) %>% 
  mutate(diff= area_km2_old-area_km2_new) %>% 
  select(-area_km2) %>% 
  arrange(diff)

#larger differences (min and max): rgn_id 145 -185,801 and rgn_id 73: 1,620,526

#There are differences in the area used to calculate pop_density inneach asssement.


#Differences in population

old_popsum <- old_pop_density %>%
  mutate(popsum_old=popsum) %>% 
  select(rgn_id, year, popsum_old)
  
new_popsum <- population %>% 
  filter(year %in% 2005:2015) %>% 
  mutate(popsum_new=popsum) %>% 
  select(-popsum)

popsum_compare <- old_popsum %>% 
  left_join(new_popsum) %>% 
  mutate(diff= popsum_old - popsum_new) %>% 
  arrange(diff)

max(popsum_compare$diff, na.rm = T) ##rgn_id 73 Russia: 8,835,620
min(popsum_compare$diff, na.rm = T) ##rgn_id 209, China: -86,635,417


#Density differences for regions 1 and 2 as an exmple..

density_compare <- popsum_compare %>% 
  filter(rgn_id==1) %>% 
  mutate(dens_old = popsum_old/23.578) %>% 
  mutate(dens_new = popsum_new/18) %>% 
  mutate(diff= dens_old-dens_new)
  
density_compare2 <- popsum_compare %>% 
  filter(rgn_id==2) %>% 
  mutate(dens_old = popsum_old/158.9320) %>% 
  mutate(dens_new = popsum_new/142 ) %>% 
  mutate(diff= dens_old-dens_new)

#Look into trend and pressure of old data
#this is done at the end of the cw_sanitation_sata prep

#Scatterplot
#population
popsum_plot <- popsum_compare %>% 
  mutate(log_old = log(popsum_old+1)) %>% 
  mutate(log_new = log(popsum_new+1))

plot(popsum_plot$log_old, popsum_plot$log_new)
abline(0,1, col="red")

#area
area_plot <- area_compare %>% 
  mutate(log_old = log(area_km2_old+1)) %>% 
  mutate(log_new = log(area_km2_new+1))

plot(area_plot$log_old, area_plot$log_new)
abline(0,1, col="red")


#compare 2016 with 2015

v2016 <- read.csv("../v2016/output/pathogens_popdensity25mi_updated.csv")%>%
  select(rgn_id, v2015_pressure = pressure_score)

v2015 <- read.csv("../v2015/data/po_pathogens_popdensity25mi_2015a_gf.csv") %>%
  left_join(v2016, by='rgn_id')

plot(v2015$v2015_pressure, v2015$pressure_score)
abline(0,1, col="red")

######################################################

#Comparing outliers data in several steps of data wrangling

#outliers rgn_id: 154, 163, 190, 81

#apparently al differencesa are due on how data is reported.
#Comparing each outlier raw data

#rgn_145 - Niue

rgn_154_old <-old_final %>% 
  filter(rgn_id==154)

rgn_154_new <-sani_final %>% 
  filter(rgn_id==154)

rgn_154 <- rgn_154_old %>% 
  left_join(rgn_154_new) %>% 
  select(-rgn_id, -rgn_name)
  
head(rgn_154)
View(rgn_154)

ggplot(data=rgn_154)+
  geom_line(aes(x=year, y=old_prop), color="blue", alpha=0.4)+
  geom_line(aes(x=year, y=basic_sani_prop), color="red", alpha=0.4)+
  ylab('raw proportion')+
  theme_bw()
  

#Note: in the old data you can see an increase in sanitation, therfore a decrease in pressure. The opposite trend is observed in the new data, there is a decrease in sanitation which implies an increase in pressure, making the trend 1 instead of -1 as in the old data.

#rgn_163 - USA

rgn_163_old <-old_final %>% 
  filter(rgn_id==163)

rgn_163_new <-sani_final %>% 
  filter(rgn_id==163)

rgn_163 <- rgn_163_old %>% 
  left_join(rgn_163_new)

View(rgn_163)

ggplot(data=rgn_163)+
  geom_line(aes(x=year, y=old_prop), color="blue", alpha=0.4)+
  geom_line(aes(x=year, y=basic_sani_prop), color="red", alpha=0.4)+
  ylab('raw proportion')+
  theme_bw()


#Note: In the old data there is a slightly increase in sanitation from the year 2000 to 2015. in the new data it seems all values are roundes to 1 so thee is no change in sanitation. This explains why the pressure trend goes from -1 to 0.


#rgn_190 - Qatar

rgn_190_old <-old_final %>% 
  filter(rgn_id==190)

rgn_190_new <-sani_final %>% 
  filter(rgn_id==190)

rgn_190 <- rgn_190_old %>% 
  left_join(rgn_190_new)

View(rgn_190)

ggplot(data=rgn_190)+
  geom_line(aes(x=year, y=old_prop), color="blue", alpha=0.4)+
  geom_line(aes(x=year, y=basic_sani_prop), color="red", alpha=0.4)+
  ylab('raw proportion')+
  theme_bw()


#Note: Old data shows a slight decrease in sanitation (increase in pressure). New data has de opposite trend, therefor it makes sense that the Trend in pressure shifts from being positive to being -1.

#rgn_81 - Cyprus

rgn_81_old <-old_final %>% 
  filter(rgn_id==81)

rgn_81_new <-sani_final %>% 
  filter(rgn_id==81)

rgn_81 <- rgn_81_old %>% 
  left_join(rgn_81_new)

View(rgn_81)

ggplot(data=rgn_81)+
  geom_line(aes(x=year, y=old_prop), color="blue", alpha=0.4)+
  geom_line(aes(x=year, y=basic_sani_prop), color="red", alpha=0.4)+
  ylab('raw proportion')+
  theme_bw()


#Note: Similar to the regions above, the old data for rgn_81 is constant in 1 and the new data slightly decreases in 2013, 2014 and 2015.


#Compara old a and new pressure scores

#read old presure scores - NOE this files only has data form 2012-2015
old_prs <- read_csv("~/github/ohiprep_v2018/globalprep/prs_cw_pathogen/v2016/output/pathogens_popdensity25mi_updated.csv") %>% 
  arrange(rgn_id)

View(old_prs)

#filter for outliers (target rgns)
old_prs_outliers <- old_prs %>% 
  filter(rgn_id %in% c(154, 163, 190, 81)) %>% 
  mutate(old_prs=pressure_score) %>% 
  select(-pressure_score)

View(old_prs_outliers)


new_prs_outliers <- unsani_prs %>% 
  filter(rgn_id %in% c(154, 163, 190, 81)) %>% 
  filter(year %in% 2012:2015) %>% 
  mutate(new_prs=pressure_score) %>% 
  select(-pressure_score)

View(new_prs_outliers)

prs_compare <- old_prs_outliers %>% 
  left_join(new_prs_outliers)

View(prs_compare)









  