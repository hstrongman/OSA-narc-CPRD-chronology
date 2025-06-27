

/*******************************************************************************
# Stata do file:    1.inc_cr_raw_cprddefinefiles.do
#
# Author:      Helen Strongman
#
# Date:        31/08/2022
#
# Description: 	This inclusion do file is run through 1.cr_raw_cprddefinefiles.do 
#				for each database and define code list. It imports individual 
#				define text files and saves them as a single stata file for the 
#				specified database and medical condition with a file type
#				variable described the CPRD file that the event was recorded in
#				and the category variable from the code list file. It checks that
#				the imported data matches the code list and Define log.
#
# Locals needed (see study conventions in 0.globals.do):
#				database
#				medcondition
#				definecount = number of events extracted and recorded in Define
#				log
#
# Inspired and adapted from: 
# 				Daniel Dedman (CPRD) first showed me the code that imports
#				all files in a folder with a specified text string in the file 
#				name 
*******************************************************************************/

/****	1. Import individual Define files and save as single Stata file per
		medition / database 											****/

/*create a local listing all Define data files for the specified condition and database*/
local myfiles: dir "$datadir_raw\define\" files "`medcondition'_`database'_Define_Inc*", respectcase
di `"`myfiles'"'

/*assign 1st macro (file name) in local as `1’*/
tokenize `"`myfiles'"'
/*start loop at i=1*/
local i=1
noisily while "`1'" !="" {
	di "`1'"
	/*import the first file - all variables imported as strings as patids 
	in CPRD GOLD and Aurum and medcodeid in Aurum must be formatted as a string*/
	if "`database'" == "gold" {
		import delimited using "$datadir_raw\define\\`1'", ///
		varnames(1) case(lower) stringcols(1 2) clear
		}
	if "`database'" == "aurum" {
		import delimited using "$datadir_raw\define\\`1'", ///
		varnames(1) case(lower) stringcols(_all) clear
		/*note keeping obstype id to compare to gold file type (might want to
		exclude test events)*/
		keep patid obsdate medcodeid obstypeid
		destring obstypeid, replace 
		}
	/*create a variable describing the file type (gold only, will keep obstypeid)
	for Aurum*/
	if "`database'" == "gold" {
		local filetypestart = strpos("`1'", "Inc") + 5
		noi di `filetypestart'
		local filetypelength = strpos("`1'", "_00") - `filetypestart'
		noi di `filetypelength'
		local filetypename = lower(substr("`1'", `filetypestart',`filetypelength'))
		noi di "`filetypename'"
		gen filetype = "`filetypename'"
		label variable filetype "CPRD file type"
		}
	if `i' >1 {
		/*append data to data in earlier files*/
		append using "$datadir_raw\1.cr_dm_cprddefinefiles_`database'.dta"
		}
		/*save Stata file with all data imported so far*/
	save "$datadir_raw\1.cr_dm_cprddefinefiles_`database'.dta", replace
	/*prepare for next iteration of loop*/
	local i=`i'+1
	/*assign next macro (filename) in local as `1'*/
	mac shift
}

/****	2. Formatting steps  ****/

/*create evdate (obsdate in aurum, eventdate in gold)*/
if "`database'" == "gold" rename eventdate obsdate
gen evdate = date(obsdate, "DMY")
format evdate %td
drop obsdate
replace evdate = date("01/01/1800", "DMY") if evdate == . /*this means that
people with coded events not associated with a date will have a diagnosis
date of 01/01/1800 and be excluded from the study population because this
is before their date of birth - NOT IN PROTOCOL*/ 
label variable evdate "Date associated with the event"

/*label observation type variable for Aurum*/
if "`database'" == "aurum" {
	do "$dodir\labels\\obstype.do"
	label values obstype obstypelab
	tab obstype, m
	}
	
/****	3. Merge with code list to add category variable  ****/

/*merge with code list file adding category variable*/
if "`database'" == "aurum" local code = "medcodeid"
if "`database'" == "gold" local code = "medcode"
merge m:1 `code' using "$codedir\codelist_`medcondition'_`database'.dta"
label variable category "Code list category"

/****	4. Data checks  ****/

/*compare to codelist*/

count if _merge == 1
if `r(N)' > 0 {
	#delimit ;
	di as yellow "There are `r(N)' codes in the data set that are not in the 
	codelist. Check that the code list that you are using in this file matches
	the code list you entered in the Define tool - see Define settings file"
	;
	#delimit cr
	assert _merge !=1
	}
	else {
		di as yellow "All codes in the dataset are in the codelist"
		}
	
count if _merge == 2 & observations > 0
if `r(N)' > 0 {
	if "`database'" == "aurum" & "`medcondition'" == "sleep_apnoea" {
		assert `r(N)' == 1
		summ observations if _merge == 2 
		assert `r(mean)' == 1 /*the Define tool did not accept
		the new code. I'm ignoring it because it was only association with 1
		observation*/
		drop if _merge == 2
		}
	#delimit ;
	di as yellow "There are `r(N)' codes in the code list that are not in the
	dataset and have at least 1 event in the build according to the CPRD
	dictionary. Check that the code list you are using in this file matches
	the code list you entered in the Define tool and that you are using the
	same CPRD build. The latter is important because codes are only included
	in the CPRD dictionary if these have been used by CPRD practices; codes
	are therefore added to the dictionary when new practices join or use a 
	code for the first time."
	;
	#delimit cr
	assert observations == 0 if _merge ==2 
	}
	else {
		#delimit ;
		di as yellow "All codes in the code list with events recorded in the
		complete CPRD database are in the dataset."
		;
		#delimit cr
		drop if _merge == 2 /*drops codes with no matching events*/
		}
	
	
/*compare to Define log*/

count
if `r(N)' != `definecount' {
	di as yellow "The total number of events does not match the Define log."
	}
assert  `r(N)' == `definecount'

/****	5. Finalise variables and save dataset  ****/

*common medical code variable (code)
if "`database'" == "aurum" {
	local extravar = "obstypeid"
	rename medcodeid code
	}
if "`database'" == "gold" {
	local extravar = "filetype"
	rename medcode code
	}
label variable code "medical code (medcodeid, medcode, icd10)"

*dataset identifier
gen database = "`database'"
label variable database "source database"

keep patid evdate code category `extravar' database 

save "$datadir_raw\1.cr_raw_cprddefinefiles_`medcondition'_`database'.dta", replace


capture log close



