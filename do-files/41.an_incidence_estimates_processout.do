capture log close
log using "$logdir\41.an_incidence_estimates_processout.txt", replace text

/*******************************************************************************
# Stata do file:    41.an_incidence_estimates_processout.do
#
# Author:      Helen Strongman
#
# Date:        14/08/2023
#
# Description: 	Table with the following variables for each covariate value
#				restricted to 2019 (OSA only) and each 5-year category (OSA
#				and narcolepsy):
#				- crude incidence rate ratio (95% CI)
#				- age/sex adjusted incidence rate ratios (95% CI)
#				- (OSA only) age/sex adjusted incidence rate ratios for complete case sample
#				- (OSA only) age/sex/BMI adjusted incidence rate ratios (95% CI)
#				- crude incidence rate (95% CI) - 2019 (OSA) and 2015-19 (both)
#
#				Plus rate ratios only with year as a covariate (2000-2019)
#
#				Primary care IRRs are for England only excepting the country comparison
#				
#
# Requirements: sigdif.ado (see https://www.stata.com/statalist/archive/2010-01/msg00355.html)
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/

pause off


/***set up temporary file for results***/
/*covariate and value labels not included. can get these by merging with
the prevalence estimates file*/

capture postclose results
tempname memhold
tempfile results
#delimit ;
postfile `memhold' str10 medcondition str9 linkedtext str20 covar
int value str10 yearcat float inccases pyears
inc_crude inc_crude_lci inc_crude_uci crude_beta crude_se crude_p
adjusted_beta adjusted_se adjusted_p 
adjustedcc_beta adjustedcc_se adjustedcc_p
bmiadjusted_beta bmiadjusted_se bmiadjusted_p
 using "`results'", replace
;
#delimit cr

