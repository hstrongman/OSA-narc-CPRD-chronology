capture log close
log using "$logdir\38.an_incidence_estimates_time.txt", replace text

/*******************************************************************************
# Stata do file:    38.an_incidence_estimates_time.do
#
# Author:      Helen Strongman
#
# Date:       13/04/2023
#
# Description: 	From protocol: (1) We will calculate annual incidence rates by 
#				dividing the number of people diagnosed within the calendar year 
#				by the total person-time contribution in the comparison group pool. 
#				95% confidence	intervals (CIs) will be calculated using the 
#				Poisson distribution.
#				NOTE - ESTIMATED ANNUAL INCIDENCE RATES FOR OSA, INCIDENCE
#				RATES FOR 5 YEAR CATEGORIES FOR NARCOLEPSY (TOO MUCH ANNUAL
#				VARIATION WITH SINGLE YEAR) AND OSA (TO HELP PRESENTATION) 
#				
#				(2) To estimate and compare annual incidence and prevalence rates, 
#				taking into account changes in population structure, we will
#				directly standardise all rates to the 2020 ONS population by age and sex. 
#				NOT NEEDED - CAN ADJUST INCIDENCE RATE RATIOS BY AGE AND SEX INSTEAD
#
#				(3) To estimate and compare the number of people with prevalent and
#				incident diagnoses of narcolepsy and OSA each year, 
#				we will directly standardise age and sex specific rates to ONS
#				population figures for each year.
#				THIS IS TRICKY FOR INCIDENCE BECAUSE THE DENOMINATOR IS THE AT
#				RISK POPULATION AND NOT THE FULL POPULATION. THIS WOULD NOT MAKE
#				MUCH DIFFERENCE FOR NARCOLEPSY WHICH IS RARE BUT COULD IMPACT
#				OSA WHICH IS MORE COMMON ESPECIALLY IN OLDER AGE GROUPS. I'VE
#				THEREFORE DECIDED NOT TO DO THIS BUT HAVE STARRED OUT THE CODE
#				BELOW IN CASE I CHANGE MY MIND.
#
# Requirements: ADAPTED dstdize package in Stata. See 
#				https://www.statalist.org/forums/forum/general-stata-discussion/general/396456-dstdize-when-popvar-is-not-integer
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/


pause off

local i = 1



foreach linkedtext in primary linked {
foreach medcondition in narcolepsy OSA {
	
	noi di as yellow "`linkedtext' `medcondition'"

	*** get crude incidence rates, cases and person time for each year
	use patid calendaryear calendaryear_cat _st _d _t _t0 _year country using  "$datadir_an/37.cr_unmatchedcohort_stsplit_allvars_`medcondition'_`linkedtext'.dta", clear

	local multiplier = 365.25 * 100000
	
	*** IR by year
	if "`medcondition'" == "OSA" {
	*full population
	strate calendaryear, per(`multiplier') output($estimatesdir/`linkedtext'`medcondition'`year'.dta, replace)
	*England only for primary care (as linked = England only)
	if "`linkedtext'" == "primary" strate calendaryear if country == 1, per(`multiplier') output($estimatesdir/`linkedtext'`medcondition'`year'_England.dta, replace)
	}
	
	*** IR by 5-year category
	*full population
	strate calendaryear_cat, per(`multiplier') output("$estimatesdir/`linkedtext'`medcondition'yearcat.dta", replace)
	
	*Each country for primary care (as linked = England only)
	if "`linkedtext'" == "primary" {
		strate calendaryear_cat if country == 1, per(`multiplier') output("$estimatesdir/`linkedtext'`medcondition'yearcat_England.dta", replace)
		strate calendaryear_cat if country == 2, per(`multiplier') output("$estimatesdir/`linkedtext'`medcondition'yearcat_Wales.dta", replace)
		strate calendaryear_cat if country == 3, per(`multiplier') output("$estimatesdir/`linkedtext'`medcondition'yearcat_Scotland.dta", replace)
		strate calendaryear_cat if country == 4, per(`multiplier') output("$estimatesdir/`linkedtext'`medcondition'yearcat_NI.dta", replace)
	}
}
}



*** append datasets with crude incidence rates
	

local i = 1
foreach linkedtext in linked primary {
foreach medcondition in OSA narcolepsy {
	di "`linkedtext' `medcondition' yearcat"
	*data for each 5-year category (OSA and narcolepsy) - full population
	use "$estimatesdir/`linkedtext'`medcondition'yearcat.dta", clear
	gen medcondition = "`medcondition'"
	gen linkedtext = "`linkedtext'"
	if "`linkedtext'" == "linked" gen country = 1
	if "`linkedtext'" == "primary" gen country = 5
	if `i' > 1 append using "$estimatesdir/38.an_incidence_estimates_time.dta"
	save "$estimatesdir/38.an_incidence_estimates_time.dta", replace
	local i = `i' + 1
	*data for each year (OSA only) - full population
	if "`medcondition'" == "OSA" {
		di "`linkedtext' `medcondition' year"
		use "$estimatesdir/`linkedtext'OSA.dta", clear
		gen medcondition = "`medcondition'"
		gen linkedtext = "`linkedtext'"
		if "`linkedtext'" == "linked" gen country = 1
		if "`linkedtext'" == "primary" gen country = 5
		append using "$estimatesdir/38.an_incidence_estimates_time.dta"
		save "$estimatesdir/38.an_incidence_estimates_time.dta", replace
	}
}
}

*data for each 5-year category (OSA and narcolepsy) - England only primary
foreach medcondition in OSA narcolepsy {
	local i = 1
	foreach country in England Wales Scotland NI {
	*yearcat
	use "$estimatesdir/primary`medcondition'yearcat_`country'.dta", clear
	gen medcondition = "`medcondition'"
	gen linkedtext = "primary"
	gen country = `i'
	append using "$estimatesdir/38.an_incidence_estimates_time.dta"
	save "$estimatesdir/38.an_incidence_estimates_time.dta", replace
	local i = `i' + 1
}
}

*data for each year (OSA) - England only primary
use "$estimatesdir/primaryOSA_England.dta", clear
gen medcondition = "OSA"
gen linkedtext = "primary"
gen country = 1
append using "$estimatesdir/38.an_incidence_estimates_time.dta"
save "$estimatesdir/38.an_incidence_estimates_time.dta", replace



rename _D inccases
rename _Y pyears100
rename _Rate ir_crude
rename _Lower ir_crude_lci
rename _Upper ir_crude_uci
order country medcondition linkedtext calendaryear calendaryear_cat inccases ir_crude ir_crude_lci ir_crude_uci

*** label variables
label variable country "Country"
label define countrylab 1 "England" 2 "Wales" 3 "Scotland" 4 "Northern Ireland" 5 "UK", replace
label values country countrylab
label variable medcondition "Sleep disorder"
label variable calendaryear "Calendar year"
label variable calendaryear_cat "Calendar-year group"
run "$dodir/labels/calendaryear_catlab"
label values calendaryear_cat calendaryear_catlab
label variable linkedtext "Data source(s)"
label variable inccases "Incident cases (n)"
label variable pyears100 "Person years / 100000"
label variable ir_crude "Crude incidence rate (per 100 000 person years)"
label variable ir_crude_lci "lower 95% confidence bound (%)"
label variable ir_crude_uci "upper 95% confidence bound (%)"
note ir_crude_lci: "Crude confidence intervals estimated using the quadratic approximation to the Poisson log likelihood for the log-rate parameter"


foreach type in crude /*st*/ {
	gen ir_`type'_str = string(ir_`type', "%9.3fc") + " (" + string(ir_`type'_lci, "%9.3fc") + "-" + string(ir_`type'_uci, "%9.3fc") + ")"
}
label variable ir_crude_str "Crude incidence rate per 100 000 person years (95% CI)"

order country medcondition linkedtext calendaryear calendaryear_cat inccases pyears ir_crude ir_crude_lci /*ir_crude_uci ir_st ir_st_lci ir_st_uci se_st*/
sort medcondition linkedtext country calendaryear calendaryear_cat 

compress
save "$estimatesdir/38.an_incidence_estimates_time.dta", replace

capture log close


/*OLD CODE

/***temporary file for crude incidence rates
tempname memcrude 
tempfile resultcrude
postfile `memcrude' str10 medcondition str7 linkedtext year cases long pyears_stp ir_crude ir_crude_lci ir_crude_uci using `resultcrude'
*/

	/*
	qui {
	forvalues year = 1999/2020 {
	***temporary file with standard population for each year
	use "$datadir_an/24.cr_ons_population_figs.dta", clear
	keep if year == `year'
	if "`medcondition'" == "OSA" drop if agecat <=14 /*drops if less than 18 years old*/
	if "`linkedtext'" == "linked" keep if country == 1 /*England only*/
	rename studypop pyears /*because we are estimating rates over time*/
	tempfile stpop`year'
	*save `"stpop`year'"'
	save `stpop`year''

	}
	}
	*/

