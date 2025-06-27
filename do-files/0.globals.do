
NOTE - KEY DIRECTORIES REMOVED FOR UPLOAD TO GITHUB

/*********************************************************
# Stata do file:    0.globals.do
#
# Author:      Helen Strongman
#
# Date:        01/08/2022
#
# Description: Globals for 22_001887_sleep-chronology project.
				Designed to allow study to be replicated for different 
				medical conditions using different filepaths
#
# Inspired and adapted from: 
# 				N/A
***********************************************************/

/*Set Stata version number*/
version 18 


/**********************************************************
# STUDY SPECIFIC GLOBALS
***********************************************************/
***CPRD builds / linkage set
*SEE CPRD RELEASE NOTES ON THIS BUILD SAVED IN DOCS FOLDER
global buildyear "2023"
global buildmonth "03"
global buildmonthalph "MAR"
global linkageset "22"

***Study start and end dates
*used in study population denominators up to weekly counts
global studystart_primary d(01/01/1990)
global studyend_primary d(30/04/2022)
global studystart_linked d(02/01/1998)
global studyend_linked d(29/03/2021) /*This is the end of HES APC /
ONS mortality data coverage (set 22/January 2022)*/

global studystart_hesapc d(01/04/1997) /*(set 21/August 2021)*/
global studyend_hesapc d(31/03/2021)
global studystart_hesae d(01/04/2003) /*(set 21/August 2021)*/
global studyend_hesae d(31/03/2020)
global studystart_hesop d(01/04/2003) /*(set 21/August 2021)*/
global studyend_hesop d(30/10/2020)


/**********************************************************
# STUDY CONVENTIONS
*********************************************************
*/

/*Abbreviations for file, variable names and locals
medcondition (narcolepsy, sleep_apnoea)
database (gold, aurum, hesapc)
filename suffix (`medcondition'_`database')
*/

/*formats
- format dates as %td
- use _prefix for temporary variables and datasets
*/


/**********************************************************
# ROUTE PATHS
*********************************************************/

/*file paths are used throughout. These follow LSHTM's license
agreement with CPRD. */

*Raw and interim data*/
*global rawdrivedir "Z:\sec-file-b-volumea\EPH\EHR group\GPRD_GOLD\"
global rawdrivedir ""
global rawdatadir "$rawdrivedir/HelenS/22_001887_sleep-chronology"

/*Analysis data and other files*/
*global maindir "C:\Users\encdhstr\Filr\Net Folders\EPH Shared\"
global maindir ""
global ehrdir "$maindir/EHR-Working"
global projectdir "$ehrdir/HelenS/22_001887_sleep-chronology"

/*CPRD monthly looksups folder*/
global cprddir ""

/**********************************************************
# PROJECT FOLDER FILEPATHS
********************************************************* */

global dodir "$projectdir/dofiles" /*Stata do files*/
global logdir "$projectdir/logfiles" /*Stata log files*/
global codedir "$projectdir/codelists/stata" /*Stata code lists - 
note code list do files are in the codelists subdirectory*/
global estimatesdir "$projectdir/estimates" /*raw estimates outputted from Stata
commands*/
global resultdir "$projectdir/results" /*aggregated table/graphs for manuscript 
or other outputs*/
global metadir "$projectdir/metadata" /*markdown output for Github*/

/*DATA FILES - Data type definitions are from CPRD multi-study license agreement*/ 
global datadir_raw "$rawdatadir/rawdata" /*data as provided by CPRD*/
global datadir_dm "$rawdatadir/managementdata" /*data management files - 
intermediate between `raw data' and `analysis data' - useful for data
management. May be required for additional analyses/validation requested*
by journal reviewers (subject to RDG approval)*/
global datadir_an "$rawdatadir/analysisdata" /*dataset including only the
variables (exposure(s), outcome(s), covariates) that are justified in the
RDG protocol and ready for use in the analysis as outlined in the approved
RDG protocol.*/

/**********************************************************
# CPRD DENOMINATOR FILES AND LOOK-UPS
********************************************************* */

/*CPRD provides denominator file and look-ups for each database build and
linkage set. These files are requested from CPRD by LSHTM's data managers.
Data specifications are available on CPRD's website.*/


/*DENOMINATOR FILES - this can be requested from CPRD by license holders.*/
local denomdir_aurum ""
global denom_aurum "`denomdir_aurum'/${buildyear}${buildmonth}_CPRDAurum_AllPats.dta"
global practice_aurum "`denomdir_aurum'/${buildyear}${buildmonth}_CPRDAurum_Practices"

local denomdir_gold "$cprddir/GPRD_Gold/Denominator files/${buildmonthalph}${buildyear}"
global denom_gold "`denomdir_gold'/all_patients_${buildmonthalph}${buildyear}.dta"
global practice_gold "`denomdir_gold'/allpractices_${buildmonthalph}${buildyear}.dta"

/*FILE IDENTYING PRACTICES THAT HAVE CONTRIBUTED TO BOTH GOLD AND AURUM*/
global visiontoemis "/${buildyear}${buildmonth}VisionToEmisMigrators.dta"

/*LINKAGE ELIGIBILITY FILE*/
local linkagesourcedir "Version${linkageset}/"
global linkagefile_gold "`linkagesourcedir'/set_${linkageset}_Source_GOLD/linkage_eligibility_new_patids.dta"
global linkagefile_aurum "`linkagesourcedir'/set_${linkageset}_Source_Aurum/Aurum_enhanced_eligibility_January_2022.dta"

/*LOOK-UPS*/
global lookupdir_aurum "/${buildyear}_${buildmonth}"
global lookupdir_gold "/Lookups_${buildyear}_${buildmonth}"



