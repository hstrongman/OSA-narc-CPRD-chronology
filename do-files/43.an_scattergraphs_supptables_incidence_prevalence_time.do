capture log close
log using "$logdir\43.an_scattergraphs_supptables_incidence_prevalence_time.txt", replace text

/*******************************************************************************
# Stata do file:    43.an_scattergraphs_supptables_incidence_prevalence_time.do
#
# Author:      Helen Strongman
#
# Date:        22/08/2023
#
# Description: Tables describing "Incidence and prevalence of OSA and
#				narcolepsy over time (crude and standardised to the UK/English
#				population) for linked and primary care only analyses
#
#				Scatter graphs combining above data:
#				- for linked data only
#				- for linked, primary care only (UK) and primary care only (England only)
#
# Requirements: gr1leg package
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/
pause off

**SET UP EXCEL WORKBOOK FOR TABLES

*notes first
notes drop _all
note: "Supplementary appendix: Prevalence and incidence of OSA and narcolepsy from 2000 to 2019"
note: "Prevalence is standardised by age/gender to the population of England (linked data) or the UK (primary care data) and each devolved nation for each calendar year"
note: "note to self - I estimated prevalence estimated from 1999 - 2020 but it is available from $studystart_linked to $studyend_linked for the linked study population and $studystart_primary to $studyend_primary for the primary care only study population"
note: "Narcolepsy incidence was estimated in 5-year categories due to low numbers of cases"
note: "Incidence in the devolved nations was estimated in 5-year categories due to low numbers of cases"
note: "note to self - calendar year labelling in input dataset is for primary care dataset - change default to linked dataset?"

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
collect export "$resultdir/43.an_scattergraphs_supptables_incidence_prevalence_time.xlsx", as(xls) sheet("notes") cell(A1) replace


include "$dodir/inc_0.figurecolours.do"
/*generate label for every 5 years
gen _mod5yr = mod(year,5)
gen label = string(crudeprev, "%9.3fc")
replace label = "" if _mod5yr !=0*/

