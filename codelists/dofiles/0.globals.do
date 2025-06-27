
/*********************************************************
# Stata do file:    0.globals.do
#
# Author:      Helen Strongman
#
# Date created: 02/08/2022
# Date of last update: 09/08/2022
#
# Description: Globals for codelist creation for 22_001887_sleep-chronology project.
				Designed to allow code lists to be updated
#
# Inspired and adapted from: 
# 				N/A
**********************************************************/

/**********************************************************
# PROJECT METADATA
**********************************************************/
version 17
global cprdbuild 2023_03 /*CPRD build*/


/**********************************************************
# ROUTE PATHS
**********************************************************/
/*main EHR working area*/
*global serverdir "C:\Users\encdhstr\Filr\Net Folders\EPH Shared"
global maindir ""

/*area for analysis data and other project files*/
global ehrdir "$maindir\"

/*CPRD monthly looksups folder*/
global cprddir "$maindir\"


/**********************************************************
# FOLDER PATHS
**********************************************************/
/***PROJECT FILES PATHS***/
/*project directory*/
global projectdir "$ehrdir\HelenS\22_001887_sleep-chronology\codelists"

global dodir "$projectdir\dofiles" /*Stata do files*/
global logdir "$projectdir\logfiles" /*Stata log files*/

global datadir_stata "$projectdir\stata" /*code list files in Stata format*/
global datadir_text "$projectdir\text" /*code list files in text format*/
global metadir "$projectdir\metadata" /*meta data for code list development*/

global olddir "$projectdir\oldlists" /*existing code lists to be updated or 
compared to the new code list*/

/*main project data management folder*/
global projectdatadir "/managementdata"


/***CPRD BUILD METADATA FILEPATHS***/
/*CPRD denominators, dictionaries, lookups directory*/

global dict_aurummed "$cprddir\CPRD Aurum\Code browsers\\${cprdbuild}\CPRDAurumMedical.dta"
global dict_aurumprod "$cprddir\CPRD Aurum\Code browsers\\${cprdbuild}\CPRDAurumProduct.dta"

global dict_goldmed "$cprddir\GPRD_Gold\Code browsers\2022_05 Browsers\medical.dta"
global dict_goldprod "$cprddir\GPRD_Gold\Code browsers\2022_05 Browsers\product.dta"

global dict_hesicd "$cprddir\HES\NHS_5thEd_data_file\ICD10_Edition5_CodesAndTitlesAndMetadata_GB_20160401.dta"


global lookupdir_aurum "/$cprdbuild"
global lookupdir_gold "Lookups_$cprdbuild/TXTFILES/"

/**********************************************************
# OTHER CONVENTIONS TO FOLLOW FOR THIS PROJECT

Abbreviations for file, variable names and locals to be
carried through to main project
- gold
- aurum
- hesapc
- narcolepsy
- sleep_apnoea
**********************************************************/
