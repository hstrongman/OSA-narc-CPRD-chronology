
capture log close
log using "$logdir\18.cr_unmatchedchort_stsplit.txt", replace text

/*******************************************************************************
# Stata do file:    18.cr_unmatchedcohort_stsplit.do
#
# Author:      Helen Strongman
#
# Date:        02/02/2023
#
# Description: 	Stsplit unmatched cohort data for incidence analysis (see next
#				do file for more information)
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/
pause off

qui {
foreach database in aurum gold {
foreach linkedtext in primary linked {
foreach medcondition in OSA narcolepsy {
		
	use "$datadir_an\10.cr_unmatchedcohort_an_flowchart_`medcondition'_`database'_`linkedtext'.dta", clear
	
	keep patid prevalent incident exposed start_fup end_fup indexdate yob gender region
	keep if exposed == 0 /*unexposed time for full study population - ends at index date for incident cases*/
	drop exposed incident prevalent
		
	gen country = 1 if region >= 1 & region <=9
	replace country = 2 if region == 10
	replace country = 3 if region == 11
	replace country = 4 if region == 12
	label variable country "Country"
		
	*stset by time since start of the study period
	*force start of the study period to the beginning of the calendar year to help stsplit
	
	/*local startyear = year(${studystart_`linkedtext'})
	gen _day1 = mdy(1, 1, `startyear')
	summ _day1*/ /* can use this as origin and then stsplit every 365.25 days
	to define approx calendar year*/
	
	gen case = 0
	replace case = 1 if indexdate == end_fup
	label variable case "Incident case"
	tab case, m
	
	stset end_fup, id(patid) failure(case == 1) origin(time 0) enter(start_fup) /*scale(365.25)*/
			
	local startyear = year(${studystart_`linkedtext'})
	local endyear = year(${studyend_`linkedtext'})
	local i = 1
	forvalues year = `startyear'/`endyear' {
		local jan1st = mdy(1,1,`year')
		if `i' == 1 local yearsplits = "`jan1st'"
		if `i' > 1 local yearsplits = "`yearsplits',`jan1st'" 
		local i = `i' + 1
	}
	local enddate = ${studyend_`linkedtext'}
	local yearsplits = "`yearsplits',`enddate'"
	di "`yearsplits'"
	
	stsplit _year, at("`yearsplits'")
	tab _year, m
		
	local startyear = year(${studystart_`linkedtext'})
	local endyear = year(${studyend_`linkedtext'})
	gen calendaryear = .
	local i = 1
	forvalues year = `startyear'/`endyear' {
		local jan1st = mdy(1,1,`year')
		replace calendaryear = `year' if _year == `jan1st'
	}
	label variable calendaryear "Year"
	tab calendaryear, m

	*define age at midpoint of year?
	gen _age = calendaryear - yob /*tried setting dates to 01/07 but makes no difference*/
	egen agecat = cut(_age), at(0 9 18 25(10)85 132)
	*replace agecat = 85 if agecat == . & _age >=85 & _age !=.

	assert agecat !=.
	
	*after stsplit, case is missing in additional rows in which an event doesn't occur
	tab case _d
	replace case = _d

	include "$dodir\0.inc_agecatlabels.do"
	drop _agecatorig
	label variable agecat "Age group"
	drop _age
	
	compress
	
	noi save "$datadir_dm\18.cr_unmatchedcohort_stsplit_`medcondition'_`database'_`linkedtext'.dta", replace
	pause
}
}
}
}

log close