foreach linkedtext in primary linked {
foreach medcondition in OSA narcolepsy {
	
	local yearcats = "1 2 3 4"
	if "`medcondition'" == "OSA" local yearcats = "2019 `yearcats'"

	foreach yearcat of local yearcats {
	
	foreach covar in agecat gender /*region*/ country carstairs urban eth5 pracsize_cat bmicat obesity {
	
		*skip country for linked data
		if "`linkedtext'" == "linked" & "`covar'" == "country" continue
		
		*skip urban for primary care data
		if "`linkedtext'" == "primary" & "`covar'" == "urban" continue
		
		di "`yearcat' `linkedtext' `medcondition' `covar'"
		
		*skip bmi and obesity for narcolepsy
		if "`medcondition'" == "narcolepsy" & "`covar'" == "bmicat" continue
		if "`medcondition'" == "narcolepsy" & "`covar'" == "obesity" continue
		
		*read in file for crude incidence - also needed for covar and value labels - only needed for linked
		if "`yearcat'" == "2019" & "`linkedtext'" == "linked" {
			*incidence rates for 2019
			use "$estimatesdir/40.an_incidence_estimates_rates_`medcondition'_`linkedtext'_`covar'_2019.dta", clear
			local yearcatname = "2019"
			} /*2019/linkedtext*/
			else {
				*incidence rates for bmicat and agecat for first 3 years cats
					if "`yearcat'" != "4" & "`yearcat'" != "2019" & ("`covar'" == "bmicat" | "`covar'" == "agecat") & "`linkedtext'" == "linked" {
						use "$estimatesdir/40.an_incidence_estimates_rates_`medcondition'_`linkedtext'_`covar'_yearcat`yearcat'.dta", clear
						local yearcatname = "yearcat`yearcat'"
						} /*incidence rates by BMI and age for additional year categories - linked data only*/
					else {
						*incidence rates for 4th year category (needed for covar and value labels for rows where rates haven't been estimated)
						use "$estimatesdir/40.an_incidence_estimates_rates_`medcondition'_`linkedtext'_`covar'_2015_19.dta", clear
						local yearcatname = "yearcat`yearcat'"
					} /*else2*/
			} /*else1*/
	
		noi {
		
		summ `covar'

		/*** data row for each covariate value (and year / year category) ***/
		if "`linkedtext'" == "primary" & "`medcondition'" == "OSA" & "`yearcat'" != "2019" continue
		if "`linkedtext'" == "primary" & "`medcondition'" == "narcolepsy" & "`yearcat'" != "4" continue
		local yearcatname = "yearcat`yearcat'"
		if "`yearcat'" == "2019" local yearcatname = "2019"

		levelsof `covar', local(values)
		foreach i of local values {
			di "`i'"
			

			*extract crude and adjusted incidence rate ratios for covariate
			foreach model in crude adjusted {
				estimates use "$estimatesdir/39.an_incidence_estimates_ratio_`medcondition'_`linkedtext'_`covar'_`yearcatname'_`model'"
				local `model'_beta = _b[`i'.`covar']
				local `model'_se = _se[`i'.`covar']
				test `i'.`covar'
				local `model'_p = r(p)
			}
			
			*extract age-sex adjusted incidence rate ratios for covariate in complete case BMI sample (OSA only)
			if "`medcondition'" == "OSA" & "`covar'" != "bmicat" & "`covar'" != "obesity" {
				estimates use "$estimatesdir/39.an_incidence_estimates_ratio_`medcondition'_`linkedtext'_`covar'_`yearcatname'_adjustedcc"
				local adjustedcc_beta = _b[`i'.`covar']
				local adjustedcc_se = _se[`i'.`covar']
				test `i'.`covar'
				local adjustedcc_p = r(p)				
			}
			else {
				local adjustedcc_beta = .
				local adjustedcc_se = .
				local adjustedcc_p = .				
			}
			
			*extract BMI adjusted incidence rate ratios for covariate (OSA only)
			if "`medcondition'" == "OSA" & "`covar'" != "bmicat" & "`covar'" != "obesity" {
				estimates use "$estimatesdir/39.an_incidence_estimates_ratio_`medcondition'_`linkedtext'_`covar'_`yearcatname'_bmiadjusted"
				local bmiadjusted_beta = _b[`i'.`covar']
				local bmiadjusted_se = _se[`i'.`covar']
				test `i'.`covar'
				local bmiadjusted_p = r(p)				
			}
			else {
				local bmiadjusted_beta = .
				local bmiadjusted_se = .
				local bmiadjusted_p = .				
			}
			
			*crude incidence rate
			local yes = 0
			if "`yearcat'" == "4" | "`yearcat'" == "2019" local yes = `yes' +  1 
			if "`linkedtext'" == "linked" & ("`covar'" == "bmicat" | "`covar'" == "agecat") local yes = `yes' +  1 
			di "yes: `yes'"
			if `yes' > 0 {
				summ _D if `covar' == `i'
				local inccases = `r(min)'
				
				summ _Y if `covar' == `i'
				local pyears = `r(min)'
				
				summ _Lower if `covar' == `i'
				local lci = `r(min)'
				
				summ _Upper if `covar' == `i'
				local uci = `r(min)'
				
				summ _Rate if `covar' == `i'
				local inc_crude = `r(min)'
				pause
			}
			else {
				local inccases = .
				local pyears = .
				local lci = .
				local uci = .
				local inc_crude = .
			}
			
			#delimit ;
			post `memhold' ("`medcondition'") ("`linkedtext'") ("`covar'") 
			(`i') ("`yearcat'") (`inccases') (`pyears')
			(`inc_crude') (`lci') (`uci') (`crude_beta') (`crude_se') (`crude_p')
			(`adjusted_beta') (`adjusted_se') (`adjusted_p') 
			(`adjustedcc_beta') (`adjustedcc_se') (`adjustedcc_p')
			(`bmiadjusted_beta') (`bmiadjusted_se') (`bmiadjusted_p')
			;
			#delimit cr

		} /*value*/
	} /*noi*/
	} /*covar*/
	} /*yearcats*/
	
	/*incidence rate ratios with calendar year as the covariate - I've only run
	this for linked data*/
	
	if "`linkedtext'" == "linked" {
		
		local covar = "calendaryear"
		
		forvalues i = 2000/2019 {
			
			/*rate ratios for years*/
			foreach model in crude adjusted {
				estimates use "$estimatesdir/39.an_incidence_estimates_ratio_`medcondition'_`linkedtext'_year_`model'"
				local `model'_beta = _b[`i'.`covar']
				local `model'_se = _se[`i'.`covar']
				test `i'.`covar'
				local `model'_p = r(p)
				}
					
			*extract age-sex adjusted incidence rate ratios for covariate in complete case BMI sample (OSA only)
			if "`medcondition'" == "OSA" {
				estimates use "$estimatesdir/39.an_incidence_estimates_ratio_`medcondition'_`linkedtext'_year_adjustedcc"
				local adjustedcc_beta = _b[`i'.`covar']
				local adjustedcc_se = _se[`i'.`covar']
				test `i'.`covar'
				local adjustedcc_p = r(p)				
				}
				else {
					local adjustedcc_beta = .
					local adjustedcc_se = .
					local adjustedcc_p = .				
				}
					
			*extract BMI adjusted incidence rate ratios for covariate (OSA only)
			if "`medcondition'" == "OSA" & "`covar'" != "bmicat" & "`covar'" != "obesity" {
				estimates use "$estimatesdir/39.an_incidence_estimates_ratio_`medcondition'_`linkedtext'_year_bmiadjusted"
				local bmiadjusted_beta = _b[`i'.`covar']
				local bmiadjusted_se = _se[`i'.`covar']
				test `i'.`covar'
				local bmiadjusted_p = r(p)				
				}
				else {
					local bmiadjusted_beta = .
					local bmiadjusted_se = .
					local bmiadjusted_p = .				
				}
			
				*note rates over time are estimated seperately
				#delimit ;
				post `memhold' ("`medcondition'") ("`linkedtext'") ("`covar'") 
				(`i') ("") (.) (.) (.) (.) (.) 
				(`crude_beta') (`crude_se') (`crude_p')
				(`adjusted_beta') (`adjusted_se') (`adjusted_p') 
				(`adjustedcc_beta') (`adjustedcc_se') (`adjustedcc_p')
				(`bmiadjusted_beta') (`bmiadjusted_se') (`bmiadjusted_p')
				;
				#delimit cr
		}
	}
		
	
} /*medcondition*/
} /*linkedtext*/


postclose `memhold'

use `results', clear
save "$datadir_an/temp.dta", replace


label variable medcondition "Sleep disorder"
label variable linkedtext "Data source(s)"
label variable inccases "Incident cases (n)"
label variable pyears "Person-years (/100 000)"
label variable inc_crude "Crude incidence rate (/100 000 person-years)"
label variable inc_crude_lci "Lower 95% confidence bound (%)"
label variable inc_crude_uci "Upper 95% confidence bound (%)"
note inc_crude_lci: "Confidence intervals estimated using Poisson methods"

gen inc_crude_str = string(inc_crude, "%9.3fc") + " (" + string(inc_crude_lci, "%9.3fc") + "-" + string(inc_crude_uci, "%9.3fc") + ")"
label variable inc_crude_str "Crude incidence rate /100 000 person-years (95% CI)"

foreach model in crude adjusted adjustedcc bmiadjusted {
	gen `model'_incratio = exp(`model'_beta)
	gen `model'_incratio_lci = exp(`model'_beta-invnorm(0.975)*`model'_se)
	gen `model'_incratio_uci = exp(`model'_beta+invnorm(0.975)*`model'_se)

	gen `model'_incratio_str  = string(`model'_incratio, "%9.2fc") + " (" + string(`model'_incratio_lci, "%9.2fc") + "-" + string(`model'_incratio_uci, "%9.2fc") + ")"
	replace `model'_incratio_str = "1" if `model'_incratio == 1 & `model'_se == 0 /*base category*/
	
	gen `model'_incratio_pstr = string(`model'_p, "%5.3fc") if `model'_p >=0.001 & `model'_p <0.01
	replace `model'_incratio_pstr = string(`model'_p, "%4.2f") if `model'_p>=0.01
	replace `model'_incratio_pstr = "<0.001" if `model'_p<0.001
	
	if "`model'" == "crude" local modelstr = "Unadjusted"
	if "`model'" == "adjusted" local modelstr = "Age and sex adjusted"
	if "`model'" == "bmiadjusted" local modelstr = "Age and sex adjusted (complete case)"
	if "`model'" == "adjustedcc" local modelstr = "Age, sex and BMI adjusted"

	label variable `model'_incratio "`modelstr' incidence rate ratio"
	label variable `model'_incratio_lci "`modelstr' lower 95% confidence bound"
	label variable `model'_incratio_uci "`modelstr' upper 95% confidence bound"
	label variable `model'_incratio_str "`modelstr' incidence rate ratio (95% CI)"
	label variable `model'_incratio_pstr "`modelstr' incidence rate ratio p-value"
	
	drop `model'_se `model'_p
}

*merge with prevalence estimates to get labels
merge m:1 medcondition linkedtext covar value using "$estimatesdir/35.an_prevalence_estimates_processout.dta", keepusing(covarlabel valuelabel) keep(1 3)
assert _merge !=1 if covar != "calendaryear"
drop _merge

save "$datadir_an/temp.dta", replace

*year categories
destring yearcat, replace
label variable yearcat "Calendar year(s)"
run "$dodir/labels/calendaryear_catlab"
label values yearcat calendaryear_catlab

note: "Incidence rate ratios estimated using log Poisson regression"
compress
save "$estimatesdir/41.an_incidence_estimates_processout.dta", replace


capture log close