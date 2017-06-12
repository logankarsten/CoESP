# Quick script to push ESP forecast plots for DWR stations to
# hydro-c1-web.

# Logan Karsten
# National Center for Atmospheric Research
# Research Applications Laboratory

plotDirHourly='/glade/u/home/karsten/RHAP_home/wrf_hydro_analysis/URG_2017/ESP_Plotting/PLOTS_HOURLY'
pushDir='/d2/hydroinspector_data/tmp/Exp_ESP/prod/analysis/ACCFLOW'

cd $plotDirHourly
for FILE in *.png; do
	AGE=`find ${FILE} -mmin +5`
	if [ ${#AGE} != 0 ]; then
		sshpass -p 'Purdy$1986_05' scp $FILE karsten@hydro-c1-web.rap.ucar.edu:${pushDir}
		rm -rf $FILE
	fi
done 
