
capture log close
log using "$logdir\49.an_table_inc_prev_ratios_linkedvsprimary.txt", replace text

/*******************************************************************************
# Stata do file:    49.an_table_inc_prev_ratios_linkedvsprimary.do
#
# Author:      Helen Strongman
#
# Date:        31/10/2023
#
# Description: 	Supplementary Appendix table comparing inc/prev ratios in
#				primary care and linked populations.
#				Region and urban-rural not included because we do not have data
#				for the full primary care cohort
#				 
# Requirements: 
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/

foreach medcondition in OSA narcolepsy {
foreach est in inc prev {
	
	***get date for medcondition / estimate combination
		
	if "`est'" == "prev" {
		use "$estimatesdir/35.an_prevalence_estimates_processout.dta", clear
	}
	
	if "`est'" == "inc" {
		use "$estimatesdir/41.an_incidence_estimates_processout.dta", clear
		local estlong "Incidence Rate Ratio (IRR)"
		local estshort "IRR"
		if "`medcondition'" == "narcolepsy" keep if yearcat == 4
		if "`medcondition'" == "OSA" keep if yearcat == 2019
	}
	
	keep if medcondition == "`medcondition'"
	drop if covar == "country" 
	drop if covar == "urban" /*not available in primary care only data*/
	
	*fixes
	replace valuelabel = "1 (lowest)" if covar == "carstairs" & value == 1
	replace valuelabel = "5 (highest)" if covar == "carstairs" & value == 5
	replace valuelabel = "Yorkshire-Humber" if valuelabel == "Yorkshire and The Hu"
	replace covarlabel = "Area based deprivation" if covar == "carstairs"
	replace bmiadjusted_`est'ratio_str = "" if medcondition == "narcolepsy"
	replace covarlabel = "Practice size quintile" if covar == "pracsize_cat"
	
	*remove number prefix from ethnicity label
	forvalues x = 0/4 {
		replace valuelabel = regexr(valuelabel, "`x'. ", "") if covar == "eth5"
	}

	keep linkedtext covar value covarlabel valuelabel crude_`est'ratio_str adjusted_`est'ratio_str bmiadjusted_`est'ratio_str
	order linkedtext covarlabel valuelabel crude_`est'ratio_str adjusted_`est'ratio_str bmiadjusted_`est'ratio_str

	tempfile long
	save `long'
	
	***create wide dataset with primary care data and linked data side by side
	foreach linkedtext in linked primary {
		
		if "`linkedtext'" == "linked" {
			local linkedshort "l"
			local linkedlong "Linked"
		}
		
			
		if "`linkedtext'" == "primary"{
			local linkedshort "p"
			local linkedlong "Primary care"
		} 

		use `long', clear
		
		keep if linkedtext == "`linkedtext'"
		drop linkedtext
		
		foreach adj in crude adjusted bmiadjusted {
			rename `adj'_`est'ratio_str `linkedshort'_`adj'_`est'ratio_str
		}
		
		keep covarlabel valuelabel `linkedshort'_crude_`est'ratio_str `linkedshort'_adjusted_`est'ratio_str `linkedshort'_bmiadjusted_`est'ratio_str covar value
		
		if "`linkedtext'" == "primary" merge 1:1 covar value using `wide'
		
		tempfile wide
		save `wide', replace
	}
	
	drop _merge
	
	***order variables and add rows between them
	
	local varlist agecat gender bmicat eth5 pracsize_cat
	
	foreach newvar in ycat covarval minval {
		gen `newvar' = .
		}
		
	local i = 1
	local y = 1
		
	foreach covar of local varlist {
		if "`covar'" == "bmicat" & "`medcondition'" == "narcolepsy" continue
		di "`covar'"
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
		
	/*number observations with one gap between covariates to represent separator 
	row*/
	gsort ycat
	gen obs = _n
	expand 2 if minval == 1, gen(expand)
	qui describe, varlist
	local varlist = "`r(varlist)'"
	di "`varlist'"
	foreach var of local varlist {
		di "`var'"
		*remove ratios in separator row
		if "`var'" == "covarlabel" continue
		if "`var'" == "obs" continue
		if "`var'" == "ycat" continue
		if "`var'" == "expand" continue
		capture confirm numeric variable `var'
		if !_rc replace `var' = . if expand == 1
		capture confirm string variable `var'
		capture replace `var' = "" if expand == 1
		}
	replace valuelabel = covarlabel if expand == 1
	replace obs = obs - 0.1 if expand == 1
	sort obs
	replace obs = _n

	***save excel file
	keep valuelabel l_crude_`est'ratio_str l_adjusted_`est'ratio_str l_bmiadjusted_`est'ratio_str p_crude_`est'ratio_str p_adjusted_`est'ratio_str p_bmiadjusted_`est'ratio_str 
	order valuelabel l_crude_`est'ratio_str l_adjusted_`est'ratio_str l_bmiadjusted_`est'ratio_str p_crude_`est'ratio_str p_adjusted_`est'ratio_str p_bmiadjusted_`est'ratio_str
	export excel using "$resultdir/49.an_table_inc_prev_ratios_linkedvsprimary.xlsx",  sheet("`medcondition'_`est'", replace)
}
}

capture log close
