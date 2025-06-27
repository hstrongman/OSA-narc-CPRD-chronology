capture log close

*change the suffix below if you want to keep a record of this
log using "$logdir\0.compress_stata_files_analysis.txt", replace text

/*******************************************************************************
# Stata do file:    0.compress_stata_files.do
#
# Author:      Helen Strongman
#
# Date:        09/02/2023
#
# Description: 	This do file compresses all Stata files in a directory. or those
#				with specified prefixes. 
#				It would be better to do this before saving the final version of
#				each file. However, late is better than never!
#
# Inspired and adapted from: 
#				N/A
*******************************************************************************/


local datadir "$datadir_dm" /*change to your directory*/
local filespec "*.dta" /*you can use wild cards to specify prefixes and suffixes
in addition to ".dta" */
*no further changes needed

pause off /*change to "pause on" if you want to look at the output for one file
at a time. type "q" (enter) to move to the next file. You can cancel this by
typing "pause off" (enter) before "q"*/

local myfiles: dir "`datadir'" files "`filespec'", respectcase
di `"`myfiles'"'

tokenize `"`myfiles'"'
local i=1
while "`1'" !="" {
	di "`1'"
	if `i' == 1 {
		local total_orig = 0
		local total_comp = 0
		local total_diff = 0
	}
	use "`datadir'\\`1'", clear
	describe
	local size_orig = int(`r(width)'*`r(N)'*1.5/(2^20))
	di "original size: `size_orig'"
	local total_orig = `total_orig' + `size_orig'
	di "total combined size of files to date: `total_orig'"
	compress
	describe
	local size_comp = int(r(width)*r(N)*1.5/(2^20))
	di "compressed size: `size_comp'"
	local size_diff = `size_orig' - `size_comp'
	di "difference between original and compressed file: `size_diff'"
	local percent_diff = (`size_diff'/`size_orig')*100
	di "Percentage difference for this file: `percent_diff'"
	local total_comp = `total_comp' + `size_comp'
	di "total combined size of compressed files to date: `total_comp'"
	save "`datadir'/`1'", replace
	local i=`i'+1
	mac shift
	pause
	}

di "Combined size (original): `total_orig'"
di "Combined size (compressed): `total_comp'"
local total_diff = `total_orig' - `total_comp' 
local percent_diff = (`total_diff'/`total_orig')*100
di "Combined percentage difference: `percent_diff'"

capture log close