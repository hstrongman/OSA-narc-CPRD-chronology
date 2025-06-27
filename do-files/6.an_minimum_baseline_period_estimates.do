clear
capture log close
log using "$logdir\6.an_minimum_baseline_period_estimates.txt", replace text

/*******************************************************************************
# Stata do file:    6.an_minimum_baseline_period_estimates
#
# Author:      Helen Strongman
#
# Date:        09/09/2022
#
# Description: 	This do file saves the incidence rates needed to define a 
# minimum baseline period using visual
# inspection of a plot of the incidence of narcolepsy and OSA over time since 
# registration; this is based on the assumption that it is likely to be less
# than the standard 12 months used in CPRD studies and will therefore increase 
# the size of the exposure groups (Leahy et al 2020).
# 
# Outputs:
# - Separate Stata files with incidence rates for each command.
# 
# 	Inspired and adapted from: 
# 	Leahy, T. P., Sammon, C., & Ramagopalan, S. (2020). 
#	Identification of an appropriate time window for the exclusion of prevalent 
#	cases recorded following registration with the clinical practice research 
#	datalink. 
#	Abstracts of the 36th International Conference on Pharmacoepidemiology & 
#	Therapeutic Risk Management, Virtual, September 16–17, 29, S3, 2465. 
#	https://doi.org/10.1002/PDS.5114

*******************************************************************************/

foreach medcondition in narcolepsy osa {
	
	use "$datadir_an\5.cr_an_minimum_baseline_period_stsplit_`medcondition'.dta", clear
	describe
	
	di as yellow "`medcondition': incidence rates for 3 month periods since analysis start (limited to first 2 years)"
	strate monthsincereg3, per(100000) output("$estimatesdir\6.an_minimum_baseline_period_estimates_3month_`medcondition'.dta", replace)
	
	di as yellow "`medcondition': incidence rates for first 6 1 month periods since analysis start"
	strate monthsincereg1, per(100000) output("$estimatesdir\6.an_minimum_baseline_period_estimates_1month_`medcondition'.dta", replace)
	
	di as yellow "`medcondition': 1 month periods stratified by database (Aurum vs GOLD)"
	strate monthsincereg1 if database == "aurum", per(100000) output("$estimatesdir\6.an_minimum_baseline_period_estimates_aurum_`medcondition'.dta", replace)
	strate monthsincereg1 if database == "gold", per(100000) output("$estimatesdir\6.an_minimum_baseline_period_estimates_gold_`medcondition'.dta", replace)
	
	di as yellow "`medcondition' :1 month period stratified by calendar year groups"
	di as yellow "1990 to 1999"
	strate monthsincereg1 if regstartyearcat == 0, per(100000) output("$estimatesdir\6.an_minimum_baseline_period_estimates_1990to1999_`medcondition'.dta", replace)
	di as yellow "2000 to 2009"
	strate monthsincereg1 if regstartyearcat == 1, per(100000) output("$estimatesdir\6.an_minimum_baseline_period_estimates_2000to2009_`medcondition'.dta", replace)
	di as yellow "2010 to 2022"
	strate monthsincereg1 if regstartyearcat == 2, per(100000) output("$estimatesdir\6.an_minimum_baseline_period_estimates_2010to2022_`medcondition'.dta", replace)
	
	di as yellow "`medcondition' :1 month period stratified by age groups (underage followed by overage where min age is 18 for narcolepsy and 40 for OSA)"
	strate monthsincereg1 if minage_flag == 0, per(100000) output("$estimatesdir\6.an_minimum_baseline_period_estimates_underage_`medcondition'.dta", replace)
	strate monthsincereg1 if minage_flag == 1, per(100000) output("$estimatesdir\6.an_minimum_baseline_period_estimates_overage_`medcondition'.dta", replace)
	}

	
capture log close

