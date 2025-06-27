`	'
/*********************************************************
# Stata do file:    0.master.do
#
# Author:      Helen Strongman
#
# Date:        30/08/2022
#
# Description: All do files for 22_001887_sleep-chronology project
#
# Do file prefixes: x.cr_raw (imports and saves raw data file)
#					x.cr_dm (creates interim/data management file)
#					x.cr_a (creates analysis file)
#					x.an (runs analysis)	
#					
#					where x is sequential from 1
#					inclusion files that are unique to the do file have the 
#					same prefix preceded by "inc_"
#					inclusion files that are used in multiple do files are
#					prefixed by inc_0.
#
# Inspired and adapted from: 
# 				N/A
********************************************************* */

/*THE FOLLOWING STATA USER-WRITTEN PACKAGES/COMMANDS ARE USED IN ONE
OR MORE DO-FILES AND NEED TO BE DOWNLOADED
distinct (used in multiple do files)
mipolate/stripolate (first used in 2.cr_a_minimum-baseline-period)
flowchart (see 14.an_flowchart_full.do)
distrate (first used in 18.an_prevalence_estimates.do)
grc1leg (first used in 29.an_prevalence_graphs.do)
*/

/*NOTE ON PATIENT IDENTIFIERS.
CPRD advise importing large numeric identifiers as strings to avoid formatting
issues when denominators are imported into software such as Excel and Stata. 
For this project, string versions of patid are used until the end of 
4.cr_dm_all_registered_patients when they are converted to numeric versions.
I used the following code to check that this would not cause any problems:
use "$denom_`database'", clear
destring patid, gen(patid_num)
tostring patid_num, gen(patid_str) format(%20.0g)
assert patid == patid_str

need to format "format patid %15.0g to see whole number"
*/

/*NOTE ON CODE IDENTIFIERS
Raw CPRD date includes long medcodeids and prodcode ids that must be imported
as strings, taking up lots of space and processing time. I have replaced
these with project specific numeric ids when importing data. This step was
not applied to the study population files*/
x
/**********************************************************
# GLOBALS AND SET UP DO FILES
***********************************************************/
do "$dodir\0.globals.do" /*run this file at the beginning of each session*/
do "$dodir\0.cr_do_aurumlabels.do" /*creates labels from aurum lookups and saves*
as do files*/
do "$dodir\0.cr_do_categorylabels.do" /*creates category labels from code list 
files and saves as do files - needed for 2.cr_raw_hesapcicd10files.do */
do "$dodir\0.markdown_setup.do" /*settings and instructions to format HTML output*/


/*EXTRACT DATA NEEDED TO DEFINE STUDY POPULATION
You will need:
1. the denominator files listed in globals.do
2. codelists for the medical condition (see codelists folder)
3. to extract files from CPRD's Define tool that include the patient identifer,
	medical code and event data for ALL events in the CPRD database matching
	the code list.
4. to request linked HES APC data (patid, icd 10 code, event date) from CPRD for primary
	and secondary codes matching the code list.
5. to request ONS mortality data (patid, date of death) for all linked records.
*/

do "$dodir\1.cr_raw_cprddefinefiles.do" /*add counts from define logs before running*/
do "$dodir\2.cr_raw_hesapcicd10files.do"
do "$dodir\3.cr_raw_onsmortalitydodfiles.do"
do "$dodir\4.cr_dm_all_registered_patients.do"

/*DEFINE STUDY POPULATION AND COHORT*/
/*Define minimum baseline period by visually inspected sleep disorder incidence
rates in the months following registration at the practice*/
do "$dodir\5.cr_an_minimum_baseline_period_stsplit.do" /*prepare data*/
do "$dodir\6.an_minimum_baseline_period_estimates.do" /*generate estimates*/
do "$dodir\7.an_minimum_baseline_period_table.do" /*combine estimates in a table*/

copy "$dodir\8.an_minimum_baseline_period_figures.txt" ., replace
dyndoc "$dodir\8.an_minimum_baseline_period_figures.txt", ///
saving("8.an_minimum_baseline_period_figures.html") replace

/*Define study population and unmatched cohort + export numbers for flow chart*/
do "$dodir\9.cr_studypopulation_an_flowchart.do"
do "$dodir\10.cr_unmatchedcohort_an_flowchart.do"
do "$dodir\11.an_unmatchedcohort_checks.do"

