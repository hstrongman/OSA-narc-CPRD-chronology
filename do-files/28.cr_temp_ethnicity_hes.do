capture log close
log using "$logdir\28.cr_temp_ethnicity_hes.txt", text replace

/*******************************************************************************
# Stata do file:    28.cr_temp_ethnicity_hes.do
#
# Author:      Rohini Mathur (modified by Adrian Root to reflect the new HES
#				ethnicity variable)
#
# Date updated:        14/06/2023
#
# Description: 	Generates a labelled 5 and 16 category ethnicity code from HES
#				gen_ethnicity variable.
#
#				The standard HES dataset gives only 1 ethnic group per patient so I am not able to sort through latest vs. most common
#				as in the CPRD- I just use the one that the MHRA team have already cleaned and decided to share. Note that the ethnos 
#				variable which is available in the HES episode file should not be used as it is combined with ethnicity codes from other
#				HES datsets such as out-pt HES in the gen_ethnicity variable. This variable is generated using a modal approach like
#				our CPRD algorithm but if there are multiple modes it is set to unknown rather than using date to break the tie.
#					
# Inspired and adapted from: 
# 				001 Clean Ethnicity codes in HES template AR (HES 14 onwards).do
#
*******************************************************************************/

X CHECK NOTE ABOVE AND RUN

**INSHEET HES DATA FOR YOUR STUDY
insheet using "insert location of HES patient file", clear

**KEEP VARIABLES FOR ETHNICITY
keep patid pracid gen_ethnicity

tab gen_ethnicity

**Ethnicity in 5 categories
gen heseth5=0 if gen_ethnicity=="White"
replace heseth5=1 if gen_ethnicity=="Indian" | gen_ethnicity=="Pakistani" | gen_ethnicity=="Oth_Asian"| gen_ethnicity=="Bangladesi"
replace heseth5=2 if gen_ethnicity=="Bl_Afric" | gen_ethnicity=="Bl_Carib" | gen_ethnicity=="Bl_Other"
replace heseth5=3 if gen_ethnicity=="Other" | gen_ethnicity=="Chinese"
replace heseth5=4 if gen_ethnicity=="Mixed"
replace heseth5=5 if gen_ethnicity=="Unknown"
tab heseth5 gen_ethnicity, missing

# del;
label define heseth5
	0"White"
	1"South Asian"
	2"Black"
	3"Other"
	4"Mixed"
	5"Not Stated";

label values heseth5 heseth5;
tab  gen_ethnicity heseth5;
# del cr

gen heseth16=.
replace heseth16=8 if gen_ethnicity=="Indian"
replace heseth16=9 if gen_ethnicity=="Pakistani"
replace heseth16=10 if gen_ethnicity=="Bangladesi"
replace heseth16=11 if gen_ethnicity=="Oth_Asian"
replace heseth16=12 if gen_ethnicity=="Bl_Carib"
replace heseth16=13 if gen_ethnicity=="Bl_Afric"
replace heseth16=14 if gen_ethnicity=="Bl_Other"
replace heseth16=15 if gen_ethnicity=="Chinese"
replace heseth16=16 if gen_ethnicity=="Other"
replace heseth16=17 if gen_ethnicity=="Unknown"
replace heseth16=18 if gen_ethnicity=="White"
replace heseth16=19 if gen_ethnicity=="Mixed"

label define heseth16 8"Indian" 9"Pakistani" 10"Bangladeshi" 11"Other Asian" 12"Caribbean" 13"African" 14"Other Black" 15"Chinese" 16"Other ethnic group" 17"Unknown" 18"White" 19"Mixed"
label values heseth16 heseth16
tab heseth16

save `Final ethnicity CPRD', replace
