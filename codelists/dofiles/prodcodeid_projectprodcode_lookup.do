
/*******************************************************************************
* Stata script:    prodcodeid_projectprodcode_lookup.do
*
* Author:      Helen Strongman
*
* Date:       29/06/2023
*
* Description: 	Create code list lookup for Aurum so that prodcodeid
* strings can be replaced with mapped numeric projectprodcodes saving
* space and time. These project ids need to be added to each
* codelist.
	
* Inspired and adapted from: Helena Carreira (LSHTM)
				
*******************************************************************************/

clear all
set more off
cap log close
log using "$logdir/prodcodeid_projectprodcode_lookup.txt", replace text

use prodcodeid using "$dict_aurumprod", clear
sort prodcodeid
gen projectprodcode = _n
summ projectprodcode, d
label variable projectprodcode "Numeric prodcode identifier mapped to CPRD's prodcodeid"
save "$datadir_stata/prodcodeid_projectprodcode_lookup.dta", replace

capture log close
