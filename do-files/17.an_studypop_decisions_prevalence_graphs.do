capture log close
log using "$logdir\17.an_studypop_decisions_prevalence_graphs.txt", replace text

/*******************************************************************************
# Stata do file:    17.an_studypop_decisions_prevalence_graphs.do
#
# Author:      Helen Strongman
#
# Date:        02/02/2023
#
# Description: 	Prevalence estimates to confirm decisions about study populations
#				for primary analysis - see 15.an_sample_summary.do
#
#				/*Plus check distributions by age. Currently planning to drop <18
#				for sleep apnoea and keep all ages for narcolepsy.*/
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/

***yearly prevalence estimates per potential study population
use "$datadir_an/16.cr_prevalence_data_byyear.dta", clear
collapse (sum) prev studypop, by(year medcondition linkedtext)
gen database = "combined"
tempfile temp
save `temp'

use "$datadir_an/16.cr_prevalence_data_byyear.dta", clear
keep if database == "aurum" & linkedtext == "linked"
collapse (sum) prev studypop, by(year medcondition)
gen linkedtext = "linked"
gen database = "aurum"
append using `temp'

gen crudeprev = (prev/studypop) * 100
label variable crudeprev "Crude prevalence (%)"
list medcondition linkedtext database crude if year == 2019

gen sourcepop = 0
label variable sourcepop "Study population source"
replace sourcepop = 1 if database == "combined" & linkedtext == "primary"
replace sourcepop = 2 if database == "combined" & linkedtext == "linked"
replace sourcepop = 3 if database == "aurum" & linkedtext == "linked"
label define sourcepoplab 1 "Primary care (Aurum and GOLD)" 2 "Primary care and linked data (Aurum and GOLD)" 3 "Primary care and linked data (Aurum only)", replace
label values sourcepop sourcepoplab

*generate label for every 5 years
gen _mod5yr = mod(year,5)
gen label = string(crudeprev, "%9.3fc")
replace label = "" if _mod5yr !=0

foreach medcondition in narcolepsy OSA {
	twoway (scatter crudeprev year if sourcepop == 1, sort msymbol(square) msize(vsmall) mlabel(label) mlabpos(6)) ///
		(scatter crudeprev year if sourcepop == 2, msymbol(triangle) msize(vsmall) mlabel(label) mlabpos(6)) ///
		(scatter crudeprev year if sourcepop == 3, msymbol(smdiamond) msize(vsmall) ) ///
		if medcondition == "`medcondition'", ///
		xlabel(1990(5)2020) ///
		ytitle(Prevalence (%)) xtitle(Year) ///
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
graph export "$resultdir/17.an_studypop_decisions_prevalence_graphs_datasource", as(emf) replace

/*
***prevalence estimates by age - linked aurum only
use "$datadir_an/16.cr_aggregated_prevalence_data.dta", clear
keep if database == "aurum" & linkedtext == "linked" & year == 2019
collapse (sum) prev studypop, by(medcondition agecat)
gen database = "combined"

gen crudeprev = (prev/studypop) * 100
label variable crudeprev "Crude prevalence (%)"

sort agecat
levelsof agecat, local(agecatlevels)

foreach medcondition in narcolepsy OSA {
	
scatter crudeprev agecat if medcondition == "`medcondition'", ///
	xlabel(`agecatlevels',valuelabel labsize(vsmall)) ///
	msymbol(square) ///
	ytitle(Prevalence (%)) xtitle(Age group) ///
	graphregion(color(white)) ///
	title("`medcondition' July 2019") ///
	name("`medcondition'", replace)
}

graph combine OSA narcolepsy, ///
iscale(*1) cols(1)  ///
name(combined, replace)

graph display combined, ysize(8) margins(tiny)
graph export "$resultdir/17.an_studypop_decisions_prevalence_graphs_agegroup", as(emf) replace
*/

capture log close
