capture log close
log using "$logdir\13.an_matchedcohort_flowchart.txt", replace text

/*******************************************************************************
# Stata do file:    13.an_matchedcohort_flowchart.do
#
# Author:      Helen Strongman
#
# Date:        05/01/2023. last updated 16/02/2023
#
# Description: 	This do file checks the matched cohort file and exports data 
#				for the flowchart. Symbols are written in Latex code
#				with "DOLSIGN" replacing "$" to avoid confusion with macros in
#				Stata
#
# Inspired and adapted from: 
#				N/A
*******************************************************************************/
pause off
local j = 1 /*dataset indicator*/

foreach database in aurum gold {
foreach linkedtext in primary linked {
foreach medcondition in OSA narcolepsy {
	
	di as yellow "`medcondition' `database' `linkedtext'"
	
	use "$datadir_an\10.cr_unmatchedcohort_an_flowchart_`medcondition'_`database'_`linkedtext'.dta", clear

	merge 1:1 patid exposed using "$datadir_dm\12.cr_getmatchedcohort_`medcondition'_`database'_`linkedtext'.dta", update replace
	
	drop if prevalent == 1 & incident == 0
	pause
	
	gen _matched = 0 if _merge == 1
	replace _matched = 1 if _merge >= 3
	assert _merge !=2
	drop _merge
	
	tab exposed _matched
	pause
	
	/*** CHECK RESULTS OF MATCHING PROCESS ***/
	
	/*allocate setid to unmatched patients (sequentially from 1)*/
	summ setid
	local maxsetid = `r(max)'
	count if _matched == 0
	gsort -setid, mfirst
	replace setid = _n + `maxsetid' if _matched == 0
	
	***number of matches per exposed patient
	bysort setid: egen _nomatches = count(exposed)
	replace _nomatches = _nomatches - 1
	di as yellow "Number of matches for exposed patients"
	tab _nomatches if exposed==1, m
	
	***characteristics of exposed patients with less than 5 matches
	gen _ageindex = year(indexdate) - year(dob)
	di as yellow "Age at index for exposed patients with less than 5 matches"
	
	tabstat _ageindex if exposed == 1, by(_nomatches) stats(min p25 median p75 max)
	tabstat indexdate if exposed == 1, by(_nomatches) stats(min p25 median p75 max) format
	tabstat start_fup, by(exposed) stats(min p25 median p75 max) format

	***same gender, practice, age (+/- 3 years) and linkage eligibility
	gen ageindex = (indexdate - dob)*365.25
	
	local extra = ""
	if "`linkedtext'" == "linked" local extra = "hes_op_e"

	gsort setid -exposed
	foreach var in gender pracid dob `extra' {
		  by setid: gen _temp = `var' if _n==1
		  by setid: egen _`var'exposed = total(_temp)
		  drop _temp
		  }
	format _dobexposed %dD/N/CY

	assert gender == _genderexposed
	assert pracid == _pracidexposed
	di as yellow "Correctly matched by gender and practice"
	if "`linkedtext'" == "linked" {
		di as yellow "HES OP eligibility status for matched pairs"
		tab hes_op_e _hes_op_eexposed, m
	}
	
	gen _agediff = year(dob) - year(_dobexposed)
	assert _agediff >= -3 & _agediff <=3
	di as yellow "Correctly matched by age"

	*at least 90 days follow-up prior to index
	assert indexdate - regstartdate >= 90
	 
	*at least 18 at index (OSA only)
	if "`medcondition'" == "OSA" assert _ageindex >= 18
	
	*duplicates - expect some of these but interesting to know how many
	duplicates report patid if _matched == 1
	
	pause

	/*** SET UP RESULTS FILE FOR EACH COHORT ***/
	local dataset = "`database'`linkedtext'`medcondition'"
	capture erase "$resultdir\_`dataset'.dta"
	tempname memhold
	postfile `memhold' int criteria float `dataset' using "$resultdir\_`dataset'"
	local i = 1
			
	/*** EXPOSED COHORT ***/
	post `memhold' (`i') (.)
	label define criterialab `i' "{bf: MATCHED EXPOSED COHORT}", add
	local i = `i' + 1
	
	gen _stillin = 1 if exposed == 1
	
	di as yellow "Not matched to sleep disorder free group"
	count if _stillin == 1 & _matched == 0
	post `memhold' (`i') (`r(N)')
	label define criterialab `i' "Not matched", add
	replace _stillin = . if _matched == 0
	local i = `i' + 1
	
	di as yellow "Matched incident sleep disorder group"
	count if _stillin == 1
	post `memhold' (`i') (`r(N)')
	label define criterialab `i' "Matched incident sleep disorder group", add
	local i = `i' + 1
	
	di as yellow "index date after end of follow-up for primary analysis"
	count if _stillin == 1 & indexdate >=d(31/12/2019)
	post `memhold' (`i') (`r(N)')
	label define criterialab `i' "index date DOLSIGN> 31/12/2019DOLSIGN", add
	replace _stillin = . if indexdate >=d(31/12/2019)
	local i = `i' + 1
	
	di as yellow "Primary matched incident sleep disorder group"
	count if _stillin == 1
	post `memhold' (`i') (`r(N)')
	label define criterialab `i' "Primary matched incident sleep disorder group", add
	local i = `i' + 1
	
	if "`linkedtext'" == "linked" {
		
		*combined two exclusion criteria below as small cell counts for not eligible
		di as yellow "Not eligible for linkage / no follow-up in coverage period for additional hospital datasets"
		assert $studystart_hesae == $studystart_hesop
		/*note - the coverage periods for hes_apc and hes_op end after 31/12/2019
		i.e. end of follow-up for primary analyses*/
		count if _stillin == 1 & (hes_op_e == 0 | indexdate < $studystart_hesop)
		post `memhold' (`i') (`r(N)')
		label define criterialab `i' "Not available for linkage to additional hospital datasets", add
		replace _stillin = . if hes_op_e == 0
		local i = `i' + 1
		
		/*
		di as yellow "No follow-up in coverage period for additional hospital datasets"
		/*note - the coverage periods for hes_apc and hes_op end after 31/12/2019
		i.e. end of follow-up for primary analyses*/
		assert $studystart_hesae == $studystart_hesop
		count if _stillin == 1 & indexdate < $studystart_hesop
		post `memhold' (`i') (`r(N)')
		label define criterialab `i' "no follow-up in coverage period for additional hospital datasets", add
		replace _stillin = . if indexdate < $studystart_hesop
		local i = `i' + 1
		*/

		di as yellow "Matched incident sleep disorder group for additional HES datasets"
		count if _stillin == 1
		post `memhold' (`i') (`r(N)')
		label define criterialab `i' "Matched incident sleep disorder group for additional HES datasets", add
		local i = `i' + 1
	}
	
	if "`linkedtext'" == "primary" {
		local x = 1
		while `x' <= 2 {
			post `memhold' (`i') (0)
			label define criterialab `i' "N/A", add
			local i = `i' + 1
			local x = `x' + 1
		}
	}
	
	drop _stillin
	/*** SLEEP DISORDER FREE COHORT ***/
	
	post `memhold' (`i') (.)
	label define criterialab `i' "MATCHED SLEEP DISORDER FREE COHORT", add
	local i = `i' + 1
	
	gen _stillin = 1 if exposed == 0
	
	di as yellow "Not matched to sleep disorder group"
	count if _stillin == 1 & _matched == 0
	post `memhold' (`i') (`r(N)')
	label define criterialab `i' "Not matched", add
	replace _stillin = . if _matched == 0
	local i = `i' + 1
	
	di as yellow "Matched sleep disorder free group"
	count if _stillin == 1
	post `memhold' (`i') (`r(N)')
	label define criterialab `i' "Matched sleep disorder free group", add
	local i = `i' + 1
	
	di as yellow "index date after end of follow-up for primary analysis"
	count if _stillin == 1 & indexdate >=d(31/12/2019)
	post `memhold' (`i') (`r(N)')
	label define criterialab `i' "index date DOLSIGN\geq 31/12/2019DOLSIGN", add
	replace _stillin = . if indexdate >=d(31/12/2019)
	local i = `i' + 1
	
	di as yellow "Primary matched sleep disorder free group"
	count if _stillin == 1
	post `memhold' (`i') (`r(N)')
	label define criterialab `i' "Primary matched sleep disorder free group", add
	local i = `i' + 1
	
	if "`linkedtext'" == "linked" {
		
		*combined two exclusion criteria below as small cell counts for not eligible
		di as yellow "Not eligible for linkage to additional hospital datasets or no follow-up in coverage period"
		count if _stillin == 1 & (hes_op_e == 0 | indexdate < $studystart_hesop)
		post `memhold' (`i') (`r(N)')
		label define criterialab `i' "Not available for linkage to additional hospital datasets", add
		replace _stillin = . if hes_op_e == 0
		local i = `i' + 1
		
		/*
		di as yellow "No follow-up in coverage period for additional hospital datasets"
		/*note - the coverage periods for hes_apc and hes_op end after 31/12/2019
		i.e. end of follow-up for primary analyses*/
		assert $studystart_hesae == $studystart_hesop
		count if _stillin == 1 & indexdate < $studystart_hesop
		post `memhold' (`i') (`r(N)')
		label define criterialab `i' "no follow-up in coverage period for additional hospital datasets", add
		replace _stillin = . if indexdate < $studystart_hesop
		local i = `i' + 1
		*/

		di as yellow "Matched sleep disorder free group for additional HES datasets"
		count if _stillin == 1
		post `memhold' (`i') (`r(N)')
		label define criterialab `i' "Matched sleep disorder free group for additional HES datasets", add
		local i = `i' + 1
	}
	
	if "`linkedtext'" == "primary" {
		local x = 1
		while `x' <= 2 {
			post `memhold' (`i') (0)
			label define criterialab `i' "N/A", add
			local i = `i' + 1
			local x = `x' + 1
		}
	}
	
	
	postclose `memhold'
	
	/*save criterialab label for linked OSA dataset - this includes all exclusion and exclusion criteria*/
	if "`medcondition'" == "OSA" & "`linkedtext'" == "linked" {
		tempfile templabel
		label list criterialab
		label save criterialab using `templabel'
	}
				
	/*DECIDED NOT TO KEEP MATCHED COHORT PATIENT LEVEL DATASET - NEED TO DECIDE ON FINAL COHORTS FIRST
	/**** MATCHED COHORT PATIENT LEVEL DATA SET ***/
	di as yellow "Matched cohort patient level data set"
	
	*drop temporary variables
	drop _*
	
	*drop unmatched
	keep if _matched == 1
	
	save "$datadir_an\13.cr_matchedcohort_an_flowchart_`medcondition'_`database'_`linkedtext'.dta", replace
	describe
	di "are all variables needed and labelled? - age groups?"
	pause
	*/			
				
	/**** FLOW CHART DATASET ****/
	use "$resultdir\_`dataset'", clear
	if `j' > 1 {
		merge 1:1 criteria using "$resultdir\13.an_matchedcohort_flowchart.dta"
		assert _merge == 3
		drop _merge
		}
	save "$resultdir\13.an_matchedcohort_flowchart.dta", replace
	*erase "_`dataset'.dta"
	local j = `j' + 1
}
}
}

/**** ADD COLUMNS FOR AURUM AND GOLD COMBINED ***/
foreach linkedtext in primary linked {
	foreach medcondition in narcolepsy OSA {
		local name "combined`linkedtext'`medcondition'"
		egen `name' = rowtotal(gold`linkedtext'`medcondition' aurum`linkedtext'`medcondition'), missing
}
}

/****  LABEL RESULTS DATASET AND VARIABLES  ****/
label data "Matched cohort flow chart"
do `templabel'
label values criteria criterialab
note: "Not available for linkage if not eligible for individual linkages or follow-up ended before start of coverage period"
pause
export excel using "$resultdir\13.an_matchedcohort_flowchart.xlsx", replace firstrow(variables)
save "$resultdir\13.an_matchedcohort_flowchart.dta", replace


** erase temporary files
local myfiles: dir "$resultdir\" files "_*", respectcase
tokenize `"`myfiles'"'
while "`1'" !="" {
	erase "$resultdir\\`1'"
	mac shift
	}


capture log close




