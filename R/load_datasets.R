#  Okay, this is the code for the non-analogue analysis:

library(neotoma)

#  Getting all the sites from neotoma is time consuming:
if(!'all.sites.RData' %in% list.files('data/')){
  all.datasets <- get_datasets(datasettype = 'pollen')
  data.ids <- sapply(all.datasets, function(x)x$DatasetID)

  #  Return all pollen sites in neotoma:
  all.sites <- get_download(data.ids)
  save(all.sites, file='data/all.sites/RData')
}
if('all.sites.RData' %in% list.files('data/')){
  load('data/all.sites.RData')
}

#  Compress the dataset taxonomies to the standard of the small Whitmore taxonomy.
if('compiled.sites.RData' %in% list.files('data/')){
  load('data/compiled.sites.RData')
}

if(!('compiled.sites.RData' %in% list.files('data/'))){
  compiled.sites <- lapply(all.sites, function(x) compile_list(x, list.name='WhitmoreSmall', type = TRUE, cf=TRUE))
  save(compiled.sites, file='data/compiled.sites.RData')  
}

#  Make the dataset into one giant table with site name, lat/long, depth and age and then counts:
if(!('compiled.pollen.RData' %in% list.files('data/'))){
  for(i in 1:length(compiled.sites)){
    x <- compiled.sites[[i]]
    
    if(is.null(x$metadata$site.data$SiteName)) x$metadata$site.data$SiteName <- paste('NoName_ID', i)
    if(is.null(x$sample.meta$depths)) x$sample.meta$depths <- NA
    if(is.null(x$sample.meta$Age)) x$sample.meta$Age <- NA
    if(is.null(x$metadata$site.data$LatitudeNorth)) x$metadata$site.data$LatitudeNorth <- NA
    if(is.null(x$metadata$site.data$LongitudeWest)) x$metadata$site.data$LongitudeWest <- NA
        
    site.info <- data.frame(sitename = x$metadata$site.data$SiteName,
                            depth = x$sample.meta$depths,
                            age = x$sample.meta$Age,
                            lat = x$metadata$site.data$LatitudeNorth,
                            long = x$metadata$site.data$LongitudeWest)
    
    if(i == 1){
      compiled.pollen <- data.frame(site.info, x$counts)
    } 
    
      if(i > 1) {
        aa <- try(merge(compiled.pollen, data.frame(site.info, x$counts), all=TRUE))
        if(length(aa) > 1) compiled.pollen <- aa
      }
    
    cat(i, '\n')
  }
  
  include <- !(is.na(compiled.pollen$age) | 
                 is.na(compiled.pollen$depth) | 
                 compiled.pollen$age > 22000 |
                 compiled.pollen$lat < 23 |
                 compiled.pollen$lat > 65 |
                 compiled.pollen$long > -40 |
                 compiled.pollen$long < -100 |
                 compiled.pollen$sitename %in% 'Mangrove Lake')
  
  compiled.pollen <- compiled.pollen[include, ]
  compiled.pollen$sitename <- as.character(compiled.pollen$sitename)
  compiled.pollen[is.na(compiled.pollen)] <- 0
  
  save(compiled.pollen, file='data/compiled.pollen.RData')

}

if('compiled.pollen.RData' %in% list.files('data/')){
  load('data/compiled.pollen.RData')
}
