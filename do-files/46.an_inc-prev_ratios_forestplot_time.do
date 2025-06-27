capture log close
log using "$logdir\46.an_inc-prev_ratios_forestplot_time.txt", replace text

/*******************************************************************************
# Stata do file:    46.an_inc-prev_ratios_forestplot_time.do
#
# Author:      Helen Strongman
#
# Date:        26/09/2023
#
# Description: 	Forest plots of age/sex adjusted (narcolepsy) and age/sex/BMI adjusted (OSA)
#				 incidence ratios - 1 plot per 5 year time period
#
#				NB - not showing regional distribution because the number of
#				practices in Eastern regions is small and will be clustered by CCG
#
#				BMI (and BMI adjusted) and ethnicity = complete case 
#
# Requirements: 
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/

pause off

foreach linkedtext in linked /*primary*/ {
foreach medcondition in OSA narcolepsy {
forvalues ycat = 1/4 {

use "$estimatesdir/41.an_incidence_estimates_processout.dta", clear
local estlong "incidence rate"
local estshort "IRR"
	
	keep if linkedtext == "`linkedtext'" & medcondition == "`medcondition'"
	di "`ycat'"
	keep if yearcat == `ycat'

	*drop obesity and bmicat
	drop if covar == "obesity"
	*drop if covar == "bmicat"
	
	*drop reference categories for binary variables
	drop if covar == "gender" & value == 1
	drop if covar == "urban" & value == 1
	
	*drop region
	drop if covar == "region"
	
	*drop agecat and bmi (scales very different to other variables)
	drop if covar == "agecat" | covar == "bmicat"
	
	*fixes
	replace valuelabel = "1 (lowest)" if covar == "carstairs" & value == 1
	replace valuelabel = "5 (highest)" if covar == "carstairs" & value == 5
	replace valuelabel = "Yorkshire-Humber" if valuelabel == "Yorkshire and The Hu"
	replace covarlabel = "Area based deprivation" if covar == "carstairs"
	replace bmiadjusted_incratio_str = "" if medcondition == "narcolepsy"
	replace covarlabel = "Practice size quintile" if covar == "pracsize_cat"
	
	if "`medcondition'" == "OSA" {
		assert bmiadjusted_incratio != . if covar != "bmicat"
		foreach var in incratio incratio_lci incratio_uci incratio_str incratio_pstr {
		replace adjusted_`var' =  bmiadjusted_`var' if !missing(bmiadjusted_incratio)
	}
	}
	
	keep covar covarlabel value valuelabel inccases adjusted_incratio* yearcat
	
	
	/*number each value (the crude and adjusted model(s) for each value 
	will have the same number)*/

	foreach newvar in ycat covarval minval {
		gen `newvar' = .
	}
		
	local country ""
	local urban ""
	*local bmicat ""
	if "`linkedtext'" == "primary" local country = "country"
	if "`linkedtext'" == "linked" local urban = "urban"
	*if "`medcondition'" == "OSA" local bmicat = "bmicat"
	
	local varlist gender eth5 `country' carstairs `urban' pracsize_cat `bmicat'
		
	local i = 1
	local y = 1
		
	foreach covar of local varlist {
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
	row and covariate label row in graphs*/
		gsort -ycat
		gen obs = _n
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
		replace obs = obs + 0.1 if expand == 1
		
		sort obs
		replace obs = _n

		/*rows to use for covariate and value labels*/
		gen covarlabrow = 1 if value == .
		gen valuelabrow = 1 if covarlabrow ==.

		/*graph column and axis headings*/
		count
		insobs 2, after(r(N))
		qui summ obs
		global headingobs = r(max) + 2
		global subheadingobs = r(max) + 1
		di $headingobs
		replace obs=$headingobs if obs==. & _n==_N 
		replace obs=$subheadingobs if obs==. & _n==_N-1
		*gen covarheading = "{bf:Variable}" if obs==$headingobs
		*gen valueheading = "{bf:Value}" if obs==$subheadingobs
		gen estheading ="{bf:`estshort' (95% CI)}" if obs==$headingobs
		gen pheading = "{bf:p-value}" if obs==$headingobs
		gen higherriskheading ="{it:(Higher)}" if obs==$headingobs
		*replace higherriskheading  = "{it:(`estlong')}" if obs== $subheadingobs
		gen lowerriskheading ="{it:(Lower)}" if obs==$headingobs
		*replace lowerriskheading ="{it:(`estlong')}" if obs==$subheadingobs

		
		/*label/headings positions*/
		*gen plabpos = 12 /*location of p-value*/
		gen estlabpos = 18.0 /*location of estimates*/
		gen covarlabpos = 0.03  /*location of variable labels*/
		gen valuelabpos = 0.0325 /*local of value labels*/
		
		gen higherlabpos=3.0
		gen lowerlabpos=0.8
		
		/*legend*/
		if "`medcondition'" == "narcolepsy" local adjlegend "Adjusted for age and sex"
		if "`medcondition'" == "OSA" local adjlegend "Adjusted for age, sex and BMI"
		
		/*xscale*/
		/*
		if "`graph'" == "person" {
			local xmin = 0.05
			if "`medcondition'" == "narcolepsy" local xmax = 2.5
			if "`medcondition'" == "OSA" local xmax = 35
		}
		if "`graph'" == "area" {
			local xmin = 0.2
			local xmax = 2.0
		}
		*/
		
		local titleletter: word `ycat' of `c(ALPHA)'
		local titletext: label calendaryear_catlab `ycat'
		
		include "$dodir/inc_0.figurecolours.do"
		
		qui summ ycat
		local yscalemax = `r(max)'
		
		/*******************************************************************************
		#draw graph
		*******************************************************************************/
		
		graph twoway ///
		/// hr and cis
		|| scatter obs adjusted_incratio, msymbol(smtriangle) msize(small) mcolor(`myblue') 		/// data points 
			xline(1, lp(solid) lw(vthin) lcolor(black))				/// add ref line
		|| rcap adjusted_incratio_lci adjusted_incratio_uci obs, horizontal lw(vthin) col(black) msize(vtiny)		/// add the CIs
		/// add results labels
		|| scatter obs estlabpos, m(i) mlab(adjusted_incratio_str) mlabcol(black) mlabsize(vsmall) mlabposition(9)  ///
		/// Headings for outcome labels and results
		|| scatter obs estlabpos if obs==$headingobs, m(i) mlab(estheading) mlabcol(black) mlabsize(vsmall) mlabpos(9) ///
		|| scatter obs higherlabpos if obs==$headingobs | obs==$subheadingobs, m(i) mlab(higherriskheading) mlabcol(black) mlabsize(vsmall) mlabpos(9) ///
		|| scatter obs lowerlabpos if obs==$headingobs | obs==$subheadingobs, m(i) mlab(lowerriskheading) mlabcol(black) mlabsize(vsmall) mlabpos(9) ///
		/// The outcome and exposure labels
		|| scatter obs covarlabpos if covarlabrow == 1, m(i) mlab(covarlabel) mlabcol(black) mlabsize(vsmall)  ///
		|| scatter obs valuelabpos if valuelabrow == 1, m(i) mlab(valuelabel) mlabcol(black) mlabsize(vsmall) ///
		/// graph options
				, ///
				title("`titleletter': `titletext'", size(small)) ///
				xtitle("IRR (95% CI)", size(vsmall) margin(0 2 0 0)) 		/// x-axis title - legend off
				xlab(0.25 0.5 1 2 3, labsize(vsmall)) /// x-axis tick marks
				xscale(range(`xmin' `xmax') log)						///	resize x-axis
				,ylab(none) ytitle("") yscale(r(1 `yscalemax') off) ysize(8)	/// y-axis no labels or title
				graphregion(color(white) margin(tiny)) /// get rid of rubbish grey/blue around graph
				legend(off) ///
				name("`medcondition'_`linkedtext'_`ycat'", replace)
} /*ycat*/
				
	graph combine `medcondition'_`linkedtext'_1 `medcondition'_`linkedtext'_2 ///
	`medcondition'_`linkedtext'_3 `medcondition'_`linkedtext'_4, ///
	graphregion(color(white)) ///
	name(`linkedtext'_`medcondition', replace)
	pause
	*graph drop OSA_`linkedtext'_inc narcolepsy_`linkedtext'_inc
	*graph drop OSA_`linkedtext'_prev narcolepsy_`linkedtext'_prev
	graph display `linkedtext'_`medcondition', ysize(8) margins(zero)
	graph export "$resultdir/46.an_inc-prev_ratios_forestplot_time_`medcondition'_`linkedtext'", as(emf) replace
				
} /*medcondition*/

} /*linkedtext*/

	

*graph drop _all

	


/*not using
	|| scatter obs covarlabpos if obs==$headingobs, m(i) mlab(covarheading) mlabcol(black) mlabsize(vsmall) mlabpos(3) ///
	|| scatter obs valuelabpos if obs==$subheadingobs, m(i) mlab(valueheading) mlabcol(black) mlabsize(vsmall) mlabpos(3) ///
	*/

capture log close
