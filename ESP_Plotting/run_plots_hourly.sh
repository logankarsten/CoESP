#!/bin/bash
#
## LSF batch script to run the test MPI code
#
#BSUB -P NRAL0017                      # Project 99999999
#BSUB -n 32                             # number of total (MPI) tasks
#BSUB -J Exp_ESP_Plotting_hourly                  # job name
#BSUB -o Exp_ESP_Plot_hourly.out                 # output filename
#BSUB -e Exp_ESP_Plot_hourly.err                 # error filename
#BSUB -W 12:00                         # wallclock time
#BSUB -q geyser


#export LSF_SERVERDIR=/ncar/opt/lsf/9.1/linux2.6-glibc2.3-x86_64/etc
#export LSF_ENVDIR=/ncar/opt/lsf/conf

cd /glade/u/home/karsten/RHAP_home/wrf_hydro_analysis/URG_2017/ESP_Plotting
mpirun.lsf ./cmd_plot_hourly.sh
