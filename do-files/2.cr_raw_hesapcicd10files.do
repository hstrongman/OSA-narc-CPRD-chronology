clear
log using "$logdir\2.cr_raw_hesapcicd10files.txt", text replace

/*******************************************************************************
# Stata do file:   2.cr_raw_hesapcicd10files.do
#
# Author:      Helen Strongman
#
# Date:        21/09/2022
#
# Description: 	This do file imports HES ICD10 files provided by CPRD upon 
				request and saves a single stata file for each  
#				primary care database and medical condition with a 
#				database variable set to hesapc
#				and the category variable from the code list file. It checks that
#				the imported data matches the code list.
#
# Inspired and adapted from: 
# 				N/A
*******************************************************************************/

foreach database in gold aurum {
	
	/****	1. Import HES APC file 							****/
	/*import the first file - all variables imported as strings as patids 
	in CPRD GOLD and Aurum must be formatted as a string*/
		
	import delimited using "$datadir_raw\22_001887_Type1_Request\22_001887_icd_`database'_hesapc.txt", ///
	varnames(1) case(lower) stringcols(_all) clear


	/****	2. Formatting steps  ****/

	/*create evdate*/
	gen evdate = date(eventdate, "DMY")
	format evdate %td
	drop eventdate
	replace evdate = date("01/01/1800", "DMY") if evdate == . /*this means that
	people with coded events not associated with a date will have a diagnosis
	date of 01/01/1800 and be excluded from the study population because this
	is before their date of birth - NOT IN PROTOCOL*/ 

	label variable evdate "Date associated with the event"

	/**** 3. Merge with code list ****/

	*need single code list for both conditions because CPRD send all data in one file
	tempfile temp
	save `temp'

	use "$codedir\codelist_narcolepsy_hesapc.dta", clear
	gen _medcondition = "narcolepsy"
	append using "$codedir\codelist_sleep_apnoea_hesapc.dta"
	replace _medcondition = "sleep_apnoea" if _medcondition == ""
	rename ICD icd

	merge 1:m icd using `temp'
	label variable category "Code list category"

	/****	3. Data checks  ****/

	/*compare to codelist*/

	count if _merge == 2
	if `r(N)' > 0 {
		#delimit ;
		di as yellow "There are `r(N)' codes in the data set that are not in the 
		codelist. Check that the code list that you are using in this file matches
		the code list you sent to CPRD"
		;
		#delimit cr
		assert _merge !=1
		}
		else {
			di as yellow "All codes in the dataset are in the codelist"
			}
		
	count if _merge == 1
	if `r(N)' > 0 {
		#delimit ;
		
		di as yellow "There are `r(N)' codes in the code list that are not in the
		dataset. Check that the code list you are using in this file matches
		the code list you sent to CPRD."
		;
		#delimit cr
		assert observations _merge !=2 
		}
		else {
			#delimit ;
			di as yellow "All codes in the code list are in the dataset."
			;
			#delimit cr
			}

	/****	4. Finalise variables  ****/

	*common medical code variable (code)
	rename icd code
	label variable code "medical code (medcodeid, medcode, icd10)"

	*dataset identifier
	gen database = "hesapc"
	label variable database "source database"

	keep patid evdate code category database _medcondition

	/****	5. Split into narcolepsy and sleep_apnoea datasets and save  ****/
	tempfile temp
	save `temp'

	keep if _medcondition == "narcolepsy"
	drop _medcondition
	label drop categorylab
	do $dodir\labels\\categorylab_narcolepsy.do"
	label values category categorylab
	save "$datadir_raw\1.cr_raw_hesapcicd10files_narcolepsy_`database'.dta", replace
	use `temp', clear

	keep if _medcondition == "sleep_apnoea"
	drop _medcondition
	label drop categorylab
	do $dodir\labels\\categorylab_sleep_apnoea.do"
	label values category categorylab
	compress
	save "$datadir_raw\1.cr_raw_hesapcicd10files_sleep_apnoea_`database'.dta", replace
}

capture log close



