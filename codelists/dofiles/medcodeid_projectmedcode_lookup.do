
/*******************************************************************************
* Stata script:    medcodeid_projectmedcode_lookup.do
*
* Author:      Helen Strongman
*
* Date:       29/06/2023
*
* Description: 	Create code list lookup for Aurum so that medcodeid and
* strings can be replaced with mapped numeric projectmedcodes saving
* space and time. These project ids need to be added to each
* codelist.
	
* Inspired and adapted from: Helena Carreira (LSHTM)
				
*******************************************************************************/

clear all
set more off
cap log close
log using "$logdir/medcodeid_projectmedcode_lookup.txt", replace text

use medcodeid observations using "$dict_aurummed", clear
sort obs medcodeid
gen projectmedcode = _n
summ projectmedcode, d
keep medcodeid projectmedcode
label variable projectmedcode "Numeric medcode identifier mapped to CPRD's medcodeid"
save "$datadir_stata/medcodeid_projectmedcode_lookup.dta", replace

capture log close
