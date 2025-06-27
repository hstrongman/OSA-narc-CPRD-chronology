
capture log close
log using "$logdir\37.cr_unmatchedchort_stsplit_allvars.txt", replace text

/*******************************************************************************
# Stata do file:    37.cr_unmatchedcohort_stsplit_allvars.do
#
# Author:      Helen Strongman
#
# Date:        11/07/2023
#
# Description: 	Add all stratification variables to stsplit data
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/
pause off

noi {
foreach linkedtext in linked primary {
foreach medcondition in OSA narcolepsy {
/*don't switch gold and aurum below*/
foreach database in gold aurum {
	
	use "$datadir_dm\18.cr_unmatchedcohort_stsplit_`medcondition'_`database'_`linkedtext'.dta", clear
	
	*** practice size quintile
	merge m:1 patid using "$datadir_dm\9.cr_studypopulation_an_flowchart_`database'.dta", keepusing(pracid pracsize)
	assert _merge !=1
	keep if _merge == 3
	drop _merge
	
	local defineboundaries = "no"
	include "$dodir/inc_0.inc_pracsize_cat.do"
	
	*** urban rural
	if "`linkedtext'" == "linked" {
		merge m:1 patid using "$datadir_raw/27.cr_raw_studypop_linked_urban_`database'.dta"
		drop if _merge ==2
		drop _merge
		tab urban, m
	}
	
	*** area based deprivation
	merge m:1 pracid using "$datadir_raw/27.cr_raw_studypop_linked_carstairs_`database'.dta"
	drop if _merge ==2
	drop _merge
	tab carstairs, m
	
	*** BMI
	if "`medcondition'" == "OSA" {
	
	*split files because there is not enough memory to do this using a single file
	*all patients from the same practice must be in the same file
	
	
	egen _filesplit = cut(pracsize), group(4) icodes
	tab _filesplit, m
	tabstat pracsize, by(_filesplit) stats(min max)
	pause
	tempfile tempmaster
	save "$datadir_dm/temp1.dta", replace /*too big as a temporary file*/
	
	forvalues i = 0/3 {
		
		use "$datadir_dm/temp1.dta", clear
		keep if _filesplit == `i'
		drop _filesplit
		joinby patid using "$datadir_dm/30.cr_bmi_datamanagement_`database'.dta", unmatched(master)
		tab _merge /*bmi missing for people with no bmi measures*/
		drop _merge
		*start of follow-up for each row
		gen _startyear = mdy(01,01,calendaryear)
		gen _fupstart = max(start_fup, _startyear)
		format _fupstart %td
		*for each year in the stsplit date, need BMI records before that date
		*first make BMI missing for people/calendar years whose first BMI record is after their latest fupstart date
		gen _keep = 0
		replace _keep = 1 if (dobmi <= _fupstart) | bmi == .
		bysort patid calendaryear: egen _keeptotal = total(_keep)
		bysort patid calendaryear: gen _keepextra = 1 if _keeptotal == 0 & _n == 1
		*br patid start_fup end_fup calendaryear bmi dobmi _startyear _fupstart _keep _keeptotal _keepextra
		replace _keep = 1 if _keepextra == 1
		replace bmi = . if _keepextra == 1
		replace dobmi = . if _keepextra == 1
		keep if _keep == 1
		drop _keep* _fupstart _startyear
		*select nearest BMI measurement on or prior to the index date
		gsort patid calendaryear -dobmi
		bysort patid calendaryear: keep if _n==1
		summ bmi, d
		
		*save/append split files
		if `i' > 0 append using "$datadir_dm/temp2.dta"
		save "$datadir_dm/temp2.dta", replace
	}
	
	erase "$datadir_dm/temp1.dta"
	
	*BMI categories
	gen bmicat = bmi
	label variable bmicat "BMI category"
	note bmicat: "World Health Organisation (WHO) Body Mass Index categories"
	note bmicat: "Based on the most recent BMI measurement on or prior to start of follow-up in calendar year"
	recode bmicat 0/18.4999999999=0 18.50/24.999999999999=1 25/29.999999999999=2 30/34.999999999999=3 35/39.99999999999=4 40/max=5
	replace bmicat = . if bmi == .
	label define bmicatlab 0 "Underweight" 1 "Normal weight" 2 "Overweight" 3 "Obesity class I" 4 "Obesity class II" 5 "Obesity class III+"
	label values bmicat bmicatlab
	tab bmicat, m
	*Obese categories
	gen obesity = bmicat
	recode obesity 0/2=0 3/5=1
	label variable obesity "Obesity"
	label define obesitylab 0 "Not obese (BMI<30kg/m2)" 1 "Obese (BMI>=30kg/m2)"
	label values obesity obesitylab
	tab obesity, m
	*BMI (3 knot cubic spline)
	mkspline bmispl=bmi, cubic nk(3) dis
	label variable bmispl1 "BMI (3 knot cubic split) 1"
	label variable bmispl2 "BMI (3 knot cubic split) 2"
	
	} /*BMI*/
		
	*** ethnicity
	merge m:1 patid using "$datadir_dm/26.cr_temp_ethnicity_primary_`database'.dta", keepusing(eth5)
	drop if _merge ==2
	drop _merge
	if "`linkedtext'" == "linked" {
		merge m:1 patid using "$datadir_raw/27.cr_raw_studypop_linked_ethnicity_`database'.dta", keepusing(heseth5)
		drop if _merge ==2
		drop _merge
		replace eth5=heseth5 if eth5>4 & heseth5!=. //replace ethnicity with HES ethnicity if still missing/notstated/equal
		drop heseth5
		}
	tab eth5, m
	pause
	replace eth5 = . if eth5 >=5
	assert eth5 !=18
	label variable eth5 "Ethnicity"
	note eth5: "derived using the most commonly recorded ethnicity in primary care data (or latest if equally common)"
	note eth5: "unknown and missing values replaced with most commonly recorded ethnicity in HES where available"
	label copy eth5 eth5lab
	label values eth5 eth5lab /*to follow consistent labelling convention*/
	
	/*** 5 YEAR CALENDAR YEAR CATEGORIES ***/
	egen byte calendaryear_cat = cut(calendaryear), at(2000(5)2020) icodes
	replace calendaryear_cat = calendaryear_cat + 1
	recode calendaryear_cat . = 0 if calendaryear < 2000
	recode calendaryear_cat . = 5 if calendaryear > 2019
	label variable calendaryear_cat "Categorical year"
	qui summ calendaryear
	local minyear = `r(min)'
	local maxyear = `r(max)'
	label define calendaryear_catlab 0 "`minyear'-1999" 1 "2000-2004" 2 "2005-2009" 3 "2010-2014" 4 "2015-2019" 5 "2020-`maxyear'", replace
	label values calendaryear_cat calendaryear_catlab
	tab calendaryear calendaryear_cat, m
	label save calendaryear_catlab using "$dodir/labels/calendaryear_catlab", replace
			
	if "`database'" == "gold" gen database = 2
	if "`database'" == "aurum" gen database = 1 
	label variable database "CPRD database"
	label define databaselab 1 "Aurum" 2 "GOLD"
	label values database databaselab
	
	drop _*
	compress
	if "`database'" == "aurum" append using "$datadir_an/37.cr_unmatchedcohort_stsplit_allvars_`medcondition'_`linkedtext'.dta"
	save "$datadir_an/37.cr_unmatchedcohort_stsplit_allvars_`medcondition'_`linkedtext'.dta", replace
	capture erase "$datadir_dm/temp2.dta"
	
	pause
	
}
}
}
}

log close