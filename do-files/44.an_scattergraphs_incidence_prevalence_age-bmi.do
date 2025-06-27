capture log close
log using "$logdir\44.an_scattergraphs_incidence_prevalence_age-bmi.txt", replace text

/*******************************************************************************
!!!! NEEDS UPDATING WHEN FINAL DECISIONS ABOUT GRAPHS ARE MADE

# Stata do file:    44.an_scattergraphs_incidence_prevalence_age-bmi.do
#
# Author:      Helen Strongman
#
# Date:        23/08/2023
#
# Description: Scatter graphs describing "Incidence and prevalence of OSA and
#				narcolepsy by age and BMI (OSA only)"
#				
#				Single point in time graph:
#				A: OSA incidence, B: Narcolepsy incidence, C: OSA prevalence, 
#				D: Narcolepsy prevalence 
#				A, C, D = 2019; B = 2015-2019 due to sample sizes
#
#				Changes over TIME graph:
#				A: OSA incidence, B: Narcolepsy incidence
#				line for each year category	
#
# Requirements: gr1leg package
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/
pause off
**SET UP EXCEL WORKBOOK FOR TABLES

/*
*notes first
notes drop _all
note: "Supplementary appendix: Prevalence and incidence of OSA and narcolepsy by age"
note: "Time period: 2019 (2015-2019 for narcolepsy incidence)"
note: "note to self- could change 2nd category to 9 to <16 to fit definition of childhood narcolepsy"

collect clear
notes _dir nameswithnotes
foreach name of local nameswithnotes {
     notes _count N : `name'
     forvalues n = 1/`N' {
          notes _fetch note : `name' `n' 
          collect get note = `"note `n' `name': `note'"'
     }
}

collect layout (cmdset)(result)
collect export "$resultdir/44.an_scattergraphs_incidence_prevalence_age.xlsx", as(xls) sheet("notes") cell(A1) replace
*/





include "$dodir/inc_0.figurecolours.do"


