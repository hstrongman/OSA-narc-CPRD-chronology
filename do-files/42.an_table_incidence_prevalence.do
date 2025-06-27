capture log close
log using "$logdir\42.an_table_incidence_prevalence.txt", replace text

/*******************************************************************************
# Stata do file:    42.an_table_incidence_prevalence.do
#
# Author:      Helen Strongman
#
# Date:        18/08/2023
#
# Description: 	Table describing "Prevalence and incidence rates of sleep 
#				disorders stratified by patient and area-based characteristics
#				in 2019*"
#				A: OSA  B: Narcolepsy (*stratified incidence data is for 2014 to 2019)
#
# Columns:  Variable/category, prevalent cases, study population, prevalence rate (95% CI) 
#			incident cases, person years, incident rate (95% CI) 
#
# Versions: Manuscript (linked cohort) Supplementary (primary care cohort)
#
# Requirements: 
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/
pause off

*** temp file with overall estimates for latest time period in full study population
use "$estimatesdir/38.an_incidence_estimates_time.dta", clear
gen _keep = 1 if medcondition == "narcolepsy" & calendaryear_cat == 4
replace _keep = 1 if medcondition == "OSA" & calendaryear == 2019
*replace _keep = 0 if linkedtext == "primary" & country == 1 /*drop England only for primary care*/
replace _keep = 0 if linkedtext == "primary" & country != 5 /*UK only for primary*/
keep if _keep == 1
drop _keep

keep medcondition linkedtext calendaryear_cat inccases pyears100 ir_crude_str
rename pyears100 pyears
rename ir_crude_str inc_crude_str
tempfile temp
save `temp'

use "$estimatesdir/32.an_prevalence_estimates_time.dta", clear
format studypop %15.0g /*added 19/06/2024)*/
gen _keep = 1 if linkedtext == "primary" & country == 5 /*United Kingdom*/
replace _keep = 1 if linkedtext == "linked" & country == 1 /*England only for linked*/
keep if _keep == 1
drop _keep

keep if year == 2019

keep medcondition linkedtext prevcases studypop prev_crude_str

merge 1:1 medcondition linkedtext using `temp', nogen noreport

gen covar = "overall"
gen covarlabel = "Full study population"
tempfile overall
save `overall'

*** read in incidence estimates stratified by characteristics
use "$estimatesdir/41.an_incidence_estimates_processout.dta", clear
keep medcondition linkedtext covar value covarlabel valuelabel inccases pyears inc_crude_str yearcat
gen _keep = 1 if medcondition == "narcolepsy" & yearcat == 4
replace _keep = 1 if medcondition == "OSA" & yearcat == 2019
keep if _keep == 1
drop _keep
drop yearcat

*** merge with prevalence estimates stratified by characteristics
merge 1:1 medcondition linkedtext covar value using "$estimatesdir/35.an_prevalence_estimates_processout.dta", keepusing(covar value covarlabel valuelabel prevcases studypop prev_crude_str praccount) update
assert covar == "bmicat" & value == 0 if _merge == 2 /*underweight dropped in incidence analysis due to small number of cases*/
assert _merge !=1
drop _merge

*** append overall
append using `overall'


*** sort covariables into order required for table
gen _covarorder = .
local i = 1
foreach covar in overall agecat gender eth5 country region carstairs urban pracsize_cat bmicat obesity {
	replace _covarorder =  `i' if covar == "`covar'"
	local i = `i' + 1
}
sort medcondition linkedtext _covarorder value
gen _obs = _n

*** add missing data rows
foreach var in studypop prevcases inccases pyears { /*studypop must be first*/
	*create _expected vars = total cases and denominators
	bysort medcondition linkedtext: egen _overall = total(`var') if covar == "overall"
	bysort medcondition linkedtext: egen _expected`var' = total(_overall)
	drop _overall
	*create _observed`var' = the actual number of people included for each covariate
	bysort medcondition linkedtext _covarorder: egen _observed`var' = total(`var')	
	*indicate where a "missing" row is needed by identifying the last covariate value for covariates with missing observations 
	if "`var'" == "studypop" {
		by medcondition linkedtext _covarorder: gen _missingneeded = 1 if _expectedstudypop != _observedstudypop & _n==_N
		expand 2 if _missingneeded == 1, gen(_expand)
		sort _obs _expand
		replace valuelabel = "Missing" if _missingneeded == 1 & _expand == 1
		*delete all other numbers and estimates for missing lines
		foreach est in prev inc {
			replace `est'_crude_str = "" if _missingneeded == 1 & _expand == 1
		}
		foreach v in studypop prevcases inccases pyears {
			replace `v' = . if _missingneeded == 1 & _expand == 1 
		}
	}
	*estimate missing numbers for each variable
	replace `var' = _expected`var' - _observed`var' if _missingneeded == 1 & _expand == 1
	pause
}


