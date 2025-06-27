capture log close
log using "$logdir\33.cr_studypopulation_mid2019.txt", replace text

/*******************************************************************************
# Stata do file:    33.cr_studypopulation_mid2019.do
#
# Author:      Helen Strongman
#
# Date:        29/03/2023
#
# Description: 	Create person level file with all covariates to estimate 
#				prevalence in 2019. Need sex, region, country, area based 
#				deprivation, urban rural, practice size, bmi and ethnicity
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/
pause off


foreach linkedtext in linked primary {
/*don't switch narcolepsy and OSA below - see comments on pracsize_cat*/
foreach medcondition in narcolepsy OSA {
/*don't switch gold and aurum below - see comments on pracsize_cat*/
foreach database in gold aurum {
	
	use "$datadir_an\10.cr_unmatchedcohort_an_flowchart_`medcondition'_`database'_`linkedtext'.dta", clear

	*** restrict to mid-2019 study population
	keep patid pracid prevalent exposed start_fup end_fup indexdate yob gender region pracsize
	local year = 2019
	gen studypop`year' = 0
	replace studypop`year' = 1 if start_fup <= d(01/07/`year') & end_fup > d(01/07/`year')
	keep if studypop`year' == 1
	label variable studypop`year' "In study population on 01/07/`year'"
	
	*** identify prevalent cases
	gen prevcase`year' = 0
	replace prevcase`year' = 1 if prevalent == 1 & indexdate <= d(01/07/`year')
	label variable prevcase`year' "Prevalent `medcondition' mid-2019"

	*** country		
	gen country = 1 if region >= 1 & region <=9
	replace country = 2 if region == 10
	replace country = 3 if region == 11
	replace country = 4 if region == 12
	label variable country "Constituent country of the United Kingdom"
	label define countrylab 1 "England" 2 "Wales" 3 "Scotland" 4 "Northern Ireland"
	label values country countrylab
		
	*** age group
	gen _age = 2019 - yob
	egen agecat = cut(_age), at(0 9 18 25(10)85 131)
	assert agecat !=.
	drop _age
	include "$dodir/0.inc_agecatlabels.do"
	drop _agecatorig
	label variable agecat "Age group"
	

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
		tempfile temp
		save `temp'
		*get latest BMI measurement prior to midyear point
		use "$datadir_dm/30.cr_bmi_datamanagement_`database'.dta", clear
		keep if dobmi <= d(01/07/`year')
		bysort patid (dobmi): keep if _n == _N
		merge 1:m patid using `temp'
		drop if _merge == 1
		drop _merge
		summ bmi, d
		*BMI categories
		gen bmicat = bmi
		label variable bmicat "BMI category"
		note bmicat: "World Health Organisation (WHO) Body Mass Index categories"
		note bmicat: "Based on the most recent BMI measurement on or prior to 01/07/2019"
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
	}
		
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

	if "`database'" == "gold" gen database = 2
	if "`database'" == "aurum" gen database = 1 
	label variable database "CPRD database"
	label define databaselab 1 "Aurum" 2 "GOLD"
	label values database databaselab
	
	if "`database'" == "aurum" {
		append using "$datadir_an/33.cr_studypopulation_mid2019_`medcondition'_`linkedtext'.dta"
		save "$datadir_an/33.cr_studypopulation_mid2019_`medcondition'_`linkedtext'.dta", replace
		*** practice size quartile
		local defineboundaries = "no"
		if "`medcondition'" == "narcolepsy" & "`linkedtext'" == "linked" local defineboundaries = "yes"
		include "$dodir/inc_0.inc_pracsize_cat.do"
		tab pracsize_cat, m
		assert pracsize_cat != .
		}
	
	compress	

	save "$datadir_an/33.cr_studypopulation_mid2019_`medcondition'_`linkedtext'.dta", replace
	local i = `i' + 1
	
	pause
} /*database*/
}
}

capture log close


