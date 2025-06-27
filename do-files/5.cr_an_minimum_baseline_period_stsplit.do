capture log close
log using "$logdir\5.cr_an_minimum_baseline_period_stsplit.txt", replace text

/*******************************************************************************
# Stata do file:    5.cr_an_minimum_baseline_period_stsplit.do
#
# Author:      Helen Strongman
#
# Date:        30/09/2022
#
# Description: 	This do file creates a dataset for each medical condition to 
#				define a minimum baseline period for the study. Each dataset
# 				includes all CPRD GOLD and Aurum patients at risk of the 
#				condition at registration in the practice and variables required 
#				for the analysis.
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/

/****  READ IN DATA SET FOR BOTH CONDITIONS  ****/
use "$datadir_dm\4.cr_dm_all_registered_patients_aurum.dta", clear
gen database = "aurum"
append using "$datadir_dm\4.cr_dm_all_registered_patients_gold.dta"
replace database = "gold" if database == ""

/****  APPLY BASIC INCLUSION/EXCLUSION CRITERIA  ****/
*meets CPRD's patient level quality criteria
keep if acceptable == 1
*follow-up during study period
gen fupenddate = min(regenddate, lcd, cprd_ddate)
format fupenddate %td
label variable fupenddate "End of patient follow-up in CPRD build"
keep if fupenddate > $studystart_primary
keep if regstartdate < $studyend_primary
keep if regstartdate < fupenddate
keep if regstartdate >= $studystart_primary & regstartdate < $studyend_primary

*duplicate practices that have contributed to GOLD and Aurum
drop if dupgoldpractice == 1

/****  GENERATE VARIABLES NEEDED TO ESTIMATE INCIDENCE RATES AND RESTRICT
DATASET TO PEOPLE AT RISK AT START OF FOLLOW-UP ****/

*year entered practice
gen regstartyear = year(regstartdate)
label variable regstartyear "Year of registration in the practice"

gen regstartyearcat = 0 if regstartyear >=1990 & regstartyear <2000
replace regstartyearcat = 1 if regstartyear >=2000 & regstartyear <2010
replace regstartyearcat = 2 if regstartyear >=2010 & regstartyear <2023
assert regstartyearcat !=.
label variable regstartyearcat "Year of registration in the practice"
label define regstartyearcatlab 0 "1990 to 1999" 1 "2000 to 2009" 2 "2010 to 2022"
label values regstartyearcat regstartyearcatlab
tab regstartyearcat, m

save "$datadir_dm\temp.dta", replace

pause on
local i = 1
foreach medcondition in narcolepsy osa {
	*if `i' > 1 
	use "$datadir_dm\temp.dta", clear
	
	/*GENERATE INDEX DATE AND AGE AT INDEX VARIABLES*/
	*note age criteria will not be applied to incidence/prevalence analyses
	*only count if clinical record on index date
	if "`medcondition'" == "osa" {
		local minage = 40
		gen osa_index = min(OSAdate_pc, OSASdate_pc, SAdate_pc)
		format osa_index %td
		}
	if "`medcondition'"  == "narcolepsy" {
		local minage = 18
		gen narcolepsy_index = narcolepsydate_pc
		format narcolepsy_index %td
		}
		
	gen _strdob = "15/07/" + string(yob)
	gen _daysatreg = (regstartdate - date(_strdob, "DMY"))
	gen _ageatreg = floor(_daysatreg/365.25)
	gen minage_flag = 0
	replace minage_flag = 1 if _ageatreg >= `minage'
	label variable minage_flag "Age at registration in the practice"
	label define minage_flaglab 0 "under `minage'" 1 "at least `minage'"
	label values minage_flag minage_flaglab
	
	/*GENERATE VARIABLE DESCRIBING ANALYSIS END DATE*/
	gen analysisend = min(fupenddate, date("$studyend_primary", "DMY"), `medcondition'_index)
	assert analysisend <= `medcondition'_index 
	label variable analysisend "Data subject exits the analysis"
	format analysisend %td
	
	/*KEEP SUBJECTS AT RISK AT REGISTRATION*/
	*no previous diagnosis
	drop if `medcondition'_index <= regstartdate
	*just to check!
	assert regstartdate < analysisend
	
	/*GENERATE FLAG IDENTIFYING PEOPLE DIAGNOSED DURING FOLLOW-UP*/
	gen inc_flag = 0
	replace inc_flag = 1 if `medcondition'_index > regstartdate & `medcondition'_index <= analysisend
	label variable inc_flag "Flag identifying subjects with incident `medcondition' diagnoses"
	tab inc_flag, m
	/*I haven't excluded subjects with other types of sleep apnoea prior to index for this analyis.
	This affects very few subjects*/
	if "`medcondition'"  == "osa" count if inc_flag == 1 & (centraldate_pc < osa_index | primarydate_pc < osa_index)
	
	/*DECLARE DATA TO BE SURVIVAL TIME DATA AND SPLIT INTO MONTHLY/3 MONTHLY TIME PERIODS*/
	keep patid regstartdate analysisend inc_flag regstartyear regstartyearcat minage_flag database
	stset analysisend, failure(inc_flag) origin(regstartdate) exit(analysisend) scale(30) id(patid)
	keep patid regstartdate regstartyear regstartyearcat minage_flag database _* /*kept regstartdate and databases to allow
	stratification by these variables*/
	/*Split individual records into 3 month time periods*/
	stsplit monthsincereg3, at(0(3)24) trim
	/*Split first 6 months into 1 month time periods*/
	stsplit monthsincereg1, at(0(1)6)
	compress
	save "$datadir_an\5.cr_an_minimum_baseline_period_stsplit_`medcondition'.dta", replace
	local i = `i' + 1
}

erase "$datadir_dm\temp.dta"

capture log close





