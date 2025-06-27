
/*******************************************************************************
# Stata do file:    inc_splitlocals.do
#
# Author:      Helen Strongman
#
# Date:        08/04/2024
#
# Description: 	This do file splits long strings stored as locals into smaller
#				strings. This is needed when using dyndoc to prevent formatting
#				problems when displaying locals.
#
# Inspired and adapted from: N/A
*******************************************************************************/

/*Input arguments needed:
originallocal = name of string local to split into new shorter strings and display
newlength = integer value describing the length of each new string
*/

capture program drop splitlocals
program splitlocals
	args originallocal newlength
	local stringlength = strlen("`originallocal'")				
	local x = 1
	while `stringlength' > 0  {
		display  _newline as text substr("`originallocal'", `x', `newlength')
		local x = `x' + `newlength'
		local stringlength = `stringlength' - `newlength'
	}
end

