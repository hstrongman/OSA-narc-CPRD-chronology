
capture log close
log using "$logdir\19.an_studypop_decisions_incidence_estimates.txt", replace text

/*******************************************************************************
# Stata do file:    19.an_studypop_decisions_incidence_estimates.do
#
# Author:      Helen Strongman
#
# Date:        02/02/2023
#
# Description: 	Estimate incidence rates by calendar year and age groups to
# 				check study population definitions.
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/
pause off

qui {

foreach strata in agecat calendaryear {
		
	capture postclose incrates
	postfile incrates str10 medcondition int sourcepop `strata' cases long pdays ir lci uci using "$estimatesdir/19.an_studypop_decisions_incidence_estimates_`strata'.dta", replace
	
	foreach linkedtext in linked primary {
	foreach medcondition in OSA narcolepsy {
		
		noi di "strata `strata', linkedtext `linkedtext', medcondition `medcondition'"
		
		*read in st split data
		use "$datadir_dm/18.cr_unmatchedcohort_stsplit_`medcondition'_aurum_`linkedtext'.dta", clear
		gen database = "aurum"
		append using "$datadir_dm/18.cr_unmatchedcohort_stsplit_`medcondition'_gold_`linkedtext'.dta"
		replace database = "gold" if database == ""
		
		if "`strata'" == "agecat" label save agecatlab using _agecatlab.do, replace
		
		*estimate incidence rate for each level of agecat or calendaryear and post to Stata file
		if "`linkedtext'" == "primary" local sourcepop = 1
		if "`linkedtext'" == "linked" local sourcepop = 2
		local multiplier = 365.25 * 100000
		levelsof `strata', local(stratalevels)
		foreach ac of local stratalevels {
			stptime if `strata' == `ac', per(`multiplier') 
			post incrates ("`medcondition'") (`sourcepop') (`ac') (`r(failures)') (`r(ptime)') (`r(rate)') (`r(lb)') (`r(ub)')
			
			if "`linkedtext'" == "linked" {
				stptime if `strata' == `ac' & database == "aurum", per(`multiplier') 
				post incrates ("`medcondition'") (3) (`ac') (`r(failures)') (`r(ptime)') (`r(rate)') (`r(lb)') (`r(ub)')
			}
		} /*stratalevels*/
		
		} /*medcondition*/
		} /*linkedtext*/
			
	postclose incrates	
	use "$estimatesdir/19.an_studypop_decisions_incidence_estimates_`strata'.dta", clear

	label variable medcondition "Sleep disorder"
	label variable sourcepop sourcepoplab
	label define sourcepoplab 1 "Primary care (Aurum and GOLD)" 2 "Primary care and linked data (Aurum and GOLD)" 3 "Primary care and linked data (Aurum only)", replace
	label values sourcepop sourcepoplab
	if "`strata'" == "calendaryear" label variable calendaryear "Calendar year"
	if "`strata'" == "agecat" {
		label variable agecat "Age group"
		do _agecatlab.do
		label values agecat agecatlab
		erase _agecatlab.do
		}
	label variable cases "Number of incident cases"
	gen pyears = pdays/365.25 /*STILL DOESN'T WORK BECAUSE TOO LONG*/
	drop pdays
	label variable pyears "Total follow up time (years)"
	label variable ir "Incidence rate (per 100 000 person years)"
	label variable lci "Lower 95% confidence limit"
	label variable uci "Upper 95% confidence limit"
	
	gen irci = string(ir, "%9.2fc") + " (" + string(lci, "%9.2fc") + "-" + string(uci, "%9.2fc") + ")"
	label variable irci "IR (95% CI)"
	
	label data "Incidence rates to check study population definitions"
	note: "See flow charts for definition of the study population"
	note irci: "95% confidence intervals estimated using the quadratic approximation to the Poisson log likelihood for the log-rate parameter"
	
	order medcondition sourcepop `strata' cases pyears ir lci uci irci 
	sort medcondition sourcepop `strata'
	
	save "$estimatesdir/19.an_studypop_decisions_incidence_estimates_`strata'.dta", replace
	pause
} /*strata*/
}
*erase _agecatlab.do

log close