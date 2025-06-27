
capture log close
log using "$logdir\50.an_incprev_adhoc.txt", replace text

/*******************************************************************************
# Stata do file:    50.an_incprev_adhoc.do
#
# Author:      Helen Strongman
#
# Date:        09/05/2024
#
# Description: 	Ad hoc analyses for incidence/prevalence paper including
#				- summary statistics for age of prevalent and incident cases
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/


foreach linkedtext in primary linked {
foreach medcondition in OSA narcolepsy {
	
	**Summary statistics for age of prevalent and incident cases
	di as yellow "`linkedtext' `medcondition'"
	use "$datadir_an\10.cr_unmatchedcohort_an_flowchart_`medcondition'_aurum_`linkedtext'.dta", clear
	append using "$datadir_an\10.cr_unmatchedcohort_an_flowchart_`medcondition'_gold_`linkedtext'.dta"
	keep patid prevalent incident exposed start_fup end_fup indexdate yob
	
	**RR year 
	*can't do this for prevalence because observations are not independent between years
			*crude
		glm prevcase2019 i.calendaryear, allbaselevels family(binomial) link(log) eform
		estimates save "$estimatesdir/34.an_prevalence_estimates_ratio_`medcondition'_`linkedtext'_`covar'_crude", replace
		*age and sex adjusted
		glm prevcase2019 ib`bl'.`covar' `adjustvars', allbaselevels family(binomial) link(log) eform
		estimates save "$estimatesdir/34.an_prevalence_estimates_ratio_`medcondition'_`linkedtext'_`covar'_adjusted", replace
		
		*OSA only
		if "`medcondition'" == "OSA" & "`covar'" != "bmicat" & "`covar'" != "obesity" {
			*start with age sex adjusted without people with missing BMI
			glm prevcase2019 ib`bl'.`covar' `adjustvars' if bmicat !=., allbaselevels family(binomial) link(log) eform
			estimates save "$estimatesdir/34.an_prevalence_estimates_ratio_`medcondition'_`linkedtext'_`covar'_adjustedcc", replace
			*age, sex bmi adjusted
			glm prevcase2019 ib`bl'.`covar' `adjustvars' i.bmicat, allbaselevels family(binomial) link(log) eform
			estimates save "$estimatesdir/34.an_prevalence_estimates_ratio_`medcondition'_`linkedtext'_`covar'_bmiadjusted", replace
		}
	
	
	/*identify prevalent cases in 2019*/
	local year = 2019
	gen studypop`year' = 0
	replace studypop`year' = 1 if start_fup <= d(01/07/`year') & end_fup > d(01/07/`year')
		
	gen prevcases`year' = 0
	replace prevcases`year' = 1 if studypop`year' == 1 & prevalent == 1 & indexdate <= d(01/07/`year')

	/*summarise age of prevalent cases*/
	gen _ageprev = `year' - yob
	summ _ageprev if prevcases`year' == 1, d
	
	/*identify incident cases in 2019*/
	gen inccases`year' = 1 if incident == 1 & year(indexdate) == `year'
	gen _ageinc  = `year' - yob
	summ _ageinc if inccases`year' == 1, d
	
	**Summary statistics for number of prevalent cases per practice
	if "`linkedtext'" == "linked" {
		keep if studypop`year' == 1
		gen pracid = mod(patid, 1000)
		collapse (sum) prevcases`year'prac=prevcases`year', by(pracid)
		summ prevcases`year'prac, d
	}
	
		
}
}




capture log close