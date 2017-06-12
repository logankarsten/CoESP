# Program to calculate biases from observed CO DWR data
# to modeled values on a daily scale. Output was generated
# for the 2004-2016 water years on a daily timestep using a
# cutout of the NWM domain, using v1.1 of the code. 

# Logan Karsten
# National Center for Atmospheric Research
# Research Applications Laboratory

# Load necessary libraries
library(ggplot2)
library(rwrfhydro)
library(data.table)
library(doParallel)
library(ncdf4)

source('/glade/u/home/karsten/RHAP_home/wrf_hydro_analysis/URG_2017/Bias_Calc_2017/Run_Retro_Calc/utils.R')

args = commandArgs(trailingOnly=TRUE)

dwrId <- c(args[1])
comId <- c(args[2])

rtLinkPath <- '/glade/p/work/karsten/URG_2017/RouteLink_URG_WY2017_CALIB.nc'
modPath <- '/glade/u/home/karsten/RHAP_home/wrf_hydro_model_runs/URG/URG_2017_RETRO'

# Calculate the index of where this stream point is as
id <- nc_open(rtLinkPath)
links <- ncvar_get(id,'link')
rtIndex <- which(links == comId)
nc_close(id)

print(paste0('RT INDEX = ',rtIndex))
# Download CO DWR data
obsStrData <- GetCoDwrData(dwrId,paramCodes=c("DISCHRG"),timeInt="daily",startDate="10/01/2003",endDate="10/01/2016")

# Compose list of model files and read in.
filesList <- list.files(path = modPath,
                       pattern = glob2rx("*.CHRTOUT_DOMAIN*"),
                       full.names = TRUE)

modData <- as.data.table(plyr::ldply(filesList, ReadChFile, c(rtIndex), .parallel = FALSE))

save(obsStrData,file=paste0('Obs_',dwrId,'.Rdata'))
save(modData,file=paste0('modStr_',dwrId,'.Rdata'))

#load(paste0('Obs_',dwrId,'.Rdata'))
#load(paste0('modStr_',dwrId,'.Rdata'))

modData <- as.data.frame(modData)

# We will only be doing analysis from 4/1 - 10/1 to capture the majority of the melt.
nDays <- 183
years <- c(2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016)
#years <- c(2004)

# Create dataframe to hold data
dfOut1 <- data.frame(matrix(NA,ncol=6,nrow=(nDays*24*length(years)*length(dwrId))))
names(dfOut1) <- c('Observed_cfs','Observed_kaf','Modeled_cfs','Modeled_kaf','POSIXct','Basin')
dfOut1$POSIXct <- as.POSIXct('1900-01-01',"%Y-%m-%d")

dfOut2 <- data.frame(matrix(NA,ncol=10,nrow=(nDays*24*length(dwrId))))
names(dfOut2) <- c('Mean_Observed_cfs','Median_Observed_cfs','Mean_Observed_kaf','Median_Observed_kaf',
                   'Mean_Modeled_cfs','Median_Modeled_cfs','Mean_Modeled_kaf','Median_Modeled_kaf',
                   'POSIXct','Basin')
dfOut2$POSIXct <- as.POSIXct('1900-01-01',"%Y-%m-%d")

dfOut3 <- data.frame(matrix(NA,ncol=7,nrow=(nDays*24*length(dwrId)*2)))
names(dfOut3) <- c('Mean_cfs','Median_cfs','Mean_kaf','Median_kaf','POSIXct','Basin','Tag')
dfOut3$POSIXct <- as.POSIXct('1900-01-01',"%Y-%m-%d")

dfOut4 <- data.frame(matrix(NA,ncol=4,nrow=(nDays*24*length(years)*(length(dwrId)*2) ) ) )
names(dfOut4) <- c('POSIXct','Basin','q_cfs','Tag')
dfOut4$POSIXct <- as.POSIXct('1900-01-01',"%Y-%m-%d")