foreach est in prev inc {
	replace `est'_crude_str = "" if _missingneeded == 1 & _expand == 1
}

*** add percentage cases 
foreach var in studypop prevcases inccases pyears  {
	gen _`var'percent = (`var' / _expected`var')*100
	gen `var'_str = string(`var') + " (" + string(_`var'percent, "%9.1fc") + "%)"
}
drop _*
label variable prevcases_str "Prevalent cases"
label variable inccases_str "Incident cases"
label variable studypop_str "Study population (n)"
label variable pyears_str "Person-years (/100 000)"


***add rows for covariate headings by replicating first row for each covariate
gen _newcovar = 1 if covarlabel != covarlabel[_n-1]
gen _obs = _n
expand 2 if _newcovar == 1, gen(_expand)
sort _obs _expand

foreach var in valuelabel praccount prevcases prevcases_str studypop studypop_str prev_crude_str inccases inccases_str pyears pyears_str inc_crude_str {
	*remove data from most variables in header row
	capture confirm string variable `var'
	if !_rc replace `var' = "" if _newcovar == 1 & _expand == 0
	capture confirm numeric variable `var'
	if !_rc replace `var' = . if _newcovar == 1 & _expand == 0	
}

**define and format characteristic column
*replace valuelabel with covarlabel in header column
levelsof covarlabel if _newcovar == 1 & _expand == 0, local(covarlabels)
foreach label of local covarlabels {
	*replace valuelabel = "{bf:`label'}" if _newcovar == 1 & _expand == 0 & covarlabel == "`label'" - formatting doesn't work with export excel
	replace valuelabel = "`label'" if _newcovar == 1 & _expand == 0 & covarlabel == "`label'"
}

drop covarlabel
rename valuelabel characteristic
label variable characteristic "Characteristic"

drop _*

keep medcondition linkedtext characteristic praccount prevcases_str studypop_str prev_crude_str inccases_str pyears_str inc_crude_str studypop
order medcondition linkedtext characteristic praccount prevcases_str studypop_str prev_crude_str inccases_str pyears_str inc_crude_str studypop

**export to Excel dataset

*notes first
notes drop _all
note: "Prevalence and incidence rates of sleep disorders over time and stratified by patient and area-based characteristics in 2019*"
note: "A: Obstructive Sleep Apnoea  B: Narcolepsy (*incidence data is for 2014 to 2019)"
note: "Incidence rates for BMI underweight were not estimated because the number of cases was too low."
note: "note to self - I need to change the coding in earlier do files to increase the size of strings for some covariate labels"

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
collect export "$resultdir/42.an_table_incidence_prevalence.xlsx", as(xls) sheet("notes") cell(A1) modify

*separate sheet for each medcondition/dataset
tempfile temp
save `temp'

foreach linkedtext in linked primary {
foreach medcondition in OSA narcolepsy {
	use `temp', clear
	keep if linkedtext == "`linkedtext'"
	keep if medcondition == "`medcondition'"
	drop medcondition linkedtext
	export excel using "$resultdir/42.an_table_incidence_prevalence.xlsx", firstrow(varlabels) sheet("`medcondition'_`linkedtext'", replace)
}
}

capture log close