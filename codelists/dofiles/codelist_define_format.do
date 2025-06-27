/*******************************************************************************
* Stata script:    codelist_define_format.do
*
* Author:      Helena Strongman
*
* Date:       09/06/2023
*
* Description: 	Convert code list files to the format needed to define cohorts
*				using CPRD's tools
	
* Inspired and adapted from: Helena Carreira's do files
				
*******************************************************************************/

*ssc install sxpose

capture program drop definecodes

program definecodes
	args concept database
	if "`database'" == "aurum" local codename medcodeid
	if "`database'" == "gold" local codename medcode
	use `codename' using "$datadir_stata\codelist_`concept'_`database'.dta", clear
	duplicates drop `codename', force
	if "`database'" == "gold" tostring `codename', replace
	sxpose, clear
	outsheet using "$datadir_text\codelist_`concept'_`database'_define.txt", comma nonames noquote replace
end
	
/*definecodes ethnicity gold
definecodes ethnicity aurum
definecodes bmi aurum
*/

definecodes bmi gold