/*Define matched cohort + export numbers for flow chart*/
do "$dodir/12.cr_getmatchedcohort.do"
*do "$dodir/12a.cr_getmatchedcohort_fixed.txt" /*removes merged Aurum practices - not needed for future runs*/
do "$dodir/13.an_matchedcohort_flowchart.do"
do "$dodir/14.an_flowchart_full.do"
do "$dodir/15.an_sample_summary.do"

/*Basic descriptive analysis for post-protocol cohort definitions*/
do "$dodir/16.cr_prevalence_data_byyear.do"
do "$dodir/17.an_studypop_decisions_prevalence_graphs.do"
do "$dodir/18.cr_unmatchedcohort_stsplit.do"
do "$dodir/19.an_studypop_decisions_incidence_estimates.do"
do "$dodir/20.an_studypop_decisions_incidence_graphs.do"

do "$dodir/21.an_sample_size_calculation.do"

/*DATA EXTRACTION PATIENT LISTS*/
do "$dodir/22.cr_dm_extraction_patlists.do" /*patlists for data extraction and
type 2 linkage request*/
do "dodir/23.cr_dm_validationstudy_patlists.do" - this study was run on a
different CPRD build due to data collection and processing delays at CPRD

/*DATA EXTRACTION FOR INCIDENCE AND PREVALENCE*/
do "$dodir/24.cr_ons_population_figs.do"
do "$dodir/25.cr_raw_ethnicity_drefine.do" /*import raw ethnicity data for study population*/
do "$dodir/26.cr_temp_ethnicity_primarycare.do" /*classify ethnicity using primary care data*/
do "$dodir/27.cr_raw_studypop_linked" /*import and format study population linked data*/
do "$dodir/29.cr_raw_bmi_drefine.do" /*import BMI data for study population*/
do "$dodir/30.cr_bmi_datamanagement.do" /*format individual BMI measurements*/



/*DATA MANAGEMENT AND ESTIMATES FOR PREVALENCE (PLUS GRAPHS FOR BSS ABSTRACT)*/
do "$dodir/31.cr_aggregated_prevalence_data.do" /*aggregated prevalence data by calendar year, age and sex*/
do "$dodir/32.an_prevalence_estimates_time.do" /*directly standardised prevalence rates by calendar year*/
do "$dodir/33.cr_studypopulation_mid2019.do" /*person level 2019 data for prevalence analysis*/ 
do "$dodir/34.an_prevalence_estimates_ratios.do" /*estimates prevalence rate ratios*/
do "$dodir/35.an_prevalence_estimates_processout.do" /*create a stata file including all prevalence estimates*/
do "$dodir/36.an_prevalence_forestplot_BSS.do" /*forest plot for BSS abstract*/

/*DATA MANAGEMENT AND ESTIMATES FOR INCIDENCE*/
do "$dodir/37.cr_unmatchedcohort_stsplit_allvars"
do "$dodir/38.an_incidence_estimates_time.do" /*incidence rates over time*/
do "$dodir/39.an_incidence_estimates_ratios.do" /*crude and adjusted incidence rate ratios*/
do "$dodir/40.an_incidence_estimates_rates.do" /*crude incidence rates for each covariate value*/
do "$dodir/41.an_incidence_estimates_processout.do"

/*BSS POSTER AND DESCRIPTIVE EPIDEMIOLOGY MANUSCRIPT TABLES AND FIGURES*/
do "$dodir/42.an_table_incidence_prevalence.do"
do "$dodir/43.an_scattergraphs_supptables_incidence_prevalence_time.do" /*figure 4 and supp*/
do "$dodir/44.an_scattergraphs_incidence_prevalence_age-bmi.do" /*figure 5*/
do "$dodir/45.an_inc-prev_ratios_forestplot.do" /*figure 2 and 3*/
do "$dodir/46.an_inc-prev_ratios_forestplot_time.do"
do "$dodir/47.an_table_inc_prev_ratios_bmicc.do" /*table comparing age-sex adjusted ratios in full study population and complete case BMI subsample*/
do "$dodir/48.an_inc-prev_ratios_forestplot_country.do" /*figure 6*/
do "$dodir/49.an_table_inc_prev_ratios_linkedvsprimary.do"
do "$dodir/50.an_incprev_adhoc.do" /*add hoc analyses e.g. summary statistics for age*/
do "$dodir/51.inc_prev_ratios_forestplot_calendartime.do" /*IRR forest plot comparing calendar years*/
leave 52 in case I need an extra



