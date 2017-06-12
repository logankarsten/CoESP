# Top level program to launch Rscripts from various cores 
# to calculate biases for a given basin. This is done to 
# poor-man speed up processing.

# Logan Karsten
# National Center for Atmospheric Research
# Research Applications Laboratory

import subprocess
from mpi4py import MPI
import math

# Establish MPI objects
comm = MPI.COMM_WORLD
size = comm.Get_size()
rank = comm.Get_rank()

rank = int(rank)
size = int(size)
numBasins = 515

numIter = int(math.ceil(float(numBasins)/float(size)))

rProgram = "/glade/u/home/karsten/RHAP_home/wrf_hydro_analysis/URG_2017/Bias_Calc_2017/Run_Retro_Calc/calc_DWR_Bias_Hourly.R"

for iteration in range(0,numIter):
	basNum = iteration*size + rank + 1

	#print "RANK = " + str(rank)
	cmd = "Rscript " + rProgram + " " + str(basNum)

	if basNum <= numBasins:
		print "BASIN NUMBER = " +  str(basNum)
	#	# Run program for this specific basin to calculate biases and generate plots
	#	subprocess.call(cmd,shell=True)		

# Shutdown MPI
comm.Disconnect()	
