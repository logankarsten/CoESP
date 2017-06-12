# R Program for plotting bias-corrected ensemble streamflow
# for various forecast points in CO to support season streamflow
# forecasting. This program utilizes model output that has already
# been read in to a NetCDF file, along with observations which are 
# stored in an R dataset.

# Logan Karsten
# National Center for Atmospheric Research
# Research Applications Laboratory

library(ggplot2)
library(ncdf4)
library(grid)

ColorBar <- function (colorVect, nOut = NULL, plot=TRUE) {
    if (FALSE) {
        clVct <- RColorBrewer::brewer.pal(8, "Dark2")
        ColorBar(clVct)
        ColorBar(clVct, nOut = 100)
        ColorBar(RColorBrewer::brewer.pal(8, "Paired"), 25)
    }
    if (!is.null(nOut))
        colorVect <- colorRampPalette(colorVect)(nOut)
    if(plot) {
      nClr <- length(colorVect)
      df <- data.frame(x = 1:nClr, y = 0, fill = colorVect)
      plot(ggplot2::ggplot(df, ggplot2::aes(x = x, y = y, fill = fill)) +
           ggplot2::geom_raster() + ggplot2::scale_fill_manual(values = colorVect) +
           ggplot2::theme_bw())
    }
    invisible(colorVect)
}

# Read in arguments that point to input files.
args = commandArgs(trailingOnly=TRUE)
modPath <- args[1]
obsDir <- args[2]
metaCsv <- args[3]
biasDir <- args[4]
basinNum <- as.integer(args[5]) + 1

plotDir <- '/glade/u/home/karsten/RHAP_home/wrf_hydro_analysis/URG_2017/ESP_Plotting/PLOTS_HOURLY'
dfOutDir <- '/glade/u/home/karsten/RHAP_home/wrf_hydro_analysis/URG_2017/ESP_Plotting/ANALYSIS_FILES_HOURLY'

ensRunsLabels <- c('20170401','20170427','20170512','20170528')
ensPlotLabels <- c('2017-04-01','2017-04-27','2017-05-12','2017-05-28')
ensYearsLabels <- c('2004','2005','2006','2007','2008','2009','2010',
                    '2011','2012','2013','2014','2015','2016')
# Load in metadata 
metaData <- read.table(metaCsv,sep=',',header=TRUE)
#metaData <- subset(metaData,DWR_ID == 'RIODELCO')
metaData <- subset(metaData,DWR_ID == metaData$DWR_ID[basinNum])

# Determine number of forecast points we are modeling
#numPts <- length(unique(obsStrData$Station))
numPts <- length(unique(metaData$DWR_ID))
dwrIds <- metaData$DWR_ID
featureIds <- metaData$ID

obsPath <- paste0(obsDir,'/Obs_',dwrIds[1],'.Rdata')
load(obsPath)

# Open up modeled values containing streamflow for all sites for melt period.
id <- nc_open(modPath)
modNcData <- ncvar_get(id,'streamflow')
modIds <- ncvar_get(id,'linkIds') 

numEns <- dim(modNcData)[3]
numRuns <- dim(modNcData)[2]
numSteps <- dim(modNcData)[1]

#Setup beginning and ending date
bDate <- as.POSIXct('2017-04-01')
eDate <- as.POSIXct('2017-10-01')
dUnits <- "hours"
diff1 <- difftime(eDate,bDate,units = dUnits)
dSec <- diff1*3600
dt <- 3600
# Populate POSIXct array
dateArray <- as.POSIXct(rep(NA,10))

for (i in 1:numSteps){
	dateArray[i] <- bDate + dt*i
}

# Create dateframe that will hold data/obs for each forecast point.
dataPlot <- data.frame(matrix(NA,ncol=8,nrow=(numSteps*numEns*numRuns + numSteps + 1)))
dataQuantile <- data.frame(matrix(NA,ncol=9,nrow=numSteps))
names(dataQuantile) <- c('POSIXct','q05','q10','q25','q50','q75','q90','q95','Product')
names(dataPlot) <- c("DWR_ID","POSIXct","Ens_Run","Year","Product","q_cfs","acc_kaf","lead_time")
dataPlot$POSIXct <- as.POSIXct('1900-01-01')
dataQuantile$POSIXct <- as.POSIXct('1900-01-01')

if (length(dwrIds) == 0){
	quit(0)
}

