capture log close
log using "$logdir\34.an_prevalence_estimates_ratios.txt", replace text

/*******************************************************************************
# Stata do file:    34.an_prevalence_estimates_ratios.do
#
# Author:      Helen Strongman
#
# Date:        20/03/2023
#
# Description: 	log binomial methods to estimate 2019 prevalence ratios for each covariate
#				crude, age gender adjusted, and age gender bmi adjusted (OSA where
#				appropriate). The latter models don't converge using bmi splines.
#
#				(extra model = age,sex adjusted restricted to people with complete
#				BMI data)
#				
#				Primary care models in England only except for country comparison
#				allows better comparison with linked models
#
#				paper justifying choice of model:
#				1. Petersen MR, Deddens JA. A comparison of two methods for estimating prevalence ratios. BMC Medical Research Methodology. 2008 Feb 28;8(1):9. 
#
# Requirements: 
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/

local i = 1
foreach linkedtext in /*linked*/ primary {
foreach medcondition in OSA narcolepsy {
	/*import patient level dataset*/
	use "$datadir_an/33.cr_studypopulation_mid2019_`medcondition'_`linkedtext'.dta", clear
	foreach covar in country bmicat obesity gender agecat region carstairs urban eth5 pracsize_cat { /*keep country first*/
		
		*skip country for linked data
		if "`linkedtext'" == "linked" & "`covar'" == "country" continue
		
		*skip urban for primary care data
		if "`linkedtext'" == "primary" & "`covar'" == "urban" continue
		
		*skip bmi and obesity for narcolepsy
		if "`medcondition'" == "narcolepsy" & "`covar'" == "bmicat" continue
		if "`medcondition'" == "narcolepsy" & "`covar'" == "obesity" continue
		
		di "`i' `linkedtext' `medcondition' `covar'"
	qui {
		*specify baselevel
		summ `covar'
		local bl = `r(min)'
		if "`covar'" == "agecat" local bl = 40
		*if "`covar'" == "pracsize_cat" local bl = 3
		*if "`covar'" == "carstairs" local bl = 3
		if "`covar'" == "region" local bl = 7 /*London*/
		if "`covar'" == "bmicat" local bl = 1
		
		*specify vars for adjustment
		local adjustvars = "ib40.agecat ib1.gender"
		if "`covar'" == "gender" local adjustvars = "ib40.agecat"
		if "`covar'" == "agecat" local adjustvars = "ib1.gender"
		
		/*** estimate prevalence ratios ***/
		
		*crude
		glm prevcase2019 ib`bl'.`covar', allbaselevels family(binomial) link(log) eform
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
		if "`covar'" == "country" keep if country == 1 /*all other primary care data only estimates should be run using data from England only*/
		local `i' = `i' + 1
	} /*qui*/
	} /*covar*/
}
}

capture log close
