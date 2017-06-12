# This is a workflow program for ingesting various ESP model runs for
# Colorado and generating real-time plots for pushing to hydro-c1-web
# for display on hydro-inspector.

# Logan Karsten
# National Center for Atmospheric Research
# Research Applications Laboratory

import numpy as np
import os
import sys
from netCDF4 import Dataset
import subprocess
import datetime
from mpi4py import MPI
import math

fcstPtCsv = "/glade/u/home/karsten/RHAP_home/wrf_hydro_analysis/URG_2017/DWR_gages_Filter_Hourly.csv"
rtLnkPath = "/glade/p/work/karsten/URG_2017/RouteLink_URG_WY2017_CALIB.nc"
ncOutPath = "/glade/u/home/karsten/RHAP_home/wrf_hydro_analysis/URG_2017/ESP_Plotting/STREAM_ESP_NC/streamFlow_2017_hourly.nc"
obsDir = "/glade/u/home/karsten/RHAP_home/wrf_hydro_analysis/URG_2017/ESP_Plotting/OBS_HOURLY"
modPath = "/glade/u/home/karsten/RHAP_home/wrf_hydro_analysis/URG_2017/ESP_Plotting/STREAM_ESP_NC/streamFlow_2017_hourly.nc"
plotProgram = "/glade/u/home/karsten/RHAP_home/wrf_hydro_analysis/URG_2017/ESP_Plotting/plotEnsembles_hourly.R"
biasCorrDir = "/glade/u/home/karsten/RHAP_home/wrf_hydro_analysis/URG_2017/Bias_Calc_2017/Run_Retro_Calc"

# Establish MPI objects
comm = MPI.COMM_WORLD
size = comm.Get_size()
rank = comm.Get_rank()

rank = int(rank)
size = int(size)
numBasins = 515
numIter = int(math.ceil(float(numBasins)/float(size)))

# Get the current date, then update the observations file to reflect current observations.
dNow = datetime.datetime.now()

# Add some latency to the observations being read in.
dNow = dNow - datetime.timedelta(seconds=3600*24)

bDate = datetime.datetime(2017,4,1)
eDate = datetime.datetime(2017,10,1)

for iteration in range(0,numIter):
	basNum = iteration*size + rank + 1

	if basNum <= numBasins:
		# Run R code to calculate accumulated flows, and ensemble plots for available stations
		cmd = "Rscript " + plotProgram + " " + modPath + " " + obsDir + " " + fcstPtCsv + " " + biasCorrDir + " " + str(basNum)
		subprocess.call(cmd,shell=True)

# Shutdown MPI
comm.Disconnect()
