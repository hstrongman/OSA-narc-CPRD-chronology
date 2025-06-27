
clear
log using "$logdir\3.cr_raw_onsmortalitydodfiles.txt", text replace

/*******************************************************************************
# Stata do file:   3.cr_raw_onsmortalitydodfiles.do
#
# Author:      Helen Strongman
#
# Date:        21/09/2022
#
# Description: 	This do file imports ONS mortality files provided by 
#				CPRD upon request, and saves a single stata file for each  
#				primary care database. 
#
# Inspired and adapted from: 
# 				N/A
*******************************************************************************/

foreach database in gold aurum {
	if "`database'" == "gold" local capdatabase "Gold"
	if "`database'" == "aurum" local capdatabase "Aurum"
	import delimited using "$datadir_raw\22_001887_Type1_Request\\`capdatabase'_ONS.txt", ///
	varnames(1) case(lower) stringcols(_all) clear

	rename dod _dod
	gen dod = date(_dod, "DMY")
	format dod %td
	summ dod, d format
	drop _dod

	compress
	save "$datadir_raw\22_001887_Type1_Request\cr_raw_onsmortalitydodfiles_`database'.dta", replace

	}

capture log close



