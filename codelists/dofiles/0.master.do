/*********************************************************
# Stata do file:    0.master.do
#
# Author:      Helen Strongman
#
# Date:        02/08/2022
#
# Description: This Master file lists all code lists that
				have been created for 22_001887_sleep-chronology
#
# Inspired and adapted from: 
# 				N/A
**********************************************************/

/**********************************************************
# Study conventions
**********************************************************/

* The names of temporary variables should be prefixed with _ 

/**********************************************************
# Copy markdown settings files to metadata folder
These are needed to format the HTML output
**********************************************************/

cd "$metadir"
copy "http://www.stata-press.com/data/r17/reporting/header.txt" ., replace
copy "http://www.stata-press.com/data/r17/reporting/stmarkdown.css" ., replace

/*DYNDOC HELP DOCUMENTS AND TIPS:
https://www.stata.com/manuals/rptdyndoc.pdf
https://www.stata.com/manuals/rptdynamictags.pdf

You can read and adapt the .txt files in the Stata do editor.

Other than the arguments described above, locals can't be used with the
HTML text.

You can find guidance about ~~~~ in the Stata documentation. I found it easiest
to add it before and after each block on text that is not within a dd command.

Text style
- use #, ## or ### to designate level 1, 2 and 3 text outside of a dd command.
- add _newline after Stata's display command to display text on next line.
	Without this, the results of subsequent display commands merge on one line.
- display as result theoretically exports bold text but this doesn't appear to work.

Error messages: these sometimes apply to a much later line of text than first
appears.

error message "attribute : not valid in dd_do tag" appears when an attribute 
(e.g. quietly or nocommands) has been specified

The following options make stata command outputs more readable in HTML:
- tabulate, markdown
- list, noobs clean

*/

do "$dodir/codelist_define_format.do" /*use this do file to transform
code lists to the format required by CPRD's online Define tool*/

/**********************************************************
# Save the following include files in the do file directory
**********************************************************/

"$dodir/inc_splitlocals.do" /*this splits long string locals into
smaller string locals so that they can be displayed properly in dyndoc html
documents*/

/**********************************************************
# Create code list lookup for Aurum so that medcodeid and
prodcodeid strings can be replaced with mapped numeric ids saving
space and time. These ids need to be added to each
codelist.
For this project, this step was completed after the study
population was defined. Ideally it would be at the start of
the project #
**********************************************************/

do "$dodir/medcodeid_projectmedcode_lookup.do"
do "$dodir/prodcodeid_projectprodcode_lookup.do"

/**********************************************************
# Define study populations. These do files create:
- HTML files describing the code list and phenotype (_description)
- HTML files describing how the code list was generated (_derivation)
- .dta code lists files including key variables 
- .txt code list files including all variables from the dictionary
Code list files are named codelist_condition_source
**********************************************************/

do "$dodir/codelist_sleep_apnoea.do"
do "$dodir/codelist_narcolepsy.do"

/**********************************************************
# Incidence and prevalence analyses. These do files create:
- HTML files describing the code list and phenotype (_description)
- HTML files describing how the code list was generated (_derivation)
- .dta code lists files including key variables 
- .txt code list files including all variables from the dictionary
Code list files are named codelist_condition_source
**********************************************************/

do "$dodir/codelist_ethnicity.do"
do "$dodir/codelist_bmi.do"

x DO FILE TEMPLATES NEED UPDATING UP TO HERE

/**********************************************************
# Healthcare resource use analyses. These do files create:
- HTML files describing the code list and phenotype (_description)
- HTML files describing how the code list was generated (_derivation)
- .dta code lists files including key variables 
- .txt code list files including all variables from the dictionary
Code list files are named codelist_condition_source
**********************************************************/

*** GP CONSULTATIONS ***
do "$dodir/codelist_cprdconsultations.do"
do "$dodir/codelist_staffgroup.do"


*** PRESCRIBING ****
do "$dodir/codelist_modafinil.do"
do "$dodir/codelist_dexamfetamine.do"
do "$dodir/codelist_methylphenidate.do"
do "$dodir/codelist_depressiondrugs.do"

**** SPECIFIC PROCEDURES AND TESTS ****
/*These will be identified in HES APC data using OPCS codes and primary care data using Read, Snomed and EMIS code lists.*/

x DO FILE TEMPLATES NEED UPDATING FROM HERE

do "$dodir/codelist_mslt.do"
do "$dodir/codelist_eeg.do"
do "$dodir/codelist_lumbarpuncture.do" - done
oxymetry/blood gas - created text files for HES APC. Would need to restrict to
overnight tests. There is one related Read code for overnight oxymetry but I can't find
anything for overnight arterial blood gas tests. I've used the CPRD browser to create a rough
codelist for other sleep disorders by searching "*sleep* *night* and "*epworth*" and
browsing all codes. Need to review for sleep specialist and decide which variables/
codes to include.


x need to tidy up narcolepsy and OSA code lists - based description on checklist - put in a table?

