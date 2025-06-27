capture log close
log using "$logdir\35.an_prevalence_estimates_processout.txt", replace text

/*******************************************************************************
# Stata do file:    35.an_prevalence_estimates_processout.do
#
# Author:      Helen Strongman
#
# Date:        19/06/2023
#
# Description: 	Table with the following variables for each covariate value:
#				- 2019 crude prevalence rate (95% CI)
#				- 2019 crude prevalence ratio (95% CI)
#				- 2019 age/sex adjusted prevalence ratios (95% CI)
#				- OSA only: 2019 age/sex/BMI adjusted prevalence ratios (95% CI)
#
#				Note: prevalence ratios not estimated for full time frame as
#				observations would not be independent. Would need to timesplit
#				dataset and use robust standard errors.
#
# Requirements: 
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/

pause off


/***set up temporary file for results***/
capture postclose results
tempname memhold
tempfile results
#delimit ;
postfile `memhold' str10 medcondition str9 linkedtext str20 covar
str20 covarlabel int value str20 valuelabel double prevcases studypop
prev_crude prev_crude_lci prev_crude_uci crude_beta crude_se crude_p
adjusted_beta adjusted_se adjusted_p 
adjustedcc_beta adjustedcc_se adjustedcc_p 
bmiadjusted_beta bmiadjusted_se bmiadjusted_p
praccount using "`results'", replace
;
#delimit cr

