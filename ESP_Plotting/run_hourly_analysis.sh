#!/bin/bash
# Top level script to run ESP analysis for DWR points where we 
# calculated bias correction factors that had hourly observations
# available. 

# Logan Karsten
# National Center for Amtospheric Research
# Research Applications Laboratory

export PATH=/glade/apps/opt/netcdf4python/1.1.1/gnu-westmere/4.8.2/bin:/glade/apps/opt/numpy/1.8.1/intel-autodispatch/14.0.2/bin:/glade/apps/opt/python/2.7.7/gnu-westmere/4.8.2/bin:/glade/apps/opt/ncview/2.1.1/gnu/4.4.6/bin:/glade/apps/opt/nco/4.5.5/gnu/4.8.2/bin:/glade/apps/opt/esmf/7.0.0-defio/intel/12.1.5/bin/binO/Linux.intel.64.mpich2.default:/glade/u/home/karsten/anaconda2/bin:/glade/u/home/karsten/lib/grib_api_1.14.2_intel/bin:/usr/lib64/qt-3.3/bin:/glade/apps/opt/netcdf/4.3.0/intel/12.1.5/bin:/glade/apps/opt/modulefiles/ys/cmpwrappers:/ncar/opt/intel/12.1.0.233/composer_xe_2011_sp1.11.339/bin/intel64:/glade/apps/opt/usr/bin:/ncar/opt/lsf/9.1/linux2.6-glibc2.3-x86_64/etc:/ncar/opt/lsf/9.1/linux2.6-glibc2.3-x86_64/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/openssh/5.7p1krb/bin:/usr/local/sbin:/opt/ibutils/bin:/ncar/opt/hpss:/glade/apps/opt/r/3.2.2/intel/16.0.0/bin:/glade/apps/opt/ncl/6.3.0/intel/12.1.5/bin

export LD_LIBRARY_PATH=/glade/apps/opt/gnu/4.7.2/lib64:/ncar/opt/intel/psxe-2016/compilers_and_libraries_2016.0.109/linux/compiler/lib/intel64:/glade/apps/opt/usr/lib:/opt/ibmhpc/pecurrent/mpich2/intel/lib64:/glade/u/home/karsten/lib/grib_api_1.14.2_intel/lib:/glade/apps/opt/esmf/7.0.0-defio/intel/12.1.5/lib/libO/Linux.intel.64.mpich2.default:/ncar/opt/intel/12.1.0.233/composer_xe_2011_sp1.11.339/compiler/lib/intel64:/ncar/opt/lsf/9.1/linux2.6-glibc2.3-x86_64/lib

export PYTHONPATH=/glade/apps/opt/netcdf4python/1.1.1/gnu-westmere/4.8.2/lib/python2.7/site-packages:/glade/apps/opt/numpy/1.8.1/intel-autodispatch/14.0.2/lib/python2.7/site-packages:/glade/apps/opt/mpi4py/1.3.1/gnu/4.8.2/lib/python2.7/site-packages

export LSF_SERVERDIR=/ncar/opt/lsf/9.1/linux2.6-glibc2.3-x86_64/etc
export LSF_ENVDIR=/ncar/opt/lsf/conf

cd /glade/u/home/karsten/RHAP_home/wrf_hydro_analysis/URG_2017/ESP_Plotting
rm -rf analysisLogHourly.txt
echo $?
rm -rf Exp_ESP_Plot_hourly.*
echo $?
rm -rf ANALYSIS_FILES_HOURLY/* 
echo $?
rm -rf OBS_HOURLY/*
echo $?
Rscript /glade/u/home/karsten/RHAP_home/wrf_hydro_analysis/URG_2017/ESP_Plotting/fetchObs.R
echo $?
bsub < /glade/u/home/karsten/RHAP_home/wrf_hydro_analysis/URG_2017/ESP_Plotting/run_plots_hourly.sh
echo $?
exit 0
