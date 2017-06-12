# Quick and dirty program to filter out sites from the first DWR filter
# list via http requests. Basically, if we cannot get data from 10/1/2003
# to 10/1/2016 for a site, then we will junk the site.

# Logan Karsten
# National Center for Atmospheric Research
# Research Applications Laboratory

import pandas as pd
import requests

csvIn = "/glade/u/home/karsten/RHAP_home/wrf_hydro_analysis/URG_2017/DWR_gages_Filter1.csv"
csvOut = "/glade/u/home/karsten/RHAP_home/wrf_hydro_analysis/URG_2017/DWR_gages_Filter2.csv"

dfIn = pd.read_csv(csvIn)

listBad = []
listGood = []

for site in range(0,len(dfIn.ID)):
	print site
	url = 'http://www.dwr.state.co.us/SurfaceWater/data/export_tabular.aspx?ID=' + \
              dfIn.DWR_ID[site] + '&MTYPE=DISCHRG&INTERVAL=2&START=10/01/03&END=10/01/16'

	r = requests.get(url)
	if r.text.find('error') != -1:
		print "REMOVING STATION: " + dfIn.DWR_ID[site]
		listBad.append(dfIn.DWR_ID[site])
	else:
		print "KEEPING STATION: " + dfIn.DWR_ID[site]
		listGood.append(dfIn.DWR_ID[site])

	# Subset dataframe to exclude bad stations
	dfOut = dfIn[dfIn.DWR_ID.isin(listGood)]

	# Reset index
	dfOut = dfOut.reset_index(drop=True)

	dfOut.to_csv(csvOut)
