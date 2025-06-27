capture log close
log using "$logdir\20.an_studypop_decisions_incidence_graphs.txt", replace text

/*******************************************************************************
# Stata do file:    20.an_studypop_decisions_incidence_graphs.do
#
# Author:      Helen Strongman
#
# Date:        14/02/2023
#
# Description: 	Graphs describing incidence rates to confirm decisions about 
#				study populations for primary analysis - see 15.an_sample_summary.do
#				
#				Plus check distributions by age. Currently planning to drop <18
#				for sleep apnoea and keep all ages for narcolepsy.
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/

***yearly incidence estimates per potential study population
use "$estimatesdir/19.an_studypop_decisions_incidence_estimates_calendaryear.dta", clear
foreach medcondition in narcolepsy OSA {
	twoway (scatter ir calendaryear if sourcepop == 1 & calendaryear <2021, sort msymbol(square)) ///
		(scatter ir calendaryear if sourcepop == 2 & calendaryear <2021, msymbol(triangle)) ///
		(scatter ir calendaryear if sourcepop == 3 & calendaryear <2021, msymbol(smdiamond)) ///
		if medcondition == "`medcondition'", ///
		xlabel(1990(5)2020) ///
		ytitle("Incidence (per 100 000 years)") xtitle(Year) ///
		legend(order(1 "Primary care only (Aurum and GOLD)" 2 "Linked data (Aurum and GOLD)" 3  "Linked data (Aurum only)") cols(1)) ///
		graphregion(color(white)) ///
		title("`medcondition'") ///
		name("`medcondition'", replace)
}

grc1leg OSA narcolepsy, ///
iscale(*1) cols(1)  ///
legendfrom(OSA)  ///
name(combined, replace)

graph display combined, ysize(8) margins(tiny)
graph export "$resultdir/20.an_studypop_decisions_incidence_graphs_datasource", as(emf) replace

***incidence estimates by age - linked aurum only
use "$estimatesdir/19.an_studypop_decisions_incidence_estimates_agecat.dta", clear
levelsof agecat, local(agecatlevels)

foreach medcondition in narcolepsy OSA {
	
scatter ir agecat if medcondition == "`medcondition'" & sourcepop == 3, ///
	msymbol(square) ///
	xlabel(`agecatlevels',valuelabel labsize(vsmall)) ///
	ytitle("Incidence (per 100 000 person years)") xtitle("Age group") ///
	graphregion(color(white)) ///
	title("`medcondition'") ///
	name("`medcondition'", replace)
	
}

graph combine OSA narcolepsy, ///
iscale(*1) cols(1)  ///
name(combined, replace)

graph display combined, ysize(8) margins(tiny)
graph export "$resultdir/20.an_studypop_decisions_incidence_graphs_agegroup", as(emf) replace


capture log close