*foreach linkedtext in "primary" "linked" {
foreach medcondition in "OSA" "narcolepsy" {
	foreach est in inc prev {
	
	if "`est'" == "prev"{
		use "$estimatesdir/32.an_prevalence_estimates_time.dta", clear
		local estlong "prevalence"
		local estvlong "standardised prevalence"
		drop if year < 2000 | year > 2019
	}
	if "`est'" == "inc" {
		use "$estimatesdir/38.an_incidence_estimates_time.dta", clear
		local estlong "incidence"
		local estvlong "crude incidence"
		
		
		/**plot 5 year calendaryears at midpoint
		if "`linkedtext'" == "primary" gen year = 1995.5 if calendaryear_cat == 0 
			*if "`linkedtext'" == "linked" replace year = 1999 if calendaryear_cat == 0
			gen year = 2002.5 if calendaryear_cat == 1
			forvalues x = 2/4 {
				replace year = 2000 + 2.5 + (`x'*5) if calendaryear_cat == `x'
			}
			/*linked - half way between 1st Jan 2020 and end March 2021
			primary - half way between 1st Jan 2020 and end April 2022*/
			if "`linkedtext'" == "linked" replace year = 2020.625 if calendaryear_cat == 5
			if "`linkedtext'" == "primary" replace year = 2021.333 if calendaryear_cat == 5*/
		
		/*rename calendaryear variable year to match prevalence and
		differentiate between narcolepsy and OSA*/
		if "`medcondition'" == "narcolepsy" {
			drop if calendaryear_cat == 0 | calendaryear_cat == 5
			rename calendaryear_cat year
		}

		if "`medcondition'" == "OSA" {
			drop if (calendaryear <2000 | calendaryear >2019) & calendaryear !=.
			drop if calendaryear_cat == 0 | calendaryear_cat == 5
			rename calendaryear year
			replace year = calendaryear_cat if calendaryear_cat !=.
		}
		
		label variable year "Calendar year"
		
		
		/*/*replace year = midpoint of categories for individual countries*/
		replace year = 1999 if calendaryear_cat == 0
		replace year = 2002.5 if calendaryear_cat == 1
		replace year = 2006.5 if calendaryear_cat == 2
		replace year = 2011.5 if calendaryear_cat == 3
		replace year = 2016.5 if calendaryear_cat == 4
		replace year = 2021 if calendaryear_cat == 5
		*/
		
		keep if year != .
		
		*rename crude incidence variables to match prevalence variables
		*create dummy standardised incidence variables
		rename ir_crude inc_crude
		gen inc_st = .
		foreach var in lci uci str {
			rename ir_crude_`var' inc_crude_`var'
			if "`var'" == "str" {
				gen inc_st_str = ""
			}
				else {
					gen inc_st_`var' = .
				}
		}
		
	}

	
	*if "`est'" == "prev" drop if country !=5  & country !=1 & linkedtext == "primary" /*only keep England and UK rows for primary care data*/
	keep if medcondition == "`medcondition'" /*& linkedtext == "`linkedtext'"*/

		/*create local with standardised estimate in 2019 (2015-19 for narcolepsy incidence) to add to box on graph
		if "`medcondition'" == "narcolepsy" & "`est'" == "inc" {
			local condition = "calendaryear_cat == 4"
		}
		else {
			local condition = "year == 2019"
		}
		
		tempvar thisrow
		gen `thisrow' = _n if `condition' & medcondition == "`medcondition'" & linkedtext == "`linkedtext'"
		qui summ `thisrow'
		assert `r(min)' == `r(max)' /*i.e. only one row meets condition*/
		local rowno = `r(min)'
		local boxest = `est'_st_str[`rowno']
		local boxn = popcases_str[`rowno']
		/*create local with population to add to box on graph*/
		if linkedtext == "linked" local bpop = "England"
		if linkedtext == "primary" local bpop = "UK"
		*/
		
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
		
		if "`est'" == "inc" {
			local ytitle "Incidence (/100 000 pyears*)"
			local ysfs "%8.3g" /*3 sfs on y axis*/
			if "`medcondition'" == "OSA"  {
				local titleletter "A"
				local ymax = .
				*local ybox = 1.4
			}
			if "`medcondition'" == "narcolepsy" {
				local titleletter "B"
				local ymax = .
				*local ybox = 0.028
			}
		}
		
		/*xaxis - moved to before each graph*/
		/*if "`medcondition'" == "narcolepsy" & "`est'" == "inc" {
			if "`linkedtext'" == "linked" {
				*label define calendaryear_cat 0 "1998-2000", modify
				*label define calendaryear_cat 5 "2020-2021*", modify
			}
			*if "`linkedtext'" == "linked" label define calendaryear_cat 5 "2020-2022*", modify
			local xlabel "1(1)4, valuelabel"
			*widen axis to give more space for labels
			local xmin 0.8
			local xmax 4.2
		}
		else {
			local xlabel "2000(4)2020"
			local xmin 2000
			local xmax 2020
		}
		*/
		
		/*label year*/
		label values year calendaryear_catlab
		
		/*decided to plot standardised estimates only for prevalence due to overlapping CIs*/
		if "`est'" == "inc" local esttype = "crude"
		if "`est'" == "prev" local esttype = "st"
		
		*MAIN PLOT- linked data i.e. England only
		gen _plot = 1 if medcondition == "`medcondition'" /*& linkedtext == "linked"*/ 
		replace _plot = 0 if medcondition == "OSA" & year < 5  /*i.e. don't plot year categories*/
		summ year if _plot == 1
		if `r(min)' == 1 {
			local xlabel "1(1)4, valuelabel"
			*widen axis to give more space for labels
			local xmin 0.8
			local xmax 4.2
			}
			else {
				local xlabel "2000(4)2020"
				local xmin 2000
				local xmax 2020
			}
			
		/*plot confidence intervals and estimate markers (in this order so that prevalence markers are not covered by the CI plots)*/
		graph twoway ///
		/*(rarea `est'_crude_lci `est'_crude_uci year if medcondition == "`medcondition'" & linkedtext == "`linkedtext'", fcolor(`myblue'%30) fintensity(inten10) lcolor(`myblue') lwidth(vthin) )*/ ///
		(rarea `est'_`esttype'_lci `est'_`esttype'_uci year if medcondition == "`medcondition'" & linkedtext == "linked" & country == 1 & _plot == 1, fcolor(`myorange'%30) fintensity(inten10) lcolor(`myorange') lwidth(vthin) ) ///
		/*(scatter `est'_crude year if medcondition == "`medcondition'" & linkedtext == "`linkedtext'", sort msymbol(square) msize(vtiny) mcolor(`myblue') ) */ ///
		(scatter `est'_`esttype' year if medcondition == "`medcondition'" & linkedtext == "linked" & country == 1 & _plot == 1, msymbol(triangle) msize(vtiny) mcolor(`myorange') lcolor(`myorange') con(line) ) ///
		, /// graph options
		ytitle("`ytitle'") xtitle("Year") ///
		yscale(range(0 `ymax')) ///
		ylabel(#4, format(`ysfs')) /// approx 4 nice labels
		xscale(range(`xmin' `xmax')) ///
		xlabel(`xlabel') ///
		legend(order(2 "estimate" 1 "95% CI" /*4 "Standardised estimate" 2 "95% CI"*/) cols(2)) ///
		title("`titleletter': `medcondition' `estvlong'") ///
		graphregion(color(white)) ///
		name("`medcondition'_main_`est'_time", replace)
		pause
		
		*SUPP APPENDIX - PRIMARY (UK AND ENGLAND) VS LINKED
		/*plot confidence intervals and estimate markers (in this order so that prevalence markers are not covered by the CI plots)*/
		graph twoway ///
		(rcap `est'_`esttype'_lci `est'_`esttype'_uci year if medcondition == "`medcondition'" & linkedtext == "linked" & country == 1 & _plot == 1, fcolor(`myorange'%30) fintensity(inten10) lcolor(`myorange') lwidth(vthin) ) ///
		(scatter `est'_`esttype' year if medcondition == "`medcondition'" & linkedtext == "linked" & country == 1 & _plot == 1, msymbol(triangle) msize(vtiny) mcolor(`myorange') lcolor(`myorange') con(line) ) ///
		(rcap `est'_`esttype'_lci `est'_`esttype'_uci year if medcondition == "`medcondition'" & linkedtext == "primary" & country == 1 & _plot == 1, fcolor(`myblue'%30) fintensity(inten10) lcolor(`myblue') lwidth(vthin) ) ///
		(scatter `est'_`esttype' year if medcondition == "`medcondition'" & linkedtext == "primary" & country == 1 & _plot == 1, msymbol(square) msize(vtiny) mcolor(`myblue') lcolor(`myblue') con(line) ) ///
		(rcap `est'_`esttype'_lci `est'_`esttype'_uci year if medcondition == "`medcondition'" & linkedtext == "primary" & country == 5 & _plot == 1, fcolor(`mypurple'%30) fintensity(inten10) lcolor(`mypurple') lwidth(vthin) ) ///
		(scatter `est'_`esttype' year if medcondition == "`medcondition'" & linkedtext == "primary" & country == 5 & _plot == 1, msymbol(circle) msize(vtiny) mcolor(`mypurple') lcolor(`mypurple') con(line) ) ///
		, /// graph options
		ytitle("`ytitle'") xtitle("Year") ///
		yscale(range(0 `ymax')) ///
		ylabel(#4, format(`ysfs')) /// approx 4 nice labels
		xscale(range(`xmin' `xmax')) ///
		xlabel(`xlabel') ///
		legend(order(2 "Linked data (England)" 4 "Primary care data only (England)" 6 "Primary care data (UK)" 1 "95% CI" /*4 "Standardised estimate" 2 "95% CI"*/) cols(2)) ///
		title("`titleletter': `medcondition' `estvlong'") ///
		graphregion(color(white)) ///
		name("`medcondition'_supp1_`est'_time", replace)
		pause
		
		*SUPP APPENDIX - PRIMARY (EACH COUNTRY)
		replace _plot = 1
		if "`est'" == "inc" {
			replace _plot = 0 if year >5 /*only plot categories for incidence data*/
		}
		summ year if _plot == 1
		if `r(min)' == 1 {
			local xlabel "1(1)4, valuelabel"
			*widen axis to give more space for labels
			local xmin 0.8
			local xmax 4.2
			}
			else {
				local xlabel "2000(4)2020"
				local xmin 2000
				local xmax 2020
			}
		
		/*plot confidence intervals and estimate markers (in this order so that prevalence markers are not covered by the CI plots)*/
		graph twoway ///
		(rcap `est'_`esttype'_lci `est'_`esttype'_uci year if medcondition == "`medcondition'" & linkedtext == "primary" & country == 1 & _plot == 1, fcolor(`myorange'%30) fintensity(inten10) lcolor(`myorange') lwidth(vthin) ) ///
		(scatter `est'_`esttype' year if medcondition == "`medcondition'" & linkedtext == "primary" & country == 1 & _plot == 1., msymbol(square) msize(vtiny) mcolor(`myorange') lcolor(`myorange') con(line) ) ///
		(rcap `est'_`esttype'_lci `est'_`esttype'_uci year if medcondition == "`medcondition'" & linkedtext == "primary" & country == 2 & _plot == 1, fcolor(`myblue'%30) fintensity(inten10) lcolor(`myblue') lwidth(vthin) ) ///
		(scatter `est'_`esttype' year if medcondition == "`medcondition'" & linkedtext == "primary" & country == 2 & _plot == 1, msymbol(square) msize(vtiny) mcolor(`myblue') lcolor(`myblue')  con(line) ) ///
		(rcap `est'_`esttype'_lci `est'_`esttype'_uci year if medcondition == "`medcondition'" & linkedtext == "primary" & country == 3 & _plot == 1, fcolor(`mypurple'%30) fintensity(inten10) lcolor(`mypurple') lwidth(vthin) ) ///
		(scatter `est'_`esttype' year if medcondition == "`medcondition'" & linkedtext == "primary" & country == 3 & _plot == 1, msymbol(square) msize(vtiny) mcolor(`mypurple') lcolor(`mypurple') con(line) ) ///
		(rcap `est'_`esttype'_lci `est'_`esttype'_uci year if medcondition == "`medcondition'" & linkedtext == "primary" & country == 4 & _plot == 1, fcolor(`myyellow'%30) fintensity(inten10) lcolor(`myyellow') lwidth(vthin) ) ///
		(scatter `est'_`esttype' year if medcondition == "`medcondition'" & linkedtext == "primary" & country == 4 & _plot == 1, msymbol(square) msize(vtiny) mcolor(`myyellow') lcolor(`myyellow') con(line) ) /// */
		, /// graph options
		ytitle("`ytitle'") xtitle("Year") ///
		yscale(range(0 `ymax')) ///
		ylabel(#4, format(`ysfs')) /// approx 4 nice labels
		xscale(range(`xmin' `xmax')) ///
		xlabel(`xlabel') ///
		legend(order(2 "England" 4 "Wales" 6 "Scotland" 8 "N. Ireland" 1 "95% CI" /*4 "Standardised estimate" 2 "95% CI"*/) cols(2)) ///
		title("`titleletter': `medcondition' `estvlong'") ///
		graphregion(color(white)) ///
		name("`medcondition'_supp2_`est'_time", replace)
		pause
	
	**TABLES FOR SUPPLEMENTARY APPENDIX
	tempfile temp
	save `temp'
	foreach linkedtext in linked primary {
		*main tables
		use `temp', clear
		sort country year
		keep if linkedtext == "`linkedtext'"
		if "`est'" == "prev" {
			keep country year prevcases studypop prev_crude_str prev_st_str popcases_str
			order country year prevcases studypop prev_crude_str prev_st_str popcases_str
		}
		if "`est'" == "inc" {
			keep country year inccases pyears100 inc_crude_str
			gen pyears_str = string(pyears100, "%9.3fc")
			label variable pyears_str "Person years / 100 000"
			drop pyears100
			order country year inccases pyears_str inc_crude_str
		}
	export excel using "$resultdir/43.an_scattergraphs_supptables_incidence_prevalence_time.xlsx", firstrow(varlabels) sheet("`medcondition'_`linkedtext'_`est'", replace)
	}
	}
}

foreach figure in main supp1 supp2 {
	grc1leg OSA_`figure'_inc_time narcolepsy_`figure'_inc_time ///
	OSA_`figure'_prev_time narcolepsy_`figure'_prev_time, ///
	legendfrom(OSA_`figure'_prev_time) position(6) ///
	graphregion(color(white)) ///
	name(`figure', replace)
	
	graph display `figure', ysize(4) xsize(8) margins(tiny)  
	graph export "$resultdir/43.an_scattergraphs_supptables_incidence_prevalence_time_`figure'.emf", as(emf) replace
}
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