*postclose `memcrude'

/*merge 1:1 medcondition linkedtext year using `resultcrude'
assert _merge == 3
drop _merge
x need code to estimate population numbers if I decide to estimate
standardised rates
order medcondition linkedtext year cases inccases pyears pyears_stp ir_crude_dstdize ir_crude ir_crude_lci ir_crude_uci ir_st ir_st_lci ir_st_uci

*** checks
assert cases == inccases
drop cases

assert pyears == pyears_stp
X need to think about this probably because of 365/366 days
drop pyears_stp

*** rescale standardised rates to per 100 000 person years
foreach incvar in _st _st_lci _st_uci {
	replace ir`incvar' = ir`incvar' * 100000
}
*/
*use `resultcrude'
	/*code in fovalues loop replaced with strate above
	forvalues year = 1999/2020 {
		noi di "`year'"
		local multiplier = 365.25 * 100000
		stptime if calendaryear == `year', per(`multiplier')
		local pyears_stp = `r(ptime)'/365.25
		post `memcrude' ("`medcondition'") ("`linkedtext'") (`year') (`r(failures)') (`pyears_stp') (`r(rate)') (`r(lb)') (`r(ub)')
		pause
		*note strate comes up with same results are stptime but can't extract data
		*can use by option with stptime but I can't see a way to extract the data
	}
	*/
	/*
	***collapse into dataset with number of cases and pyears by age /gender / year
	
	*accounting for leap years
	gen _pdays = _t - _t0
	qui sum _pdays
	local daysinyear = `r(max)'
	gen pyears = _pdays / `daysinyear'
		
	gen inccases = _d
	assert  _st == 1
		
	collapse (sum) inccases pyears, by(calendaryear gender agecat)
	pause
		
	tempfile aggregated
	save `aggregated'
	
	forvalues year = 1999/2020 {
		
		use `aggregated'
		keep if calendaryear == `year'
		
		** estimate standardised incidence rate
		gen _dummy = 1
		dstdize_hs inccases pyears agecat gender, by(_dummy) using(`stpop`year'')
		
		*** post results into matrix
		matrix C = r(Nobs)\r(crude)\r(adj)\r(lb_adj)\r(ub_adj)
		matrix list C
		matrix D = C'
		matrix colnames D = Nobs ir_crude_dstdize ir_st ir_st_lci ir_st_uci
		matrix list D

		*** collapse dataset to a single row per each medical condition/year/country and add variables from matrix
		collapse (sum) inccases pyears
		svmat D, names(col)

		gen _diff = pyears - Nobs
		assert _diff <=1
		drop _diff
		drop Nobs
	
		gen year = `year'
		gen medcondition = "`medcondition'"
		gen linkedtext = "`linkedtext'"
		

		if `i' > 1 append using "$estimatesdir/36.an_incidence_estimates.dta"
		save "$estimatesdir/36.an_incidence_estimates.dta", replace
		local i = `i' + 1
	}
	
/*label variable ir_st "Standardised incidence rate (per 100 000 person years)"
note ir_st: "Standardised using age and sex stratified ONS population estimates for each year"
label variable ir_st_lci "lower 95% confidence bound (%)"
label variable ir_st_uci "upper 95% confidence bound (%)"
note ir_st_lci: "Exact standardised confidence intervals estimated using Poisson process"

label variable popcases "Estimated cases in the population (n)"
label variable popcases_lpi "lower plausible bound based on 95% CI for standardised prevalence"
label variable popcases_upi "upper plausible bound based on 95% CI for standardised prevalence"

*label variable ir_st_str "Standardised prevalence rate per 100 000 person years (95% CI)"
*note standardpop: "ONS standard population restricted to 18 and over for OSA"
*/
	*/