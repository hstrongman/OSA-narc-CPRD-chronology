
capture log close
log using "$logdir\25.cr_raw_ethnicity_drefine.txt", text replace

/*******************************************************************************
# Stata do file:    25.cr_raw_ethnicity_define.do
#
# Author:      Helen Strongman
#
# Date:        12/06/2023
#
# Description: 	This do file imports text files including ethnicity data, restricts
#				the data to people in the study population, formats key variables,
#				and saves the data as a stata file.
#
# Before running this do file: 
#				Run Define query in CPRD's online system for 
#				ethnicity medcodeids in CPRD Aurum with no additional
#				conditions specified.
#				Note: for this project an extra define query was run following
#				small changes to the code list.
#				
#				Run Refine query in CPRD's online system for ethnicity medcodes
#				in CPRD GOLD. (Note can't get sysdate in Define)
#					
# Inspired and adapted from: 
# 				N/A
#
*******************************************************************************/

noisily {
foreach database in gold aurum {
	
/****	1. Import individual Define files and save as single Stata file per database ****/

if "`database'" == "gold" {
	local tool_lower = "refine"
	local tool_upper = "Refine"
} 


if "`database'" == "aurum" {
	local tool_lower = "define"
	local tool_upper = "Define"
}

/*create a local listing all Define data files for the specified condition and database*/
di "$datadir_raw/studypopulation_ethnicity/`tool_lower'_ethnicity_`database'_`tool_upper'*"
local myfiles: dir "$datadir_raw/studypopulation_ethnicity/" files "`tool_lower'_ethnicity_`database'_`tool_upper'*", respectcase
di `"`myfiles'"'

/*assign 1st macro (file name) in local as `1'*/
tokenize `"`myfiles'"'
/*start loop at i=1*/
local i=1
noisily while "`1'" !="" {
	di "`1'"
	/*import the first file - all variables imported as strings as patids 
	in CPRD GOLD and Aurum and medcodeid in Aurum must be formatted as a string*/
	import delimited using "$datadir_raw/studypopulation_ethnicity/`1'", ///
	varnames(1) case(lower) stringcols(_all) clear
	if "`database'" == "gold" {
		keep patid eventdate sysdate medcode
		destring medcode, replace
		destring patid, replace
		}
	if "`database'" == "aurum" {
		keep patid obsdate enterdate medcodeid
		destring patid, replace
		}
	if `i' >1 {
		/*append data to data in earlier files*/
		append using "$datadir_raw/25.cr_raw_ethnicity_drefine_`database'.dta"
		}
		/*save Stata file with all data imported so far*/
	save "$datadir_raw/25.cr_raw_ethnicity_drefine_`database'.dta", replace
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
label variable evdate "Date associated with the event"

/*create enterdate (enterdate in aurum,sysdate in gold)*/
*note sysdate not available using Define for CPRD GOLD
if "`database'" == "aurum" rename enterdate sysdate
gen enterdate = date(sysdate, "DMY")
format enterdate %td
drop sysdate
label variable enterdate "Date event entered into software system"

	
/****	3. Merge with code list to add ethnicity variables  ****/

/*merge with code list file adding category variable*/
if "`database'" == "aurum" local code = "medcodeid"
if "`database'" == "gold" local code = "medcode"
merge m:1 `code' using "$codedir/codelist_ethnicity_`database'.dta"
keep if _merge == 3 /*note some codes were dropped from the ethnicity code list
after extraction*/
drop _merge
if "`database'" == "aurum" {
	drop medcodeid
	rename projectmedcode code
}
if "`database'" == "gold" {
	rename medcode code
} 
label variable code "medcode(id) - project specific for Aurum"

/****	4. Merge with study population file and save dataset  ****/

merge m:1 patid using "$datadir_dm/9.cr_studypopulation_an_flowchart_`database'.dta"
keep if _merge == 3
drop _merge 

keep patid evdate enterdate code eth5 eth16

save "$datadir_raw/25.cr_raw_ethnicity_drefine_`database'.dta", replace

}
}

capture log close



