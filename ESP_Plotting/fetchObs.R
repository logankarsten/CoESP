# Quick and dirty program to download CODWR observations for a set
# of forecast streamflow points.

# Logan Karsten
# National Center for Atmospheric Research
# Research Applications Laboratory

library(rwrfhydro)

outDir <- "/glade/u/home/karsten/RHAP_home/wrf_hydro_analysis/URG_2017/ESP_Plotting/OBS_HOURLY"
ptsCsv <- "/glade/u/home/karsten/RHAP_home/wrf_hydro_analysis/URG_2017/DWR_gages_Filter_Hourly.csv"

metaData <- read.table(ptsCsv,header=TRUE,sep=',',stringsAsFactors = FALSE)
dwrIds <- metaData$DWR_ID
numPts = length(metaData$ID)

for (basin in dwrIds){
        print(basin)
        idsTmp <- c(basin)
        obsStrData <- GetCoDwrData(idsTmp,paramCodes=c("DISCHRG"),timeInt="hourly",startDate="04/01/2017",endDate=strftime(Sys.time(),'%m/%d/%Y'))
	outFile <- paste0(outDir,'/Obs_',basin,'.Rdata')
	if (file.exists(outFile)){
		file.remove(outFile)
	}
	save(obsStrData,file=outFile)
}
