
capture log close
log using "$logdir\30.cr_bmi_datamanagement.do", text replace

/*******************************************************************************
# Stata do file:    30.cr_bmi_datamanagement.do
#
# Author:      Helen Strongman
#
# Date:        27/06/2023
#
# Description: 	This do file selects and formats valid BMI measurements from
#				the raw data.
#
# Inspired and adapted from: 
# 				Krishnan Bhaskaran's pr_getallbmirecords do file. This was
#				originally written for CPRD GOLD and adapated by Angel Wong
#				and Helena Carreira for Aurum.
#
*******************************************************************************/

include "$dodir/pr_30.getallbmirecords_studypop.do"

pause off

*GET ALL CPRD AURUM BMI RECORDS

/*the do file fails when using the complete file -
create 2 roughly equally sized datasets keeping all rows for individual
patients together*/
use "$datadir_raw/29.cr_raw_bmi_drefine_aurum.dta", clear
sort patid
gen _obs = _n
count
local halfpats = floor(`r(N)'/2)

preserve
keep if _obs < `halfpats'
count
summ patid
save "$datadir_raw/30.temp_aurum1.dta", replace

restore
keep if _obs >= `halfpats'
count
summ patid
save "$datadir_raw/30.temp_aurum2.dta", replace
pause

forvalues x = 1/2 {
	
	pr_getallbmirecords, database("aurum") patientfile("$datadir_dm/9.cr_studypopulation_an_flowchart_aurum.dta") clinicalfile("$datadir_raw/25.temp_aurum`x'.dta") additionalfile("na")
	summ bmi, d
	if `x' == 2 append using "$datadir_dm/30.cr_bmi_datamanagement_aurum.dta"
	save "$datadir_dm/30.cr_bmi_datamanagement_aurum.dta", replace
	erase "$datadir_raw/30.temp_aurum`x'.dta"
	
	}

*GET ALL CPRD GOLD BMI RECORDS
pr_getallbmirecords, database("gold") patientfile("$datadir_dm/9.cr_studypopulation_an_flowchart_gold.dta") clinicalfile("$datadir_raw/25.cr_raw_bmi_drefine_gold_Clinical.dta") additionalfile("$datadir_raw/25.cr_raw_bmi_drefine_gold_Additional.dta")
save "$datadir_dm/30.cr_bmi_datamanagement_gold.dta", replace
summ bmi, d



capture log close



