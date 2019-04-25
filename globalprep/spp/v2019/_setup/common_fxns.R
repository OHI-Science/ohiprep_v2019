### Support functions for this project

### setup common directories
dir_setup <- file.path(dir_goal, '_setup')
dir_data  <- file.path(dir_goal, '_data')
dir_spatial  <- file.path(dir_goal, '_spatial')
dir_output  <- file.path(dir_goal, '_output')
dir_goal_anx <- file.path(dir_anx, goal, scenario, 'spp_risk_dists')

### * IUCN API functions
### * Simple Features and Raster common functions
### * Other random helper functions

### common plot functions/variables
### This color scheme and label scheme matches the mean risk maps
risk_cols <- c('green4', viridis::inferno(6, direction = -1))
risk_vals <- c(0, .2, .3, .4, .5, .7, 1.0)
risk_lbls <- c('LC', 'NT', 'VU', 'EN', 'CR', 'EX')
risk_brks <- c( 0.0,  0.2,  0.4,  0.6,  0.8,  1.0)

### This color scheme and label scheme matches the pct threatened maps
thr_cols <- viridis::viridis(6, direction = +1)
thr_vals <- c(0, .25, .33, .42, .50, 1)
### much of the density between .25 and .50
thr_brks <- c(0, .25, .50, .75, 1)
thr_lbls <- c('0%', '25%', '50%', '75%', '100%')


### cat if not knitting; message if knitting

cat_msg <- function(x, ...) {
  if(is.null(knitr:::.knitEnv$input.dir)) {
    ### not in knitr environment, so use cat()
    cat(x, ..., '\n')
  } else {
    ### in knitr env, so use message()
    message(x, ...)
  }
  return(invisible(NULL))
}

### Simple Features functions
gp_proj4 <- '+proj=cea +lon_0=0 +lat_ts=45 +x_0=0 +y_0=0 +ellps=WGS84 +units=m +no_defs'


clip_to_globe <- function(x) {
  ### for SF features, transform to wgs84, clip to +-180 and +-90
  epsg <- st_crs(x)$epsg
  if(epsg != 4326 | is.na(epsg)) {
    message('Original EPSG = ', epsg, '; Proj4 = ', st_crs(x)$proj4string,
            '\n...converting to EPSG:4326 WGS84 for clipping')
    x <- st_transform(x, 4326)
  }
  x_bbox <- st_bbox(x)
  if(x_bbox$xmin < -180 | x_bbox$xmax > +180 |
     x_bbox$ymin <  -90 | x_bbox$ymax >  +90) {
    message('Some bounds outside +-180 and +-90 - clipping')
    z <- st_crop(x, y = c('xmin' = -180,
                          'ymin' =  -90,
                          'xmax' = +180,
                          'ymax' =  +90)) %>%
      st_cast('MULTIPOLYGON')
    # z <- as(x, 'Spatial') %>%
    #   raster::crop(raster::extent(-180, 180, -90, 90)) %>%
    #   st_as_sf()
    ### otherwise is sfc_GEOMETRY which doesn't play well with fasterize.
    ### The st_crop solution works great most of the time; but for
    ### spp 21132910 (at least) the crop turned things into linestrings
    ### that couldn't be converted with st_cast('MULTIPOLYGON').
  } else {
    message('All bounds OK, no clipping necessary')
    z <- x
  }
  return(z)
}

clip_to_globe_sp <- function(x) {
  ### Convert to SP and use raster::crop - this is a backup when the 
  ### sf method (st_crop) fails miserbably
  epsg <- st_crs(x)$epsg
  if(epsg != 4326 | is.na(epsg)) {
    message('Original EPSG = ', epsg, '; Proj4 = ', st_crs(x)$proj4string,
            '\n...converting to EPSG:4326 WGS84 for clipping')
    x <- st_transform(x, 4326)
  }
  x_bbox <- st_bbox(x)
  if(x_bbox$xmin < -180 | x_bbox$xmax > +180 |
     x_bbox$ymin <  -90 | x_bbox$ymax >  +90) {
    message('Some bounds outside +-180 and +-90 - clipping')
    z <- as(x, 'Spatial') %>%
      raster::crop(raster::extent(-180, 180, -90, 90)) 
    z_sf <- z %>%
      st_as_sf()
    
    return(z_sf)
    
  } else {
    message('All bounds OK, no clipping necessary')
    z <- x
  }
  return(z)
}

