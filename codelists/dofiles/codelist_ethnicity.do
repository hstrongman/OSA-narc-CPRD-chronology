
/*******************************************************************************
* Stata script:    codelist_ethnicity.do
*
* Author:      Rohini Mathur, Angel Wong, Emily Herret, Helen Strongman
*
* Date:        19/05/2023
*
* Description: 	Run dyndoc formatted scripts to create the following HTML docs:
				(1) codelist_ethnicity_description.html (describes the
				code lists and how to use them to define ethnicity).
				(2) codelist_ethnicity_derivation_* where * = aurum and gold
				 (describes the search criteria and includes information
				needed to check the code lists)
	
* Inspired and adapted from: 
				
*******************************************************************************/

clear all
set more off
cap log close
log using "$logdir\codelist_ethnicity_log.txt", replace text

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


copy "$dodir\codelist_ethnicity_description.txt" ., replace

dyndoc "$dodir\codelist_ethnicity_description.txt", ///
saving("codelist_ethnicity_description.html") replace

copy "$dodir\codelist_ethnicity_derivation.txt" ., replace

dyndoc "$dodir\codelist_ethnicity_derivation.txt" ///
aurum "$dict_aurummed" medcodeid snomedctconceptid, ///
saving("codelist_ethnicity_derivation_aurum.html") replace

dyndoc "$dodir\codelist_ethnicity_derivation.txt" ///
gold "$dict_goldmed" medcode readcode, ///
saving("codelist_ethnicity_derivation_gold.html") replace

*add project specific medcodeid
use "$datadir_stata/codelist_ethnicity_aurum", clear
merge 1:1 medcodeid using "$datadir_stata/medcodeid_projectmedcode_lookup.dta"
drop if _merge == 2
drop _merge
save "$datadir_stata/codelist_ethnicity_aurum", replace


capture log close
