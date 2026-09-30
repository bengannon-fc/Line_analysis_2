####################################################################################################
#### Line analysis
#### Author: Ben Gannon (benjamin.gannon@usda.gov)
#### Date Created: 12/05/2025
#### Last Modified: 09/30/2026
####################################################################################################
# Summary: ingests polylines, generates sample points at fixed distance intervals along the lines, 
# extracts raster data for sample point buffers, and outputs point and polyline results.
# Input data is controlled in the companion spreadsheet.
# - Analysis lines: single shapefile with lines to analyze, can include a PACE or similar
#   strategy classification scheme in a "Strategy" text attribute 
# - Rasters: including options for extraction function and several data transformations
# - Parameters: sample point spacing, buffer distance for extraction, naming 
# Constraints:
# - Cannot accommodate multipart lines, converted to singlepart in script
####################################################################################################
#-> Set working directory
setwd('C:/Users/UserName/WorkingDirectory') # User should adjust
####################################################################################################

############################################START MESSAGE###########################################
cat('Line analysis\n',sep='')
cat('Started at: ',as.character(Sys.time()),'\n\n',sep='')
cat('Errors and Warnings (if they exist):\n')
####################################################################################################

############################################START SET UP############################################

#-> Load packages (and install if necessary)
pd <- .libPaths()[1]
#pd <- 'C:/Users/UserName/R/R-4.5.0/library' # Or, specify library directory
packages <- c('terra','plyr','readxl')
for(package in packages){
	if(suppressMessages(!require(package,lib.loc=pd,character.only=T))){
		install.packages(package,lib=pd,repos='https://repo.miserver.it.umich.edu/cran/')
		suppressMessages(library(package,lib.loc=pd,character.only=T))
		require(package,lib.loc=pd,character.only=T)
	}
}

#-> Load in settings
settings <- data.frame(read_excel('01_Line_analysis_settings.xlsx',sheet='Settings'))
run_name <- settings[settings$Setting=='Run name','Value']
run_name <- gsub(',','',gsub(' ','_',run_name)) # Clean up for file naming
bdist <- as.numeric(settings[settings$Setting=='Buffer','Value'])
pdist <- as.numeric(settings[settings$Setting=='Point spacing','Value'])
rasters <- data.frame(read_excel('01_Line_analysis_settings.xlsx',sheet='Rasters'))
rasters <- rasters[rasters$Include==1,]
alines <- settings[settings$Setting=='Analysis lines','Value']

#-> Load in analysis lines
if(file.exists(alines)){
	al <- vect(alines)
}else{
	cat(paste0('The analysis lines shapefile input does not exist!\n',
	           'Correct the file path. Use forward slashes. Include the ".shp" file extension.\n'))
}
if(!exists('al')){ # Do not run without valid shapefile
	quit()
}

#-> Check that all the input rasters exist
rasters$Status <- 0
for(i in 1:nrow(rasters)){
	if(!file.exists(rasters$Raster[i])){
		cat(paste0('The ',rasters$Name[i],' raster input does not exist!\n',
	               'Correct the file path. Use forward slashes. ',
				   'Include the ".tif" file extension.\n'))
		rasters$Status[i] <- 1
	}
}
if(sum(rasters$Status) > 0){ # Do not run without valid raster(s)
	quit()
}

#-> Function to generate regularly-spaced points along line centerlines
# inLine = single polyline with line id field (LID)
# pdist = point spacing distance in meters
# returns sample points for line tagged with LID and sequential point IDs (PID)
regPoints <- function(inLine,pdist){
	lcdf <- crds(inLine,df=T) # Get coordinates
	lcdf$pdist <- 0 # Field for point distances
	for(i in 2:nrow(lcdf)){ # Calculate point distances
		lcdf$pdist[i] <- sqrt((lcdf[i,'x'] - lcdf[(i-1),'x'])^2 + (lcdf[i,'y'] - lcdf[(i-1),'y'])^2)
	}
	lcdf$cdist <- cumsum(lcdf$pdist) # Calculate cumulative distance
	npoints <- round(max(lcdf$cdist)/pdist,0) # Calculate number of points to generate
	if(npoints == 0){ # Means line is shorter than desired point spacing
		bds <- max(lcdf$cdist)/2 # Use midpoint for break distance
	}
	if(npoints > 0){ # Means line is at least as long as desired point spacing
		rem <- (max(lcdf$cdist) - npoints*pdist)/2 # Get remainder
		bds <- seq(pdist/2 + rem,max(lcdf$cdist) - pdist/2 - rem,pdist) # Calc break distances
	}
	spdf.l <- list()
	for(i in 1:length(bds)){
		scp <- max(which(lcdf$cdist <= bds[i])) # Starting calculation point for interpolation
		if(lcdf$cdist[scp] < bds[i]){ # Interpolate
			sp <- lcdf[scp,]; ep <- lcdf[(scp+1),] # Starting point and end point
			xdiff <- ep$x - sp$x # x difference
			ydiff <- ep$y - sp$y # y difference
			if(xdiff != 0){
				m <- ydiff/xdiff # Calculate slope
				z <- bds[i] - lcdf$cdist[scp] # Calculate z (hypotenuse)
				x <- sqrt((z^2)/abs(1+m^2)) # Solve for x
				if(xdiff < 0){ # Add correct sign to x if it was negative
					x <- x*(-1)
				}
				y <- x*m # Solve for y
			}else{
				x <- 0
				y <- ifelse(ydiff > 0,bds[i] - lcdf$cdist[scp],-1*(bds[i] - lcdf$cdist[scp]))
			}
			spdf.l[[length(spdf.l)+1]] <- data.frame(x=sp$x+x,y=sp$y+y,cdist=bds[i]) # Save point
		}else{ # Use exact point if match
			spdf.l[[length(spdf.l)+1]] <- lcdf[scp,] # Use exact point
		}
	}
	spdf <- do.call('rbind',spdf.l) # Compile to data frame
	sps <- vect(as.matrix(spdf[,c('x','y')]),crs=crs(inLine),type='points') # Convert to spatial
	sps$LID <- inLine$LID # Transfer line ID
	sps$PID <- seq(1,nrow(sps),1) # Generate point ID
	return(sps) # Return points
}


