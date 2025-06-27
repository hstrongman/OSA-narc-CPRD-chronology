capture log close
log using "$logdir\40.an_incidence_estimates_rates.txt", replace text

/*******************************************************************************
# Stata do file:    40.an_incidence_estimates_rates.do
#
# Author:      Helen Strongman
#
# Date:        14/08/2023
#
# Description: 	estimate crude incidence rates for each covariate strata
#				(1) restricting to 2019 for OSA (2) 
#				last 5 year age category for narcolepsy (2015-2019)
#
#				plus agecat and BMI cat for each yearcat - linked only
#
# Requirements: 
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/

pause off

foreach linkedtext in linked primary {
foreach medcondition in OSA narcolepsy {
noi {
		
		di "`medcondition'" "`linkedtext'"
		pause
		
		/** set up dataset for regression models to use individual calendar
		years for OSA and 5 year age categories for narcolepsy*/
		use "$datadir_an/37.cr_unmatchedcohort_stsplit_allvars_`medcondition'_`linkedtext'.dta", clear
		gen pdays = _t - _t0
		
		*keep latest year category
		*keep if calendaryear_cat == 4
		
		
		if "`medcondition'" == "OSA" {
			/*recategorise underweight as missing due to rare
			events. The other option is to combine with normal weight - this
			would differ from the approach for the prevalence analysis
			and be less informative*/
			recode bmicat 0 = .
		}
	
		
		/*Estimate rates for each covariate value (with exceptions)*/
		
			foreach covar in bmicat obesity gender agecat region country carstairs urban eth5 pracsize_cat {
				
				*skip country for linked data
				if "`linkedtext'" == "linked" & "`covar'" == "country" continue
				
				*skip urban for primary care data
				if "`linkedtext'" == "primary" & "`covar'" == "urban" continue
				
				*skip bmi and obesity for narcolepsy
				if "`medcondition'" == "narcolepsy" & "`covar'" == "bmicat" continue
				if "`medcondition'" == "narcolepsy" & "`covar'" == "obesity" continue
				
				di "`linkedtext' `medcondition' `covar'"
				
				*specify baselevel
				
				summ `covar'
				local bl = `r(min)'
				if "`covar'" == "agecat" local bl = 40
				*if "`covar'" == "pracsize_cat" local bl = 3
				*if "`covar'" == "carstairs" local bl = 3
				if "`covar'" == "region" local bl = 7 /*London*/
				if "`covar'" == "bmicat" local bl = 1
				
				
				/*estimate crude incidence rates for 2019 (OSA) and 2015-2019 (both)*/
				local multiplier = 365.25 * 100000
				if "`medcondition'" == "OSA" {
					strate `covar' if calendaryear == 2019, per(`multiplier') output($estimatesdir/40.an_incidence_estimates_rates_`medcondition'_`linkedtext'_`covar'_2019.dta, replace)
					}
				strate `covar' if calendaryear_cat == 4, per(`multiplier') output($estimatesdir/40.an_incidence_estimates_rates_`medcondition'_`linkedtext'_`covar'_2015_19.dta, replace)
				pause
				
				
				/*estimate crude incidence rates for 3 remaining yearcats - linked data only, agecat and bmicat only*/
				if "`linkedtext'" == "linked" & ("`covar'" == "bmicat" | "`covar'" == "agecat") {
					forvalues ycat = 1/3 {
						local multiplier = 365.25 * 100000
						strate `covar' if calendaryear_cat == `ycat', per(`multiplier') output($estimatesdir/40.an_incidence_estimates_rates_`medcondition'_`linkedtext'_`covar'_yearcat`ycat'.dta, replace)
					}
				}
			}  /*covar*/
} 
}
}


capture log close