valid_check <- function(spp_shp) {
  valid <- st_is_valid(spp_shp)
  ### can return a vector if multiple polygons with same ID
  if(any(!valid)) {
    cat_msg('Found invalid geometries')
    
    bbox_shp <- st_bbox(spp_shp)
    if(bbox_shp$xmin < -180 | bbox_shp$xmax > 180) {
      cat_msg('Bounding box outside +/- 180; buffering with dist = 0')
      ### check area before and after buffering to make sure no loss
      area_pre  <- st_area(spp_shp) %>% as.numeric() / 1e6
      spp_shp   <- st_buffer(spp_shp, dist = 0) %>%
        st_cast('MULTIPOLYGON')
      area_post <- st_area(spp_shp) %>% as.numeric() / 1e6
      
      area_check <- all.equal(area_pre, area_post)
      area_ratio <- max(sum(area_pre) / sum(area_post),
                        sum(area_post) / sum(area_pre))
      
      
      ### error check to make sure the buffer didn't lose polygons
      if(area_check == FALSE | 
         (class(area_check) != 'logical' & area_ratio > 1.001)) {
        ### use all.equal() for near equality, and for comparing all 
        ### elements in case of a vector.  If a difference, choose an arbitrary
        ### threshold for "close enough".
        cat_msg('Error: area_pre = ', round(sum(area_pre), 3), 
                '; area_post = ', round(sum(area_post), 3), 
                '; area_ratio = ', round(area_ratio, 5), '; not equal!')
        stop('Area_pre and area_post not equal!')
      } else {
        cat_msg('Area check good!  area_pre = ', round(sum(area_pre), 3), 
                '; area_post = ', round(sum(area_post), 3), 
                '; area_ratio = ', round(area_ratio, 5), '; all equal!')
      }
    } else {
      cat_msg('bbox not exceeded; no need to fix polygon with buffer')
    }
  }
  return(spp_shp)
}


### Functions for accessing IUCN API

### `get_from_api()` is a function to access the IUCN API, given a url 
### (specific to data sought), parameter, and key (stored in ohi/git-annex), 
### as well as a delay if desired (to ease the load on the IUCN API server). 
### `mc_get_from_api()` runs the `get_from_api()` function across multiple 
### cores for speed...


library(parallel)
library(jsonlite)

### api_key stored on git-annex so outside users can use their own key
api_file <- file.path(dir_M, 'git-annex/globalprep/spp_ico', 
                      'api_key.csv')
api_key <- scan(api_file, what = 'character')

# api_version <- fromJSON('http://apiv3.iucnredlist.org/api/v3/version') %>%
#   .$version


api_version <- '2019-1'


get_from_api <- function(url, param, api_key, delay) {
  
  i <- 1; tries <- 5; success <- FALSE
  
  while(i <= tries & success == FALSE) {
    message('try #', i)
    Sys.sleep(delay * i) ### be nice to the API server? later attempts wait longer
    api_info <- fromJSON(sprintf(url, param, api_key)) 
    if (class(api_info) != 'try-error') {
      success <- TRUE
    } else {
      warning(sprintf('try #%s: class(api_info) = %s\n', i, class(api_info)))
    }
    message('... successful? ', success)
    i <- i + 1
  }
  
  if (class(api_info) == 'try-error') { ### multi tries and still try-error
    api_return <- data.frame(param_id  = param,
                             api_error = 'try-error after multiple attempts')
  } else if (class(api_info$result) != 'data.frame') { ### result isn't data frame for some reason
    api_return <- data.frame(param_id  = param,
                             api_error = paste('non data.frame output: ', class(api_info$result), ' length = ', length(api_info$result)))
  } else if (length(api_info$result) == 0) { ### result is empty
    api_return <- data.frame(param_id  = param,
                             api_error = 'zero length data.frame')
  } else {
    api_return <- api_info %>%
      data.frame(stringsAsFactors = FALSE)
  }
  
  return(api_return)
}

mc_get_from_api <- function(url, param_vec, api_key, cores = NULL, delay = 0.5) {
  
  if(is.null(cores)) 
    numcores <- ifelse(Sys.info()[['nodename']] == 'mazu', 12, 1)
  else 
    numcores <- cores
  
  out_list <- parallel::mclapply(param_vec, 
                                 function(x) get_from_api(url, x, api_key, delay),
                                 mc.cores   = numcores,
                                 mc.cleanup = TRUE) 
  
  if(any(sapply(out_list, class) != 'data.frame')) {
    error_list <- out_list[sapply(out_list, class) != 'data.frame']
    message('List items are not data frame: ', paste(sapply(error_list, class), collapse = '; '))
    message('might be causing the bind_rows() error; returning the raw list instead')
    return(out_list)
  }
  
  out_df <- out_list %>%
    bind_rows()
  out_df <- out_df %>%
    setNames(names(.) %>%
               str_replace('result.', ''))
  return(out_df)
}

