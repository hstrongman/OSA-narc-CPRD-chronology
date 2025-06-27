capture log close
log using "$logdir\32.an_prevalence_estimates_time.txt", replace text

/*******************************************************************************
# Stata do file:    32.an_prevalence_estimates_time.do
#
# Author:      Helen Strongman
#
# Date:        15/06/2023
#
# Description: 	From protocol: "We will estimate the point prevalence of 
#				diagnosed OSA and narcolepsy for each calendar year in the
#				study period by dividing the number of people in the sleep
#				disorder group under follow-up at this time with the total
#				number of people in the study population under follow-up at 
#				this time. "
#
#				HAVEN'T DONE THIS BIT - OK BECAUSE WE ARE NOT ESTIMATING RATIOS
#				OVER TIME -
#				To estimate and compare annual incidence and prevalence rates, 
#				taking into account changes in population structure, we will
#				directly standardise all rates to the 2020 ONS population by age and sex. 
#
#				"To estimate and compare the number of people with prevalent
#				and incident diagnoses of narcolepsy and OSA each year, we will
#				directly standardise age and sex specific rates to ONS population
#				figures for each year."
#
# Requirements: dstdize package in Stata
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/

/*PREVALENCE RATES OVER TIME FOR WHOLE POPULATION*/

local i = 1
foreach linkedtext in linked primary {
forvalues year = 1999/2020 {
foreach medcondition in OSA narcolepsy {
	
	***temporary file with standard population for the relevant year
	tempfile temp
	use "$datadir_an/24.cr_ons_population_figs.dta", clear
	keep if year == `year'
	if "`medcondition'" == "OSA" drop if agecat <=14 /*drops if less than 18 years old*/
	save `temp'

	*** get dataset with aggregated prevalence data for the year/medcondition
	use "$datadir_an/31.cr_aggregated_prevalence_data.dta" if year == `year' & medcondition == "`medcondition'" & linkedtext == "`linkedtext'", clear
	collapse (sum) prevcases studypop, by(agecat gender country)
	if "`linkedtext'" == "primary" {
		*add a row for all countries combined
		tempfile temp
		save `temp'
		collapse (sum) prevcases studypop, by(agecat gender)
		gen country = 5
		label define countrylab 5 "United Kingdom", add
		label values country countrylab
		append using `temp'
	}
	
	*** estimate standardised prevalence rates
	dstdize prevcases studypop agecat gender, using(`temp') by(country)

	*** post results into matrix
	matrix C = r(Nobs)\r(crude)\r(adj)\r(lb_adj)\r(ub_adj)\r(se)
	matrix list C
	matrix D = C'
	matrix colnames D = Nobs prev_crude prev_st prev_st_lci prev_st_uci se_st
	matrix list D

	*** collapse dataset to a single row per each medical condition/year/country and add variables from matrix
	collapse (sum) prevcases studypop, by(country)
	svmat D, names(col)
	*assert studypop == Nobs /*checks that results are added to the right row*/
	*fix below because formatting issue makes UK population differ by 1
	gen _diff = studypop - Nobs
	assert _diff <=1
	drop _diff
	
	*** estimate confidence intervals for crude prevalence using exact methods
	gen prev_crude_lci = .
	gen prev_crude_uci = .
	
	distinct country
	forvalues country = 1/`r(ndistinct)' {
		local obs = studypop[`country']
		local cases = prevcases[`country']
	
		cii proportions `obs' `cases', exact
		replace prev_crude_lci = r(lb) in `country' /*corrected 02/09/2024*/
		replace prev_crude_uci = r(ub) in `country'
	}
	
	*** create Stata file with estimates for each year/medcondition
	gen year = `year'
	gen medcondition = "`medcondition'"
	gen linkedtext = "`linkedtext'"

	if `i' > 1 append using "$estimatesdir/32.an_prevalence_estimates_time.dta"
	save "$estimatesdir/32.an_prevalence_estimates_time.dta", replace
	local i = `i' + 1
}
}
}

save "$estimatesdir/32.an_prevalence_estimates_time.dta", replace

*** estimate numbers in full population (and 95% PIs/)