count <- 1
count2 <- 1
for (year in years){
  print(year)
  for (basin in dwrId){
    wy <- year + 1
    bStr <- paste0(year,'-04-01')
    eStr <- paste0(year,'-10-01')
    bDate <- as.POSIXct(bStr,'%Y-%m-%d',tz="UTC")
    eDate <- as.POSIXct(eStr,'%Y-%m-%d',tz="UTC")
    stId <- comId[1]

    accRunoffModel <- 0.0
    accRunoffObs <- 0.0
    for (day in 1:nDays){
	# Since observations only occur once a day, we will "assume" this flow is representative across
	# all hours of the day. 
	dCurrentDay <- bDate + 3600*day*24
	indDaily <- which(as.Date(obsStrData$POSIXct) == as.Date(dCurrentDay))
	dailyCfs <- obsStrData$DISCHRG..cfs.[indDaily[1]]
	dailyCms <- obsStrData$q_cms[indDaily[1]]
	for (hour in 1:24){
		obsNaFlag <- 0
        	dfOut1$Basin[count] <- basin
        	dCurrent <- bDate + 3600*day*24 + 3600*hour
        	dfOut1$POSIXct[count] <- dCurrent

		print(dCurrent)
		#ind <- which(obsStrData$POSIXct == dCurrent)
                #dfOut1$Observed_cfs[count] <- obsStrData$DISCHRG..cfs.[ind[1]]
		dfOut1$Observed_cfs[count] <- dailyCfs
		runoff2_af <- dailyCms*(3600)/1233.48
                #runoff2_af <- obsStrData$q_cms[ind[1]]*(3600)/1233.48
                runoff2_kaf <- runoff2_af/1000.0
		if (is.na(dfOut1$Observed_cfs[count])){
			# We have missing values, set a flag to simply skip over accumulated obs/modeled 
			# flow here.
			obsNaFlag <- 0
			accRunoffObs <- accRunoffObs
		} else {
			obsNaFlag <- 1
			accRunoffObs <- accRunoffObs + runoff2_kaf
		}
                dfOut1$Observed_kaf[count] <- accRunoffObs

                dfOut4$POSIXct[count2] <- dCurrent
                dfOut4$Tag[count2] <- 'Observed'
                dfOut4$Basin[count2] <- basin
		dfOut4$q_cfs[count2] <- dailyCfs
                #dfOut4$q_cfs[count2] <- obsStrData$DISCHRG..cfs.[ind[1]]
                count2 <- count2 + 1

        	ind <- which(modData$POSIXct == dCurrent)
        	dfOut1$Modeled_cfs[count] <- modData$q_cms[ind[1]]*35.3147 # Convert modeled values in CMS to CFS
        	runoff1_af <- modData$q_cms[ind[1]]*(3600)/1233.48
        	runoff1_kaf <- runoff1_af/1000.0
		if (obsNaFlag == 0){
			accRunoffModel <- accRunoffModel
		} else {
			accRunoffModel <- accRunoffModel + runoff1_kaf
		}
        	dfOut1$Modeled_kaf[count] <- accRunoffModel

        	dfOut4$POSIXct[count2] <- dCurrent
        	dfOut4$Tag[count2] <- 'Modeled'
        	dfOut4$Basin[count2] <- basin
        	dfOut4$q_cfs[count2] <- modData$q_cms[ind[1]]*35.3147 # Convert modeled values in CMS to CFS
        	count2 <- count2 + 1

        	count <- count + 1

	}

    }
  }
}

