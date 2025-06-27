capture log close
log using "$logdir\11.an_unmatchedcohort_checks.txt", replace text

/*******************************************************************************
# Stata do file:    11.an_unmatchedcohort_checks.do
#
# Author:      Helen Strongman
#
# Date:        12/12/2022
#
# Description: 	This do file flags investigates issues in cohort data to inform
#				post-hoc decisions described in the protocol.
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/

pause off

foreach linkedtext in primary linked {
	foreach medcondition in narcolepsy OSA {
		
		di as yellow "`medcondition' `linkedtext'"

		use "$datadir_an\10.cr_unmatchedcohort_an_flowchart_`medcondition'_aurum_`linkedtext'.dta", clear
		append using "$datadir_an\10.cr_unmatchedcohort_an_flowchart_`medcondition'_gold_`linkedtext'.dta"

		if "`medcondition'" == "narcolepsy" {
			/*I didn't include cataplexy only codes in the narcolepsy definition because a
			single cataplexy code might not represent narcolepsy and index dates can't
			be backdated due to future information biases*/
			gen _priorcataplexy = 0
			replace _priorcataplexy = 1 if cataplexydate_pc < indexdate
			tab _priorcataplexy exposed, m col
		}
		
		/*is there a sensible way to group OSA codes e.g. obstructive/no obstructive
		note - probably best not too given high proportion of "sleep apnoea" codes
		especially in linked data*/ 
		if "`medcondition'" == "OSA" {
			*exposed people*
			tab indexcode if exposed == 1, m sort
			*incident cases*
			tab indexcode if incident == 1, m sort
		}
		
		/*how much of a difference does HES APC make in linked datasets*/
		if "`linkedtext'" == "linked" {

			tab cprdvshesapc
		
			/*loose very few events by restricting follow-up time to HES OP/ HES A&E 
			coverage period*/
			*exposed people*
			tab hes_op_e exposed, m col
			*incident cases*
			tab hes_op_e if incident == 1
		}
	pause
	}
}


