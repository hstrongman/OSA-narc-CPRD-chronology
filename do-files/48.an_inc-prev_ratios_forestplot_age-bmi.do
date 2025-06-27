capture log close
log using "$logdir\48.an_inc-prev_ratios_forestplot_age-bmi.txt", replace text

/*******************************************************************************
# Stata do file:    48.an_inc-prev_ratios_forestplot-age-bmi.do
#
# Author:      Helen Strongman
#
# Date:        18/10/2023
#
# Description: 	Forest plots of IRRs and PRs for age and BMI in linked and primary
#				care study populations
#
# Requirements: 
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/

pause off


foreach linkedtext in linked primary {
foreach medcondition in OSA narcolepsy {
foreach est in inc prev {
foreach covar in agecat bmicat {
	/*separate graphs for each variable because scales differ hugely*/
	if "`medcondition'" == "narcolepsy" & "`covar'" == "bmicat" continue	
	
	if "`est'" == "prev" {
		use "$estimatesdir/35.an_prevalence_estimates_processout.dta", clear
		local estlong "prevalence"
		local estshort = "PR"
	}
	
	if "`est'" == "inc" {
		use "$estimatesdir/41.an_incidence_estimates_processout.dta", clear
		local estlong "incidence rate"
		local estshort "IRR"
		if "`medcondition'" == "narcolepsy" keep if yearcat == 4
		if "`medcondition'" == "OSA" keep if yearcat == 2019
	}
	
	if "`linkedtext'" == "linked" local linkedlong "Linked"
	if "`linkedtext'" == "primary" local linkedlong "Primary"
	
	
	keep if linkedtext == "`linkedtext'" & medcondition == "`medcondition'"
	
	keep if covar == "`covar'" 
	
	replace bmiadjusted_`est'ratio_str = "" if medcondition == "narcolepsy"
	replace bmiadjusted_`est'ratio_str = "" if covar == "bmicat"
	
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
	
	/*number each value (the crude and adjusted model(s) for each value 
	will have the same number)*/

	foreach newvar in ycat covarval minval {
		gen `newvar' = .
		}
	
	
	local y = 1
	
	replace covarval = 1 if covar == "`covar'"
				
	levelsof value if covar == "`covar'", local(values)
	summ value if covar == "`covar'"
	local minval = `r(min)'
		foreach val of local values {
			if `val' == `minval' replace minval = 1 if covar == "`covar'" & value == `val' & model == "1.crude"
			replace ycat = `y' if covar == "`covar'" & value == `val'
			local y = `y' + 1
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
		replace higherriskheading  = "{it:(`estlong')}" if obs== $subheadingobs
		gen lowerriskheading ="{it:(Lower)}" if obs==$headingobs
		replace lowerriskheading ="{it:(`estlong')}" if obs==$subheadingobs
		*replace higherriskheading ="{it:risk)}" if obs==$subheadingobs
		*replace lowerriskheading ="{it:risk)}" if obs==$subheadingobs
		*replace obs=$headingobs-1 if obs==.
		
		/*label/headings positions*/
		*gen plabpos = 12 /*location of p-value*/
		
		if "`covar'" == "agecat" {
			gen estlabpos = 50.0 /*location of estimates*/
			gen covarlabpos = 0.005  /*location of variable labels*/
			gen valuelabpos = 0.0055 /*local of value labels*/
			gen higherlabpos=5.0
			gen lowerlabpos=0.8
			local xlab "0.05 0 1 2 3"
		}
		
		if "`covar'" == "bmicat" {
			gen estlabpos = 1000.0 /*location of estimates*/
			gen covarlabpos = 0.03  /*location of variable labels*/
			gen valuelabpos = 0.035 /*local of value labels*/
			gen higherlabpos=7.5
			gen lowerlabpos=0.8
			local xlab "0.5 0 2 5 10 20 30"
		}		
		
		
		
		/*legend*/
		if "`covar'" == "agecat" {
			local adjlegend "Adjusted for sex"
			*local bmiadjlegend "Adjusted for sex and BMI"
			local labelorder "1 3 5"
			local label5 "label(5 "Adjusted for sex and BMI")"
		}
		
		if "`covar'" == "bmicat" {
			local adjlegend "Adjusted for age and sex"
			local labelorder "1 3"
			local label 5 ""
		}
		

		if "`linkedtext'" == "linked" {
			if "`medcondition'" == "OSA" local titleletter "A"
			if "`medcondition'" == "narcolepsy" local titleletter "C"
		}
		
		if "`linkedtext'" == "primary" {
			if "`medcondition'" == "OSA" local titleletter "B"
			if "`medcondition'" == "narcolepsy" local titleletter "D"
		}
		
		include "$dodir/inc_0.figurecolours.do"
		
		qui summ ycat
		local yscalemax = `r(max)'
		
		/*******************************************************************************
		#draw graph
		*******************************************************************************/
		
		graph twoway ///
		/// hr and cis (crude)
		|| scatter obs `est'ratio if model == "1.crude", msymbol(smtriangle) msize(small) mcolor(`myorange') 		/// data points 
			xline(1, lp(solid) lw(vthin) lcolor(black))				/// add ref line
		|| rcap `est'ratio_lci `est'ratio_uci obs if model == "1.crude", horizontal lw(vthin) col(black) msize(vtiny)		/// add the CIs
		/// hr and cis (adjusted)
		|| scatter obs `est'ratio if model == "2.adjusted", msymbol(smsquare) msize(small) mcolor(`myblue') 		/// data points 
		|| rcap `est'ratio_lci `est'ratio_uci obs if model == "2.adjusted", horizontal lw(vthin) color(black) msize(vtiny)	/// add the CIs	
		/// hr and cis (BMI adjusted)
		|| scatter obs `est'ratio if model == "3.bmiadjusted", msymbol(smsquare) msize(small) mcolor(`myyellow') 		/// data points 
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
				title("`titleletter': `medcondition' `linkedlong'", size(small)) ///
				xtitle("PR (95% CI)", size(vsmall) margin(0 2 0 0)) 		/// x-axis title - legend off
				xlab(`xlab', labsize(vsmall)) /// x-axis tick marks
				xscale(range(`xmin' `xmax') log)						///	resize x-axis
				,ylab(none) ytitle("") yscale(r(1 `yscalemax') off) ysize(8)	/// y-axis no labels or title
				graphregion(color(white)) /// get rid of rubbish grey/blue around graph
				legend(order(`labelorder') label(1 "Crude estimate") label(3 "`adjlegend'") `label5'  /// legend (1 = first plot, 3 = 3rd plot, 5 = 5th plot)
				size(vsmall) rows(2) nobox region(lstyle(none) col(none) margin(zero)) bmargin(zero)) ///
				name("`medcondition'_`linkedtext'_`est'_`covar'", replace)
				
		*|| scatter obs plabpos if obs==$headingobs, m(i) mlab(pheading) mlabcol(black) mlabsize(vsmall) mlabpos(9) ///
		/// add p values
		*|| scatter obs plabpos, m(i) mlab(prevratio_pstr) mlabcol(black) mlabsize(vsmall) mlabposition(9) ///
		
		
		*graph display `medcondition'_`linkedtext'_`est', ysize(2.0) xsize(4.0) margins(tiny)
		*graph export "$resultdir\36.an_prevalence_forestplot_`medcondition'_`linkedtext'_`graph'", as(emf) replace
		*pause
	*} /*graph type*/
	} /*prev/inc*/
} /*medcondition*/
} /*linked text*/
} /*covar*/


	
	foreach est in inc prev {
		grc1leg OSA_linked_`est'_agecat OSA_primary_`est'_agecat ///
		narcolepsy_linked_`est'_agecat narcolepsy_primary_`est'_agecat, ///
		legendfrom(OSA_linked_`est'_agecat) position(6) ///
		graphregion(color(white)) rows(2) ///
		name(`est'_agecat, replace)
		graph display `est'_agecat, ysize(8) margins(tiny)
		graph export "$resultdir/48.an_inc-prev_ratios_forestplot_age_`est'", as(emf) replace
		
		grc1leg OSA_linked_`est'_bmicat OSA_primary_`est'_bmicat, ///
		legendfrom(OSA_linked_`est'_bmicat) position(6) ///
		graphregion(color(white)) rows(1) ///
		name(`est'_bmicat, replace)
		graph display `est'_bmicat, ysize(4) margins(tiny)
		graph export "$resultdir/48.an_inc-prev_ratios_forestplot_bmi_`est'", as(emf) replace
	}



*graph drop _all



capture log close