*generate temporary file with standard population for each year/medcondition/country
*including the United Kingdom = all countries combined
use "$datadir_an/24.cr_ons_population_figs.dta", clear
keep if year >=1999 & year < 2021
collapse (sum) studypop, by(year country)
tempfile tempnarc
save `tempnarc'
collapse (sum) studypop, by(year)
gen country = 5
append using `tempnarc'
gen medcondition = "narcolepsy"
tempfile tempnarc
save `tempnarc'

use "$datadir_an/24.cr_ons_population_figs.dta", clear
drop if agecat <=14 /*drops if less than 18)*/
keep if year >=1999 & year < 2021
collapse (sum) studypop, by(year country)
tempfile tempOSA
save `tempOSA'
collapse (sum) studypop, by(year)
gen country = 5
append using `tempOSA'
gen medcondition = "OSA"

append using `tempnarc'
rename studypop standardpop
label define countrylab 5 "United Kingdom", add
label values country countrylab

merge 1:m year medcondition country using "$estimatesdir/32.an_prevalence_estimates_time.dta"
drop _merge

gen popcases = prev_st * standardpop

/*From KB - I'm slightly less sure that a CI makes sense for the estimated 
absolute number (let alone how you would actually do it), because that isn't
really a sample-based statistic that you are inferring back to the wider 
(/conceptually "infinite") population. I wonder whether better to just work out
the estimated numbers at the LCI and UCI of your prevalence estimates – 
it wouldn't be a CI in itself but you could just call it what it is – 
the estimated number at the extremes of the plausible range for true prevalence… 
and it does the same job of conveying the uncertainty*/
gen popcases_lpi = prev_st_lci * standardpop
gen popcases_upi = prev_st_uci * standardpop


*** change rates from proportion to percentages
drop se*
foreach var in prev_crude prev_crude_lci prev_crude_uci prev_st prev_st_lci prev_st_uci {
	replace `var' = `var' * 100
}
	

*** label variables
drop Nobs
label variable medcondition "Sleep disorder"
label variable year "Calendar year"
label variable linkedtext "Data source(s)"
label variable prevcases "Prevalent cases (n)"
label variable studypop "Study population (n)"
label variable prev_crude "Crude prevalence (%)"
label variable prev_crude_lci "lower 95% confidence bound (%)"
label variable prev_crude_uci "upper 95% confidence bound (%)"
note prev_crude_lci: "Exact crude confidence intervals estimated using binomial methods"
label variable prev_st "Standardised prevalence (%)"
note prev_st: "standardised using age and sex stratified ONS population estimates for each year"
label variable prev_st_lci "lower 95% confidence bound (%)"
label variable prev_st_uci "upper 95% confidence bound (%)"
note prev_st_lci: "Exact standardised confidence intervals estimated using poisson process"
label variable popcases "Estimated cases in the population (n)"
label variable popcases_lpi "lower plausible bound based on 95% CI for standardised prevalence"
label variable popcases_upi "upper plausible bound based on 95% CI for standardised prevalence"

foreach type in crude st {
	gen prev_`type'_str = string(prev_`type', "%9.3fc") + " (" + string(prev_`type'_lci, "%9.3fc") + "-" + string(prev_`type'_uci, "%9.3fc") + ")"
}
label variable prev_crude_str "Crude prevalence % (95% CI)"
label variable prev_st_str "Standardised prevalence % (95% CI)"

gen popcases_str = string(popcases, "%9.0fc") + " (" + string(popcases_lpi, "%9.0fc") + "-" + string(popcases_upi, "%9.0fc") + ")"
label variable popcases_str "Estimated cases in the population n (95% plausible interval)"

label variable standardpop "ONS population (n)"
note standardpop: "Restricted to 18 and over for OSA"

order year country medcondition linkedtext prevcases studypop prev_crude_str prev_st_str popcases_str prev_crude prev_crude_lci prev_crude_uci prev_st prev_st_lci prev_st_uci popcases popcases_lpi popcases_upi
sort year medcondition linkedtext country

compress
save "$estimatesdir/32.an_prevalence_estimates_time.dta", replace

capture log close
