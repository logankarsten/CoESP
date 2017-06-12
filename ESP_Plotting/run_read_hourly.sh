#!/bin/csh
#
## LSF batch script to run the test MPI code
#
#BSUB -P NRAL0017                      # Project 99999999
#BSUB -n 1                             # number of total (MPI) tasks
#BSUB -R "span[ptile=1]"               # run a max of 8 tasks per node
#BSUB -q geyser
#BSUB -J Exp_ESP_Read_Hourly                  # job name
#BSUB -o Exp_ESP_Read_Hourly.out                 # output filename
#BSUB -e Exp_ESP_Read_Hourly.err                 # error filename
#BSUB -W 24:00                         # wallclock time

cd /glade/u/home/karsten/RHAP_home/wrf_hydro_analysis/URG_2017/ESP_Plotting
mpirun.lsf ./cmd_read_hourly.sh