foreach linkedtext in linked primary {
foreach medcondition in OSA narcolepsy {
	use "$datadir_an/33.cr_studypopulation_mid2019_`medcondition'_`linkedtext'.dta", clear
	
	foreach covar in gender agecat country carstairs urban eth5 pracsize_cat bmicat obesity {
	
		*skip country for linked data
		if "`linkedtext'" == "linked" & "`covar'" == "country" continue
		
		*skip urban for primary care data
		if "`linkedtext'" == "primary" & "`covar'" == "urban" continue
		
		di "`i' `linkedtext' `medcondition' `covar'"
		
		*skip bmi and obesity for narcolepsy
		if "`medcondition'" == "narcolepsy" & "`covar'" == "bmicat" continue
		if "`medcondition'" == "narcolepsy" & "`covar'" == "obesity" continue

		qui {
		
		summ `covar'


		/*** data row for each covariate value ***/
		levelsof `covar', local(values)
		foreach i of local values {
			di "`i'"

			*extract crude and adjusted risk ratios for covariate
			foreach model in crude adjusted {
				estimates use "$estimatesdir/34.an_prevalence_estimates_ratio_`medcondition'_`linkedtext'_`covar'_`model'"
				local `model'_beta = _b[`i'.`covar']
				local `model'_se = _se[`i'.`covar']
				test `i'.`covar'
				local `model'_p = r(p)
			}
			
			*OSA only
			if "`medcondition'" == "OSA" & "`covar'" != "bmicat" & "`covar'" != "obesity" {
				*extract age,sex adjusted risk ratios restricted to BMI complete case sample for covariate
				estimates use "$estimatesdir/34.an_prevalence_estimates_ratio_`medcondition'_`linkedtext'_`covar'_adjustedcc"
				local adjustedcc_beta = _b[`i'.`covar']
				local adjustedcc_se = _se[`i'.`covar']
				test `i'.`covar'
				local adjustedcc_p = r(p)
				*extract BMI adjusted risk ratios for covariate
				estimates use "$estimatesdir/34.an_prevalence_estimates_ratio_`medcondition'_`linkedtext'_`covar'_bmiadjusted"
				local bmiadjusted_beta = _b[`i'.`covar']
				local bmiadjusted_se = _se[`i'.`covar']
				test `i'.`covar'
				local bmiadjusted_p = r(p)				
			}
			else {
				local bmiadjusted_beta = .
				local bmiadjusted_se = .
				local bmiadjusted_p = .	
				local adjustedcc_beta = .
				local adjustedcc_se = .
				local adjustedcc_p = .
			}
			
			*crude prevalence (%)
			count if `covar' == `i'
			local obs = `r(N)'
			count if `covar' == `i' & prevcase2019 == 1
			local cases = `r(N)'
			
			*crude prevalence rate
			cii proportions `obs' `cases', exact
			local prev_crude = r(proportion) * 100
			local lci = r(lb) * 100
			local uci = r(ub) * 100
			local valuelabel: label `covar'lab `i'
			local covarlabel: variable label `covar' 
			
			*number of practices for region and country*/
			local praccount = .
			if "`covar'" == "region" | "`covar'" == "country" {
				distinct pracid if `covar' == `i'
				local praccount = `r(ndistinct)'
				di "`praccount'"
				pause
				}
			#delimit ;
			post `memhold' ("`medcondition'") ("`linkedtext'") ("`covar'") 
			("`covarlabel'") (`i') ("`valuelabel'") (`cases') (`obs')
			(`prev_crude') (`lci') (`uci') (`crude_beta') (`crude_se') (`crude_p')
			(`adjusted_beta') (`adjusted_se') (`adjusted_p')
			(`adjustedcc_beta') (`adjustedcc_se') (`adjustedcc_p')  
			(`bmiadjusted_beta') (`bmiadjusted_se') (`bmiadjusted_p') (`praccount')
			;
			#delimit cr
		}
	}
}
}
} /*qui*/

postclose `memhold'

use `results', clear
save "$datadir_an/temp.dta", replace


** estimate number of practices per region/country


label variable medcondition "Sleep disorder"
label variable linkedtext "Data source(s)"
label variable prevcases "Prevalent cases (n)"
label variable studypop "Study population (n)"
label variable prev_crude "Crude prevalence (%)"
label variable prev_crude_lci "lower 95% confidence bound (%)"
label variable prev_crude_uci "upper 95% confidence bound (%)"
note prev_crude_lci: "Exact crude confidence intervals estimated using binomial methods"

gen prev_crude_str = string(prev_crude, "%9.3fc") + " (" + string(prev_crude_lci, "%9.3fc") + "-" + string(prev_crude_uci, "%9.3fc") + ")"
label variable prev_crude_str "Crude prevalence % (95% CI)"

foreach model in crude adjusted adjustedcc bmiadjusted {
	gen `model'_prevratio = exp(`model'_beta)
	gen `model'_prevratio_lci = exp(`model'_beta-invnorm(0.975)*`model'_se)
	gen `model'_prevratio_uci = exp(`model'_beta+invnorm(0.975)*`model'_se)

	gen `model'_prevratio_str  = string(`model'_prevratio, "%9.2fc") + " (" + string(`model'_prevratio_lci, "%9.2fc") + "-" + string(`model'_prevratio_uci, "%9.2fc") + ")"
	replace `model'_prevratio_str = "1" if `model'_prevratio == 1 & `model'_se == 0 /*base category*/
	
	gen `model'_prevratio_pstr = string(`model'_p, "%5.3fc") if `model'_p >=0.001 & `model'_p <0.01
	replace `model'_prevratio_pstr = string(`model'_p, "%4.2f") if `model'_p>=0.01
	replace `model'_prevratio_pstr = "<0.001" if `model'_p<0.001
	
	if "`model'" == "crude" local modelstr = "Unadjusted"
	if "`model'" == "adjusted" local modelstr = "Age and sex adjusted"
	if "`model'" == "adjustedcc" local modelstr = "Age and sex adjusted (complete BMI data)"
	if "`model'" == "bmiadjusted" local modelstr = "Age, sex and BMI adjusted"

	label variable `model'_prevratio "`modelstr' prevalence ratio"
	label variable `model'_prevratio_lci "`modelstr' lower 95% confidence bound"
	label variable `model'_prevratio_uci "`modelstr' upper 95% confidence bound"
	label variable `model'_prevratio_str "`modelstr' prevalence ratio (95% CI)"
	label variable `model'_prevratio_pstr "`modelstr' prevalence ratio p-value"
	
	drop `model'_se `model'_p
}

label variable praccount "Number of practices in study population"

note: "Prevalence ratios estimated using log binomial regression"
compress
save "$estimatesdir/35.an_prevalence_estimates_processout.dta", replace


capture log close
