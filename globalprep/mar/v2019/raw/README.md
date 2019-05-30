## Source for Truj_label_sust.csv:

Mariculture Sustainability Index (Trujillo 2008)

Trujillo, P. (2008) Using a mariculture sustainability index to rank countries’   performance. p. 28-56 In: Alder, J. and Pauly, D. (eds.) A comparative assessment of biodiversity, fisheries and aquaculture in 53 countries’ Exclusive Economic Zones. Fisheries Centre Research Reports 16(7). Fisheries Centre, University of British Columbia, Vancouver, Canada. 

Column headers:

country - country name (from original paper)
species_fao - corresponding species name in FAO mariculture data
fao - fao region
environment - brackish or marine
species_Truj - species name (from original paper)
taxon - OHI assigned taxon for species_Truj categories that are very broad and could help gapfill FAO species that do not have a Trujillo sustainability score 
match_type - describes the level of specificity per observation (e.g. taxon, c_sp, c_sp_env, c_sp_fao, species)
gapfill - recorded gapfill method
Maric_sustainability - scaled MSI
Genetic escapees - score originally from Trujillo paper are rescaled from 0-10 to 0-1, where 1 is the highest score. This is based on whether the species being cultured is native or introduced


## Notes:
I improved matching between FAO taxa and Trujillo taxa.  However, this level of change should be saved for OHI 2018.  Specifically, I made the "alias" list more complete, this field is used to identify a more general taxa that matches the Trujillo data.