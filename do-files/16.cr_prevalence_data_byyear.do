capture log close
log using "$logdir\16.cr_prevalencedata_byyear.txt", replace text

/*******************************************************************************
# Stata do file:    16.cr_prevalence_data_byyear.do
#
# Author:      Helen Strongman
#
# Date:        30/01/2023. Last updated 15/05/2023 - restricted to prevalence by
#				year.
#
# Description: 	Create aggregated data for prevalence analysis (see next
#				do file for more information)
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/
pause off

local i = 1
qui {
foreach database in aurum gold {
foreach linkedtext in primary linked {
foreach medcondition in OSA narcolepsy {
	
	use "$datadir_an\10.cr_unmatchedcohort_an_flowchart_`medcondition'_`database'_`linkedtext'.dta", clear
	
	keep patid prevalent exposed start_fup end_fup indexdate yob gender region
		
	/*
	gen country = 1 if region >= 1 & region <=9
	replace country = 2 if region == 10
	replace country = 3 if region == 11
	replace country = 4 if region == 12
	*drop region
	*/
	
	*** create locals describing the start and end year for the dataset
	local startyear = year(${studystart_`linkedtext'})
	if month(${studystart_`linkedtext'}) < 7 local startyear = `startyear' + 1
	di `startyear'
	local endyear = year(${studyend_`linkedtext'})
	if month(${studyend_`linkedtext'}) < 7 local endyear = `endyear' - 1 
	di `endyear'
	
	/*** create variables flagging the study population and prevalent cases for
	each year PLUS locals with each new variable***/
	local studypopyears ""
	local prevcasesyears ""
	forvalues year = `startyear' / `endyear' {
		di as yellow `year'
		
		gen studypop`year' = 0
		replace studypop`year' = 1 if start_fup <= d(01/07/`year') & end_fup > d(01/07/`year')
		
		gen prevcases`year' = 0
		replace prevcases`year' = 1 if studypop`year' == 1 & prevalent == 1 & indexdate <= d(01/07/`year')
		
	}
	
	/*
	/*** aggregate counts of people in study population and prevalent cases by
	year of birth, gender, country and region***/
	collapse (sum) `studypopyears' `prevcasesyears', by(yob gender region country)
	*/
	
	/*** aggregate counts of people in study population and prevalence cases by
	year ***/
	collapse (sum) studypop* prevcases*
	
	/*
	/*** reshape to dataset with one row for each year and distinct strata grouping ***/
	reshape long studypop prevcases, i(yob gender region country) j(year)
	*/
	
	/***reshape to dataset with one row for each year*/
	gen _dummy = 1
	reshape long studypop prevcases, i(_dummy) j(year)
	drop _dummy
	
	/*
	/*** drop rows with 0 people in the study population (checking that they are
	impossible or v old ages) */
	gen _age = year - yob
	if "`database'" == "aurum" assert _age <= 18 | _age >90 if studypop == 0
	*assert doesn't work for GOLD because the number of practices decreases substantially from 2014
	pause
	drop if studypop == 0
	
	/*** aggregate counts by age group*/
	egen agecat = cut(_age), at(0 9 18 25(10)85 131)
	*replace agecat = 85 if agecat == . & _age >=85 & _age !=.
	assert agecat !=.

	drop _age
	collapse (sum) studypop prevcases, by(year agecat gender region country)
	pause
	*/
	
	/*** save dataset with one row for each year, strata and dataset/medcondition ***/
	gen database = "`database'"
	gen linkedtext = "`linkedtext'"
	gen medcondition = "`medcondition'"
	
	if `i' > 1 append using "$datadir_an/16.cr_aggregated_prevalence_data.dta"
	save "$datadir_an/16.cr_aggregated_prevalence_data.dta", replace
	local i = `i' + 1 /*note i is set at the beginning of the do file*/
}
}
}
}


/*label variables and values*/
label variable prev "Number of prevalent cases at midpoint of year"
label variable studypop "Number of people in population at midpoint of year"
label variable year "Year"
/*label variable agecat "Age group"
label variable country "Constituent country of the United Kingdom"
*/
label variable database "CPRD database"
label variable linked "Primary care or linked cohort"
label variable medcondition "Sleep disorder"

/*
label define countrylab 1 "England" 2 "Wales" 3 "Scotland" 4 "Northern Ireland"
label values country countrylab
include "$dodir/0.inc_agecatlabels.do"
drop _agecatorig
*/

compress
save "$datadir_an/16.cr_prevalence_data_byyear.dta", replace

capture log close

*}

/*ANOTHER WAY TO TO THIS - TAKES LONGER TO RUN
tempname memhold
tempfile tempfile
postfile `memhold' str10 medcondition str5 database str7 linked int(year country agecat) float(prevcases studypop) using `tempfile'

qui {
foreach database in aurum gold {
foreach linkedtext in primary linked {
foreach medcondition in narcolepsy OSA {
	
	use "$datadir_an\10.cr_unmatchedcohort_an_flowchart_`medcondition'_`database'_`linkedtext'.dta", clear
	
	keep patid prevalent exposed start_`linkedtext' end_`linkedtext' indexdate yob gender region
		
	gen country = 1 if region >= 1 & region <=9
	replace country = 2 if region == 10
	replace country = 3 if region == 11
	replace country = 4 if region == 12
	drop region
	
	local startyear = year(${studystart_`linkedtext'})
	if month(${studystart_`linkedtext'}) < 7 local startyear = `startyear' + 1
	di `startyear'
	local endyear = year(${studyend_`linkedtext'})
	if month(${studyend_`linkedtext'}) < 7 local endyear = `endyear' - 1 
	di `endyear'
	
	forvalues year = `startyear' / `endyear' {
		di as yellow `startyear'
		
		gen _age = `year' - yob
		egen agecat = cut(_age), at(0(10)100) label
		pause
		replace agecat = 9 if agecat == . & _age >=90 & _age!=.
		pause
		
		if "`database'" == "linked" local maxcountry = 1
		if "`database'" == "primary" local maxcountry = 4
		
		forvalues agecat = 0/9 {
		forvalues country = 1/`maxcountry' {
			if "`database'" == "aurum" & (`country' == 2 | `country' == 3) continue
		
			count if start_`linkedtext' <= d(01/07/`year') & end_`linkedtext' > d(01/07/`year') & agecat == `agecat' & country == `country'
			local studypop = `r(N)'
			
			count if prevalent == 1 & indexdate <= d(01/07/`year') & agecat == `agecat' & country == `country'
			local prevcases = `r(N)'
				
			noi display "`medcondition' `database' `linkedtext' `year' `country' `agecat' `prevcases' `studypop'"
			pause
			post `memhold' ("`medcondition'") ("`database'") ("`linkedtext'") (`year') (`country') (`agecat') (`prevcases') (`studypop')
		}
		}
		drop _age agecat
	
	}
		
}
}
}
}

postclose `memhold'
	

/***add rows for aurum and gold combined***/
use "$datadir_an/13.cr_aggregated_prevalence_data.dta"
collapse (sum) prevcases studypop, by(medcondition linked year country region gender agecat)
gen database = "combined"
append using "$datadir_an/13.cr_aggregated_prevalence_data.dta"
*/	


