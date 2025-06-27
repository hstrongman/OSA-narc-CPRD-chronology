capture log close
log using "$logdir\24.cr_ons_population_figs.txt", replace text

/*******************************************************************************
# Stata do file:    24.cr_ons_population_figs.do
#
# Author:      Helen Strongman
#
# Date:        30/01/2023
#
# Description: 	Import and format ONS age and gender specific population
#				estimates for each constituent country of the UK
#
# Reference: Office for National Statistics, Population estimates for the UK
#			 and constituent countries by sex and age; historical time series
#			release number MYE14, 25 June 2021
#			https://www.ons.gov.uk/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/populationestimatesforukenglandandwalesscotlandandnorthernireland
#			(next release: summer 2023)	
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/

capture program drop importons

program importons
	args table countrycode
	import excel using "$estimatesdir/ukpopulationestimates18382020.xlsx", clear sheet("Table `table'") cellrange(A5:AF286) firstrow /*2020 to 1990*/
	gen country = 1
	gen gender = .
	replace gender = 1 in 97/187
	replace gender = 2 in 191/281
	drop if gender == .

	replace Age = "90" if Age == "90+"
	destring Age, replace
	egen agecat = cut(Age), at(0 9 18 25(10)85)
	replace agecat = 85 if Age >=85
	assert agecat !=.

	local yearvars ""
	forvalues year = 1990/2020 {
		local yearvars "`yearvars' Mid`year'"
	}

	collapse (sum) `yearvars', by(agecat gender)
	reshape long Mid, i(agecat gender) j(year)
	rename Mid studypop
	gen country = `countrycode'
	if `countrycode' > 1 append using "$datadir_an/17.cr_ons_population_figs.dta"
	save "$datadir_an/17.cr_ons_population_figs.dta", replace
end

importons 11 1 /*England*/
importons 13 2 /*Wales*/
importons 16 3 /*Scotland*/
importons 19 4 /*Northern Ireland*/

label variable agecat "Age group"
label variable gender "Sex"
label define genderlab 1 "male" 2 "female"
label values gender genderlab
label variable studypop "Number of individuals in population"
label define countrylab 1 "England" 2 "Wales" 3 "Scotland" 4 "Northern Ireland"
label values country countrylab

include "$dodir/0.inc_agecatlabels.do"
drop _agecatorig

sort country year agecat gender
compress
save "$datadir_an/24.cr_ons_population_figs.dta", replace

/*
keep if country == 1
keep if year > year(${studystart_linked})
keep if year <= year(${studyend_linked})

save "$datadir_an/24.cr_ons_population_figs_linked.dta", replace
*/

capture log close