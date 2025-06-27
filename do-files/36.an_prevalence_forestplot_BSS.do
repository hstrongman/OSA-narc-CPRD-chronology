capture log close
log using "$logdir\34.an_prevalence_forestplot.txt", replace text

/*******************************************************************************
# Stata do file:    34.an_prevalence_forestplot.do
#
# Author:      Helen Strongman
#
# Date:        30/03/2023
#
# Description: 	Forest plots of crude and age/sex adjusted prevalence ratios 
#				for 2019
#
# Requirements: 
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/


pause on

foreach linkedtext in linked primary {
foreach medcondition in OSA narcolepsy {
	
	use "$estimatesdir/35.an_prevalence_estimates_processout.dta", clear
	
	keep if linkedtext == "`linkedtext'" & medcondition == "`medcondition'"
	
	*drop youngest age categories
	if "`medcondition'" == "narcolepsy" drop if covar == "agecat" & value == 5
	if "`medcondition'" == "OSA" drop if covar == "agecat" & value == 22
	
	*drop practice size
	drop if covar == "pracsize_cat"
	
	*drop ethnicity not stated
	drop if covar == "eth5" & value == 5
	
	*drop reference categories for binary variables
	drop if covar == "gender" & value == 1
	drop if covar == "urban" & value == 1
	
	*rename longer categories
	replace valuelabel = "1 (lowest)" if covar == "carstairs" & value == 1
	replace valuelabel = "5 (highest)" if covar == "carstairs" & value == 5
	replace valuelabel = "Yorkshire-Humber" if valuelabel == "Yorkshire and The Hu"
	replace covarlabel = "Area based deprivation" if covar == "carstairs"
	
	
	*need crude and adjusted estimates to be separate rows row
	expand 2, gen(expand)
	gen model = "crude" if expand == 0
	replace model = "adjusted" if expand == 1
	drop expand
	
	foreach suffix in prevratio prevratio_lci prevratio_uci prevratio_str prevratio_pstr {
		rename crude_`suffix' `suffix'
		replace `suffix' = adjusted_`suffix' if model == "adjusted"
		drop adjusted_`suffix'
	}
	keep covar covarlabel value valuelabel prevcases studypop prev_crude_str prevratio prevratio_lci prevratio_uci prevratio_str prevratio_pstr model
	/*outcome label
	gen outcomelabel = "Coronary artery disease" if outcome == "cad"
	replace outcomelabel = "Stroke" if outcome == "stroke"
	replace outcomelabel = "Heart failure / cardiomyopathy" if outcome == "hf"
	replace outcomelabel = "Venous thromboembolism" if outcome == "vt"
	
	
	*exposure label
	rename exposure exposurelabel
	
	
	*combined numeric outcome exposure variable
	*local exposureloc " "No chemotherapy" "FEC" "EC" "
	local exposureloc " "FEC" "EC" "
	*/
	
	/*number each value (the crude and adjusted model for each value 
	will have the same number)*/

	foreach newvar in ycat covarval minval {
		gen `newvar' = .
	}
	
	if "`linkedtext'" == "primary" local extra = "country"
	if "`linkedtext'" == "linked" local extra = "urban"
	
	local i = 1
	local y = 1
	foreach covar in gender agecat region `extra' carstairs eth5 {
			replace covarval = `i' if covar == "`covar'"
			
			levelsof value if covar == "`covar'", local(values)
			summ value if covar == "`covar'"
			local minval = `r(min)'
			foreach val of local values {
				if `val' == `minval' replace minval = 1 if covar == "`covar'" & value == `val' & model == "crude"
				replace ycat = `y' if covar == "`covar'" & value == `val'
				local y = `y' + 1
			}
			local i = `i' + 1
	}
	
	/*number observations with one gap between covariates to represent separator 
	row and covariate label row in graphs*/
	gsort -ycat model
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
	gen valuelabrow = 1 if covarlabrow ==. & model == "crude"

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
	gen prheading ="{bf:PR (95% CI)}" if obs==$headingobs
	gen pheading = "{bf:p-value}" if obs==$headingobs
	gen higherriskheading ="{it:(Higher risk)}" if obs==$headingobs
	gen lowerriskheading ="{it:(Lower risk)}" if obs==$headingobs
	*replace higherriskheading ="{it:risk)}" if obs==$subheadingobs
	*replace lowerriskheading ="{it:risk)}" if obs==$subheadingobs
	*replace obs=$headingobs-1 if obs==.
	
	/*label/headings positions*/
	*gen plabpos = 12 /*location of p-value*/
	gen prlabpos = 8.0 /*location of PR estimates*/
	gen covarlabpos = 0.08  /*location of variable labels*/
	gen valuelabpos = 0.085 /*local of value labels*/
	
	gen higherlabpos=2.0
	gen lowerlabpos=1.0
	
	/*legend*/
	local adjlegend "Adjusted for age categories and sex"
	
	include "$dodir/inc_0.figurecolours.do"
	
	qui summ ycat
	local yscalemax = `r(max)'
	
	/*******************************************************************************
	#draw graph
	*******************************************************************************/
	
	graph twoway ///
	/// hr and cis (crude)
	|| scatter obs prevratio if model == "crude", msymbol(smtriangle) msize(small) mcolor(`myorange') 		/// data points 
		xline(1, lp(solid) lw(vthin) lcolor(black))				/// add ref line
	|| rcap prevratio_lci prevratio_uci obs if model == "crude", horizontal lw(vthin) col(black) msize(vtiny)		/// add the CIs
	/// hr and cis (adjusted)
	|| scatter obs prevratio if model == "adjusted", msymbol(smsquare) msize(small) mcolor(`myblue') 		/// data points 
	|| rcap prevratio_lci prevratio_uci obs if model == "adjusted", horizontal lw(vthin) color(black) msize(vtiny)	/// add the CIs	
	/// add results labels
	|| scatter obs prlabpos, m(i) mlab(prevratio_str) mlabcol(black) mlabsize(vsmall) mlabposition(9)  ///
	/// Headings for outcome labels and results
	|| scatter obs prlabpos if obs==$headingobs, m(i) mlab(prheading) mlabcol(black) mlabsize(vsmall) mlabpos(9) ///
	|| scatter obs higherlabpos if obs==$headingobs | obs==$subheadingobs, m(i) mlab(higherriskheading) mlabcol(black) mlabsize(vsmall) mlabpos(9) ///
	|| scatter obs lowerlabpos if obs==$headingobs | obs==$subheadingobs, m(i) mlab(lowerriskheading) mlabcol(black) mlabsize(vsmall) mlabpos(9) ///
	/// The outcome and exposure labels
	|| scatter obs covarlabpos if covarlabrow == 1, m(i) mlab(covarlabel) mlabcol(black) mlabsize(vsmall)  ///
	|| scatter obs valuelabpos if valuelabrow == 1, m(i) mlab(valuelabel) mlabcol(black) mlabsize(vsmall) ///
	/// graph options
			, ///
			xtitle("PR (95% CI)", size(vsmall) margin(0 2 0 0)) 		/// x-axis title - legend off
			xlab(0.25 0.5 1 2 3, labsize(vsmall)) /// x-axis tick marks
			xscale(range(0.2 3) log)						///	resize x-axis
			,ylab(none) ytitle("") yscale(r(1 `yscalemax') off) ysize(8)	/// y-axis no labels or title
			graphregion(color(white)) /// get rid of rubbish grey/blue around graph
			legend(order(1 3) label(1 "Crude prevalence ratio") label(3 "Prevalence ratio adjusted for age categories and sex")  /// legend (1 = first plot, 3 = 3rd plot, 5 = 5th plot)
			size(vsmall) rows(2) nobox region(lstyle(none) col(none) margin(zero)) bmargin(zero)) ///
			name("`medcondition'_`linkedtext'", replace)
			
	*|| scatter obs plabpos if obs==$headingobs, m(i) mlab(pheading) mlabcol(black) mlabsize(vsmall) mlabpos(9) ///
	/// add p values
	*|| scatter obs plabpos, m(i) mlab(prevratio_pstr) mlabcol(black) mlabsize(vsmall) mlabposition(9) ///
	
	
	graph display `medcondition'_`linkedtext', ysize(8.0) margins(tiny)
	graph export "$resultdir\36.an_prevalence_forestplot_`medcondition'_`linkedtext'", as(emf) replace
	pause
}

	/*grc1leg OSA_`linkedtext' narcolepsy_`linkedtext', ///
	legendfrom(OSA_`linkedtext') position(6) ///
	graphregion(color(white)) ///
	name(`linkedtext', replace)
	*/
	

}
	

graph drop _all

	


/*not using
	|| scatter obs covarlabpos if obs==$headingobs, m(i) mlab(covarheading) mlabcol(black) mlabsize(vsmall) mlabpos(3) ///
	|| scatter obs valuelabpos if obs==$subheadingobs, m(i) mlab(valueheading) mlabcol(black) mlabsize(vsmall) mlabpos(3) ///
	*/

capture log close
