capture log close
log using "$logdir\12.cr_getmatchedcohort.txt", replace text

/*******************************************************************************
# Stata do file:    12.cr_getmatchedcohort.do
#
# Author:      Helen Strongman
#
# Date:        20/12/2023. last updated 15/02/2023
#
# Description: 	This do file identifies matches for the narcolepsy and OSA
#				groups (Aurum/Gold, primary/linked). 
#
#				Each person in the sleep disorder group is matched to up to 5 
#				people on year of birth (plus/minus 3 years), sex, practice, 
#				and registration time whereby the matched person will be currently 
#				registered on the diagnosis date of the matched person with a
#				sleep disorder and have at least the 90 days of registration
#				prior to this date.
#
# Decision: I considered matching by eligibility to HES outpatient data to avoid
#			losing unexposed people for whom elegibility differed to the matched
#			exposed person. This might lead to overmatching due to potential
#			similarities between people whose eligibility status differs
#			betweeen datasets.
# 
#			Note that HES eligibility would normally be the same in all
#			datasets. Differences in the linkage dataset I have used
#			occur because CPRD have prioritised linkage to key datasets 
#			during the Covid-19 pandemic rather than linking all datasets
#			concurrently.
#
# Inspired and adapted from: 
#				This do file uses "getmatchedcohort.ado" by
#				Krishnan Bhaskaran (November 2015)
*******************************************************************************/

local datasetchange = 0 /*The datasignature command is used at the end of the 
do file to check that the patient level dataset has not changed since this do
file was last run. Setting this local to 1 overides this*/


foreach database in aurum gold {
foreach linkedtext in primary linked {
foreach medcondition in OSA narcolepsy {
	
	/*COHORT FOR MATCHING*/
	use "$datadir_an\10.cr_unmatchedcohort_an_flowchart_`medcondition'_`database'_`linkedtext'.dta", clear
	drop if prevalent == 1 & incident == 0
	assert prevalent == 0 & incident == 0 if exposed == 0
	
	rename start_fup startdate 
	rename end_fup enddate 
	
	/*gen _date18 = dob + (365.25 * 18) - removed from unmatched cohort
	format _date18 %td
	if "`medcondition'" == "OSA" replace startdate = max(_date18, startdate)
	assert startdate < enddate
	*/
	
	/*SEE NOTE ABOVE - DECIDED NOT TO DO THIS
	/* In order to match on HES outpatient linkage eligibility, make four 
	categories of gender (male & eligible, male & not eligible, 
	and similar 2 for female).*/

	gen _link = 0
	if "`linkedtext'" == "linked" replace _link = 1 if hes_e_op == 1
	tab _link, m

	rename gender _gendertrue

	gen gender = 5 if _link == 1 & _gender == 1
	replace gender = 6 if _link == 0 & _gender == 1
	replace gender = 7 if _link == 1 & _gender == 2
	replace gender = 8 if _link == 0 & _gender == 2

	tab gender, m

	assert gender == 1 if _gender == 5 | _gender ==6
	assert gender == 1 if _gender == 7 | _gender ==8
	*/

	keep patid pracid gender yob exposed indexdate startdate enddate
	
	/*MATCHING PROCESS*/
	set seed 92378
	getmatchedcohort, practice gender yob yobwindow(3) followup dayspriorreg(0) ctrlsperexp(5) ///
		cprddb("`database'") savedir("$datadir_dm") updates(1000) dontcheck
	
	use "$datadir_dm\getmatchedcohort.dta", clear
	/*check that there are no changes to the patient level dataset when the file is rerun
	- if there are, subsequent do files need to be rerun*/
	compress
	if `datasetchange' == 1 datasignature set, reset saving("$datadir_an\12.cr_getmatchedcohort_`medcondition'_`database'_`linkedtext'.dtasig", replace)
	datasignature confirm using "$datadir_an\12.cr_getmatchedcohort_`medcondition'_`database'_`linkedtext'.dtasig"
	save "$datadir_dm\12.cr_getmatchedcohort_`medcondition'_`database'_`linkedtext'.dta", replace
	erase "$datadir_dm\getmatchedcohort.dta"

}
}
}

capture log close





