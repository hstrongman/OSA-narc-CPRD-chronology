
/*******************************************************************************
* Stata script:    codelist_sleep_apnoea.do
*
* Author:      Helen Strongman
*
* Date:        05/08/2022
*
* Description: 	Run dyndoc formatted scripts to create the following HTML docs:
				(1) codelist_sleep_apnoea_description.html (describes the
				code lists and how to use them to define Obstructive Sleep
				Apnoea).
				(2) codelist_sleep_apnoea_derivation_* where * = aurum, gold
				and HES (describes the search criteria and includes information
				needed to check the code lists)
	
* Inspired and adapted from: 
				
*******************************************************************************/

clear all
set more off
cap log close
log using "$logdir\codelist_sleep_apnoea_log.txt", replace text

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

copy "$dodir\codelist_sleep_apnoea_description.txt" ., replace

dyndoc "$dodir\codelist_sleep_apnoea_description.txt", ///
saving("codelist_sleep_apnoea_description.html") replace

copy "$dodir\codelist_sleep_apnoea_derivation.txt" ., replace

dyndoc "$dodir\codelist_sleep_apnoea_derivation.txt" ///
aurum "$dict_aurummed" medcodeid snomedctconceptid, ///
saving("codelist_sleep_apnoea_derivation_aurum.html") replace

dyndoc "$dodir\codelist_sleep_apnoea_derivation.txt" ///
gold "$dict_goldmed" medcode readcode, ///
saving("codelist_sleep_apnoea_derivation_gold.html") replace

dyndoc "$dodir\codelist_sleep_apnoea_derivation.txt" ///
hesapc "$dict_hesicd" ICD alt_code, ///
saving("codelist_sleep_apnoea_derivation_hesicd.html") replace




capture log close
