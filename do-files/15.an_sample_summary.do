capture log close
log using "$logdir\15.an_sample_summary.txt", replace text

/*******************************************************************************
# Stata do file:    14.an_sample_summary.do
#
# Author:      Helen Strongman
#
# Date:        30/01/2023
#
# Description: 	This do file creates a table describing the sample size for 
#				each cohort. It was used to select the primary cohort.
#
# Exerpt from protocol:	The study will include primary care only and linked cohorts. 
# The primary care only cohort will be used for the primary analysis, 
# when secondary care data is not essential, to maximise sample size. 
# The linked cohort will be used for primary analysis where the outcome is 
# measured using linked data only or validation studies have demonstrated low 
# sensitivity with the use of primary care data only, 
# and in sensitivity analyses for other outcomes. 
# This will be restricted to English practices due to linkage eligibility. 
#
# Should the number of practices contributing to CPRD Aurum increase substantially
# before data extraction, the study will be restricted to CPRD Aurum and the 
# linked cohort will be used for the primary analysis as the proportional gain
# in sample size from using CPRD GOLD and primary care data only will be much reduced.
#
# DECISION: Narcolepsy - sufficient gain in sample size for narcolepsy to stick to original plan
#			except restrict linked datasets to eligible for all linkages.
#
#			OSA - sample size greater for linked data - could do OSA Aurum only.
#
# Inspired and adapted from: 
#				N/A
*******************************************************************************/

/*** read in data from full flowchart files, select key datasets and criteria ***/
use "$resultdir/10.cr_unmatchedcohort_an_flowchart.dta", clear
keep criteria combinedprimaryOSA combinedlinkedOSA aurumprimaryOSA aurumlinkedOSA combinedprimarynarcolepsy aurumprimarynarcolepsy combinedlinkednarcolepsy aurumlinkednarcolepsy 
order criteria combinedprimaryOSA combinedlinkedOSA aurumprimaryOSA aurumlinkedOSA combinedprimarynarcolepsy aurumprimarynarcolepsy combinedlinkednarcolepsy aurumlinkednarcolepsy
label list criterialab

gen _keep = 0
replace _keep = 1 if criteria == 9 /*prevalent sleep disorder*/
replace _keep = 1 if criteria == 12 /*incident sleep disorder*/
keep if _keep == 1
drop _keep

replace criteria = 1 if criteria == 9
replace criteria = 2 if criteria == 12

tempfile temp
save `temp'

use "$resultdir\13.an_matchedcohort_flowchart.dta", clear
keep criteria combinedprimaryOSA combinedlinkedOSA aurumprimaryOSA aurumlinkedOSA combinedprimarynarcolepsy aurumprimarynarcolepsy combinedlinkednarcolepsy aurumlinkednarcolepsy
order criteria combinedprimaryOSA combinedlinkedOSA aurumprimaryOSA aurumlinkedOSA combinedprimarynarcolepsy aurumprimarynarcolepsy combinedlinkednarcolepsy aurumlinkednarcolepsy
label list criterialab

gen _keep = 0
replace _keep = 1 if criteria == 3 /*matched sleep disorder group*/
replace _keep = 1 if criteria == 5 /*primary matched incident sleep disorder group i.e. follow up before 31/01/2023*/
replace _keep = 1 if criteria == 7 /*matched sleep disorder group for additional HES datasets*/
keep if _keep == 1
drop _keep

replace criteria = 3 if criteria == 3
replace criteria = 4 if criteria == 5
replace criteria = 5 if criteria == 7

append using `temp'

/*** label variables and values, plus add notes ***/

notes drop _all
note: "Table describing sleep disorder sample sizes for main cohorts"

rename criteria group
label variable group "Sleep disorder group"

label define grouplab 1 "Prevalent sleep disorder" 2 "Incident sleep disorder" 3 "Matched sleep disorder group" 4 "Primary matched sleep disorder group" 5 "Matched sleep disorder group for additional HES datasets"
label values group grouplab

sort group

note group: "Primary matched sleep disorder group restricted to people with follow-up prior to 31/12/2019."
note group: "Additional HES datasets are HES A&E data and HES Outpatient data."

foreach medcondition in OSA narcolepsy {
	label variable combinedprimary`medcondition' "Primary care data - `medcondition'"
	label variable aurumprimary`medcondition' "Primary care from CPRD Aurum only - `medcondition'"
	label variable combinedlinked`medcondition' "Linked data - `medcondition'"
	label variable aurumlinked`medcondition' "Linked data from CPRD Aurum only - `medcondition'"
}

/*** Save/export Stata and Excel datasets plus notes ***/

save "$resultdir/15.an_sample_summary.dta", replace
export excel using "$resultdir/15.an_sample_summary.xlsx", replace firstrow(varlabels) sheet("data")

collect clear
notes _dir nameswithnotes
foreach name of local nameswithnotes {
     notes _count N : `name'
     forvalues n = 1/`N' {
          notes _fetch note : `name' `n' 
          collect get note = `"note `n' `name': `note'"'
     }
}

collect layout (cmdset)(result)
collect export "$resultdir/15.an_sample_summary", as(xls) sheet("notes") cell(A1) modify

capture log close
