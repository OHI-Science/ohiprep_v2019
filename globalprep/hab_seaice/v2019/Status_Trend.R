for (p in poles){ 
  
   #p="n" # testing
   p="s"
  ######################################################################################################################
  ## This section is mostly for Visualization
  ######################################################################################################################
  
  ## type (r.typ) (land, coast, shore, water) and region (r.rgn) rasters that are created are used later
  ## r.ice and r.ice.edge rasters are not used later

  
  ## identify the reference rasters for the north and south pole:
  if (p == "n"){
    l = "n201203"; w = 641; h = 709
  } else {
    l = "s201209"; w = 940; h = 671
  }
  
  ## load the .rdata file created in the "ObtainingData.R" function:
  ## s = raster stack of the ice data for all years/months
  ## pts = points data of OHI regions, NSIDC type of land cover, and data extracted from each NSIDC ice layer
  load(file = file.path(dir_M, 
                        sprintf("git-annex/globalprep/_raw_data/NSIDC_SeaIce/%s/%s_rasters_points.rdata", 
                                assessYear, p)))
  
  ## using the reference rasters ("l") for the north and south pole 
  r = raster(s,l) # select the "l" (i.e., reference) raster layer from the stack
  
  ## create a NSIDC land cover types raster (used later on):
  r.typ = setValues(r, pts$type_nsidc) 
  
  ## create a proprtion ice cover (excluding land/coast) raster (used only to visualize):
  r.ice = r
  r.ice[r.typ < 2] = NA # include: shore(2), water(3), hole(4); exclude: land(0), coast(1)
  r.ice = r.ice/250 # convert ice score to proportion
  
  ## create an ice edge habitat raster (ice between 10-50%) (used only to visualize):
  r.ice.edge = r.ice
  r.ice.edge[r.ice.edge<0.1 | r.ice.edge>0.5] = NA
  
  ## create a region raster that excludes land and coast areas (used later on):
  r.rgn = setValues(r, pts$rgn_id) # create a new raster with the regions 
  r.rgn[r.typ < 2] = NA # exclude: land(0), coast(1) from the regions
  
  ## plot data
  png(file.path(here(), "globalprep/hab_seaice", assessYear, sprintf("int/%s_IceEdgeHabitat_overview.png",p)), width=w, height=h)
  par(mfcol=c(2,2))
  plot(r.typ, col=rev(topo.colors(length(unique(r.typ)))), main="Pixel Type\n(0=land,1=coast,2=shore,3=water,4=hole)")
  plot(r.ice, col=tim.colors(64), main=sprintf("Ice Concentration (%s)",l))
  plot(r.rgn, col=tim.colors(length(unique(r.rgn))), main="OHI Region")
  plot(r.ice.edge, col=tim.colors(64), main="Ice Edge Habitat\n 10% to 50% Concentration")
  dev.off()

  ######################################################################################################################
  ## Converts the (s)tack of rasters to (i)ce concentration
  ######################################################################################################################
  
  si = s # convert (s)tack of rasters to (i)ce concentration
  
  si[is.na(r.rgn) | r.rgn == 0] = NA # converting land/coast regions to NA (previously excluded water, but want FAO stats)
  si[si > 250] = 250 # convert hole (value=251) to max ice
  si = si/250 # divide byt 250 to get 0 to 1 ice proportion
  names(si) = names(s)
  
  ######################################################################################################################
  ## Subset ice concentration stacks
  ######################################################################################################################
  
  sih = si >= 0.1 & si <= 0.5 # (s)tack of (i)ce edge (h)abitat based on concentrations within 0.1 and 0.5
  sip = si >= 0.15 & r.typ == 2 # (s)tack of (i)ce (p)rotection based on shore pixels with concentrations > 0.15
  sip[is.na(r.rgn) | r.rgn == 0] = NA # sip located on shoreline
  names(sih) = names(s)
  names(sip) = names(s)
  
  ######################################################################################################################
  # Calculate average total ice coverage per year (across all years)
  ######################################################################################################################
  
  ## calculate Reference as average of total annual sea ice
  ## sum sea ice of all months and divide by total number of years
  
  yrs.s = as.factor(substr(names(s),2,5)) # get reference to years by column
  ref.year.locs <- which(yrs.s %in% ref.years) # ref.years defined in hab_seaice_dataprep.Rmd
  
  ## sum pixels across all the layers in the sip and sih stacks, divide by number of years
  rih.R = sum(sih[[ref.year.locs]])/length(ref.years) # raster of ice habitat for Reference
  rip.R = sum(sip[[ref.year.locs]])/length(ref.years) # raster of ice protection for Reference
  
  ## summarize Reference by region (add all values in each region)
  z.h.R = zonal(rih.R, r.rgn, sum) # zonal ice edge habitat Reference
  z.p.R = zonal(rip.R, r.rgn, sum) # zonal ice protection Reference 
  
  
  ######################################################################################################################
  ## Sum pixels across months for each year (results in N = 1 layer for each year)  
  ######################################################################################################################
  
  sih.yr = stackApply(sih, yrs.s, sum)
  sip.yr = stackApply(sip, yrs.s, sum)
  names(sih.yr) = levels(yrs.s)
  names(sip.yr) = levels(yrs.s)
  
  ######################################################################################################################
  # Get moving average with 3 year window for last 6 years
  ######################################################################################################################
  
  ## could replace/simplify with raster v2.6-7 "movingFun" function?
  
  range.years = (final.year-10):(final.year) # final.year defined in data prep set-up code chunk
  
  for (yr in range.years){ # for each of the summed years worth of data
    # yr = 2011  # testing
    ir = which(names(sih.yr) %in% sprintf("X%d",(yr - 2):(yr))) # collect layers including year of interest, and 2 previous
    lyr = sprintf("avg3yr_%d", yr)
    if (yr == min(range.years)){    
      sih.avg3yr = mean(sih.yr[[ir]])
      sip.avg3yr = mean(sip.yr[[ir]])        
      names(sih.avg3yr) = lyr
      names(sip.avg3yr) = lyr
    } else {
      sih.avg3yr = stack(sih.avg3yr, mean(sih.yr[[ir]]))
      sip.avg3yr = stack(sip.avg3yr, mean(sip.yr[[ir]]))
      names(sih.avg3yr) = c(lyrs, lyr)      
      names(sip.avg3yr) = c(lyrs, lyr)
    }
    
    lyrs = names(sih.avg3yr)
  }
  
  ## output is a raster with the average of 3 years of data
  
  ######################################################################################################################
  ## Summarize averaged data for each year/region, output is a dataframe
  ######################################################################################################################
  
  z.h.T = sih.avg3yr %>% zonal(r.rgn, sum) %>% merge(z.h.R) # has years in range.years (final.year-10 to final.year)
  z.p.T = sip.avg3yr %>% zonal(r.rgn, sum) %>% merge(z.p.R)    
  
  ## Reference values (mean across all years)
  R.h = z.h.T[["value"]] # aka z.h.R
  R.p = z.p.T[["value"]] # aka z.p.R

  for (yr in range.years){ 
    # yr = 2006  # testing
    avg3yr.h = z.h.T[[sprintf("avg3yr_%d", yr)]]
    avg3yr.p = z.p.T[[sprintf("avg3yr_%d", yr)]]
    z.h.T[[sprintf("pctdevR_%d", yr)]] =  avg3yr.h/R.h
    z.p.T[[sprintf("pctdevR_%d", yr)]] =  avg3yr.p/R.p # results in a bunch of NaN where "value" (Reference) is zero
  }
  
  ######################################################################################################################
  ## Calculate trend
  ######################################################################################################################
  
  ## Regression model for each region for the selected years and save the slope and R2 to the z.h.T dataframe
  for (j in (final.year-6):final.year){
    # j = 2012 # testing
    trend.years = (j - 4):j
    early_year <- min(trend.years)
    
    for (i in 1:nrow(z.h.T)){ 
      # i = 3 # testing
      if (z.h.T$value[i] > 0){
        mdl = lm(y ~ x, data.frame(x = trend.years, y = as.numeric(z.h.T[i,sprintf("pctdevR_%d", trend.years)])))
        adjust_prop_change <- as.numeric(z.h.T[i,sprintf("pctdevR_%d", early_year)])
        z.h.T[i, sprintf("Trend_%sto%s_pctdevRperyr", 
                         min(trend.years), max(trend.years))] = mdl$coefficients[["x"]]/adjust_prop_change
      }
    }
  }
  
  ## Regression model for each region for the selected years and save the slope and R2 to the z.p.T dataframe
  for (j in (final.year-6):final.year){ # j = 2015
    trend.years = (j - 4):j
    early_year <- min(trend.years) 
    
    for (i in 1:nrow(z.p.T)){ # i = 3
      if (z.p.T$value[i] > 0){
        mdl = lm(y ~ x, data.frame(x = trend.years, y = as.numeric(z.p.T[i, sprintf("pctdevR_%d", trend.years)])))
        adjust_prop_change <- as.numeric(z.p.T[i,sprintf("pctdevR_%d", early_year)])
        z.p.T[i, sprintf("Trend_%sto%s_pctdevRperyr", 
                         min(trend.years), max(trend.years))] = mdl$coefficients[["x"]]/adjust_prop_change
      }
    }
  }
  
  ######################################################################################################################
  ## Calculate status and add to z.h.T data and z.p.T data
  ######################################################################################################################
  
  ## use the pctdevR_ values for relevant year, in lieu of status
  
  names(z.h.T)[names(z.h.T) == "value"] = sprintf("Reference_avg%sto%smonthlypixels", min(ref.years), max(ref.years))
  names(z.p.T)[names(z.p.T) == "value"] = sprintf("Reference_avg%sto%smonthlypixels", min(ref.years), max(ref.years))
  z.h.T[["pole"]] = p
  z.p.T[["pole"]] = p
  
  labels = pts %>% data.frame() %>% dplyr::select("rgn_id", "rgn_typ", "rgn_nam") %>% dplyr::distinct()
  
  z.h.T <- merge(z.h.T, labels, by.x = "zone", by.y = "rgn_id")
  z.p.T <- merge(z.p.T, labels, by.x = "zone", by.y = "rgn_id")
  
  names(z.h.T)[names(z.h.T) == "zone"] = "rgn_id"    
  names(z.p.T)[names(z.p.T) == "zone"] = "rgn_id"
  
  write.csv(z.h.T, file.path(here(), "globalprep/hab_seaice", assessYear, sprintf("int/%s_IceEdgeHabitat_ref%sto%s.csv", p, 
                           min(ref.years), max(ref.years))), row.names = FALSE)
  write.csv(z.p.T, file.path(here(), "globalprep/hab_seaice", assessYear, sprintf("int/%s_IceShoreProtection_ref%sto%s.csv", p, 
                           min(ref.years), max(ref.years))), row.names = FALSE) 
  
}
