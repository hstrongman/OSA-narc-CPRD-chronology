capture log close
log using "$logdir\4.cr_dm_all_registered_patients.txt", replace text

/*******************************************************************************
# Stata do file:    4.cr_dm_all_registered_patients
#
# Author:      Helen Strongman
#
# Date:        22/09/2022 (last updated 30/03/2023 - practice size variable added)
#
# Description: 	This do file creates a single stata analysis file for each 
#				specified database and medical condition including all patients in 
#				the CPRD GOLD and CPRD Aurum files with variables needed to
#				finalise the study population definition.
#
# Protocol clarification: Do not include referral or test/value codes when
#				identifying the index date (based on file types in GOLD
#				and obstype variable in Aurum)
#				
# Inspired and adapted from: 
# 				N/A
*******************************************************************************/

foreach database in aurum gold {
	
	foreach medcondition in sleep_apnoea narcolepsy {

		display as yellow "Database: `database'"
		display as yellow "Medical condition: `medcondition'"
		
		/**** 1. FOR EACH MEDICAL CONDITION CREATE DATASET FROM PRIMARY CARE DEFINE
		FILES AND HES APC DATA WITH 1 ROW PER PATIENT AND VARIABLES DESCRIBING THE 
		FIRST EVENT IN EACH CATEGORGY (DATE AND FILE/OBS TYPE) ******/

		*** PRIMARY CARE FILES ***
		use "$datadir_dm\1.cr_raw_cprddefinefiles_`medcondition'_`database'.dta", clear
		distinct patid
		
		/*** Create common fobstype variable ***/
		gen fobstype = .
		label variable fobstype "Observation/file type of first record"
		label define fobstypelab 1 "clinical" 2 "referral" 3 "test"
		label values fobstype fobstypelab
		
		
		if "`database'" == "aurum" {
			assert inlist(obstypeid, 3, 7, 8, 10)
			/*note: I haven't classified obstypes with 0 sleep disorder events*/
			replace fobstype = 1 if inlist(obstypeid, 3, 7) /*Document or observation*/
			replace fobstype = 2 if obstype == 8 /*referral*/
			replace fobstype = 3 if inlist(obstypeid, 9, 10) /*Value*/
			tab fobstype obstypeid, m
			drop obstypeid
		}
		
		if "`database'" == "gold" {
			replace fobstype = 1 if filetype == "clinical"
			replace fobstype = 2 if filetype == "referral"
			replace fobstype = 3 if filetype == "test"
			tab fobstype filetype, m
			drop filetype
		}
		
		note: "Referral and test/value records excluded (based on GOLD file type and Aurum observation type)"
		
		/*decided to restrict to clinical events at this stage as this is need
		for the indidence prevalence analysis*/
		keep if fobstype == 1
		drop fobstype
		
		distinct patid
		local patcount = `r(ndistinct)'
		
		/***restrict to first event in each category (prioritises clinical event
		if more than one event on same day)*/
		bysort patid category `typevar' (evdate): keep if _n == 1
		distinct patid
		assert `r(ndistinct)' == `patcount'
		
		***create variables for first event in each codelist category
		*cycle through each value of category
		qui summ category
		local minval = `r(min)'
		local maxval = `r(max)'
		noi forvalues x = `minval'/`maxval' {
			di `x'
			/*define a local from the category value label*/
			local categorylong: label categorylab `x'
			di "`categorylong'"
			/*define a short label to match the category value label*/
			local direction "longtoshort"
			qui include "$dodir\inc_0.longshortlabels.do"
			di "`categoryshort'"
			/*create a variable named using the short label including the first ever event
			date for the category*/
			local datevarname = "`categoryshort'date_pc"
			gen _temp = evdate if category == `x'
			bysort patid: egen `datevarname' = min(_temp)
			label variable `datevarname' "Date of 1st primary care `categorylong' record"
			format `datevarname' %td
			drop _temp
		} /*code list categories*/
			
		/*drop duplicates and check that this creates a dataset with one line per
		patient and includes all patients in original file*/
		distinct patid
		drop code category evdate
		duplicates drop
		qui count
		assert `r(N)' == `patcount'
		
		*** HES APC FILES ***
		tempfile primarycare
		save `primarycare'
		use "$datadir_raw\1.cr_raw_hesapcicd10files_`medcondition'_`database'.dta", clear
		*restrict to first event in each category
		bysort patid category (evdate): keep if _n == 1
		distinct patid
		*create variables for first event in each category
		*cycle through each value of category
		qui summ category
		local minval = `r(min)'
		local maxval = `r(max)'
		noi forvalues x = `minval'/`maxval' {
			di `x'
			/*define a local from the category value label*/
			local categorylong: label categorylab `x'
			di "`categorylong'"
			/*define a short label to match the category value label*/
			local direction "longtoshort"
			qui include "$dodir\inc_0.longshortlabels.do"
			di "`categoryshort'"
			/*create a variable named using the short label including the first ever event
			date for the category*/
			local datevarname = "`categoryshort'date_hesapc"
			gen _temp = evdate if category == `x'
			bysort patid: egen `datevarname' = min(_temp)
			label variable `datevarname' "Date of 1st HES APC`categorylong' record"
			format `datevarname' %td
			drop _temp
		}
		gen _hesapc = 1
		keep patid *_hesapc
		duplicates drop
		merge 1:1 patid using `primarycare'
		drop _merge
		
		save "$datadir_dm\\_`medcondition'.dta", replace
		distinct patid
		
	} /*medical condition*/
	
	
	/**** 2. MERGE DATA FOR EACH MEDICAL CONDITION AND MERGE WITH DENOMINATOR 
	FILES, FORMAT AND LABEL VARIABLES ******/
	use "$datadir_dm\\_sleep_apnoea.dta", clear
	merge 1:1 patid using "$datadir_dm\\_narcolepsy.dta"
	drop _merge
	erase "$datadir_dm\\_sleep_apnoea.dta"
	erase "$datadir_dm\\_narcolepsy.dta"

	if "`database'" == "aurum" {
		merge 1:1 patid using "$denom_aurum", keepusing(patid pracid yob gender mob regstartdate regenddate cprd_ddate acceptable)
	}

	if "`database'" == "gold" {
		merge 1:1 patid using "$denom_gold", keepusing(patid yob gender mob crd tod deathdate accept)
		gen pracid = substr(patid,-5,.)
		destring pracid, replace
		}
	
	assert _hesapc == 1 if _merge == 1 /*some people in the hesapc data will not
	be in the denominator for the CPRD build*/
	drop if _merge == 1
	drop _merge _hesapc database

	/*bring in practice data (last collection data, region, up-to-standard (empty for aurum))*/
	merge m:1 pracid using "${practice_`database'}"
	assert _merge !=1
	drop if _merge == 2
	drop _merge
	assert region !=.
	
	**renamevariables to be consistent for gold and aurum
	*keeping to aurum naming conventions as much as possible
	if "`database'" == "gold" {
		rename crd regstartdate
		rename tod regenddate
		rename accept acceptable
		label variable uts "up-to-standard date"
		rename deathdate cprd_ddate
		}
	
	/*create practice size variable*/
	/*practice size estimated on 1st July 2019 as a default. Last collection
	dates are prior to 2019 for some practices. Practice size for these
	practices are estimated on the last year that these practices were still
	contributing to CPRD on 1st July **/

	gen _year = 2019

	gen _maxyear = year(lcd)
	replace _maxyear = _maxyear - 1 if month(lcd) < 7
	replace _year = _maxyear if _maxyear <2019 
	
	drop _maxyear 
	
	gen _midpoint = mdy(07,01,_year)
	format _midpoint %td

	gen _studypop = 0
	replace _studypop = 1 if regstart <= _midpoint & regenddate > _midpoint & cprd_ddate > _midpoint
	bysort pracid: egen pracsize = count(_studypop)
	summ pracsize, d
	drop _*
	
	/*use Vision to EMIS migrators data to identify GOLD practices that migrated
	to Aurum*/
	gen dupgoldpractice = 0
	label variable dupgoldpractice "Vision practice migrated to EMIS"
	if "`database'" == "gold" {
		gen gold_pracid = pracid
		merge m:1 gold_pracid using "$visiontoemis", keepusing(gold_pracid)
		replace dupgoldpractice = 1 if _merge == 3
		drop _merge gold_pracid
	}
		

	**label values for new categorical variables
	/*label gender variable*/
	if "`database'" == "aurum" {
		rename gender _gender
		gen gender = . if _gender == ""
		replace gender = 1 if _gender == "M"
		replace gender = 2 if _gender == "F"
		replace gender = 3 if _gender == "I"
		replace gender = 4 if _gender == "U"
		drop _gender
	}
	
	label define genderlab 1 "male" 2 "female" 3 "indeterminate" 4 "unknown"
	label values gender genderlab
	replace gender = . if gender == 0

	/*label values for region variable - aurum lookup matches gold for codes 1 to 12, has
	an additional 0 = None*/
	do "$dodir\labels\region.do"
	label values region regionlab
	tab region, m
	
	/*label variables*/
	label variable patid "Patient identifier"
	label variable gender "Sex"
	label variable yob "Year of birth"
	label variable mob "Month of birth (for those under 16)"
	replace mob = . if mob == 0
	label variable regstart "Date current registration period began"
	label variable regend "Date registration at the practice ended"
	label variable cprd_ddate "Date of death (cprd algorithm)"
	label variable acceptable "CPRD's patient level quality standard flag"
	label variable pracid "Practice identifier"
	label variable region "Region"
	label variable lcd "Last collection date"
	label variable pracsize "Practice size"
	note pracsize: "As a default, practice size is estimated using the study population in mid-2019"
	note pracsize: "For CPRD GOLD practices with last collection dates prior to mid-2019"
	* will create an include file to generate categorical variables
	
	/**** 4. MERGE WITH ONS MORTALITY DATA ***/
	merge 1:1 patid using "$datadir_raw\22_001887_Type1_Request\cr_raw_onsmortalitydodfiles_`database'.dta"
	drop if _merge == 2
	drop _merge
	label variable dod "Date of death (ONS mortality data)"
	
	/**** 5. MERGE WITH LINKAGE DENOMINATOR FILES ******/
	if "`database'" == "gold" destring patid, replace /*see note on patid format in master do file*/
	local linkageglobal "linkagefile_`database'"
	merge 1:1 patid using "${`linkageglobal'}", keep(1 3) keepusing(hes* ons_death_e lsoa_e)
	/*if you are using different combinations of linked data, you will need to 
	change the flags listed in keepusing()*/
	label variable hes_apc_e "Eligibility for linkage to HES APC data"
	label variable hes_op_e "Eligibility for linkage to HES Outpatient data"
	label variable hes_ae_e "Eligibility for linkage to HES A&E data" 
	label variable ons_death_e "Eligibility for linkage to ONS death data" 
	label variable lsoa_e "Eligibility for linkage to HES Outpatient data" 
	label variable lsoa_e "Eligible for linkage to practice level area based data"
	drop _merge
	
	/*** 6. SAVE DATASET ***/
	if "`database'" == "aurum" destring patid, replace /*see note on patid format in master do file*/
	format patid %15.0g
	compress
	save "$datadir_dm\4.cr_dm_all_registered_patients_`database'.dta", replace
	describe
	notes
	
	/*** 4. CHECK THAT DATASET INCLUDES ALL PATIENTS IN THE DENOMINATOR ***/
	qui describe using "${denom_`database'}"
	local denompatients = `r(N)'
	count
	assert `r(N)' == `denompatients'
}

capture log close




