
capture log close
log using "$logdir\47.an_table_inc_prev_ratios_bmicc.txt", replace text

/*******************************************************************************
# Stata do file:    47.an_table_inc_prev_ratios_bmicc.txt
# Author:      Helen Strongman
#
# Date:        25/08/2023
#
# Description: 	Supplementary Appendix table comparing age-sex adjusted IRRs and
#				PRs in complete case BMI cohort  - OSA only
#				 
# Requirements: 
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/

*bring in incidence and prevalence estimates and merge
use "$estimatesdir/41.an_incidence_estimates_processout.dta", clear
keep if yearcat == 2019 & medcondition == "OSA" & linkedtext == "linked"
keep covarlabel valuelabel adjusted_incratio_str adjustedcc_incratio_str

tempfile temp
save `temp'

use "$estimatesdir/35.an_prevalence_estimates_processout.dta", clear
keep if medcondition == "OSA" & linkedtext == "linked"
keep covar covarlabel value valuelabel adjusted_prevratio_str adjustedcc_prevratio_str
merge 1:1 covarlabel valuelabel using `temp'

drop _merge
*drop BMI and obesity
drop if covar == "bmicat" | covar == "obesity"

*label fixes
replace valuelabel = "1 (lowest)" if covar == "carstairs" & value == 1
replace valuelabel = "5 (highest)" if covar == "carstairs" & value == 5
replace valuelabel = "Yorkshire-Humber" if valuelabel == "Yorkshire and The Hu"
replace covarlabel = "Area based deprivation" if covar == "carstairs"
replace covarlabel = "Practice size quintile" if covar == "pracsize_cat"

*add separator row between covariates
gen covarval = .
gen minval = .
gen ycat = .
local i = 1
local y = 1
foreach covar in agecat gender eth5 carstairs urban pracsize_cat region {
	
	/*flag covariates with number to denote order and flag minimum value of each covariate*/
		
	replace covarval = `i' if covar == "`covar'"
	levelsof value if covar == "`covar'", local(values)
	summ value if covar == "`covar'"
	local minval = `r(min)'
	foreach val of local values {
		if `val' == `minval' replace minval = 1 if covar == "`covar'" & value == `val'
		replace ycat = `y' if covar == "`covar'" & value == `val'
		local y = `y' + 1
		}
	
	local i = `i' + 1
}
	
/*number observations with one gap between covariates to represent separator row*/
gsort ycat
gen obs = _n
/*add row and remove values*/
expand 2 if minval == 1, gen(expand)
qui describe, varlist
local varlist = "`r(varlist)'"
di "`varlist'"
foreach var of local varlist {
	if "`var'" == "covarlabel" continue
	if "`var'" == "obs" continue
	if "`var'" == "ycat" continue
	if "`var'" == "expand" continue
	capture confirm numeric variable `var'
	if !_rc replace `var' = . if expand == 1
	capture confirm string variable `var'
	capture replace `var' = "" if expand == 1
	}
*reorder
replace obs = obs - 0.1 if expand == 1	
sort obs
replace obs = _n
replace valuelabel = covarlabel if expand == 1

keep valuelabel adjusted_prevratio_str adjustedcc_prevratio_str adjusted_incratio_str adjustedcc_incratio_str

*relabel variables
label variable adjusted_prevratio_str "PR (full study population)"
label variable adjustedcc_prevratio_str "PR (complete case)"
label variable adjusted_incratio_str "IRR (full study population)"
label variable adjustedcc_incratio_str "IRR (complete case)"
label variable valuelabel "Characteristic"



export excel using "$resultdir/47.an_table_inc_prev_ratios_bmicc.xlsx", firstrow(varlabels) replace

capture log close


