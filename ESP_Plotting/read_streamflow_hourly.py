# Quick and dirty program to read in ESP streamflow for a set
# of predefined forecast points. Data will be stored 
# in a NetCDF file as a time series. This is done as reading
# in streamflow data through R has proven to be slow and
# inefficient. 

# Logan Karsten
# National Center for Atmospheric Research 
# Research Applications Laboratory

import numpy as np
from netCDF4 import Dataset
import pandas as pd
import datetime
import os

fcstPtsCsv = "/glade/u/home/karsten/RHAP_home/wrf_hydro_analysis/URG_2017/DWR_gages_Filter_Hourly.csv"
rtLnkPath = "/glade/p/work/karsten/URG_2017/RouteLink_URG_WY2017_CALIB.nc"
ncOutPath = "/glade/u/home/karsten/RHAP_home/wrf_hydro_analysis/URG_2017/ESP_Plotting/STREAM_ESP_NC/streamFlow_2017_hourly.nc"

espDates = ['20170401','20170427','20170512','20170528']
years = [2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016]

begDate = datetime.datetime(2017,4,1)
endDate = datetime.datetime(2017,10,1)
dt = endDate - begDate

nHours = dt.days*24

# Open the streamflow forecast point file and read in linkIDs to be read in.
dfPts = pd.read_csv(fcstPtsCsv)

# Read in the RouteLink file, loop through the forecast points, and calculate
# the index values for each forecast point. These will be used to subset from 
# the CHRTOUT files.
idRt = Dataset(rtLnkPath)
indexValues = np.empty([len(dfPts.ID)],np.int32)
for station in range(0,len(dfPts.ID)):
	print station
	indexValues[station] = np.where(idRt.variables['link'][:] == dfPts.ID[station])[0][0]

# Create output arrays to hold streamflow data.
dataOut = np.empty([len(dfPts.ID),len(years),len(espDates),nHours],np.float32)
idsOut = np.empty([len(dfPts.ID)],np.int32)
idsOut[:] = dfPts.ID

# Fill data with missing values 
dataOut[:,:,:] = -9999.0

# Loop through each ESP forecast, then each year. Read in CHRTOUT for a given hour, and proceed.
for esp in range(0,len(espDates)):
	print "ESP = " + espDates[esp]
	for year in range(0,len(years)):

		print "YEAR = " + str(years[year])
		espDate = datetime.datetime.strptime(espDates[esp],'%Y%m%d')
		topDir = "/glade/u/home/karsten/RHAP_home/wrf_hydro_model_runs/URG/URG_ESP_" + \
                         espDate.strftime('%m%d%Y')

		yearDir = topDir + "/" + str(years[year])
			
		# Loop through all possible dates. If a CHRTOUT file is not found, it's assumed 
		# the model was ran after this date, so keep the output array as missing.
		for hour in range(0,nHours):
			dCurrent = begDate + datetime.timedelta(seconds=3600*hour)
			fileIn = yearDir + "/" + dCurrent.strftime('%Y%m%d%H') + '00.CHRTOUT_DOMAIN1'
			if os.path.isfile(fileIn):
				idTmp = Dataset(fileIn,'r')
				dataOut[:,year,esp,hour] = idTmp.variables['streamflow'][indexValues]
				idTmp.close()

# Write output to NetCDF file
idOut = Dataset(ncOutPath,'w')

ptsDim = idOut.createDimension('fcstPts',len(dfPts.ID))
yearDim = idOut.createDimension('years',len(years))
espDim = idOut.createDimension('esp',len(espDates))
timeDim = idOut.createDimension('Time',nHours)

streamVar = idOut.createVariable('streamflow','f4',('fcstPts','years','esp','Time'),fill_value=-9999.0,zlib=True,complevel=2)
idVar = idOut.createVariable('linkIds','i4',('fcstPts'),zlib=True,complevel=2)

streamVar.units = "m^3s-1"
streamVar.long_name = "Streamflow"

idVar.long_name = "NHD Flowline ID"

streamVar[:,:,:,:] = dataOut
idVar[:] = idsOut

idOut.close()