drop_geom <- function(sf) {
  sf %>% as.data.frame() %>% select(-geometry)
}


library(tidyverse)
library(RColorBrewer)
library(stringr)
library(here)

# set the Mazu shortcuts based on operating system
dir_M <- c('Windows' = '//mazu.nceas.ucsb.edu/ohi',
           'Darwin'  = '/Volumes/ohi',    ### connect (cmd-K) to smb://mazu/ohi
           'Linux'   = '/home/shares/ohi')[[ Sys.info()[['sysname']] ]] %>%
  path.expand()

dir_O <- c('Windows' = '//mazu.nceas.ucsb.edu/ohara',
           'Darwin'  = '/Volumes/ohara',    ### connect (cmd-K) to smb://mazu/ohara
           'Linux'   = '/home/ohara')[[ Sys.info()[['sysname']] ]] %>%
  path.expand()


### Set up some options
# options(scipen = "999")           ### Turn off scientific notation
options(stringsAsFactors = FALSE) ### Ensure strings come in as character types


### generic theme for all plots
ggtheme_plot <- function(base_size = 9) {
  theme(axis.ticks = element_blank(),
        text       = element_text(family = 'Helvetica', color = 'gray30', size = base_size),
        axis.text  = element_text(size = rel(0.8)),
        axis.title = element_text(size = rel(1.0)),
        plot.title = element_text(size = rel(1.25), hjust = 0, face = 'bold'),
        panel.background = element_blank(),
        strip.background = element_blank(),
        strip.text       = element_text(size = base_size, face = 'italic'),
        legend.position  = 'right',
        panel.border     = element_blank(),
        panel.grid.minor = element_blank(),
        panel.grid.major = element_line(colour = 'grey90', size = .25),
        # panel.grid.major = element_blank(),
        legend.key       = element_rect(colour = NA, fill = NA),
        axis.line        = element_blank() # element_line(colour = "grey30", size = .5)
  )}

### generic theme for maps
ggtheme_map <- function(base_size = 9) {
  theme(text             = element_text(family = 'Helvetica', color = 'gray30', size = base_size),
        plot.title       = element_text(size = rel(1.25), hjust = 0, face = 'bold'),
        panel.background = element_blank(),
        legend.position  = 'right',
        panel.border     = element_blank(),
        panel.grid.minor = element_blank(),
        panel.grid.major = element_blank(),
        # panel.grid.major = element_blank(),
        axis.ticks       = element_blank(),
        axis.text        = element_blank(),
        axis.title       = element_blank(),
        legend.key       = element_rect(colour = NA, fill = NA),
        axis.line        = element_blank()) # element_line(colour = "grey30", size = .5)) +
}

show_dupes <- function(x, y, na.rm = FALSE) {
  if(na.rm)
    x <- x[!is.na(x[[y]]), ]
  
  # x is data frame, y is field (as character) within that dataframe
  z <- x[x[[y]] %in% x[[y]][duplicated(x[[y]])], ]
}

get_rgn_names <- function() {
  x <- foreign::read.dbf('~/github/ohibc/prep/_spatial/ohibc_rgn.dbf', as.is = TRUE) %>%
    dplyr::select(rgn_id, rgn_name, rgn_code) %>%
    bind_rows(data.frame(rgn_id   = 0,
                         rgn_name = 'British Columbia',
                         rgn_code = 'BC'))
}

clean_df_names <- function(df) {
  df <- df %>%
    setNames(tolower(names(.)) %>%
               str_replace_all('[^a-z0-9]+', '_') %>%
               str_replace_all('^_+|_+$', ''))
  return(df)
}

ditch_mac_cruft <- function() {
  all_files <- list.files(getwd(), all.files = TRUE,
                          recursive = TRUE, full.names = TRUE)
  
  cruft <- all_files[stringr::str_detect(basename(all_files), pattern = '^\\._|^.DS_Store')]
  message('ditching mac cruft files: \n  ', paste0(cruft, collapse = '\n  '))
  unlink(cruft)
}
