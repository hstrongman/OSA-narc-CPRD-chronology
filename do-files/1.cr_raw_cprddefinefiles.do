
capture log close
log using "$logdir\1.cr_raw_cprddefinefiles.txt", text replace

/*******************************************************************************
# Stata do file:    1.cr_dm_cprddefinefiles.do
#
# Author:      Helen Strongman
#
# Date:        30/08/2022
#
# Description: 	This do file uses 1.inc_cprddefinefiles.do to imports individual 
#				define text files and saves them as a single stata file for the 
#				specified database and medical condition with a file type
#				variable described the CPRD file that the event was recorded in
#				and the category variable from the code list file. It checks that the 
#				imported data matches the code list and Define log.
#				
# Inspired and adapted from: 
# 				N/A
#
# Before running this file: check that the database and medcondition locals
#				match your study population. Add definecount locals using data
#				from the log file exported from define (xxx.Define.log.txt).
*******************************************************************************/

foreach database in aurum gold {
	foreach medcondition in sleep_apnoea narcolepsy {
		if "`database'" == "aurum" & "`medcondition'" == "sleep_apnoea" local definecount = 606191
		if "`database'" == "aurum" & "`medcondition'" == "narcolepsy" local definecount = 30776
		if "`database'" == "gold" & "`medcondition'" == "sleep_apnoea" local definecount = 153620
		if "`database'" == "gold" & "`medcondition'" == "narcolepsy" local definecount = 6979
		di as yellow "`medcondition' `database' `definecount'"
		include "$dodir\inc_1.cr_raw_cprddefinefiles.do"
		compress
		save "$datadir_dm\1.cr_raw_cprddefinefiles_`medcondition'_`database'.dta", replace
	}
}

capture log close



