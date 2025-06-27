capture log close
log using "$logdir\22.cr_dm_extraction_patlists.txt", replace text

/*******************************************************************************
# Stata do file:    22.cr_dm_extraction_patlists.do
#
# Author:      Helen Strongman
#
# Date:        29/03/2022
#
# Description: 	This do file prepares the data needed to extract primary care
#				data from CPRD and request linked data files. All files should 
#				include patids only.
#
#				Files for linked data requests should be provided as
#				tab-delimited text files (.txt). Multiple zipped files can be provided.
#				Each zipped file must not exceed 20MB. The number of patients
#				in each list needs to be entered into the online form.
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/

/*CPRD GOLD AND CPRD AURUM PATIENT LIST FOR AREA BASED DATA. NEEDED FOR
DESCRIPTIVE STUDY ESTIMATING INCIDENCE AND PREVALENCE OF SLEEP DISORDERS IN THE
STUDY POPULATION AS WELL AS MATCHED COHORT ANALYSIS*/
pause off

cd "$datadir_raw/22_001887_patlists/"

/*
foreach database in gold aurum {
	/*NOTE - IN HINDSIGHT, I SHOULD HAVE USED "$datadir_dm\9.cr_studypopulation_an_flowchart_aurum.dta" HERE
	ONE PATIENT HAS BEEN DROPPED BECAUSE OF THIS*/
	use "$datadir_an\10.cr_unmatchedcohort_an_flowchart_OSA_`database'_linked.dta", clear
	append using "$datadir_an\10.cr_unmatchedcohort_an_flowchart_narcolepsy_`database'_linked.dta"
	*see later code and comments about BMI data
	gen _studypop2019 = 0
	replace _studypop2019 = 1 if start_fup < d(31/12/2019) & end_fup > d(01/01/2019)
	keep patid _studypop2019
	bysort patid: egen studypop2019 = max(_studypop2019)
	pause
	drop _*
	duplicates drop
	count
	display as yellow "Number of patients in area based `database' file: `r(N)'"
	/*
	***split into text files < 20MB
	*set the target zipped file size
	local targetfilesize = 20 * 1024 * 1024
	di "targetfilesize: `targetfilesize'"
	*save the data as a text file
	local zipfilename "cr_dm_extraction_patlists_`database'_studypop" 
	export delimited patid using "`zipfilename'.txt", delimiter(tab) replace
	*zip the text file
	zipfile "`zipfilename'.txt", saving("`zipfilename'.zip", replace) complevel(9)
	pause
	*calculate the zipped file size
	local zippedfilesize = `r(compressed_size)'
	di "zippedfilesize: `zippedfilesize'"
	* Check if the zipped file is larger than the target size
	if `zippedfilesize' >  `targetfilesize' {
		*if it is, split into multiple files
		local numsplits = ceil(`zippedfilesize' / `targetfilesize') + 1 /*plus 1 to account for uneven file sizes*/ 
		di "numsplits: `numsplits'"
		*split into random samples
		splitsample patid, nsplit(`numsplits') rseed(2308)  generate(fileno, replace)
		qui sum fileno
		pause
		assert `r(min)' == 1
		local y = 1
		while `y' <= `numsplits' {
			export delimited patid using "`zipfilename'`y'.txt" if fileno == `y', delimiter(tab) replace
			zipfile "`zipfilename'`y'.txt", saving("`zipfilename'`y'.zip", replace) complevel(9)
			local newzippedfilesize = `r(compressed_size)'
			di `newzippedfilesize'
			assert `newzippedfilesize' <= (`targetfilesize')
			local y = `y' + 1
			pause
			pause off
		}
	}
	
	*restrict to 2019 to extract BMI and ethnicity data (it would be impractical to extract BMI data for all years and both primary care and linked populations)
	keep if studypop2019 == 1
	keep patid
	count
	display as yellow "Number of patients in 2019 `database' study population file: `r(N)'"
	export delimited patid using "$datadir_raw\22_001887_patlists\cr_dm_extraction_patlists_`database'_studypop2019.txt", delimiter(tab) replace
	zipfile "$datadir_raw\22_001887_patlists\cr_dm_extraction_patlists_`database'_studypop2019.txt", saving("cr_dm_extraction_patlists_`database'_studypop2019.zip", replace) complevel(9)
	*/
	
}
*/

/*PRACTICES IN PRIMARY CARE COHORTS WHO WHERE NOT INCLUDED IN LINKED COHORT
- NEED TO REQUEST PRACTICE BASED CARSTAIRS DATA FOR THESE*/

HAVEN'T RUN THIS BIT YET

foreach database in gold aurum {
	*ALL PRACTICES IN PRIMARY COHORT
	use pracid using "$datadir_an\10.cr_unmatchedcohort_an_flowchart_OSA_`database'_primary.dta", clear
	duplicates drop
	tempfile temp
	save `temp', replace
	use pracid using "$datadir_an\10.cr_unmatchedcohort_an_flowchart_narcolepsy_`database'_primary.dta", clear
	duplicates drop 
	merge 1:1 pracid using `temp', nogen
	tempfile primary
	save `primary', replace
	
	*ALL PRACTICES IN LINKED COHORT
	use pracid using "$datadir_an\10.cr_unmatchedcohort_an_flowchart_OSA_`database'_primary.dta", clear
	duplicates drop
	tempfile temp
	save `temp', replace
	use pracid using "$datadir_an\10.cr_unmatchedcohort_an_flowchart_narcolepsy_`database'_primary.dta", clear
	duplicates drop 
	merge 1:1 patid using `temp', nogen
	
	*MERGE AND DROP LINKED
	merge 1:1 pracid using `primary'
	keep if _merge == 2
	drop _merge
	
	count
	display as yellow "Number of `database' practices in primary care cohort but not linked cohort"
	export delimited using "$datadir_raw\22_001887_patlists\cr_dm_extraction_patlists_`database'_extrapracids.txt", delimiter(tab) replace
	*leave as text file - would 
}
	

	

/*CPRD GOLD AND AURUM PATIENT LIST FOR MATCHED COHORT*/
foreach database in gold aurum {

	foreach medcondition in OSA narcolepsy {
		foreach linkedtext in linked primary {
			
		use "$datadir_dm\12.cr_getmatchedcohort_`medcondition'_`database'_`linkedtext'.dta", clear
		keep patid
		duplicates drop
			
		count
		display as yellow "Number of patients in `medcondition' matched cohort `database' `linkedtext' file: `r(N)'"
		export delimited patid using "$datadir_raw\22_001887_patlists\cr_dm_extraction_patlists_matchedcohort_`medcondition'_`database'_`linkedtext'.txt", delimiter(tab) replace
	*zipfile "$datadir_raw\22_001887_patlists\cr_dm_extraction_patlists_`database'_matchedcohort.txt", saving("cr_dm_extraction_patlists_`database'_matchedcohort.zip", replace) complevel(9)
}
}
}

/*Text to submit in answer to: Please enter any further information that is 
relevant to your linkage request

My protocol requires area based data for the study population to allow for
stratification of incidence and prevalence rates by urban-rural status and 
Carstairs index. HES ethnicity data is also required for this cohort.
Data files for these datasets have the suffix "studypop". 
There are 33829629 patids in the Aurum file and 4031963 patids in the GOLD file.

Linked HES and ONS mortality datasets are only required for the matched cohort.
Data files for these datasets have the suffice "matchedcohort"
There are 1064427 in the Aurum file and 97313 in the GOLD file.
*/

/*The `CPRD data minimisation workbook' is saved in the docs folder in $projectdir
*/

log close

