# Quick program to download observations from DWR

library(rwrfhydro)

ptsCsv <- "/glade/u/home/karsten/RHAP_home/wrf_hydro_analysis/URG_2017/DWR_gages_Filter2.csv"

metaData <- read.table(ptsCsv,header=TRUE,sep=',',stringsAsFactors = FALSE)
dwrIds <- metaData$DWR_ID
numPts = length(metaData$ID)

for (basin in dwrIds){
	print(basin)
	idsTmp <- c(basin)
	obsStrData <- GetCoDwrData(idsTmp,paramCodes=c("DISCHRG"),timeInt="hourly",startDate="10/01/2003",endDate="10/01/2016")
	save(obsStrData,file=paste0('Obs_',basin,'.Rdata'))

}