foreach linkedtext in "linked" "primary" {
foreach medcondition in "narcolepsy" "OSA" {
	
foreach var in agecat bmicat {
if "`medcondition'" == "narcolepsy" & "`var'" == "bmicat" continue
	
	***get value labels for later
	/*need a dataset with all values of the variable - reading in a subset of rows saves time*/
	use `var' using  "$datadir_an/33.cr_studypopulation_mid2019_`medcondition'_`linkedtext'.dta", clear
	/*check that all BMI values are represented*/
	di "`var'"
	if "`var'" == "bmicat" {
		qui summ bmicat
		local i = `r(min)'
		local max = `r(max)'
		while `i' <= `max' {
			qui count if bmicat == `i'
			assert `r(N)' > 0
			local i = `i' + 1
		}
	*remove " class " from label to make it shorter
	label define bmicatlab 3 "Obesity I", modify
	label define bmicatlab 4 "Obesity II", modify
	label define bmicatlab 5 "Obesity III+", modify
	local i = `i' + 1
	}

	label list `var'lab
	tempfile `var'lab
	label save `var'lab using ``var'lab', replace
		
	*use estimates file and keep correct year/yearcat
	foreach est in inc prev  {
	
	if "`est'" == "prev"{
		use medcondition linkedtext covar value valuelabel prevcases studypop prev_crude prev_crude_lci prev_crude_uci prev_crude_str if covar == "`var'" using "$estimatesdir/35.an_prevalence_estimates_processout.dta", clear
		local estlong "prevalence"
		gen yearcat = 2019
	}
	if "`est'" == "inc" {
		use medcondition linkedtext covar value valuelabel inccases pyears inc_crude inc_crude_lci inc_crude_uci inc_crude_str yearcat if covar == "`var'" using "$estimatesdir/41.an_incidence_estimates_processout.dta", clear
		local estlong "incidence"
		
		/*if "`medcondition'" == "narcolepsy" {
			keep if yearcat == 4
			drop yearcat
		}

		if "`medcondition'" == "OSA" {
			keep if yearcat == 2019
			drop yearcat
		}
		*/
		
	}

	keep if medcondition == "`medcondition'"
	
	*recreate labeled variable
	rename value `var'
	run ``var'lab'
	label values `var' `var'lab
		
		/*y axis range and box placement*/
		if "`est'" == "prev" {
			local ytitle "Prevalence (%)"
			local ysfs "%8.2g" /*2 sfs on y axis*/
			if "`medcondition'" == "OSA"  {
				local titleletter "C"
				local ymax = .
				*local ybox = 1.4
			}
			if "`medcondition'" == "narcolepsy" {
				local titleletter "D"
				local ymax = .
				*local ybox = 0.028
			}
		}
		

		
		/***xaxis*/
		if "`var'" == "bmicat" local xtitle = "Body Mass Index"
		if "`var'" == "agecat" local xtitle = "Age group"
		*to show categories on x axis
		levelsof `var', local(numlist)
		local xlabel "`numlist', valuelabel alternate"
		di "`xlabel'"
		*to show numbers of x axis
		*local xlabel "0(20)100"
		*widen axis to give more space for labels
		qui summ `var'
		local xmin `r(min)'
		local xmax `r(max)'
		
		
		*MAIN PLOTS
		local mainyear = 2019
		if "`medcondition'" == "narcolepsy" & "`est'" == "inc" local mainyear = 4
		
		if "`est'" == "inc" {
			local ytitle "Incidence (/100 000 pyears*)"
			local ysfs "%8.3g" /*3 sfs on y axis*/
			if "`medcondition'" == "OSA"  {
				local titletext "A: OSA `estlong'"
				local ymax = .
				*local ybox = 1.4
			}
			if "`medcondition'" == "narcolepsy" {
				local titletext "C: Narcolepsy age group 2014-2019" /*changed this to combine with graph over time - demonstrates CIs*/
				local ymax = .
				*local ybox = 0.028
			}
		}
		
		/*plot confidence intervals and estimate markers (in this order so that prevalence markers are not covered by the CI plots)*/
		graph twoway ///
		(rarea `est'_crude_lci `est'_crude_uci `var' if medcondition == "`medcondition'" & linkedtext == "`linkedtext'" & yearcat == `mainyear', fcolor(`myblue'%30) fintensity(inten10) lcolor(`myblue') lwidth(thin) ) ///
		(scatter `est'_crude `var' if medcondition == "`medcondition'" & linkedtext == "`linkedtext'" & yearcat == `mainyear', sort msymbol(square) msize(vsmall) mcolor(`myblue') ) ///
		, /// graph options
		ytitle("`ytitle'") xtitle("") ///
		yscale(range(0 `ymax')) ///
		ylabel(#4, format(`ysfs')) /// approx 4 nice labels
		xscale(range(`xmin' `xmax')) ///
		xlabel(`xlabel') ///
		legend(order(2 "Crude estimate" 1 "95% CI") cols(2)) ///
		title("`titletext'") ///
		plotregion(margin(medlarge)) /// to display the full label for the last category
		graphregion(color(white)) ///
		name("`medcondition'_`linkedtext'_`est'_`var'_m", replace)
		
		*INCIDENCE OVER TIME
		
		local ytitle "Incidence (/100 000 pyears*)"
		local ysfs "%8.3g" /*3 sfs on y axis*/
		if "`medcondition'" == "OSA"  {
			if "`var'" == "agecat" local titletext "A: OSA age group over time"
			if "`var'" == "bmicat" local titletext "B: OSA Body Mass Index over time"
			}
		if "`medcondition'" == "narcolepsy" {
			local titletext "D: Narcolepsy age group over time"
			}
		
		if "`est'" == "inc" & "`linkedtext'" == "linked" & "`medcondition'" == "OSA" {
			*removed rareas and added connectors because lines for narcolepsy overlap - might be better to visualise this in forest plots
			graph twoway ///
			(rarea `est'_crude_lci `est'_crude_uci `var' if medcondition == "`medcondition'" & linkedtext == "`linkedtext'" & yearcat == 1, fcolor(`mypurple'%5) fintensity(inten0) lcolor(`mypurple') lwidth(thin) )  ///
			(scatter `est'_crude `var' if medcondition == "`medcondition'" & linkedtext == "`linkedtext'" & yearcat == 1, sort msymbol(square) msize(vsmall) mcolor(`mypurple') lcolor(`mypurple') ) ///
			(rarea `est'_crude_lci `est'_crude_uci `var' if medcondition == "`medcondition'" & linkedtext == "`linkedtext'" & yearcat == 2, fcolor(`myblue'%5) fintensity(inten0) lcolor(`myblue') lwidth(thin) )  ///
			(scatter `est'_crude `var' if medcondition == "`medcondition'" & linkedtext == "`linkedtext'" & yearcat == 2, sort msymbol(circle) msize(vsmall) mcolor(`myblue') lcolor(`myblue') ) ///
			(rarea `est'_crude_lci `est'_crude_uci `var' if medcondition == "`medcondition'" & linkedtext == "`linkedtext'" & yearcat == 3, fcolor(`myorange'%5) fintensity(inten0) lcolor(`myorange') lwidth(thin) )  ///
			(scatter `est'_crude `var' if medcondition == "`medcondition'" & linkedtext == "`linkedtext'" & yearcat == 3, sort msymbol(diamond) msize(vsmall) mcolor(`myorange') lcolor(`myorange') ) ///
			(rarea `est'_crude_lci `est'_crude_uci `var' if medcondition == "`medcondition'" & linkedtext == "`linkedtext'" & yearcat == 4, fcolor(`myyellow'%5) fintensity(inten0) lcolor(`myyellow') lwidth(thin) )  ///
			(scatter `est'_crude `var' if medcondition == "`medcondition'" & linkedtext == "`linkedtext'" & yearcat == 4, sort msymbol(triangle) msize(vsmall) mcolor(`myyellow') lcolor(`myyellow') ) ///
			, /// graph options
			ytitle("`ytitle'") xtitle("") ///
			yscale(range(0 `ymax')) ///
			ylabel(#4, format(`ysfs')) /// approx 4 nice labels
			xscale(range(`xmin' `xmax')) ///
			xlabel(`xlabel') ///
			legend(order(2 "2000-2004" 4 "2005-2009" 6 "2010-2014" 8 "2015-2019" 1 "95% CI") cols(5)) ///
			title("`titletext'") ///
			plotregion(margin(medlarge)) /// to display the full label for the last category
			graphregion(color(white)) ///
			name("`medcondition'_`linkedtext'_`est'_`var'_t", replace)
			pause
		}
		
		if "`est'" == "inc" & "`linkedtext'" == "linked" & "`medcondition'" == "narcolepsy" {
			*removed rareas and added connectors because lines for narcolepsy overlap - might be better to visualise this in forest plots
			graph twoway ///
			(scatter `est'_crude `var' if medcondition == "`medcondition'" & linkedtext == "`linkedtext'" & yearcat == 1, sort msymbol(square) msize(vsmall) mcolor(`mypurple') connect(direct) lcolor(`mypurple') ) ///
			(scatter `est'_crude `var' if medcondition == "`medcondition'" & linkedtext == "`linkedtext'" & yearcat == 2, sort msymbol(circle) msize(vsmall) mcolor(`myblue') connect(direct) lcolor(`myblue') ) ///
			(scatter `est'_crude `var' if medcondition == "`medcondition'" & linkedtext == "`linkedtext'" & yearcat == 3, sort msymbol(diamond) msize(vsmall) mcolor(`myorange') connect(direct) lcolor(`myorange') ) ///
			(scatter `est'_crude `var' if medcondition == "`medcondition'" & linkedtext == "`linkedtext'" & yearcat == 4, sort msymbol(triangle) msize(vsmall) mcolor(`myyellow') connect(direct) lcolor(`myyellow') ) ///
			, /// graph options
			ytitle("`ytitle'") xtitle("") ///
			yscale(range(0 `ymax')) ///
			ylabel(#4, format(`ysfs')) /// approx 4 nice labels
			xscale(range(`xmin' `xmax')) ///
			xlabel(`xlabel') ///
			legend(order(1 "2000-2004" 2 "2005-2009" 3 "2010-2014" 4 "2015-2019") cols(4)) ///
			title("`titletext'") ///
			plotregion(margin(medlarge)) /// to display the full label for the last category
			graphregion(color(white)) ///
			name("`medcondition'_`linkedtext'_`est'_`var'_t", replace)
			pause
		}
	} /*prev/inc*/
} /*var*/
} /*medcondition*/
} /*linkedtext*/


foreach linkedtext in linked primary {
foreach var in agecat bmicat {
	
	if "`var'" == "agecat" {
		grc1leg OSA_`linkedtext'_inc_`var'_m narcolepsy_`linkedtext'_inc_`var'_m ///
		OSA_`linkedtext'_prev_`var'_m  narcolepsy_`linkedtext'_prev_`var'_m , ///
		legendfrom(OSA_`linkedtext'_prev_`var'_m) position(6) ///
		graphregion(color(white)) ///
		name(`linkedtext'_`var'_m, replace)
		
		graph display `linkedtext'_`var'_m, ysize(4) xsize(8) margins(tiny) 
		graph export "$resultdir/44.an_scattergraphs_incidence_prevalence_`var'_`linkedtext'_m", as(emf) replace

	}
	
	if "`var'" == "bmicat" {
		grc1leg OSA_`linkedtext'_inc_`var'_m  ///
		OSA_`linkedtext'_prev_`var'_m, ///
		legendfrom(OSA_`linkedtext'_prev_`var'_m) position(6) ///
		graphregion(color(white)) cols(2) ///
		name(`linkedtext'_`var'_m, replace)
		
		graph display `linkedtext'_`var'_m, ysize(4) xsize(8) margins(tiny)
		graph export "$resultdir/44.an_scattergraphs_incidence_prevalence_`var'_`linkedtext'_m", as(emf) replace
	}
} /*var*/
}

	grc1leg OSA_linked_inc_agecat_t narcolepsy_linked_inc_agecat_m  ///
	OSA_linked_inc_bmicat_t narcolepsy_linked_inc_agecat_t, ///
	legendfrom(OSA_linked_inc_agecat_t) position(6) ///
	graphregion(color(white)) ///
	name(linked_t, replace)
		
	graph display linked_t, ysize(4) xsize(8) margins(tiny) 
	graph export "$resultdir/44.an_scattergraphs_incidence_prevalence_linked_t.emf", as(emf) replace
	*graph drop _all






capture log close

/*
		*text(`ybox' 1998 "2019 Standardised `estlong' (95% CI):" "`boxest'" "2019 Estimated cases in `bpop' (95% plausible interval):" "`boxn'" , placement(east) box just(center) margin(l+4 t+1 b+1) width(85) fcolor(white) bcolor(white) size(smallmed)) ///

/*decided not to add text versions of standardised prevalence and number in population
to the bottom of the graph - will need to put this in a table*/
gen prev_stpos = -0.1
gen plotstr = 1 if mod(year,4)==0 /*identifies multiples of 4*/		
yscale(range(0 0.025)) ///
(scatter prev_stpos year if medcondition == "`medcondition'" & linkedtext == "linked" & plotstr == 1 , msymbol(i) mlabcol(black) mlab(prev_st_str) mlabsize(small) mlabposition(6)) ///
*/