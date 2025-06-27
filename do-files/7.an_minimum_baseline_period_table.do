clear
capture log close
log using "$logdir\7.an_minimum_baseline_period_table.txt", replace text

/*******************************************************************************
# Stata do file:    7.an_minimum_baseline_period_table
#
# Author:      Helen Strongman
#
# Date:        04/11/2022
#
# Description: 	This do file appends incidence rates needed to define a 
# minimum baseline period to a single table. (see previous do file for
# full explanation)
# 
# Outputs:
# - Table with incidence rates over months since registration
# 
# 	Inspired and adapted from: 
# 	see previous do file

*******************************************************************************/
local i = 1
foreach medcondition in osa narcolepsy {
	
	**** append estimates and create variable and category variables
	use "$estimatesdir\6.an_minimum_baseline_period_estimates_3month_`medcondition'.dta", clear
	drop if monthsincereg3 <= 3 /*first 6 months split into 1 month period in subsequent file*/
	rename monthsincereg3 monthsincereg1
	gen _3month = 1
	append using "$estimatesdir\6.an_minimum_baseline_period_estimates_1month_`medcondition'.dta"
	drop if monthsincereg1 == 6 & _3month == . /*this category covers >6 months to 2 years and is not needed*/
	drop _3month
	gen variable = "Overall"
	label variable variable "Stratifying variable"
	gen category = "Overall"
	label variable category "Category of stratifying variable"
	
	foreach database in aurum gold {
		append using "$estimatesdir\6.an_minimum_baseline_period_estimates_`database'_`medcondition'.dta"
		drop if monthsincereg1 == 6 & variable == "" /*this category covers >6 months to 2 years and is not needed*/
		replace variable = "Database" if variable == ""
		if "`database'" == "aurum" replace category = "Aurum" if category == ""
		if "`database'" == "gold" replace category = "GOLD" if category == ""
	}
	
	foreach timeperiod in 1990to1999 2000to2009 2010to2022 {
		append using "$estimatesdir\6.an_minimum_baseline_period_estimates_`timeperiod'_`medcondition'.dta"
		drop if monthsincereg1 == 6 & variable == "" /*this category covers >6 months to 2 years and is not needed*/
		replace variable = "Time period" if variable == ""
		local stringyear =  subinstr("`timeperiod'","to"," to ",1)
		replace category = "`stringyear'" if category == ""
	}
	

	append using "$estimatesdir\6.an_minimum_baseline_period_estimates_underage_`medcondition'.dta"
	drop if monthsincereg1 == 6 & variable == "" /*this category covers >6 months to 2 years and is not needed*/
	replace variable = "Age group" if variable == ""
	replace category = "under 18" if "`medcondition'" == "narcolepsy" & category == ""
	replace category = "under 40" if "`medcondition'" == "osa" & category == ""
	
	append using "$estimatesdir\6.an_minimum_baseline_period_estimates_overage_`medcondition'.dta"
	drop if monthsincereg1 == 6 & variable == "" /*this category covers >6 months to 2 years and is not needed*/
	replace variable = "Age group" if variable == ""
	replace category = "18 plus" if "`medcondition'" == "narcolepsy" & category == ""
	replace category = "40 plus" if "`medcondition'" == "osa" & category == ""
	
	gen medcondition = "`medcondition'"
	label variable medcondition "Sleep disorder"
	
	if `i' > 1 append using "$estimatesdir\7.an_minimum_baseline_period_table.dta"
	
	save "$estimatesdir\7.an_minimum_baseline_period_table.dta", replace
	local i = `i' + 1
}
	
	**** Format and label monthsincereg and strrate output
	notes drop _all
	
	rename monthsincereg1 monthsincereg
	label variable monthsincereg "Number of months since registration"
	
	label define monthsincereglab 0 "0 to <1 months", replace
	forvalues m = 1(1)5 {
		local upper = `m' + 1
		label define monthsincereglab `m' "`m' to `upper' months", add
	}
	
	forvalues m = 6(3)21 {
		local upper = `m' + 3
		label define monthsincereglab `m' "`m' to `upper' months", add
	}
	
	label values monthsincereg monthsincereglab
	tab monthsincereg

	rename _D cases
	label variable case "Number of incident cases"
	rename _Y persontime
	label variable persontime "Total follow up time (months)"
	rename _Rate ir 
	label variable ir "Incidence Rate"
	rename _Lower lci
	label variable lci "Lower 95% confidence limit"
	rename _Upper uci
	label variable uci "Upper 95% confidence limit"
	
	gen irci = string(ir, "%9.2fc") + " (" + string(lci, "%9.2fc") + "-" + string(uci, "%9.2fc") + ")"
	label variable irci "IR (95% CI)"
	
	label data "Incidence rates to define minimum baseline period"
	note: "Population: All people with research quality data at risk of the sleep disorder at registration in the CPRD practice and during the study period (Jan 1990 to April 2022)."
	note: "Population: People are followed up from registration in the CPRD practice to end of data collection or end of study period (April 2022)."
	note: "Population: Data collection ends at the earliest of death, transfer out of practice, or practice data collection by CPRD"
	note: "People diagnosed with the sleep disorder prior to registration in the practice are not at risk / included in the dataset."
	note cases: "First ever coded clinical* record of the sleep disorder (exclusion criteria for prior records of rare types of sleep apnoea not applied)"
	note cases: "*Referral and test/value records not included (based on GOLD file type and Aurum observation type)"
	note persontime: "Number of months from start of time since diagnosis category to the earliest of the end of time since diagnosis category or end of follow-up"
	note irci: "95% confidence intervals estimated using the quadratic approximation to the Poisson log likelihood for the log-rate parameter"
	note variable: "Overall, Age group, (CPRD) database, (calendar) time period"
	
	order medcondition monthsincereg variable category cases persontime ir lci uci irci 
	
	save "$estimatesdir\7.an_minimum_baseline_period_table.dta", replace
	
	
capture log close