# Loop through each forecast point, place data into the data frame
for (station in 1:numPts){
	count <- 1
	dwrId <- dwrIds[station]
	dataPlot$DWR_ID <- dwrId
	featureId <- featureIds[station]

	obsStrDataTmp <- subset(obsStrData,Station == dwrId)

	print(dwrId)
	countTime <- 1
	# Loop throuh all the time steps and place observations into the plotting data frame.
	for (i in 1:numSteps){
		dataPlot$POSIXct[count] <- dateArray[i]
		dataPlot$Ens_Run[count] <- 'Obs'
		dataPlot$Year[count] <- 'Obs'
		dataPlot$Product[count] <- 'Obs'
		indTmp <- which(obsStrDataTmp$POSIXct == dateArray[i])
		if(length(indTmp) != 0){
			dataPlot$q_cfs[count] <- obsStrDataTmp$DISCHRG..cfs.[indTmp]
		}
		count <- count + 1
	}

	# Calculate where we have valid observations as there may be period of missing data.
	indObsValid <- which(!is.na(dataPlot$q_cfs) & dataPlot$Product == 'Obs')

	# Calculate accumulated flow (where valid observations exist) in thousands of acre-feet.
	# NOTE this is a conversion from cfs to acre-feet.
	dataPlot$acc_kaf[indObsValid] <- cumsum(((dataPlot$q_cfs[indObsValid]*3600.0)/43559.9)/1000.0)

	# Pull out array of observed streamflow and accumulated flow for use later.
	dfObs <- subset(dataPlot,Product == 'Obs')
 
	dfPrint <- subset(dataPlot,Product == 'Obs')
	# Open up and load in bias-correction information previously calculated.
	biasFile <- paste0(biasDir,'/BIAS_STATS_HOURLY/',dwrId,'_biasStats.Rdata')
	if(!file.exists(biasFile)){
           biasFactor <- 1.0
	} else {
	   load(biasFile)
	   biasFactor <- dfBias$mean_bias_factor
		#biasFactor <- 0.89
	}
	if (dwrId == "RIODELCO") {
                biasFactor = 0.89
        } else if (dwrId == "CONMOGCO") {
                biasFactor = 1.0
        } else if (dwrId == "LOSORTCO") {
                biasFactor = 0.66
        } else if (dwrId == "SANORTCO") {
                biasFactor = 0.29
        } else if (dwrId == "SANMANCO") {
		biasFactor = 0.31
	}
	# Loop through each ensemble run
	for (ensRun in 1:numRuns){
		countYear <- 1
		# Loop through each ensemble year
		for (ensYear in 1:numEns){
			productStr <- paste0(ensRunsLabels[ensRun],'_',ensYearsLabels[ensYear])
			dataPlot$Ens_Run[count:(count+numSteps)] <- ensRunsLabels[ensRun]
			dataPlot$Year[count:(count+numSteps)] <- ensYearsLabels[ensYear]	
			dataPlot$POSIXct[count:(count+numSteps)] <- dateArray
			dataPlot$Product[count:(count+numSteps)] <- productStr
			indIdNc <- which(modIds == featureId)
			modDataTmp <- modNcData[,ensRun,ensYear,indIdNc]
			modDataTmp <- modDataTmp*biasFactor
			#accModKaf <- cumsum(((modDataTmp*3600.0)/1233.48)/1000.0)
			dataPlot$q_cfs[count:(count+numSteps)] <- modDataTmp

			# Determine beginning of model run. If it's not the first time step, determine if accumulated
			# observations exist and add them to the modeled values. 
			indTmp <- which(!is.na(modDataTmp))

			# Calculate lead times (in time steps)
			leadTimes <- indTmp - indTmp[1]
			leadTmp <- dataPlot$lead_time[count:(count+numSteps)] 
			leadTmp[indTmp] <- leadTimes
			dataPlot$lead_time[count:(count+numSteps)] <- leadTmp
	
			# Calculate accumulated flow where model values are valid.
			accModKaf <- modDataTmp
			accModKaf <- NA
			# NOTE this is a conversion from cfs to acre-feet
			accModKaf[indTmp] <- cumsum(((modDataTmp[indTmp]*3600.0)/1233.48)/1000.0)

			if (dateArray[indTmp[1]] != dateArray[2]) {
				# This isn't an 4/1 ESP. We need to add observed accumulated flow at this time step
				# to the accumulated flow.
				if (!is.na(dfObs$acc_kaf[indTmp[1]])){
					accModKaf[indTmp] <- accModKaf[indTmp] + dfObs$acc_kaf[indTmp[1]]
				} else {
					# No observations are present here.... For simplicity, we are going 
					# to add the previous ESP run's accumulated flow value here.
					# Most likely this is a station that has not begun to report streamflow
					# due to delayed meltout. This is being done to keep the plots looking consistent.
					dataTmp <- subset(dataPlot,Ens_Run == ensRunsLabels[ensRun-1] & 
                                                          Year == ensYearsLabels[ensYear] &
							  POSIXct == dateArray[indTmp[1]])
					accModKaf[indTmp] <- accModKaf[indTmp] + dataTmp$acc_kaf[1]
				}
			}
			dataPlot$acc_kaf[count:(count+numSteps)] <- accModKaf
			count <- count + numSteps
	
		}
	}

	dataModel <- subset(dataPlot,Product != 'Obs')
	dataObservations <- subset(dataPlot,Product == 'Obs')

	# Loop through all the time steps and calculate quantile stats on forecasted flow
	for (i in 1:numSteps){
		dateTmp <- dateArray[i]
		dataQuantile$POSIXct[i] <- dateTmp
		dataQuantile$Product[i] <- 'Ensemble'
		dataQuantile$q05[i] <- quantile(dataModel$acc_kaf[which(dataModel$POSIXct == dateTmp & !is.na(dataModel$acc_kaf))],0.05)
		dataQuantile$q10[i] <- quantile(dataModel$acc_kaf[which(dataModel$POSIXct == dateTmp & !is.na(dataModel$acc_kaf))],0.10)
		dataQuantile$q25[i] <- quantile(dataModel$acc_kaf[which(dataModel$POSIXct == dateTmp & !is.na(dataModel$acc_kaf))],0.25)
		dataQuantile$q50[i] <- quantile(dataModel$acc_kaf[which(dataModel$POSIXct == dateTmp & !is.na(dataModel$acc_kaf))],0.50)
		dataQuantile$q75[i] <- quantile(dataModel$acc_kaf[which(dataModel$POSIXct == dateTmp & !is.na(dataModel$acc_kaf))],0.75)
		dataQuantile$q90[i] <- quantile(dataModel$acc_kaf[which(dataModel$POSIXct == dateTmp & !is.na(dataModel$acc_kaf))],0.90)
		dataQuantile$q95[i] <- quantile(dataModel$acc_kaf[which(dataModel$POSIXct == dateTmp & !is.na(dataModel$acc_kaf))],0.95)		
	}

	colorBreaks <- c(0,240*(1:16))
	colorVect <- RColorBrewer::brewer.pal(10,'Paired')
	colorLabels <- colorBreaks/24
	colorGuide <- guides(col = guide_legend(nrow = 8))
	colorName <- 'Forecast (Days)'
	colorVect2 <- c('cyan',ColorBar(colorVect, nOut=max(colorBreaks)-1, plot=FALSE))
	xLabel <- 'Date'
	yLabel <- 'Accumulated Flow (thousands acre-feet)'
	title <- paste('2017 Colorado ESP for: ',dwrId)
	tblHdr <- grobTree(textGrob('ESP               Mean/Median (thousands acre-feet)',
                           x=0.01,y=0.99,hjust=0,gp=gpar(fontsize=8,fontface='italic')))
	# Generate accumulated flow plots
	gg <- ggplot(data=dataModel,aes(x=POSIXct,y=acc_kaf,group=Product,color=lead_time),size=0.25,alpha=0.6) + 
			geom_smooth(data=dataQuantile,aes(x=POSIXct,y=q50,ymin=q05,ymax=q95),stat='identity',
			            alpha=0.3,fill='grey90',color='white') + 
			geom_smooth(data=dataQuantile,aes(x=POSIXct,y=q50,ymin=q10,ymax=q90),stat='identity',
                                    alpha=0.3,fill='grey45',color='white') +
			geom_smooth(data=dataQuantile,aes(x=POSIXct,y=q50,ymin=q25,ymax=q75),stat='identity',
                                    alpha=0.3,fill='black',color='white') +
			geom_line(size=0.25,alpha=0.6) +
                        geom_point(data=dataObservations,aes(x=POSIXct,y=acc_kaf),color='black',size=0.6,shape=21,alpha=0.05) +
			ggtitle(title) + xlab(xLabel) + ylab(yLabel) +
			annotation_custom(tblHdr) + 
			theme_bw() + 
			guides(alpha=FALSE,colour= guide_legend(override.aes = list(size=5,alpha=1))) + 
			scale_alpha_continuous(range=rev(c(0.45, .65)-.3)) + 
			scale_color_gradientn(colors=colorVect2,
										breaks=colorBreaks,
										labels=colorLabels,
										name=colorName) + 
			guides(fill=guide_legend(order=1), colour=guide_legend(order=2)) +
      	colorGuide
	# Print mean/median accumulated flows for each ESP value to the plot
	for (ensRun in 1:numRuns){
		annualFlows <- array(NA,c(numEns))
		for (ensYear in 1:numEns){
			annualFlows[ensYear] <- max(dataModel$acc_kaf[which(dataModel$Ens_Run == ensRunsLabels[ensRun] & dataModel$Year == ensYearsLabels[ensYear])],na.rm=TRUE)
		}
		meanKaf <- mean(annualFlows)
		medianKaf <- median(annualFlows)
		txtTmp <- paste0(ensPlotLabels[ensRun],'    ',format(round(meanKaf,1)),
                                 ' / ',format(round(medianKaf,1)))
		valTxt <- grobTree(textGrob(txtTmp,x=0.01,y=(0.99-(0.02*ensRun)),hjust=0,gp=gpar(fontsize=8,fontface='italic')))
		gg <- gg + annotation_custom(valTxt)
	}
	plotPath <- paste0(plotDir,'/Exp_ESP_',dwrId,'_',strftime(Sys.time(),'%Y%m%d'),'_ACCFLOW.png') 
	ggsave(filename=plotPath,plot=gg)
	 
	fileOut = paste0(dfOutDir,'/data_analysis_',dwrId,'.Rdata')
	save(dataPlot,dataModel,dataObservations,dataQuantile,file=fileOut)
}
