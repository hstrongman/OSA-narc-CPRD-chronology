capture log close
log using "$logdir\0.cr_do_aurumlabels.txt", replace text

/*******************************************************************************
# Stata do file:    0.cr_do_aurumlabels.do
#
# Author:      Helen Strongman
#
# Date:        09/09/2022
#
# Description: 	This do file creates labels from the Aurum lookup files and
#				saves them separate do files in "$dodir\labels\"
#
# Inspired and adapted from: 
# 				N/A
*******************************************************************************/

/*create a local listed all aurum lookup files*/
local myfiles: dir "$lookupdir_aurum/" files "*.txt", respectcase
di `"`myfiles'"'

/*assign 1st macro (file name) in local as `1'*/
tokenize `"`myfiles'"'
/*start loop at i=1*/
local i=1
noisily while "`1'" !="" {
	di "`1'"
	/*assign next macro in local as `1' and end loop for non-standard lookup 
	files (standard files have two variables: xid where x = the variable name 
	and description)*/
	local skip = 0
	if strmatch("`1'", "*Dictionary.txt") local skip = 1 
	if strmatch("`1'", "*common_dosages.txt") local skip = 1 
	if strmatch("`1'", "*Migrators.txt") local skip = 1 
	if strmatch("`1'", "*Gender.txt") local skip = 1 /*standard descriptions 
	are initials e.g. M rather than words e.g. male and denominator file has
	string rather than numeric variable*/
	if strmatch("`1'", "*ConsSource.txt") local skip = 1 /*there are too many
	values with multiple values matching a single text string - will need to 
	merge with data to label*/
	if strmatch("`1'", "*NumUnit.txt") local skip = 1 /*as above*/
	if strmatch("`1'", "*QuantUnit.txt") local skip = 1 /*as above*/
	if `skip' == 1 {
		mac shift
		continue
		}
	*read in look-up file
	import delimited using "$lookupdir_aurum/`1'", clear case(lower)
	if "`1'" == "Sign.txt" {
		*each code is duplicated e.g. 1 = "Minor Problem" and 1 = "minor"
		drop if description == "minor"
		drop if description == "major"
		}
	*create locals for idvar, var and varlab
	describe *id, varlist
	local idvar = "`r(varlist)'"
	di "`idvar'"
	isid `idvar', sort
	local var = regexr("`idvar'", "id", "")
	di "`var'"
	local varlab = "`var'" + "lab"
	di "`varlab'"
	*create locals with minimum and maximum values
	summ `idvar'
	local start = r(min)
	local end = r(max)
	*drop previous label (important because values will be added to the label through the loop)
	capture label drop `varlab'
	*loop through each value assigning label to each code
	forvalues j = `r(min)'/`r(max)' {
		levelsof description if `idvar' == `j', local(x)
		di `x'
		assert description == `x' if `idvar' == `j'
		label define `varlab' `j' `x', add
	}
	/*save label*/
	label list `varlab'
	label save `varlab' using "$dodir/labels/`var'.do", replace
	/*prepare for next iteration of loop*/
	local i=`i'+1
	/*assign next macro (filename) in local as `1'*/
	mac shift
}

/*Note: region - aurum lookup matches gold for codes 1 to 12, has
an additional 0 = None*/
	