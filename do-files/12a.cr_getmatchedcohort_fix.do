capture log close
log using "$logdir\12a.cr_getmatchedcohort.txt", replace text

/*******************************************************************************
# Stata do file:    12a.cr_getmatchedcohort_fixed.do
#
# Author:      Helen Strongman
#
# Date:        29/06/2023
#
# Description: 	This do file removes merged Aurum practices from the
#				get matched cohort file. These were removed from the study
#				population after the matched cohort data were extracted and linkedtext
#				data requested. This do file would not be needed if the study
#				was repeated.
#
# Inspired and adapted from: 
#				N/A
*******************************************************************************/

pause on
foreach database in aurum {
foreach linkedtext in primary linked {
foreach medcondition in OSA narcolepsy {
	
	use "$datadir_dm\12.cr_getmatchedcohort_`medcondition'_`database'_`linkedtext'.dta", clear
	save "$datadir_dm\12.cr_getmatchedcohort_`medcondition'_`database'_`linkedtext'_old.dta", replace
	
	gen pracid = mod(patid, 100000)
	
	local mergedprac = "20024 20036 20091 20202 20254 20389 20430 20469 20487 20552"
	local mergedprac = "`mergedprac' 20554 20734 20790 20803 20868 20996 21001 21078 21118"
	local mergedprac = "`mergedprac' 21172 21173 21277 21334 21390 21444 21451 21553 21558 21585"

	gen _mergedprac = 0
	foreach prac of local mergedprac {
		replace _mergedprac = 1 if pracid == `prac'
		}
		
	tab _mergedprac, m
	pause
		
	drop if _mergedprac == 1
	drop _mergedprac pracid

	compress
	save "$datadir_dm\12.cr_getmatchedcohort_`medcondition'_`database'_`linkedtext'.dta", replace
}
}
}

capture log close





