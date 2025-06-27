capture log close
log using "$logdir\10.cr_unmatchedcohort_an_flowchart.txt", replace text

/*******************************************************************************
# Stata do file:    10.cr_unmatchedcohort_an_flowchart.do
#
# Author:      Helen Strongman
#
# Date:        05/01/2023. Last updated 17/06/2024 (corrected flowchart errors).
#
# Description: 	This do file flags exposed (prevalent and incident sleep disorder) 
#				and unexposed (sleep disorder free) people in the unmatched cohort 
#				and keeps/generates variables needed for matching process and 
#				the descriptive incidence/prevalence analysis.
# 
#				The do file additionally populates a spreadsheet with numbers
#				needed to describe how the primary care and linked study 
#				populations were defined. Symbols are written in Latex code
#				with "DOLSIGN" replacing "$" to avoid confusion with macros in
#				Stata
#				
# Inspired and adapted from: 
#				N/A	
*******************************************************************************/
pause off
local datasetchange = 0 /*The datasignature command is used at the end of the 
do file to check that the patient level dataset has not changed since this do
file was last run. Setting this local to 1 overides this*/

local j = 1 /*dataset indicator*/
foreach database in aurum gold {
	/****  READ IN STUDY POPULATION DATA  ****/
		foreach linkedtext in primary linked {
			foreach medcondition in OSA narcolepsy {
				use "$datadir_dm\9.cr_studypopulation_an_flowchart_`database'.dta", clear
				keep if studypop_`linkedtext' == 1
				
				/*** SET UP RESULTS FILE FOR EACH COHORT ***/
				local dataset = "`database'`linkedtext'`medcondition'"
				capture erase "$resultdir\_`dataset'.dta"
				tempname memhold
				postfile `memhold' int criteria float `dataset' using "$resultdir\_`dataset'"
				local i = 1
				
				/*** DEFINE EXPOSED COHORT ***/
				post `memhold' (`i') (.)
				label define criterialab `i' "UNMATCHED EXPOSED COHORT", add
				local i = `i' + 1
				
				*** PREVALENT COHORT ***
				gen _stillin = 1
				di as yellow "number of people with and without a clinical code for `medcondition'"
				if "`medcondition'" == "narcolepsy" {
					if "`linkedtext'" == "primary" {
						gen indexdate = narcolepsydate_pc
						}
					if "`linkedtext'" == "linked" {
						gen indexprimary = narcolepsydate_pc
						gen indexhesapc = narcolepsydate_hesapc
						/*NB need to keep variables with original name for later
						in do file*/
						gen indexdate = min(indexprimary, indexhesapc)
						}
				}
				if "`medcondition'" == "OSA" {
					if "`linkedtext'" == "primary" {
						gen indexdate = min(OSAdate_pc, SAdate_pc, SASdate_pc, OSASdate_pc)
					}
					if "`linkedtext'" == "linked" {
						gen indexprimary = min(OSAdate_pc, SAdate_pc, SASdate_pc, OSASdate_pc)
						gen indexhesapc = min(SAdate_hesapc, SASdate_hesapc)
						format indexprimary indexhesapc %td
						label variable indexhesapc "First record of OSA in HES APC"
						label variable indexprimary "First record of OSA in primary care data"
						gen indexdate = min(indexprimary, indexhesapc)
						}
				}
				format indexdate %td
				label variable indexdate "First coded clinical record of `medcondition'"
				note indexdate: "Referral and test/value records not included (based on GOLD file type and Aurum observation type)"
				note indexdate: "Cataplexy only records not included in narcolepsy definition"
				
				count if indexdate != .
				pause
				local with = `r(N)'
				count if indexdate == .
				local without = `r(N)'
				replace _stillin = 0 if indexdate == .
				
				post `memhold' (`i') (`without')
				label define criterialab `i' "No coded records for sleep disorder", add
				local i = `i' + 1
			
				post `memhold' (`i') (`with')
				label define criterialab `i' "DOLSIGN\geq1DOLSIGN coded record for sleep disorder", add
				local i = `i' + 1		
				
			
				di as yellow "At least one record with missing date"
				count if indexdate == d(01/01/1800) & _stillin == 1
				pause
				post `memhold' (`i') (`r(N)')
				label define criterialab `i' "Missing date for DOLSIGN\geq1DOLSIGN record", add
				replace _stillin = 0 if indexdate == d(01/01/1800)
				local i = `i' + 1				
				
				di as yellow "Index date (first ever coded record) on or after end of study period"
				count if indexdate >= ${studyend_`linkedtext'} & _stillin == 1
				pause
				post `memhold' (`i') (`r(N)')
				label define criterialab `i' "Index date DOLSIGN\geqDOLSIGN end of study period", add
				replace _stillin = 0 if indexdate >= ${studyend_`linkedtext'}
				local i = `i' + 1	
				
				di as yellow "Index date on or after end of follow-up"
				count if indexdate >= end_`linkedtext' & _stillin == 1
				pause
				post `memhold' (`i') (`r(N)')
				label define criterialab `i' "Index date DOLSIGN\geqDOLSIGN end of follow-up", add
				replace _stillin = 0 if indexdate >= end_`linkedtext'
				local i = `i' + 1
						
				di as yellow "Record of central or primary sleep apnoea before index or start of follow-up"
				if "`medcondition'" == "narcolepsy" {
					post `memhold' (`i') (0)
					}
				if "`medcondition'" == "OSA" {
					gen _othersadate = min(centraldate_pc, primarydate_pc)
					if "`linkedtext'" == "linked" replace _othersadate = min(_othersadate, centraldate_hesapc, primarydate_hesapc)
					format _othersadate %td
					count if (_othersadate <= indexdate |  _othersadate <= start_`linkedtext') & _stillin == 1
					pause
					replace _stillin = 0 if _othersadate <= indexdate | _othersadate <= start_`linkedtext'
					post `memhold' (`i') (`r(N)')
					}
				label define criterialab `i' "Record of central or primary sleep apnoea DOLSIGN\leqDOLSIGN index", add
				local i = `i' + 1
				
				/*combined with above 24/01/2023*
				di as yellow "Record of central or primary sleep apnoea before start of follow-up"
				if "`medcondition'" == "narcolepsy" {
					post `memhold' (`i') (0)
					label define criterialab `i' "N/A", add
					}
				if "`medcondition'" == "OSA" {
					count if _othersadate <= start_`linkedtext' & _stillin == 1
					replace _stillin = 0 if  _othersadate <= start_`linkedtext'
					post `memhold' (`i') (`r(N)')
					label define criterialab `i' "Record of central or primary sleep apnoea before start of follow-up", add
					}
				local i = `i' + 1
				*/
				
				di as yellow "Aged <= 18 at index (OSA only)"
				if "`medcondition'" == "OSA" {
					count if _stillin == 1 & date18 > indexdate
					replace _stillin = 0 if date18 > indexdate
					post `memhold' (`i') (`r(N)')
				}
				if "`medcondition'" == "narcolepsy" {
					post `memhold' (`i') (0)
				}
				label define criterialab `i' "Aged DOLSIGN<18DOLSIGN at index date", add
				local i = `i' + 1
				
				di as yellow "Prevalent sleep disorder"
				gen prevalent = _stillin
				label variable prevalent "Prevalent `medcondition'"
				count if prevalent == 1
				pause
				post `memhold' (`i') (`r(N)')
				label define criterialab `i' "Prevalent sleep disorder", add
				local i = `i' + 1				
				
				*** INCIDENT UNMATCHED COHORT ***
				di as yellow "index date in the 90 days after practice registration"
				count if indexdate < (regstartdate + 90) & indexdate >= regstartdate & _stillin == 1
				pause
				post `memhold' (`i') (`r(N)')
				label define criterialab `i' "Index date DOLSIGN<90DOLSIGN days after practice registration", add
				replace _stillin = 0 if indexdate < regstartdate + 90 & indexdate >= regstartdate & _stillin == 1 /*& indexdate >= regstartdate added 17/06/2024*/
				local i = `i' + 1
				/*note 90 day criteria goes before "before follow-up" because 
				start_`linkedtext' incorporates regstart + 90*/
			
				di as yellow "Index date before start of follow-up"
				count if indexdate < start_`linkedtext' & _stillin == 1
				pause
				post `memhold' (`i') (`r(N)')
				label define criterialab `i' "Index dateDOLSIGN<DOLSIGN start of follow-up", add
				replace _stillin = 0 if indexdate < start_`linkedtext' & _stillin == 1
				local i = `i' + 1				
				
				di as yellow "Incident sleep disorder"
				rename _stillin incident
				label variable incident "Incident `medcondition'"
				count if incident == 1
				pause
				post `memhold' (`i') (`r(N)')
				label define criterialab `i' "Incident sleep disorder", add
				local i = `i' + 1
				
				/*moved up to remove from prevalent cohort
				di as yellow "Aged >= 18 at index (OSA only)"
				if "`medcondition'" == "OSA" {
					count if incident == 1 & date18 >= indexdate
					post `memhold' (`i') (`r(N)')
					label define criterialab `i' "Aged DOLSIGN<18DOLSIGN at index date", add
					local i = `i' + 1
				}
				if "`medcondition'" == "narcolepsy" {
					post `memhold' (`i') (0)
					label define criterialab `i' "N/A", add
					local i = `i' + 1
				}
				*/
				
				/*not required - removed from prevalent cohort
				gen incidentformatching = incident
				if "`medcondition'" == "OSA" replace incidentformatching = 0 if date18 >= indexdate
				label variable incidentformatching "Incident cohort for matching"
				note incidentformatching: "Matched cohort will be restricted to age 18 and over for OSA"
				count if incidentformatching == 1
				post `memhold' (`i') (`r(N)')
				label define criterialab `i' "Incident sleep disorder for matching", add
				local i = `i' + 1
				pause
				*/
				
				*** SLEEP DISORDER FREE COHORT ***
				gen _stillin = 1
				post `memhold' (`i') (.)
				label define criterialab `i' "UNMATCHED SLEEP DISORDER FREE COHORT", add
				local i = `i' + 1
				
				di as yellow "Coded record of sleep disorder on or prior to start of follow-up"
				count if indexdate <= start_`linkedtext' & indexdate != d(01/01/1800) /*& indexdate != d(01/01/1800) added 17/06/2024*/
				pause
				post `memhold' (`i') (`r(N)')
				label define criterialab `i' "Index date DOLSIGN\leqDOLSIGN start of follow-up", add
				replace _stillin = 0 if indexdate <= start_`linkedtext' & indexdate != d(01/01/1800)
				local i = `i' + 1
				
				di as yellow "At least one coded record of sleep disorder with missing date"
				count if indexdate == d(01/01/1800) & _stillin == 1
				pause
				post `memhold' (`i') (`r(N)')
				label define criterialab `i' "Missing date for DOLSIGN\geq1DOLSIGN record", add
				replace _stillin = 0 if indexdate == d(01/01/1800) & _stillin == 1
				local i = `i' + 1	
				
				di as yellow "Coded record of sleep disorder less than 90 days after registration"
				count if indexdate <= regstartdate + 90 & _stillin == 1
				pause
				post `memhold' (`i') (`r(N)')
				label define criterialab `i' "Index date DOLSIGN<90DOLSIGN days after registration", add
				replace _stillin = 0 if indexdate < regstartdate + 90 & _stillin == 1
				local i = `i' + 1
				
				di as yellow "Coded record of central or primary sleep apnoea on or prior to start of follow-up"
				if "`medcondition'" == "narcolepsy" {
					post `memhold' (`i') (0)
					}
				if "`medcondition'" == "OSA" {
					count if _othersadate <= start_`linkedtext' & _stillin == 1
					pause
					replace _stillin = 0 if _othersadate <= start_`linkedtext' & _stillin == 1
					post `memhold' (`i') (`r(N)')
					}
				label define criterialab `i' "Central or primary sleep apnoea DOLSIGN\leqDOLSIGN start of follow-up", add
				local i = `i' + 1
				
				di as yellow "Aged <18 at end of sleep disorder free follow-up"
				if "`medcondition'" == "OSA" {
					count if _stillin == 1 & (end_`linkedtext' <= date18 | indexdate <= date18 | _othersadate <= date18) & _stillin == 1
					replace _stillin = 0 if (end_`linkedtext' <= date18 | indexdate <= date18 | _othersadate <= date18) & _stillin == 1
					post `memhold' (`i') (`r(N)')
					}
				if "`medcondition'" == "narcolepsy" {
					post `memhold' (`i') (0)
				}
				label define criterialab `i' "Aged DOLSIGN<18DOLSIGN at end of sleep disorder free follow-up", add
				local i = `i' + 1

				di as yellow "Unmatched sleep disorder free cohort"
				rename _stillin unexposed
				label variable unexposed "Unexposed `medcondition'"
				count if unexposed == 1
				pause
				post `memhold' (`i') (`r(N)')
				label define criterialab `i' "Sleep disorder free for incidence/prevalence analysis", add
				local i = `i' + 1
				
				/*moved up / modified to remove from unmatched cohort
				di as yellow "Aged <18 at end of sleep disorder free follow-up"
				if "`medcondition'" == "OSA" {
					count if unexposed == 1 & (end_`linkedtext' <= date18 | indexdate <= date18 | _othersadate <= date18)
					post `memhold' (`i') (`r(N)')
					label define criterialab `i' "Aged DOLSIGN<18DOLSIGN at end of sleep disorder free follow-up", add
					local i = `i' + 1
					gen unexposedformatching = unexposed
					replace unexposedformatching = 0 if (end_`linkedtext' <= date18 | indexdate <= date18 | _othersadate <= date18)
					label variable unexposedformatching "Sleep disorder free cohort for matching"
					note unexposedformatching: "Matched cohort will be restricted to age 18 and over for OSA"
					}
				if "`medcondition'" == "narcolepsy" {
					post `memhold' (`i') (0)
					label define criterialab `i' "N/A", add
					local i = `i' + 1
					gen unexposedformatching = 1
				}
				count if unexposedformatching == 1
				pause
				post `memhold' (`i') (`r(N)')
				label define criterialab `i' "Sleep disorder free group for matching", add
				local i = `i' + 1
				*/
				postclose `memhold'
				
				
				/**** UNMATCHED COHORT PATIENT LEVEL DATA SET ***/
				di as yellow "Unmatched cohort patient level data set"
				
				/*** create variable describing code type recorded at index*/
				
				if "`medcondition'" == "OSA" local prefixlist "OSA OSAS SA SAS"
				if "`medcondition'" == "narcolepsy" local prefixlist "narcolepsy"
				
				if "`linkedtext'" == "primary" local dataablist = "pc"
				if "`linkedtext'" == "linked" local dataablist = "pc hesapc"
					
				gen _pc = 0 if indexdate !=.
				gen _hesapc = 0 if indexdate !=.
					
				foreach prefix of local prefixlist {
						gen _`prefix' = 0
						foreach dataab of local dataablist {
							if strpos("`prefix'", "O") == 1 & "`dataab'" == "hesapc" continue
							replace _`prefix' = 1 if `prefix'date_`dataab' == indexdate & indexdate !=.
							replace _`dataab' = 1 if `prefix'date_`dataab' == indexdate & indexdate !=.
						}
					}
				
				gen indexcode = ""
				label variable indexcode "`medcondition' code type(s) recorded at index"
					gen _codecount = 0
					foreach prefix of local prefixlist {
						replace _codecount = _codecount + 1 if _`prefix' == 1
						replace indexcode = "`prefix'" if _`prefix' == 1 & _codecount == 1
						replace indexcode = indexcode + " + " + "`prefix'" if _`prefix' == 1 & _codecount > 1
						drop _`prefix'
						}
				drop _codecount
				tab indexcode, m
				
				/*** create variable describing whether codes are recorded in 
				primary care and/or linked data ***/
				
				if "`linkedtext'" == "linked" {
					if "`medcondition'" == "narcolepsy" {
						rename narcolepsydate_hesapc indexlinked
						label variable indexlinked "First record of narcolepsy in HES APC"
						/*variable generated previously for OSA*/
					}
					gen cprdvshesapc = 0 if indexhesapc !=. | indexprimary !=.
					label variable cprdvshesapc "Concordance between CPRD and HES APC"
					recode cprdvshesapc 0 = 1 if indexhesapc == indexprimary
					recode cprdvshesapc 0 = 2 if indexhesapc < indexprimary & indexhesapc !=. & indexprimary !=.
					recode cprdvshesapc 0 = 3 if indexhesapc > indexprimary & indexhesapc !=. & indexprimary !=.
					recode cprdvshesapc 0 = 4 if indexhesapc ==. | indexprimary !=.
					recode cprdvshesapc 0 = 5 if indexhesapc !=. | indexprimary ==.

					label define cprdvshesapclab 1 "CPRD and HES APC on index" 2 "HES APC first" 3 "CPRD first" 4 "CPRD only" 5 "HES APC only"
					label values cprdvshesapc cprdvshesapclab
				}
				
				
				/*
				gen indexdatabase = 1 if _pc == 1 & _hesapc == 0
				replace indexdatabase = 2 if _pc == 0 & _hesapc == 1
				replace indexdatabase = 3 if _pc == 1 & _hesapc == 1
				label variable indexdatabase "Database(s) with `medcondition' recorded on index date"		
				label define indexdatabaselab 1 "primary" 2 "HES APC" 3 "primary + HES APC", replace
				label values indexdatabase indexdatabaselab
				tab indexdatabase, m
				drop _hesapc _pc
				pause
				*/	
				
				*** drop if no longer in study population
				
				*code checks that people who are dropped have no eligible follow-up time
				gen _drop = 0 if incident == 0 & unexposed == 0 & prevalent == 0
				recode _drop 0 = 1 if indexdate < regstartdate + 90 
				recode _drop 0 = 1 if indexdate == d(01/01/1800)

				if "`medcondition'" == "OSA" {
					recode _drop 0 = 1 if _othersadate <= start_`linkedtext'
					recode _drop 0 = 1 if _othersadate <= start_`linkedtext'
					recode _drop 0 = 1 if date18 >= end_`linkedtext'
					recode _drop 0 = 1 if indexdate < date18
					recode _drop 0 = 1 if _othersadate < date18
				}
				
				drop if _drop == 1
				count if incident == 0 & unexposed == 0 & prevalent == 0
				assert `r(N)' == 0
				drop _drop
				
				/*** time split patients included in both unexposed and exposed cohorts
				and adjust start and end of follow-up*/
				
				assert prevalent == 1 if incident == 1

				gen exposed = .
				**always exposed
				replace exposed = 1 if prevalent == 1 & incident == 0
				assert indexdate == start_`linkedtext' if unexposed == 0 & incident == 1 & prevalent == 1
				replace exposed = 1 if unexposed == 0 & incident == 1 & prevalent == 1
				**never exposed
				replace exposed = 0 if unexposed == 1 & prevalent == 0 & incident == 0
				

				**exposed during follow-up (i.e. incident cases)
				assert incident == 1 & unexposed == 1 if exposed == .
				expand 2 if exposed == ., gen(_expand)
				tab _expand if exposed == ., m nolab
				
				
				/*make original copy unexposed*/ 
				replace incident = 0 if _expand == 0 & exposed == .
				replace exposed = 0 if _expand == 0 & exposed == . 
				replace prevalent = 0 if exposed == 0
				
				/*make duplicate copy incident*/
				replace exposed = 1 if _expand == 1 /*make incident*/

				drop unexposed _expand

				label variable exposed "exposure status"
				label define exposedlab 0 "unexposed" 1 "exposed", replace
				label values exposed exposedlab
				tab exposed, m
				
				/*gen formatching = 0
				replace formatching = 1 if exposed == 0 & unexposedformatching == 1
				replace formatching = 1 if incident == 1 & incidentformatching == 1
				label variable formatching "Eligible for matched cohort"
				note formatching: "restricted to people age 18 or over at index (exposed) or at end of sleep disorder free follow-up"
				drop unexposedformatching incidentformatching
				*/
				
				assert indexdate > start_`linkedtext' | indexdate < end_`linkedtext' if exposed == 0 & indexdate !=.
				*replace indexdate = . if exposed == 0 /*removed 03/02/2023 - needed to modify end_`linkedtext' below and to estimate incidence*/
		
				note drop _dta
				gen start_fup = start_`linkedtext'
				format start_fup %td
				replace start_fup = max(start_`linkedtext', indexdate) if exposed == 1
				if "`medcondition'" == "OSA" replace start_fup = max(date18, start_fup)
				label variable start_fup "Start of follow-up in unmatched cohort"
				note start_fup: "Follow-up starts at the latest of registration + 90 days, the start of the study period, (the 18th birthday - OSA only), and (and the index date - exposed time)"
				drop start_`linkedtext'
				
				gen end_fup = end_`linkedtext'
				format end_fup %td
				if "`medcondition'" == "OSA" replace end_fup = min(end_`linkedtext', _othersadate)
				replace end_fup = min(end_`linkedtext', indexdate) if exposed == 0
				label variable end_fup "End of follow-up in unmatched cohort"
				note end_fup: "Follow-up ends at the latest of transfer out of practice, death, 2 months prior to the last collection date, (the first coded record of primary or central sleep apnoea - OSA only), and (the index date - sleep disorder free time only)"
				drop end_`linkedtext'
				
				gen _followuptime = end_fup - start_fup
				summ _followuptime, d
				assert _followuptime >0
				drop _followuptime
				
				/*save criterialab label*/
				tempfile templabel
				label list criterialab
				label save criterialab using `templabel'
	
				/**** SAVE FILE FOR EACH COHORT ****/
				di as yellow "save file for each cohort"
				local keep "patid pracid" /*identifiers*/
				local keep "`keep' prevalent incident exposed" /*cohort*/
				local keep "`keep' indexdate start_fup end_fup" /*rate variables*/
				local keep "`keep' dob yob gender region pracsize indexcode" /*stratification and matching variables*/ 
				local extra ""
				if "`medcondition'" == "narcolepsy" local extra "cataplexy*" 
				if "`linkedtext'" == "linked" local extra "`extra' cprdvshesapc"
				local keep "`keep' `extra' regstartdate" /*varibles to check post-hoc decisions and for sensitivity analyses*/
				if "`linkedtext'" == "linked" local keep "`keep' hes_op_e hes_ae_e" /*variables needed for matched cohort analyses*/
				local keep = regexr("`keep'", "  ", " ")
				di "`keep'"
				keep `keep'
				order `keep'
				gen database = "`database'"
				label variable database "CPRD database"
				/*check that there are no changes to the patient level dataset when the file is rerun
				- if there are, subsequent do files need to be rerun*/
				compress
				if `datasetchange' == 1 datasignature set, saving("$datadir_an\10.cr_unmatchedcohort_an_flowchart_`medcondition'_`database'_`linkedtext'.dtasig", replace) reset
				datasignature confirm using "$datadir_an\10.cr_unmatchedcohort_an_flowchart_`medcondition'_`database'_`linkedtext'.dtasig"
				save "$datadir_an\10.cr_unmatchedcohort_an_flowchart_`medcondition'_`database'_`linkedtext'.dta", replace
				describe
				pause
				
				/**** FLOW CHART DATASET ****/
				use "$resultdir\_`dataset'", clear
				if `j' > 1 {
					merge 1:1 criteria using "$resultdir\10.cr_unmatchedcohort_an_flowchart.dta"
					assert _merge == 3
					drop _merge
					}
				save "$resultdir\10.cr_unmatchedcohort_an_flowchart.dta", replace
				*erase "_`dataset'.dta"
				local j = `j' + 1
				pause
			} /*medcondition*/
		} /*linked*/
	} /*database*/
	
/**** ADD COLUMNS FOR AURUM AND GOLD COMBINED ***/
foreach linkedtext in primary linked {
	foreach medcondition in narcolepsy OSA {
		local name "combined`linkedtext'`medcondition'"
		egen `name' = rowtotal(gold`linkedtext'`medcondition' aurum`linkedtext'`medcondition'), missing
}
}

/****  LABEL RESULTS DATASET AND VARIABLES  ****/
label data "Unmatched cohort flow chart"
do `templabel'
label values criteria criterialab
note: "See database, variable labels and notes in patient level database"
pause
export excel using "$resultdir\10.cr_unmatchedcohort_an_flowchart.xlsx", replace firstrow(variables)
save "$resultdir\10.cr_unmatchedcohort_an_flowchart.dta", replace

** erase temporary files
local myfiles: dir "$resultdir\" files "_*", respectcase
tokenize `"`myfiles'"'
while "`1'" !="" {
	erase "$resultdir\\`1'"
	mac shift
	}



capture log close





