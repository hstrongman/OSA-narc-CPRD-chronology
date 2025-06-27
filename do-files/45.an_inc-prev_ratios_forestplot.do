capture log close
log using "$logdir\45.an_inc-prev_ratios_forestplot.txt", replace text

/*******************************************************************************
# Stata do file:    45.an_inc-prev_ratios_forestplot.do
#
# Author:      Helen Strongman
#
# Date:        23/08/2023
#
# Description: 	Forest plots of crude, age/sex adjusted and age/sex/BMI adjusted (OSA only)
#				 incidence ratios for 2019 (2015-2019 for narcolepsy IRs)
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

foreach linkedtext in linked primary {
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
	
	keep if linkedtext == "`linkedtext'" & medcondition == "`medcondition'"
	if "`linkedtext'" == "primary" drop if covar == "region" & value >=10 /*countries duplicated in region/country*/
	
	*drop age
	drop if covar == "agecat" 
	
	*drop bmi and obesity (show on separate graph?)
	drop if covar == "bmicat"
	drop if covar == "obesity"
	
	*drop reference categories for binary variables
	drop if covar == "gender" & value == 1
	drop if covar == "urban" & value == 1
	
	*drop region
	drop if covar == "region"
	
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
	
	/*
	/*separate graphs for patient and area based characteristics*/
	local extravar ""
	if "`medcondition'" == "OSA" local extravar = "bmicat"
	local varlistperson "agecat gender eth5 `extravar'"
	if "`linkedtext'" == "primary" local extravar = "country"
	if "`linkedtext'" == "linked" local extravar = "urban"
	local varlistarea "region `extravar' carstairs pracsize_cat"
	
	di "area: `varlistarea'"
	di "person: `varlistperson'"
	
	gen graph = ""
	
	foreach graph in person area {
		foreach var of local varlist`graph' {
			replace graph = "`graph'" if covar == "`var'" 
		}
		
	X to reinstate this need to add `graph' to all outputs and follow instructions
	below
	}

	tempfile allvars
	save `allvars'
	
	foreach graph in person area {
		
		use `allvars', clear
		keep if graph == "`graph'"
	*/
	
		/*number each value (the crude and adjusted model(s) for each value 
		will have the same number)*/

		foreach newvar in ycat covarval minval {
			gen `newvar' = .
		}
		
		*remove rows up to and incluing "local varlist" if splitting covariates between graphs
		*AND change varlist to varlist`graph' in foreach command
		local country ""
		local urban ""
		if "`linkedtext'" == "primary" local country = "country"
		if "`linkedtext'" == "linked" local urban = "urban"
		local varlist gender eth5 `country' carstairs `urban' pracsize_cat /*bmicat obesity*/
		
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
		replace obs = obs + 0.1 if expand == 1
		
		sort obs
		*replace obs = _n
		drop obs expand
		
		/*number observations with one gap between covariates to represent separator 
		row and covariate label row in graphs*/
		gsort -ycat -model
		gen obs = _n
		*expand 2 if minval == 1, gen(expand)
		expand 2 if model == "1.crude", gen(expand)
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
		gen covarlabrow = 1 if covar == "" & covarlabel[_n+1] != covarlabel
		replace covarlabel = "{bf:" + covarlabel + "}"
		
		*gen covarlabrow = 1 if value == .
		*gen valuelabrow = 1 if covarlabrow ==. & model == "1.crude"
		gen valuelabrow = 1 if model == "1.crude"

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
		gen estlabpos = 15.0 /*location of estimates*/
		gen covarlabpos = 0.06  /*location of variable labels*/
		gen valuelabpos = 0.065 /*local of value labels*/
		
		gen higherlabpos=3
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
		
		/*if "`est'" == "prev" {
			if "`medcondition'" == "OSA" local titleletter "C"
			if "`medcondition'" == "narcolepsy" local titleletter "D"
		}
		
		if "`est'" == "inc" {
			if "`medcondition'" == "OSA" local titleletter "A"
			if "`medcondition'" == "narcolepsy" local titleletter "B"
		}
		*/
		
		if "`est'" == "inc" local titleletter "A"
		if "`est'" == "prev" local titleletter "B"
		
		*include "$dodir/inc_0.figurecolours.do"
		
		qui summ ycat
		local yscalemax = `r(max)'
		
		if "`medcondition'" == "narcolepsy" local legend `"order(1 3) label(1 "Crude estimate") label(3 "adjusted for age and sex")"'
		if "`medcondition'" == "OSA" local legend `"order(1 3 5) label(1 "Crude estimate") label(3 "adjusted for age and sex") label(5 "adjusted for age, sex and BMI")"'
		noi di `"`legend'"'
	
	
		/*******************************************************************************
		#draw graph
		*******************************************************************************/
		
		graph twoway ///
		/// hr and cis (crude)
		|| scatter obs `est'ratio if model == "1.crude", msymbol(circle_hollow) msize(small) mcolor(black) 		/// data points 
			xline(1, lp(solid) lw(vthin) lcolor(black))				/// add ref line
		|| rcap `est'ratio_lci `est'ratio_uci obs if model == "1.crude", horizontal lw(vthin) col(black) msize(vtiny)		/// add the CIs
		/// hr and cis (adjusted)
		|| scatter obs `est'ratio if model == "2.adjusted", msymbol(circle) msize(small) mcolor(gray)		/// data points 
		|| rcap `est'ratio_lci `est'ratio_uci obs if model == "2.adjusted", horizontal lw(vthin) color(black) msize(vtiny)	/// add the CIs	
		/// hr and cis (BMI adjusted)
		|| scatter obs `est'ratio if model == "3.bmiadjusted", msymbol(circle) msize(small) mcolor(black) 		/// data points 
		|| rcap `est'ratio_lci `est'ratio_uci obs if model == "3.bmiadjusted", horizontal lw(vthin) color(black) msize(vtiny)	/// add the CIs		
		/// add results labels
		|| scatter obs estlabpos, m(i) mlab(`est'ratio_str) mlabcol(black) mlabsize(9.5pt) mlabposition(9)  ///
		/// Headings for outcome labels and results
		|| scatter obs estlabpos if obs==$headingobs, m(i) mlab(estheading) mlabcol(black) mlabsize(vsmall) mlabpos(9) ///
		|| scatter obs higherlabpos if obs==$headingobs | obs==$subheadingobs, m(i) mlab(higherriskheading) mlabcol(black) mlabsize(vsmall) mlabpos(9) ///
		|| scatter obs lowerlabpos if obs==$headingobs | obs==$subheadingobs, m(i) mlab(lowerriskheading) mlabcol(black) mlabsize(vsmall) mlabpos(9) ///
		/// The outcome and exposure labels
		|| scatter obs covarlabpos if covarlabrow == 1, m(i) mlab(covarlabel) mlabcol(black) mlabsize(10.5pt)  ///
		|| scatter obs valuelabpos if valuelabrow == 1, m(i) mlab(valuelabel) mlabcol(black) mlabsize(10.5pt) ///
		/// graph options
				, ///
				title("`titleletter': `estlong'", size(small)) ///
				xtitle("`estshort' (95% CI)", size(vsmall) margin(0 2 0 0)) 		/// x-axis title - legend off
				xlab(0.25 0.5 1 2 3, labsize(vsmall) noticks) /// x-axis tick marks
				xscale(range(`xmin' `xmax') log)						///	resize x-axis
				,ylab(none) ytitle("") yscale(r(1 `yscalemax') off) ysize(8)	/// y-axis no labels or title
				graphregion(color(white)) /// get rid of rubbish grey/blue around graph
				legend(`legend'  /// legend (1 = first plot, 3 = 3rd plot, 5 = 5th plot)
				size(vsmall) rows(1) nobox region(lstyle(none) col(none) margin(zero)) bmargin(zero)) ///
				name("`medcondition'_`linkedtext'_`est'", replace)
				
		*|| scatter obs plabpos if obs==$headingobs, m(i) mlab(pheading) mlabcol(black) mlabsize(vsmall) mlabpos(9) ///
		/// add p values
		*|| scatter obs plabpos, m(i) mlab(prevratio_pstr) mlabcol(black) mlabsize(vsmall) mlabposition(9) ///
		
		
		*graph display `medcondition'_`linkedtext'_`est', ysize(2.0) xsize(4.0) margins(tiny)
		*graph export "$resultdir\36.an_prevalence_forestplot_`medcondition'_`linkedtext'_`graph'", as(emf) replace
		*pause
	*} /*graph type*/
	} /*prev/inc*/
} /*medcondition*/

	/*foreach graph in person area {
		grc1leg OSA_`linkedtext'_inc_`graph' narcolepsy_`linkedtext'_inc_`graph' ///
		OSA_`linkedtext'_prev_`graph' narcolepsy_`linkedtext'_prev_`graph', ///
		legendfrom(OSA_`linkedtext'_inc_`graph') position(6) ///
		graphregion(color(white)) ///
		name(`linkedtext'_`graph', replace)
		pause
		graph drop OSA_`linkedtext'_inc_`graph' narcolepsy_`linkedtext'_inc_`graph'
		graph drop OSA_`linkedtext'_prev_`graph' narcolepsy_`linkedtext'_prev_`graph'
	}
	*/
	di "OSA_`linkedtext'_inc"
	
	/*foreach est in inc prev {
		grc1leg OSA_`linkedtext'_`est' narcolepsy_`linkedtext'_`est', ///
		legendfrom(OSA_`linkedtext'_`est') position(6) ///
		graphregion(color(white)) ///
		name(`linkedtext'_`est', replace)
		pause
		graph display `linkedtext'_`est', ysize(8) margins(tiny)
		graph export "$resultdir/45.an_inc-prev_ratios_forestplot_`linkedtext'_`est'", as(emf) replace
	}
	*/
	
	foreach medcondition in OSA narcolepsy {
		grc1leg `medcondition'_`linkedtext'_inc `medcondition'_`linkedtext'_prev, ///
		legendfrom(`medcondition'_`linkedtext'_inc) position(6) ///
		graphregion(color(white)) ///
		name(`linkedtext'_`medcondition', replace)
		pause
		graph display `linkedtext'_`medcondition', ysize(8) margins(tiny)
		graph export "$resultdir/45.an_inc-prev_ratios_forestplot_`linkedtext'_`medcondition'.emf", as(emf) replace
	}
	

} /*linkedtext*/

	

*graph drop _all

	


/*not using
	|| scatter obs covarlabpos if obs==$headingobs, m(i) mlab(covarheading) mlabcol(black) mlabsize(vsmall) mlabpos(3) ///
	|| scatter obs valuelabpos if obs==$subheadingobs, m(i) mlab(valueheading) mlabcol(black) mlabsize(vsmall) mlabpos(3) ///
	*/

capture log close