print(dfOut1)
count <- 1
count2 <- 1
# Calculate mean/median values
for (basin in dwrId){
  year <- 2004
  bStr <- paste0(year,'-04-01')
  eStr <- paste0(year,'-10-01')
  bDate <- as.POSIXct(bStr,'%Y-%m-%d',tz="UTC")
  eDate <- as.POSIXct(eStr,'%Y-%m-%d',tz="UTC")

  for (day in 1:nDays){
    for (hour in 1:24){
       dfOut2$Basin[count] <- basin
       dCurrent <- bDate + 3600*day*24 + hour*3600
       dfOut2$POSIXct[count] <- dCurrent
       dateStr <- strftime(dCurrent,'%m-%d')

       ind <- which(dfOut1$Basin == basin & dfOut1$POSIXct == dCurrent)
       dfOut2$Mean_Observed_cfs[count] <- mean(dfOut1$Observed_cfs[ind],na.rm=TRUE)
       dfOut2$Median_Observed_cfs[count] <- median(dfOut1$Observed_cfs[ind],na.rm=TRUE)
       dfOut2$Mean_Observed_kaf[count] <- mean(dfOut1$Observed_kaf[ind],na.rm=TRUE)
       dfOut2$Median_Observed_kaf[count] <- median(dfOut1$Observed_kaf[ind],na.rm=TRUE)
       dfOut2$Mean_Modeled_cfs[count] <- mean(dfOut1$Modeled_cfs[ind],na.rm=TRUE)
       dfOut2$Median_Modeled_cfs[count] <- median(dfOut1$Modeled_cfs[ind],na.rm=TRUE)
       dfOut2$Mean_Modeled_kaf[count] <- mean(dfOut1$Modeled_kaf[ind],na.rm=TRUE)
       dfOut2$Median_Modeled_kaf[count] <- median(dfOut1$Modeled_kaf[ind],na.rm=TRUE)

       dfOut3$Mean_cfs[count2] <- mean(dfOut1$Observed_cfs[ind],na.rm=TRUE)
       dfOut3$Median_cfs[count2] <- median(dfOut1$Observed_cfs[ind],na.rm=TRUE)
       dfOut3$Mean_kaf[count2] <- mean(dfOut1$Observed_kaf[ind],na.rm=TRUE)
       dfOut3$Median_kaf[count2] <- median(dfOut1$Observed_kaf[ind],na.rm=TRUE)
       dfOut3$POSIXct[count2] <- dCurrent
       dfOut3$Basin[count2] <- basin
       dfOut3$Tag[count2] <- 'Observed'
       count2 <- count2 + 1

       dfOut3$Mean_cfs[count2] <- mean(dfOut1$Modeled_cfs[ind],na.rm=TRUE)
       dfOut3$Median_cfs[count2] <- median(dfOut1$Modeled_cfs[ind],na.rm=TRUE)
       dfOut3$Mean_kaf[count2] <- mean(dfOut1$Modeled_kaf[ind],na.rm=TRUE)
       dfOut3$Median_kaf[count2] <- median(dfOut1$Modeled_kaf[ind],na.rm=TRUE)
       dfOut3$POSIXct[count2] <- dCurrent
       dfOut3$Basin[count2] <- basin
       dfOut3$Tag[count2] <- 'Modeled'
       count2 <- count2 + 1

       count <- count + 1

    }
  }

# Print mean/median for each year to screen
  for (yearTmp in years){
    ind <- which(dfOut1$Basin == basin & as.numeric(strftime(dfOut1$POSIXct,'%Y')) == yearTmp)
    print(paste0('BASIN = ',basin))
    print(paste0('YEAR = ',yearTmp))
    print(paste0('MAX OBSERVED KAF = ',max(dfOut1$Observed_kaf[ind],na.rm=TRUE)))
    print(paste0('MAX MODELED KAF = ',max(dfOut1$Modeled_kaf[ind],na.rm=TRUE)))
  }
}

#save(dfOut3,file='TEST.Rdata')

