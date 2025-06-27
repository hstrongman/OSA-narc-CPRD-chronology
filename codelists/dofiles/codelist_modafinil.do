
/*******************************************************************************
* Stata script:    codelist_modafinil.do
*
* Author:      Helen Strongman
*
* Date:        02/02/2024
*
* Description: 	Run dyndoc formatted scripts to create the following HTML docs:
				(1) codelist_modafinil.html (describes the
				code lists).
				(2) codelist_modafinil_* where * = aurum and gold
	
* Inspired and adapted from: 
				
*******************************************************************************/

clear all
set more off
cap log close
log using "$logdir\codelist_modafinil_log.txt", replace text

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

copy "$dodir\codelist_modafinil_description.txt" ., replace

dyndoc "$dodir\codelist_modafinil_description.txt", ///
saving("codelist_modafinil_description.html") replace

copy "$dodir\codelist_modafinil_derivation.txt" ., replace

dyndoc "$dodir\codelist_modafinil_derivation.txt" ///
aurum "$dict_aurumprod" prodcodeid dmdid, ///
saving("codelist_modafinil_derivation_aurum.html") replace

dyndoc "$dodir\codelist_modafinil_derivation.txt" ///
gold "$dict_goldprod" prodcode gemscriptcode, ///
saving("codelist_modafinil_derivation_gold.html") replace


capture log close
