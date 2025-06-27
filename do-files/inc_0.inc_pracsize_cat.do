
/*******************************************************************************
# Stata do file:    0.inc_pracsize_cat.do
#
# Author:      Helen Strongman
#
# Date:        30/03/2023
#
# Description: 	This inclusion do file is used in multiple do files. It 
#				creates a categorical practice size variable.
#
#				Quintile boundaries are based on practices included in the main
#				analysis database (linked CPRD GOLD and Aurum combined,
#				narcolepsy as this includes under 18s). This
#				keeps consistency between analyses. I tried using national
#				practice sizes but CPRD includes more large practices than
#				small practices.
#
# Locals needed: 
#
# Inspired and adapted from: 
# 				N/A
*******************************************************************************/



/** create practice size quintiles based on main analysis study population -
(Aurum/GOLD combined - linked - narcolepsy as OSA restriced to > 18)*/

/*confirm that a local has been created in the main do file to specify whether
the boundaries should be defined or not*/

assert "`defineboundaries'" == "yes" | "`defineboundaries'" == "no"


/* this creates unevenly sized groups at a patient level - more patients in 
quintiles representing bigger practices*/

if "`defineboundaries'" == "yes" {
	
	*set up file for lookup
	tempfile results
	tempname memhold
	postfile `memhold' str3 pctile float pracsize using "`results'", replace

	*calculate min and max  and save to temporary dataset
	gsort pracid
	by pracid: gen _indexpat = 1 if _n==1
	noi summ pracsize if _indexpat == 1, d
	
	foreach extreme in min max {
		local number = r(`extreme')
		noi di `number'
		post `memhold' ("`extreme'") (`number')
	}

	*calculate percentile boundaries and save to temporary dataset
	_pctile pracsize if _indexpat == 1, p(20, 40, 60, 80)
	return list
	
	local i = 1
	forvalues x = 20(20)80 {
		local number = r(r`i')
		noi di `number'
		post `memhold' ("p`x'") (`number')
		local i = `i' + 1
	}
	
	postclose `memhold'
	use `results', clear
	gen pracid = 0
	label variable pracid
	note: "the pracid variable is a dummy variable"
	
	label variable pctile "Practice size quartile boundary"
	label variable pracsize "Practice size"
	
	save "$estimatesdir/0_inc_pracsize_cat.dta", replace
	
	use "$datadir_an/33.cr_studypopulation_mid2019_`medcondition'_`linkedtext'.dta", clear

}

/*append pracsize lookup file to study population file (to avoid preserving
and restoring the study population file)*/
append using "$estimatesdir/0_inc_pracsize_cat.dta"

/*create locals for boundaries using the four rows added to the full datafile*/
levelsof pctile, local(pctilenames)

foreach name of local pctilenames {
	local localname = "`name'val"
	summ pracsize if pracid == 0 & pctile == "`name'"
	scalar `localname' = r(min)
}

scalar list _all

/* create pracsize_cat variable*/
gen pracsize_cat = .
replace pracsize_cat = 5 if pracsize >= minval & pracsize < p20val
replace pracsize_cat = 4 if pracsize >= p20val & pracsize < p40val
replace pracsize_cat = 3 if pracsize >= p40val & pracsize < p60val
replace pracsize_cat = 2 if pracsize >= p60val & pracsize < p80val
replace pracsize_cat = 1 if pracsize >= p80val & pracsize <= maxval
tab pracsize_cat, m
	
label variable pracsize_cat "Practice size quintile"
note pracsize_cat: "Practice size was estimated using the full GOLD and Aurum linked study population in mid-2019"
note pracsize_cat: "or the year prior to the last collection date if earlier than mid-2019"
note pracsize_cat: "Practice size quintile boundaries were based on practices included in linked CPRD GOLD and Aurum data combined"

label define pracsize_catlab 1 "1 largest" 2 "2" 3 "3" 4 "4" 5 "5 smallest", replace
label values pracsize_cat pracsize_catlab
tab pracsize_cat, m


*drop extra rows
drop if pracid == 0
drop pctile

/*alternative - by patient level quintiles
egen pracsize = cut(pracsize), group(5) label
tab pracsize
*/
