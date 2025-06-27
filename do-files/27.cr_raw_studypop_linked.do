
capture log close
log using "$logdir\27.cr_raw_studypop_linked.txt", text replace

/*******************************************************************************
# Stata do file:    27.cr_raw_studypop_linked.do
#
# Author:      Helen Strongman
#
# Date:        16/06/2023
#
# Description: 	This do file imports linked text files including deprivation,
#				urban rural and HES ethnicity data, formats key variables,
#				and saves the data as a stata file.
#
# Before running this do file: 
#				See instructions in 22.cr_dm_extraction_patlists.do
#					
# Inspired and adapted from: 
# 				ethnicity categorisation uses code developed by Rohini Mathur
#				and Adrian Root
#
*******************************************************************************/

foreach database in gold aurum {
	if "`database'" == "aurum" local database_upper = "Aurum"
	if "`database'" == "gold" local database_upper = "GOLD"
	
	cd "$datadir_raw/22_001887_Type2_request/Results/`database_upper'_linked/Study_pop"

	/*LSOA data*/
	import delimited using "practice_carstairs_22_001887.txt", varnames(1) case(lower) clear
	describe
	keep pracid gb2011_carstairs_5
	rename gb2011_carstairs_5 carstairs
	label variable carstairs "Area based deprivation"
	label define carstairslab 1 "1 (least deprived)" 2 "2" 3 "3" 4 "4" 5 "5 (most deprived)"
	label values carstairs carstairslab
	note carstairs: "based on Carstairs Index for the practice postcode linked to the 2011 census"
	save "$datadir_raw/27.cr_raw_studypop_linked_carstairs_`database'.dta", replace
	
	import delimited using "patient_urban_rural_22_001887.txt", varnames(1) case(lower) clear
	keep patid e2011_urban_rural
	rename e2011_urban_rural urban
	label variable urban "Urban-rural"
	label define urbanlab 1 "urban" 2 "rural"
	label values urban urbanlab
	note urban: "based on patient postcode linked to the 2011 census"
	tab urban, m
	describe
	save "$datadir_raw/27.cr_raw_studypop_linked_urban_`database'.dta", replace
	
	/*HES ethnicity data*/
	import delimited using "hes_patient_22_001887_ethnicity.txt", varnames(1) case(lower) clear
	keep patid gen_ethnicity
	rename gen_ethnicity ethnicity_apc
	save "$datadir_raw/27.cr_raw_studypop_linked_ethnicity_`database'.dta", replace
	foreach hestype in ae op {
		import delimited using "hes`hestype'_patient_22_001887_ethnicity.txt", varnames(1) case(lower) clear
		keep patid gen_ethnicity
		rename gen_ethnicity ethnicity_`hestype'
		merge 1:1 patid using "$datadir_raw/27.cr_raw_studypop_linked_ethnicity_`database'.dta"
		drop _merge
		save "$datadir_raw/27.cr_raw_studypop_linked_ethnicity_`database'.dta", replace
	}
	gen ethnicity = ethnicity_apc
	assert ethnicity == ethnicity_op if ethnicity != "" & ethnicity_op !=""
	replace ethnicity = ethnicity_op if ethnicity == "" & ethnicity_op !=""
	assert ethnicity == ethnicity_ae if ethnicity != "" & ethnicity_ae !=""
	replace ethnicity = ethnicity_ae if ethnicity == "" & ethnicity_ae !=""
	tab ethnicity, m
	
	gen heseth5=0 if ethnicity=="White"
	replace heseth5=1 if ethnicity=="Indian" | ethnicity=="Pakistani" | ethnicity=="Oth_Asian"| ethnicity=="Bangladesi"
	replace heseth5=2 if ethnicity=="Bl_Afric" | ethnicity=="Bl_Carib" | ethnicity=="Bl_Other"
	replace heseth5=3 if ethnicity=="Other" | ethnicity=="Chinese"
	replace heseth5=4 if ethnicity=="Mixed"
	replace heseth5=5 if ethnicity=="Unknown"
	tab heseth5 ethnicity, missing

	# del;
	label define heseth5
		0"White"
		1"South Asian"
		2"Black"
		3"Other"
		4"Mixed"
		5"Not Stated";

	label values heseth5 heseth5;
	tab ethnicity heseth5;
	# del cr

	gen heseth16=.
	replace heseth16=8 if ethnicity=="Indian"
	replace heseth16=9 if ethnicity=="Pakistani"
	replace heseth16=10 if ethnicity=="Bangladesi"
	replace heseth16=11 if ethnicity=="Oth_Asian"
	replace heseth16=12 if ethnicity=="Bl_Carib"
	replace heseth16=13 if ethnicity=="Bl_Afric"
	replace heseth16=14 if ethnicity=="Bl_Other"
	replace heseth16=15 if ethnicity=="Chinese"
	replace heseth16=16 if ethnicity=="Other"
	replace heseth16=17 if ethnicity=="Unknown"
	replace heseth16=18 if ethnicity=="White"
	replace heseth16=19 if ethnicity=="Mixed"

	label define heseth16 8"Indian" 9"Pakistani" 10"Bangladeshi" 11"Other Asian" 12"Caribbean" 13"African" 14"Other Black" 15"Chinese" 16"Other ethnic group" 17"Unknown" 18"White" 19"Mixed"
	label values heseth16 heseth16
	tab heseth16
	keep patid heseth5 heseth16
	note: "hes ethnicities derived using the most common ethnicity recorded across datasets"
	save "$datadir_raw/27.cr_raw_studypop_linked_ethnicity_`database'.dta", replace
}

capture log close



