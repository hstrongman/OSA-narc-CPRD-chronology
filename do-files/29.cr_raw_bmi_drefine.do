
capture log close
log using "$logdir\29.cr_raw_bmi_drefine.txt", text replace

/*******************************************************************************
# Stata do file:    29.cr_raw_bmi_define.do
#
# Author:      Helen Strongman
#
# Date:        15/06/2023
#
# Description: 	This do file imports text files including BMI data, restricts
#				the data to people in the study population, formats key variables,
#				and saves the data as a stata file.
#
# Before running this do file: 
#				Run Define query in CPRD's online system for 
#				BMI medcodeids in CPRD Aurum with no additional
#				conditions specified. It is not possible to restrict this to
#				people registered in 2019 as previously planned.
#				
#				Run Refine query in CPRD's online system for BMI entity types
#				in CPRD GOLD. (weight/bmi entity==13, height entity==14). The
#				query needs to be run seperately for the Additional and Clinical
#				files.
#					
# Inspired and adapted from: 
# 				N/A
#
*******************************************************************************/
pause off

capture program drop importbmi

program define importbmi
	args tool_lower tool_upper database suffix
	di "CPRD tool (lower case): `tool_lower'"
	di "CPRD tool (upper case): `tool_upper'"
	di "Database: `database'"
	di "File type for Refine preceded by _ (leave empty Define): `suffix'"
	
	/****	1. Import individual Define files and save as single Stata file per database ****/

	/*create a local listing all Define data files for the specified condition and database*/
	di "$datadir_raw/studypopulation_bmi/`tool_lower'_bmi_`database'_`tool_upper'`suffix'*"
	local myfiles: dir "$datadir_raw/studypopulation_bmi/" files "`tool_lower'_bmi_`database'_`tool_upper'`suffix'*", respectcase
	di `"`myfiles'"'

	/*assign 1st macro (file name) in local as `1'*/
	tokenize `"`myfiles'"'
	/*start loop at i=1*/
	local i=1
	qui while "`1'" !="" {
		noi di "`1'"
		local proceedif0 = strmatch("`1'", "*log.txt")
		if `proceedif0' == 0 {
		/*import each file - all variables imported as strings as patids 
		in CPRD GOLD and Aurum and medcodeid in Aurum must be formatted as a string*/
		if "`database'" == "gold" {
			if "`suffix'" == "_Additional" {
				import delimited using "$datadir_raw/studypopulation_bmi/`1'", ///
				varnames(1) case(lower) clear
				assert enttype == 13 | enttype == 14
				keep patid adid enttype data1 data3
				pause
				}
			if "`suffix'" == "_Clinical" {
				import delimited using "$datadir_raw/studypopulation_bmi/`1'", ///
				varnames(1) case(lower) clear
				assert enttype == 13 | enttype == 14
				keep patid eventdate medcode adid
				rename eventdate obsdate
				gen evdate = date(obsdate, "DMY")
				format evdate %td
				drop obsdate
				label variable evdate "Date associated with the event"
				}
		}
			
		if "`database'" == "aurum" {
			import delimited using "$datadir_raw/studypopulation_bmi/`1'", ///
			varnames(1) case(lower) stringcols(9) clear
			pause
			keep patid obsdate medcodeid value numunitid
			*replace medcodeid with projectmedcode to reduce size of dataset
			merge m:1 medcodeid using "$codedir/codelist_bmi_aurum.dta", keepusing(projectmedcode)
			drop if _merge == 2
			drop _merge
			drop medcodeid
			*format event date
			gen evdate = date(obsdate, "DMY")
			format evdate %td
			drop obsdate
			label variable evdate "Date associated with the event"
			compress
			}
		if `i' >1 {
			/*append data to data in earlier files*/
			append using "$datadir_raw/29.cr_raw_bmi_drefine_`database'`suffix'.dta"
			}
			/*save Stata file with all data imported so far*/
		save "$datadir_raw/29.cr_raw_bmi_drefine_`database'`suffix'.dta", replace
		pause
		/*prepare for next iteration of loop*/
		local i=`i'+1
		/*assign next macro (filename) in local as `1'*/
		} /*not a log file*/
		mac shift
	}


	/****	2. Formatting steps  ****/
	
	/*moved to earlier to keep file size down during processing
	/*create evdate (obsdate in aurum, eventdate in gold)*/
	if "`database'" == "gold" & "`suffix'" == "_Clinical" rename eventdate obsdate
	if "`suffix'" != "_Additional" {
		gen evdate = date(obsdate, "DMY")
		format evdate %td
		drop obsdate
		label variable evdate "Date associated with the event"
	}
	*/

	/*
	/*create enterdate (enterdate in aurum,sysdate in gold)*/
	*note sysdate not available using Define for CPRD GOLD - won't use for either
	if "`database'" == "aurum" rename enterdate sysdate
	gen enterdate = date(sysdate, "DMY")
	format enterdate %td
	drop sysdate
	label variable enterdate "Date event entered into software system"
	*/

	/****	3. Merge with study population file and save dataset  ****/

	/*local database = "gold"
	local suffix = "_Clinical"*/
	use "$datadir_raw/25.cr_raw_bmi_drefine_`database'`suffix'.dta", clear
	
	if "`suffix'" != "_Additional" {
		*rename medcode* code
		*label variable code "medcode(id)"
		local extra = "yob"
	}
	
	
	merge m:1 patid using "$datadir_dm/9.cr_studypopulation_an_flowchart_`database'.dta", keepusing(patid `extra')
	keep if _merge == 3
	drop _merge 

	save "$datadir_raw/29.cr_raw_bmi_drefine_`database'`suffix'.dta", replace

end

*importbmi define Define aurum ""

importbmi refine Refine gold _Additional
*importbmi refine Refine gold _Clinical


capture log close



