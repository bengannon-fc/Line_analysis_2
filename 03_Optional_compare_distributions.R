####################################################################################################
#### Compare distributions for strategic options
#### Author: Ben Gannon (benjamin.gannon@usda.gov)
#### Date Created: 12/06/2025
#### Last Modified: 09/30/2026
####################################################################################################
# Compare each index across scenarios with histograms. Requires a "Strategy" text attribute in the
# original input. There is no required schema, but it is recommended to keep the strategy class
# names relatively short (< 30 characters) to make the titles fit.
####################################################################################################
#-> Set working directory
setwd('C:/Users/UserName/WorkingDirectory') # User should adjust
####################################################################################################

############################################START MESSAGE###########################################
cat('Compare distributions for strategic options\n',sep='')
cat('Started at: ',as.character(Sys.time()),'\n\n',sep='')
cat('Errors and Warnings (if they exist):\n')
####################################################################################################

############################################START SETUP#############################################

#-> Load packages
pd <- .libPaths()[1]
#pd <- 'C:/Users/UserName/R/R-4.5.0/library' # Or, specify library directory
packages <- c('terra','plyr','readxl')
for(package in packages){
	if(suppressMessages(!require(package,lib.loc=pd,character.only=T))){
		install.packages(package,lib=pd,repos='https://repo.miserver.it.umich.edu/cran/')
		suppressMessages(library(package,lib.loc=pd,character.only=T))
		require(package)
	}
}

#-> Load in settings
rasters <- data.frame(read_excel('01_Line_analysis_settings.xlsx',sheet='Rasters'))
rasters <- rasters[rasters$Include==1,]
settings <- data.frame(read_excel('01_Line_analysis_settings.xlsx',sheet='Settings'))
run_name <- settings[settings$Setting=='Run name','Value']
run_name_file <- gsub(',','',gsub(' ','_',run_name)) # Clean up for file naming

#-> Load in results of spatial analysis
al <- vect(paste0('./',run_name_file,'/',run_name_file,'_analysis_lines.shp'))
alp <- vect(paste0('./',run_name_file,'/',run_name_file,'_analysis_line_points.shp'))

#############################################END SETUP##############################################

##########################################START ANALYSIS############################################

#-> Join strategy attribute from lines to points
alp <- merge(alp,data.frame(al)[,c('LID','Strategy')],by='LID',all.x=T)

#-> Get unique list of strategies to plot
pstrats <- unique(al$Strategy)
pstrats <- pstrats[order(pstrats)]

#-> Iterate through rasters to create distribution comparison figures
for(i in 1:nrow(rasters)){
	
	#-> Organize data breakpoints and colors
	brks <- as.numeric(unlist(strsplit(rasters$Bins[i],',')))
	labs <- unlist(strsplit(rasters$R_bin_labels[i],','))
	for(j in 1:length(labs)){
		if(nchar(labs[j]) > 10){
			labs[j] <- paste0(substr(labs[j],1,9),'.')
		}
	}
	colRP <- unlist(strsplit(rasters$R_ColorPalette[i],','))
	cols <- colorRampPalette(colRP)(length(brks)-1)
	
	#-> Generate histogram data (separated from plotting to standardize the y axis)
	pers.l <- list()
	for(j in 1:length(pstrats)){
		
		#-> Extract data values for scenario
		s_vals <- data.frame(alp[alp$Strategy==pstrats[j],])[,rasters$Name[i]]

		#-> Get counts in bins
		s_freq <- hist(s_vals,breaks=brks,plot=F)$count

		#-> Get percentages in bins
		pers.l[[j]] <- 100*(s_freq/sum(s_freq))
	
	}
	
	for(j in 1:length(pstrats)){
		
		#-> Calculate length of line
		line_length <- sum(al[al$Strategy==pstrats[j],'Length_mi'])
		
		#-> Create barplot
		fname <- paste0('./',run_name_file,'/',run_name_file,'_distribution_',
	                gsub(' ','_',rasters$Name[i]),'_',gsub(' ','_',pstrats[j]),'.jpg')
		jpeg(fname,width=700,height=600,pointsize=20,quality=80,type='cairo')
		barplot(pers.l[[j]],col=cols,main=pstrats[j],cex.main=2,
				ylim=c(0,max(unlist(pers.l))*1.05),
				ylab='Percent of line length',xlab=rasters$Map_name[i],names=labs,cex.names=0.8)
		mtext(paste0('Line length = ',round(line_length,1),'-mi'),side=3,line=-0.5,cex=1)
		g <- dev.off()

	}


}

###########################################END ANALYSIS#############################################

####################################################################################################
cat('\nFinished at: ',as.character(Sys.time()),'\n\n',sep='')
############################################END LOGGING#############################################
