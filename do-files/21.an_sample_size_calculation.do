capture log close
log using "$logdir\21.an_sample_size_calculation.txt", replace text

/*******************************************************************************
# Stata do file:    21.an_sample_size_calculation.txt
#
# Author:      Helen Strongman
#
# Date:        16/05/2023 - rewritten from fellowship application do file
#
# Description: 	This do file estimates maximum detectable rate ratios and risk
#				ratios based on estimated sample sizes.
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/

capture program drop samplesizehs
program define samplesizehs 
	args medcondition source measure samplen
	
	*estimate minimum risk ratio/risk difference given sample size at cohort entry and specified proportions in the narcolepsy group
	*Note - will be using poisson regression with censoring at start and end of follow-up for each year relative to diagnosis
	*assumption = sample size is stable for the first 6 months
	di "sleep disorder: `medcondition'"
	di "source: `source'"
	di "effect measure: `measure'"
	di "sample size: `samplen'"
	
	tempfile temp
	power twoproportions (0.01 0.05), effect(`measure') n1(`samplen') nratio(5) power(0.9) saving(`temp')
	use `temp', clear
	rename delta `measure'
	gen events = floor(N1*p1)
	keep N1 `measure' p1 events
	rename N1 sample
	rename p1 risk
	list

end

*March 2023 build
foreach medcondition in narcolepsy {
	foreach source in combprimary comblinked aurumlinked {
		if "`medcondition'" == "narcolepsy" & "`source'" == "combprimary" local samplen = 3249 /*3495*/
		if "`medcondition'" == "narcolepsy" & "`source'" == "comblinked" local samplen = 2804
		if "`medcondition'" == "narcolepsy" & "`source'" == "aurumlinked" local samplen = 2490 
	
		foreach measure in ratio diff {
			samplesizehs "`medcondition'" "`source'" "`measure'" `samplen'
		}
	}
}

*May 2022 build
foreach measure in ratio diff {
	samplesizehs narcolepsy combprimary `measure' 3249
}

log close

/*alternative for rate ratio - power cox , effect(hr) power(0.9) sd(0.372678) n(66) direction(upper)
where n = expected number of events in exposed and controls = incidence x total sample size
= (0.004*2736*6)
and sd is a function of the ratio, = sqrt(1/6*(5/6)) */
