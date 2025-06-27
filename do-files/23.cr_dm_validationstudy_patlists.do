capture log close
log using "$logdir\23.cr_dm_validationstudy_patlists.txt", replace text

/*******************************************************************************
# Stata do file:    23.cr_dm_validatoinstudy_patlists.do
#
# Author:      Helen Strongman
#
# Date:        29/03/2022
#
# Description: 	This do file prepares patient lists for the validation study.
#				In the protocol, we said that: "we will select a random subset 
#				of 143 people for each sleep disorder leading to 200 (100 x 2) 
#				responses, assuming a 70% response rate."
#
#				The expected response rate is now much lower at x% so ...
#
#				linked data and primary care data? Probably linked data only but
#				then excludes devolved nations
#
#				GOLD and Aurum - probably just Aurum as GOLD is dying!
#
#				Plus it might be difficult to ensure that we have enough GOLD
#				patients for meaningful analysis
#
#				Files for linked data requests should be provided as
#				tab-delimited text files (.txt) and zipped into
#				a single file, prior to transfer to the CPRD. 
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/


foreach medcondition in OSA narcolepsy {
	use "$datadir_dm\12.cr_getmatchedcohort_`medcondition'_aurum_linked.dta", clear
	keep patid
	set seed 23084
	sample x
	count
	display as yellow "Number of patients in matched cohort `database' file: `r(N)'"
	export delimited using "$datadir_raw\23.cr_dm_validationstudy_patlists.txt", delimiter(tab) replace
}


log close

