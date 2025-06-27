capture log close
log using "$logdir\0.cr_do_categorylabels.txt", replace text

/*******************************************************************************
# Stata do file:    0.cr_do_categorylabels.do
#
# Author:      Helen Strongman
#
# Date:        09/09/2022
#
# Description: 	This do file creates saves category labels from code lists in
#				separate do files in "$dodir\labels\"
#
# Inspired and adapted from: 
# 				N/A
*******************************************************************************/

foreach medcondition in sleep_apnoea narcolepsy {
	use "$codedir\codelist_`medcondition'_aurum.dta", clear
	label list categorylab
	label save categorylab using "$dodir\labels\\categorylab_`medcondition'.do", replace
	}
	
capture log close
