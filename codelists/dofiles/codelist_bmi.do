
/*******************************************************************************
* Stata script:    codelist_bmi.do
*
* Author:      Angel Wong, Harriet Forbes, Helen Strongman
*
* Date:        24/05/2023
*
* Description: 	Run dyndoc formatted scripts to create the following HTML docs:
				(1) codelist_bmi_description.html (describes the
				code lists).
				(2) codelist_bmi_derivation_* where * = aurum
				(describes the search criteria and includes information
				needed to check the code lists)
				
				Note: BMI identified in CPRD GOLD using entity types.
	
* Inspired and adapted from: See codelist_bmi_description.html.
				
*******************************************************************************/

clear all
set more off
cap log close
log using "$logdir\codelist_bmi_log.txt", replace text

/*Notes and instructions for modifying these files: 
- The copy command copies the current .txt file from $dodir to $metadir. 
- dyndoc creates the HTML file and saves it in $metadir. 
- *** ALWAYS MODIFY .txt FILES IN $dodir. ***
- The arguments following the dyndoc command are:
	database name: `1'
	dictionary filepath `2'
	CPRD code variable `3'
	Original code variable `4'
- These arguments can be displayed in the HTML document using
	<<dd_display: `x'>> and used as a local within stata commands
*/

cd "$metadir" 

copy "$dodir\codelist_bmi_description.txt" ., replace
dyndoc "$dodir\codelist_bmi_description.txt", ///
saving("codelist_bmi_description.html") replace

copy "$dodir\codelist_bmi_derivation.txt" ., replace
dyndoc "$dodir\codelist_bmi_derivation.txt" ///
aurum "$dict_aurummed" medcodeid snomedctconceptid, ///
saving("codelist_bmi_derivation_aurum.html") replace

*add project specific medcodeid
use "$datadir_stata/codelist_bmi_aurum", clear
merge 1:1 medcodeid using "$datadir_stata/medcodeid_projectmedcode_lookup.dta"
keep if _merge ==3
drop _merge
save "$datadir_stata/codelist_bmi_aurum", replace



capture log close