#############################################END SET UP#############################################

###########################################START ANALYSIS###########################################

#-> Create output directory
dir.create(paste0('./',run_name))

#-> Format analysis lines for processing
al <- makeValid(al) # Repair geometry
al <- disagg(al) # Multipart to singlepart
al$LID <- seq(1,nrow(al),1) # Add line ID field
al$Length_m <- perim(al) # Get length of each line
al$Length_mi <- al$Length_m*(1/1609.34)

#-> Convert lines to points for analysis
# Uses regPoints function defined above
alp.l <- list() # List to store results
for(i in 1:nrow(al)){ # Iterate through lines
	alp.l[[i]] <- regPoints(al[i,],pdist) # Generate regular points		
}
alp <- do.call('rbind',alp.l) # Compile results
alpb <- buffer(alp,width=bdist) # Create associated buffers for summary stats

###---> Extract raster values

for(i in 1:nrow(rasters)){
	#-> Read in raster
	rast_i <- rast(rasters$Raster[i])
	#-> Project analysis line point buffers to match raster
	alpb <- project(alpb,crs(rast_i)) # Match projections
	#-> Crop raster to necessary extent
	rast_i <- crop(rast_i,buffer(vect(ext(alpb),crs=crs(rast_i)),width=bdist*2))
	#-> Reclassify
	if(!is.na(rasters$Reclass[i])){
		classes <- unlist(strsplit(rasters$Reclass[i],';'))
		from <- NA; to <- NA
		for(j in 1:length(classes)){
			csplit <- unlist(strsplit(classes[j],' '))
			from[j] <- as.numeric(csplit[1]); to[j] <- as.numeric(csplit[2])
		}
		rast_i <- classify(rast_i,rcl=data.frame(from,to)) 
	}
	#-> Apply correction factor if specified 
	if(!is.na(rasters$CorrFactor[i])){
		rast_i <- rast_i*rasters$CorrFactor[i]
	}
	#-> Replace NA with zero
	if(!is.na(rasters$NA2Zero[i])){
		rast_i[is.na(rast_i)] <- 0
	}
	#-> Extract raster data
	X <- extract(rast_i,alpb,fun=rasters$Extract_function[i],na.rm=T)[,2] # Extract
	alpb$X <- round(X,rasters$Decimals[i]) # Round
	names(alpb)[ncol(alpb)] <- rasters$Name[i] # Rename field
}
#-> Join to point data
alp <- merge(alp,data.frame(alpb),by=c('LID','PID'),all.x=T)

#-> Save analysis line points for mapping
alp_save <- alp
for(i in 1:nrow(rasters)){ # Recode NA so it is properly exported to shapefile
	X <- data.frame(alp_save)[,rasters$Name[i]]
	X[is.na(X)] <- -1
	alp_save[,rasters$Name[i]] <- X
}
writeVector(alp_save,filename=paste0('./',run_name,'/',run_name,'_analysis_line_points.shp'),
            overwrite=T)
				
#-> Attribute analysis lines with min, mean, and max of each metric
for(i in 1:nrow(rasters)){
	alp$X <- data.frame(alp)[,paste(rasters$Name[i])]
	decimal <- rasters$Decimals[i]
	xdf <- ddply(data.frame(alp),.(LID),summarize,
				 min = round(min(X,na.rm=T),decimal),
				 mean = round(mean(X,na.rm=T),decimal),
				 max = round(max(X,na.rm=T),decimal))
	al <- merge(al,xdf,by='LID',all.x=T)
	al$min[is.na(al$mean)] <- -1 # Recode NA so it is properly exported to shapefile
	al$max[is.na(al$mean)] <- -1
	al$mean[is.na(al$mean)] <- -1
	names(al)[(ncol(al)-2):ncol(al)] <- paste(rasters$Name[i],c('min','mean','max'),sep='_')
	alp$X <- NULL
}	
	
#-> Save analysis lines for mapping and analysis
writeVector(al,filename=paste0('./',run_name,'/',run_name,'_analysis_lines.shp'),overwrite=T)				

############################################END ANALYSIS############################################

####################################################################################################
cat('\nFinished at: ',as.character(Sys.time()),'\n\n',sep='')
############################################END LOGGING#############################################

