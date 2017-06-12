#!/bin/csh
#
## LSF batch script to run the test MPI code
#
#BSUB -P NRAL0017                      # Project 99999999
#BSUB -n 512                             # number of total (MPI) tasks
#BSUB -x
#BSUB -J URG_bias_calc_hourly                  # job name
#BSUB -o URG_bias_calc_hourly.out                 # output filename
#BSUB -e URG_bias_calc_hourly.err                 # error filename
#BSUB -W 12:00                         # wallclock time
#BSUB -q premium

cd /glade/u/home/karsten/RHAP_home/wrf_hydro_analysis/URG_2017/Bias_Calc_2017/Run_Retro_Calc
mpirun.lsf ./cmd_run_hourly.sh
