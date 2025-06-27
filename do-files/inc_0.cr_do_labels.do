

/*******************************************************************************
# Stata do file:    inc_0.cr_do_linkedlabels.do
#
# Author:      Helen Strongman
#
# Date:        13/12/2023
#
# Description: 	This do file creates labels from lookup files added to
#				"$dodir\labels\" and saves them separate do files in 
#				"$dodir\labels\"
#
# Inspired and adapted from: 
# 				N/A
#
# Requirements: tab delimited lookup text file in "$dodir/labels/";
#				filename = variable name from raw data or bespoke lookup name
#				1st column 1st row = id variable, data = numerical values; 
#				2nd column 1st row = "description", data = text
#
#				local for varname/bespoke lookup name
*******************************************************************************/
	
	*read in specified lookup file
	import delimited using  "$dodir/labels/`varname'.txt", clear varnames(1) case(lower) delimiters("\t")
	*create locals for varlab
	local varlab = "`varname'" + "lab"
	di "`varlab'"
	*create locals with minimum and maximum values
	*assumes the id variable is the first variable in the dataset
	qui describe, varlist
	tokenize `r(varlist)'
	local idname = "`1'"
	di "`idname'"
	summ `idname'
	local start = r(min)
	local end = r(max)
	*drop previous label (important because values will be added to the label through the loop)
	capture label drop `varlab'
	*loop through each value assigning label to each code
	qui forvalues j = `r(min)'/`r(max)' {
		count if `idname' == `j'
		if `r(N)' == 0 continue
		levelsof description if `idname' == `j', local(x)
		di `x'
		assert description == `x' if `idname' == `j'
		label define `varlab' `j' `x', add
	}
	/*save label*/
	label list `varlab'
	label save `varlab' using "$dodir/labels/`varname'.do", replace
	