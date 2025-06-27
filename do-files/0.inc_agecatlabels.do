/*******************************************************************************
# Stata do file:    0.inc_agecatlabels.do
#
# Author:      Helen Strongman
#
# Date:        06/02/2023
#
# Description: 	This inclusion do file is used in multiple do files. It labels
#				agecat variables created with egen, cut() and changes the value
#				to the midpoint of the category.
#				First used in 16.cr_aggregated_prevalence_data.do
#
# Requirements: agecat variable defined using egen, cut() 
#
# Inspired and adapted from: 
# 				Krishan Bhaskaran's do files linking locals to graph titles.
*******************************************************************************/


	rename agecat _agecatorig
	gen agecat = .

	note agecat: "Variable values are set at midpoint or next integer value of the age category"

	capture program drop agecatlabels
	program agecatlabels
		args leftend next action
		noi di "left end of age category: `leftend'"
		noi di "left end of next age category: `next'"
		local midpoint = `leftend' + (`next' - `leftend')/2
		noi di "exact midpoint: `midpoint'"
		capture confirm integer number `midpoint'
		if _rc > 0 {
			local midpoint = ceil(`midpoint')
			noi di "next integer midpoint: `midpoint'"
		} 
		replace agecat = `midpoint' if _agecatorig == `leftend'
		label define agecatlab `midpoint' "`leftend' to < `next'", `action'
	end

	*loop through each value of original agecat variable
	*first loop sets left end of age category for 1st value
	*second loop:
		* sets right end of age category for 2nd value,
		* runs agecatlabels programme
		* sets left end of value for 2nd label
	*etc.
	levelsof _agecatorig, local(leftendlist)
	di "`leftendlist'"
	local i = 1
	noi foreach l of local leftendlist {
		if `i' == 1 local leftend = `l'
		if `i' > 1 {
			local next = `l'
			if `i' == 2 agecatlabels `leftend' `next' "replace"
			if `i' > 2 agecatlabels `leftend' `next' "add"
			local leftend = `l'
		}
		local i = `i' + 1
	}
	
	*last value needs specific code
	*add options to table for age categories options with different end values
	replace agecat = 90 if _agecatorig == 85
	label define agecatlab 90 "85 plus", add

	label list agecatlab
	label values agecat agecatlab
	tab agecat, m