# Generate Plots
for (basin in dwrId){
  title1 <- paste0('Mean Accumulated Runoff ',basin)
  title2 <- paste0('Median Accumulated Runoff ',basin)
  title3 <- paste0('Streamflow for ',basin)
  path1 <- paste0('mean_acc_runoff_kaf_',basin,'.png')
  path2 <- paste0('median_acc_runoff_kaf_',basin,'.png')

  dfTmp <- subset(dfOut3,Basin == basin)
  dfTmp1 <- subset(dfOut2,Basin == basin)

  gg <- ggplot(dfTmp, aes(x=POSIXct,y=Mean_kaf,color=Tag)) + geom_line() +
  #      geom_line(dfTmp, aes(x=POSIXct,y=Mean_Modeled_kaf,color=Mean_Modeled_kaf)) + 
        ggtitle(title1) + xlab('Date') + ylab('Accumulated Runoff (thousands acre-feet)')
  ggsave(filename=path1,plot=gg)

  gg <- ggplot(dfTmp, aes(x=POSIXct,y=Median_kaf,color=Tag)) + geom_line() +
  #      geom_line(dfTmp, aes(x=POSIXct,y=Median_Modeled_kaf,color=Median_Modeled_kaf)) +
        ggtitle(title2) + xlab('Date') + ylab('Accumulated Runoff (thousands acre-feet)')
  ggsave(filename=path2,plot=gg)

  # Generate hydrograph for all years
  
  #gg <- ggplot(dfOut4,aes(x=POSIXct,y=q_cfs,color=Tag)) + geom_line() + 
  #      ggtitle(title3) + xlab('Date') + ylab('Streamflow (cfs)')
  #pathLgHydro <- paste0(basin,'_Hydrograph_All_Years.png')
  #ggsave(filename=pathLgHydro,plot=gg)

  # Generate hydrographs for each year.
  for (year in years){
    bStr <- paste0(year,'-04-01')
    eStr <- paste0(year,'-10-01')
    bDate <- as.POSIXct(bStr,'%Y-%m-%d',tz="UTC")
    eDate <- as.POSIXct(eStr,'%Y-%m-%d',tz="UTC")
    title4 <- paste0(basin,' Hydrograph for Water Year: ',year)

    dfTmp2 <- subset(dfOut4,POSIXct >= bDate)
    dfTmp2 <- subset(dfTmp2,POSIXct <= eDate)
    dfTmp2 <- subset(dfTmp2,Basin == basin)
    pathAnnual <- paste0(basin,'_Hydrograph_',year,'.png')
    gg <- ggplot(dfTmp2,aes(x=POSIXct,y=q_cfs,color=Tag)) + geom_line() + 
          ggtitle(title4) + xlab('Date') + ylab('Streamflow (cfs)')
    ggsave(filename=pathAnnual,plot=gg)

  }

  # Calculate mean/median accumulated runoff values
  meanObsKaf <- max(dfTmp1$Mean_Observed_kaf,na.rm=TRUE)
  medianObsKaf <- max(dfTmp1$Median_Observed_kaf,na.rm=TRUE)
  meanModKaf <- max(dfTmp1$Mean_Modeled_kaf,na.rm=TRUE)
  medianModKaf <- max(dfTmp1$Median_Modeled_kaf,na.rm=TRUE)
  meanBias <- ((meanModKaf/meanObsKaf)-1)*100.0
  medianBias <- ((medianModKaf/medianObsKaf)-1)*100.0
  meanFactor <- (1.0/(meanModKaf/meanObsKaf))
  medianFactor <- (1.0/(medianModKaf/medianObsKaf))
  print(dfTmp)
  # Print acc runoff values
  print(paste0('BASIN = ',basin))
  print(paste0('MEAN OBS RUNOFF = ',meanObsKaf,' THOUSANDS ACRE FEET'))
  print(paste0('MEDIAN OBS RUNOFF = ',medianObsKaf,' THOUSANDS ACRE FEET'))
  print(paste0('MEAN MOD RUNOFF = ',meanModKaf,' THOUSANDS ACRE FEET'))
  print(paste0('MEDIAN MOD RUNOFF = ',medianModKaf,' THOUSANDS ACRE FEET'))
  print(paste0('MEAN RUNOFF BIAS AGAINST OBS = ',meanBias,' PERCENT'))
  print(paste0('MEDIAN RUNOFF BIAS AGAINST OBS = ',medianBias,' PERCENT'))
  print(paste0('MEAN CORRECTION FACTOR = ',meanFactor))
  print(paste0('MEDIAN CORRECTION FACTOR = ',medianFactor))

}
