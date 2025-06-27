capture log close
log using "$logdir\48.an_inc-prev_ratios_forestplot_country.txt", replace text

/*******************************************************************************
# Stata do file:    48.an_inc-prev_ratios_forestplot_country.do
#
# Author:      Helen Strongman
#
# Date:        31/10/2023
#
# Description: 	Forest plots of crude, age/sex adjusted and age/sex/BMI adjusted (OSA only)
#				prevalence ratios and incidence rate ratios for 2019 (2015-2019 for narcolepsy IRs)
#
#				only shows ratios for countries using primary care data
#
#				BMI (and BMI adjusted) and ethnicity = complete case 
#
# Requirements: 
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/

pause on

foreach medcondition in OSA narcolepsy {
foreach est in inc prev {
	
	if "`est'" == "prev" {
		use "$estimatesdir/35.an_prevalence_estimates_processout.dta", clear
		local estlong "Prevalence Ratio (PR)"
		local estshort = "PR"
	}
	
	if "`est'" == "inc" {
		use "$estimatesdir/41.an_incidence_estimates_processout.dta", clear
		local estlong "Incidence Rate Ratio (IRR)"
		local estshort "IRR"
		if "`medcondition'" == "narcolepsy" keep if yearcat == 4
		if "`medcondition'" == "OSA" keep if yearcat == 2019
	}
	
	keep if linkedtext == "primary" & medcondition == "`medcondition'"
	keep if covar == "country"
	replace valuelabel = "N.Ireland" if value == 4
	
	*need crude and adjusted estimates to be separate rows
	expand 2, gen(_expand)

	gen model = "1.crude" if _expand == 0
	replace model = "2.adjusted" if _expand == 1
	drop _expand
	
	expand 2 if model == "2.adjusted", gen(_expand)
	replace model = "3.bmiadjusted" if _expand == 1
	drop _expand
	
	foreach suffix in `est'ratio `est'ratio_lci `est'ratio_uci `est'ratio_str `est'ratio_pstr {
		rename crude_`suffix' `suffix'
		replace `suffix' = adjusted_`suffix' if model == "2.adjusted"
		replace `suffix' = bmiadjusted_`suffix' if model == "3.bmiadjusted"
		drop adjusted_`suffix' bmiadjusted_`suffix'
	}
	keep covar covarlabel value valuelabel `est'cases `est'_crude_str `est'ratio `est'ratio_lci `est'ratio_uci `est'ratio_str `est'ratio_pstr model
	
	/*number each value (the crude and adjusted model(s) for each value will have the same number)*/

	foreach newvar in ycat covarval minval {
		gen `newvar' = .
	}
		
	*remove rows up to and incluing "local varlist" if splitting covariates between graphs
	*AND change varlist to varlist`graph' in foreach command

	local varlist country
		
	local i = 1
	local y = 1
		
	foreach covar of local varlist {
		replace covarval = `i' if covar == "`covar'"
				
		levelsof value if covar == "`covar'", local(values)
		summ value if covar == "`covar'"
		local minval = `r(min)'
		foreach val of local values {
			if `val' == `minval' replace minval = 1 if covar == "`covar'" & value == `val' & model == "1.crude"
			replace ycat = `y' if covar == "`covar'" & value == `val'
			local y = `y' + 1
		}
			local i = `i' + 1
		}
		
		
		/*number observations with one gap between covariates to represent separator 
		row and covariate label row in graphs*/
		gsort -ycat -model
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

		capture replace incratio_str = "" if strmatch(incratio_str, "*. (.-.)*")
		replace obs = obs + 0.1 if expand == 1
		
		sort obs
		replace obs = _n

		/*rows to use for covariate and value labels*/
		gen covarlabrow = 1 if value == .
		gen valuelabrow = 1 if covarlabrow ==. & model == "1.crude"

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
		*replace higherriskheading ="{it:risk)}" if obs==$subheadingobs
		*replace lowerriskheading ="{it:risk)}" if obs==$subheadingobs
		*replace obs=$headingobs-1 if obs==.
		
		/*label/headings positions*/
		*gen plabpos = 12 /*location of p-value*/
		gen estlabpos = 30.0 /*location of estimates*/
		gen covarlabpos = 0.03  /*location of variable labels*/
		gen valuelabpos = 0.035 /*local of value labels*/
		
		gen higherlabpos=4
		gen lowerlabpos=0.8
		
		/*legend*/
		local adjlegend "Adjusted for age and sex"
		local bmiadjlegend "Adjusted for age, sex and BMI"
		
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
		
		if "`est'" == "prev" {
			if "`medcondition'" == "OSA" local titleletter "C"
			if "`medcondition'" == "narcolepsy" local titleletter "D"
		}
		
		if "`est'" == "inc" {
			if "`medcondition'" == "OSA" local titleletter "A"
			if "`medcondition'" == "narcolepsy" local titleletter "B"
		}
		
		include "$dodir/inc_0.figurecolours.do"
		
		qui summ ycat
		local yscalemax = `r(max)'
		
		/*******************************************************************************
		#draw graph
		*******************************************************************************/
		
		graph twoway ///
		/// hr and cis (crude)
		|| scatter obs `est'ratio if model == "1.crude", msymbol(circle_hollow) msize(small) mcolor(black)  		/// data points 
			xline(1, lp(solid) lw(vthin) lcolor(black))				/// add ref line
		|| rcap `est'ratio_lci `est'ratio_uci obs if model == "1.crude", horizontal lw(vthin) col(black) msize(vtiny)		/// add the CIs
		/// hr and cis (adjusted)
		|| scatter obs `est'ratio if model == "2.adjusted", msymbol(circle) msize(small) mcolor(gray)		/// data points 
		|| rcap `est'ratio_lci `est'ratio_uci obs if model == "2.adjusted", horizontal lw(vthin) color(black) msize(vtiny)	/// add the CIs	
		/// hr and cis (BMI adjusted)
		|| scatter obs `est'ratio if model == "3.bmiadjusted", msymbol(circle) msize(small) mcolor(black)  		/// data points 
		|| rcap `est'ratio_lci `est'ratio_uci obs if model == "3.bmiadjusted", horizontal lw(vthin) color(black) msize(vtiny)	/// add the CIs		
		/// add results labels
		|| scatter obs estlabpos, m(i) mlab(`est'ratio_str) mlabcol(black) mlabsize(vsmall) mlabposition(9)  ///
		/// Headings for outcome labels and results
		|| scatter obs estlabpos if obs==$headingobs, m(i) mlab(estheading) mlabcol(black) mlabsize(vsmall) mlabpos(9) ///
		|| scatter obs higherlabpos if obs==$headingobs | obs==$subheadingobs, m(i) mlab(higherriskheading) mlabcol(black) mlabsize(vsmall) mlabpos(9) ///
		|| scatter obs lowerlabpos if obs==$headingobs | obs==$subheadingobs, m(i) mlab(lowerriskheading) mlabcol(black) mlabsize(vsmall) mlabpos(9) ///
		/// The outcome and exposure labels
		|| scatter obs covarlabpos if covarlabrow == 1, m(i) mlab(covarlabel) mlabcol(black) mlabsize(vsmall)  ///
		|| scatter obs valuelabpos if valuelabrow == 1, m(i) mlab(valuelabel) mlabcol(black) mlabsize(vsmall) ///
		/// graph options
				, ///
				title("`titleletter': `medcondition' `estlong'", size(small)) ///
				xtitle("`estshort' (95% CI)", size(vsmall) margin(0 2 0 0)) 		/// x-axis title - legend off
				xlab(0.25 0.5 1 2 3, labsize(vsmall)) /// x-axis tick marks
				xscale(range(`xmin' `xmax') log)						///	resize x-axis
				,ylab(none) ytitle("") yscale(r(1 `yscalemax') off) ysize(8)	/// y-axis no labels or title
				graphregion(color(white)) /// get rid of rubbish grey/blue around graph
				legend(order(1 3 5) label(1 "Crude estimate") label(3 "adjusted for age and sex") label(5 "adjusted for age, sex and BMI")  /// legend (1 = first plot, 3 = 3rd plot, 5 = 5th plot)
				size(vsmall) rows(1) nobox region(lstyle(none) col(none) margin(zero)) bmargin(zero)) ///
				name("`medcondition'_`est'", replace)

	} /*prev/inc*/
} /*medcondition*/


grc1leg OSA_inc narcolepsy_inc OSA_prev narcolepsy_prev, ///
legendfrom(OSA_inc) position(6) ///
graphregion(color(white)) ///
name(country, replace)
pause
graph display country, ysize(8) margins(tiny)
graph export "$resultdir/48.an_inc-prev_ratios_forestplot_country.emf", as(emf) replace
	
	


	

*graph drop _all

	




capture log close
