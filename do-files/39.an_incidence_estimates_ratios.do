capture log close
log using "$logdir\39.an_incidence_estimates_ratios.txt", replace text

/*******************************************************************************
# Stata do file:    39.an_incidence_estimates_ratios.do
#
# Author:      Helen Strongman
#
# Date:        19/04/2023
#
# Description: 	glm log poisson models to estimate crude, age/sex adjusted, and age/sex/BMI
#				adjusted (OSA only) incidence ratios considering calendar time
#				by (1) restricting to 2019 for OSA (2) 
#				for 5 year calendar year categories for both conditions
#				
#				Added age, sex adjusted restricted to people with complete BMI
#				data to explore impact of missing data
#
#				Note: Alternative methods to look at changes over time include
#				using adjustment and interaction terms for calendar year in the
#				models. This assumes that the independent effect of age, sex
#				and BMI is consistent between years which is unlikely. 
#
#				Amended on 11 April so that all primary care only estimates
#				except country only use data from England. This makes the linked
#				and primary care cohorts more comparable.
#
# Requirements: 
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/

pause off

foreach linkedtext in /*linked*/ primary {
foreach medcondition in OSA narcolepsy {
qui {
		
		
		di "`medcondition'" "`linkedtext'"
		pause
		
		/** set up dataset for regression models to use individual calendar
		years for OSA and 5 year age categories for narcolepsy*/
		use "$datadir_an/37.cr_unmatchedcohort_stsplit_allvars_`medcondition'_`linkedtext'.dta", clear
		gen pdays = _t - _t0
		
		*stop in 2019 to exclude pandemic year and because end of linked data coverage = March 2020
		*start in 2000 to avoid problems with model convergence due to low diagnosis rates
		drop if calendaryear <2000 | calendaryear >2019
		
		
		if "`medcondition'" == "OSA" {
			/*recategorise underweight as missing due to rare
			events. The other option is to combine with normal weight - this
			would differ from the approach for the prevalence analysis
			and be less informative*/
			recode bmicat 0 = .
			local yearvar = "calendaryear"
		}
	
		*define calendar years for each set of regression models and incidence rates (see below)
		qui summ calendaryear_cat
		local minyearcat = `r(min)'
		local maxyearcat = `r(max)'
		if "`linkedtext'" == "primary" local minyearcat = `maxyearcat' /*for primary care definition, only need most recent year category*/
		
		/*Run regression models for each covariate (with exceptions)*/
		
			foreach covar in country bmicat obesity gender agecat region carstairs urban eth5 pracsize_cat { /*keep country first*/
				
				*skip country for linked data
				if "`linkedtext'" == "linked" & "`covar'" == "country" continue
				
				*skip urban and area based deprivation for primary care data
				*only requested linked area based data for the linked cohort.
				if "`linkedtext'" == "primary" & "`covar'" == "urban" continue
				if "`linkedtext'" == "primary" & "`covar'" == "carstairs" continue
				
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
				
				*specify vars for adjustment
				local adjustvars = "ib40.agecat ib1.gender"
				if "`covar'" == "gender" local adjustvars = "ib40.agecat"
				if "`covar'" == "agecat" local adjustvars = "ib1.gender"
				
				/*** estimate incidence ratios for 2019 (OSA) ***/
					if "`medcondition'" == "OSA" {
						*crude
						glm case ib`bl'.`covar' if calendaryear == 2019, exposure(pdays) allbaselevels family(poisson) link(log) eform
						estimates save "$estimatesdir/39.an_incidence_estimates_ratio_`medcondition'_`linkedtext'_`covar'_2019_crude", replace
						*age and sex adjusted
						glm case ib`bl'.`covar' `adjustvars' if calendaryear == 2019, exposure(pdays) allbaselevels family(poisson) link(log) eform
						estimates save "$estimatesdir/39.an_incidence_estimates_ratio_`medcondition'_`linkedtext'_`covar'_2019_adjusted", replace
						*OSA only
						if "`covar'" != "bmicat" & "`covar'" != "obesity" {
							*start with age sex adjusted without people with missing BMI
							glm case  ib`bl'.`covar' `adjustvars' if calendaryear == 2019 & bmicat !=., exposure(pdays) allbaselevels family(poisson) link(log) eform
							estimates save "$estimatesdir/39.an_incidence_estimates_ratio_`medcondition'_`linkedtext'_`covar'_2019_adjustedcc", replace								
							*age, sex and BMI adjusted
							glm case  ib`bl'.`covar' `adjustvars' i.bmicat if calendaryear == 2019, exposure(pdays) allbaselevels family(poisson) link(log) eform
							estimates save "$estimatesdir/39.an_incidence_estimates_ratio_`medcondition'_`linkedtext'_`covar'_2019_bmiadjusted", replace				
						}
					}
					
				/*** estimate incidence ratios for each calendar year category ***/
				forvalues yearcat = `minyearcat'/`maxyearcat' {
					if "`linkedtext'" == "primary" & "`medcondition'" == "OSA" continue
					*crude
						glm case ib`bl'.`covar' if calendaryear_cat == `yearcat', exposure(pdays) allbaselevels family(poisson) link(log) eform
						estimates save "$estimatesdir/39.an_incidence_estimates_ratio_`medcondition'_`linkedtext'_`covar'_yearcat`yearcat'_crude", replace
						*age and sex adjusted
						glm case ib`bl'.`covar' `adjustvars' if calendaryear_cat == `yearcat', exposure(pdays) allbaselevels family(poisson) link(log) eform
						estimates save "$estimatesdir/39.an_incidence_estimates_ratio_`medcondition'_`linkedtext'_`covar'_yearcat`yearcat'_adjusted", replace
						*OSA only
						if "`medcondition'" == "OSA" & ("`covar'" != "bmicat" & "`covar'" != "obesity") {
							*start with age sex adjusted without people with missing BMI
							glm case ib`bl'.`covar' `adjustvars' if calendaryear_cat == `yearcat' & bmi !=., exposure(pdays) allbaselevels family(poisson) link(log) eform
							estimates save "$estimatesdir/39.an_incidence_estimates_ratio_`medcondition'_`linkedtext'_`covar'_yearcat`yearcat'_adjustedcc", replace							
							*age, sex and BMI adjusted
							glm case  ib`bl'.`covar' `adjustvars' i.bmicat if calendaryear_cat == `yearcat', exposure(pdays) allbaselevels family(poisson) link(log) eform
							estimates save "$estimatesdir/39.an_incidence_estimates_ratio_`medcondition'_`linkedtext'_`covar'_yearcat`yearcat'_bmiadjusted", replace				
						}
				}
				
				
				
				/*TRIED THE BELOW - 
				2019 ESTIMATES BASED ON THE INTERACTION TERM WERE CLOSER TO CRUDE 2019 ESTIMATES ESTIMATED BY RESTRICTING TO 2019 THAN
				TO ADJUSTED ESTIMATES PROVING ASSUMPTION THAT CONFOUNDER EFFECTS VARY BY YEAR DESCRIBED AT TOP OF DO FILE
				/*estimate incidence rate ratios for full time period adjusted by calendar year to describe influence of calendar time*/
				*crude
				glm case ib`bl'.`covar' i.`yearvar', exposure(pdays) allbaselevels family(poisson) link(log) eform
				estimates save "$estimatesdir/39.an_incidence_estimates_ratio_`medcondition'_`linkedtext'_`covar'_yearadjust_crude", replace
				*age and sex adjusted
				glm case ib`bl'.`covar' i.`yearvar' `adjustvars', exposure(pdays) allbaselevels family(poisson) link(log) eform
				estimates save "$estimatesdir/39.an_incidence_estimates_ratio_`medcondition'_`linkedtext'_`covar'_yearadjust_adjusted", replace
				*age, sex and BMI adjusted (OSA only)
				if "`medcondition'" == "OSA" & "`covar'" != "bmicat" & "`covar'" != "obesity" {
					glm case  ib`bl'.`covar' i.`yearvar' `adjustvars' ib1.bmicat, exposure(pdays) allbaselevels family(poisson) link(log) eform
					estimates save "$estimatesdir/39.an_incidence_estimates_ratio_`medcondition'_`linkedtext'_`covar'_yearadjust_bmiadjusted", replace				
				}				
				
				/*estimate incidence rate ratios for full time period stratified by calendar year to test for interaction / describe changes over time where appropriate*/
				*crude
				glm case ib`bl'.`covar'##i.`yearvar', exposure(pdays) allbaselevels family(poisson) link(log) eform
				estimates save "$estimatesdir/39.an_incidence_estimates_ratio_`medcondition'_`linkedtext'_`covar'_yearinteraction_crude", replace
				*age and sex adjusted
				glm case ib`bl'.`covar'##i.`yearvar' `adjustvars', exposure(pdays) allbaselevels family(poisson) link(log) eform
				estimates save "$estimatesdir/39.an_incidence_estimates_ratio_`medcondition'_`linkedtext'_`covar'_yearinteraction_adjusted", replace
				*age, sex and BMI adjusted (OSA only)
				if "`medcondition'" == "OSA" & "`covar'" != "bmicat" & "`covar'" != "obesity" {
					glm case  ib`bl'.`covar'##i.`yearvar' `adjustvars' ib1.bmicat, exposure(pdays) allbaselevels family(poisson) link(log) eform
					estimates save "$estimatesdir/39.an_incidence_estimates_ratio_`medcondition'_`linkedtext'_`covar'_yearinteraction_bmiadjusted", replace				
				}
				*/
				
				/*moved to next do file
				/*estimate crude incidence rates for 2019 (OSA) and 5 year categories (both)*/
				local multiplier = 365.25 * 100000
				if "`medcondition'" == "OSA" {
					strate `covar' if `yearvar' == 2019, per(`multiplier') output($estimatesdir/39.an_incidence_estimates_ratio_`medcondition'_`linkedtext'_`covar'_2019_rate.dta, replace)
					}
				forvalues yearcat = `minyearcat'/`maxyearcat' {
					strate `covar', per(`multiplier') output($estimatesdir/39.an_incidence_estimates_ratio_`medcondition'_`linkedtext'_`covar'_yearcat`yearcat'_rate.dta, replace)
					}
				*/
				if "`covar'" == "country" keep if country == 1 /*all other primary care data only estimates should be run using data from England only*/
			}  /*covar*/
			
			*/
			*estimate IRRs for calendar years - to what extent is the change explained by differences in age, sex and BMI distribution
			
			if "`linkedtext'" == "linked" {
				glm case i.calendaryear, exposure(pdays) allbaselevels family(poisson) link(log) eform
				estimates save "$estimatesdir/39.an_incidence_estimates_ratio_`medcondition'_`linkedtext'_year_crude", replace
				*age and sex adjusted
				local adjustvars = "ib40.agecat ib1.gender"
				glm case i.calendaryear `adjustvars', exposure(pdays) allbaselevels family(poisson) link(log) eform
				estimates save "$estimatesdir/39.an_incidence_estimates_ratio_`medcondition'_`linkedtext'_year_adjusted", replace
				*OSA only
				if "`medcondition'" == "OSA" {
					*start with age sex adjusted without people with missing BMI
					glm case i.calendaryear `adjustvars' if bmicat !=., exposure(pdays) allbaselevels family(poisson) link(log) eform
					estimates save "$estimatesdir/39.an_incidence_estimates_ratio_`medcondition'_`linkedtext'_year_adjustedcc", replace								
					*age, sex and BMI adjusted
					glm case  i.calendaryear `adjustvars' i.bmicat, exposure(pdays) allbaselevels family(poisson) link(log) eform
					estimates save "$estimatesdir/39.an_incidence_estimates_ratio_`medcondition'_`linkedtext'_year_bmiadjusted", replace				
				}
			}
					
} 
}
}


capture log close
