capture log close
log using "$logdir\14.an_flowchart_full.txt", replace text

/*******************************************************************************
# Stata do file:    14.an_flowchart_full.do
#
# Author:      Helen Strongman
#
# Date:        12/01/2023. last updated 21/02/2023
#
# Description: 	This do file creates a CONSORT style flow chart for each cohort
#
# Requirements: Latex editor - Overleaf free version
#				https://github.com/IsaacDodd/flowchart/blob/master/flowchart_example1.do
#				
#				inc_14.flowchart_simplerow.do inclusion file for flowchart
#				rows with one inclusion or exclusion critieria for the sleep
#				disorder and sleep disorder free groups
#
# Inspired and adapted from: 
#				This do file uses the PGF/TikZ package
# 				Author  : Morten Vejs Willert (July 2010)
# 				License : Creative Commons attribution license
*******************************************************************************/

/**** FLOWCHART COMMAND SETUP *********************/
*net get flowchart
flowchart setup, update
flowchart getstarted

/*** SPECIFY COHORTS FOR FLOWCHARTS ***************/
/*options are:
- primary combined (largest study population)
- linked combined (more complete data, minimal difference between cohorts for
each analysis)
- linked aurum only (might not be v different to linked combined)
*/

pause off
foreach medcondition in OSA narcolepsy {
foreach linkedtext in linked primary {
foreach database in combined aurum {
	*do not run for aurum only primary care*/
	*if "`linkedtext'" == "primary" & "`database'" == "aurum" continue
			
	/**** DISPOSITION SUBANALYSIS: ********************/
				
	/***flowchart labels, numbers and boxes for study population*/
	use "$resultdir/9.cr_studypopulation_an_flowchart.dta", clear

	local row1incname: label criterialab 1
	local row1incno = `database'`linkedtext'[1]

	local datarow = 2
	local excno = 1
	local row1exctot = 0
	while `excno' <=6 {
		*if `excno' == 4 & "`linkedtext'" == "primary" continue
		local row1excname`excno': label criterialab `datarow'
		local row1excno`excno' = `database'`linkedtext'[`datarow']
		di `row1excno1'
		local row1exctot = `row1exctot' + `row1excno`excno''
		local datarow = `datarow' + 1
		local excno = `excno' + 1
	}

	local row2incname: label criterialab `datarow'
	local row2incno = `database'`linkedtext'[`datarow']

	di "`medcondition' `linkedtext' `database'"
	di `row1exctot'
	pause

	/***flowchart labels, numbers and boxes for unmatched cohort*/
	use "$resultdir/10.cr_unmatchedcohort_an_flowchart.dta", clear

	/*split into exposed and unexposed
	local row = 3
	local criterianoleft = 3
	local criterianoright = 2 - change this to study population or try to remove
	local inclusion = 1
	include "$dodir/inc_14.an_flowchart_simplerow.do"
	*/
	
	*row 3 left: >= 1 code record
	local datarow = 3
	local row3incname: label criterialab `datarow'
	local row3incno = `database'`linkedtext'`medcondition'[`datarow']


	*row 4: left = index date after end of follow-up/study period, right = index date before start of follow-up	
	local row4leftexcname "Excluded"

	*row 4 exclusions for prevalent and unexposed cohorts
	if "`medcondition'" == "OSA" local excrows = 5
	if "`medcondition'" == "narcolepsy" local excrows = 3
	
	local datarow = 4
	local excno = 1
	local row4leftexctot = 0
	while `excno' <=`excrows' {
		local row4leftexcname`excno': label criterialab `datarow'
		local row4leftexcno`excno' = `database'`linkedtext'`medcondition'[`datarow']
		local row4leftexctot = `row4leftexctot' + `row4leftexcno`excno''
		local datarow = `datarow' + 1
		local excno = `excno' + 1
	}

	local row4rightexcname "Excluded"

	local datarow = 14
	local excno = 1
	local row4rightexctot = 0
	di `row4rightexctot'
	while `excno' <=5 {
		local row4rightexcname`excno': label criterialab `datarow'
		local row4rightexcno`excno' = `database'`linkedtext'`medcondition'[`datarow']
		if `row4rightexcno`excno'' != . local row4rightexctot = `row4rightexctot' + `row4rightexcno`excno''
		local datarow = `datarow' + 1
		local excno = `excno' + 1
	}


	/*row 5: left = Sleep disorder prevalence analysis group, right = sleep disorder free prevalence analysis group*/
	local row = 5
	local criterianoleft = 9
	local criterianoright = 19
	local inclusion = 1
	include "$dodir/inc_14.an_flowchart_simplerow.do"


	/*row 6: left = index date before follow-up start, right = blank*/
	local row6leftexcname "Excluded"

	local datarow = 10
	local excno = 1
	local row6leftexctot = 0
	while `excno' <=2 {
		local row6leftexcname`excno': label criterialab `datarow'
		local row6leftexcno`excno' = `database'`linkedtext'`medcondition'[`datarow']
		local row6leftexctot = `row6leftexctot' + `row6leftexcno`excno''
		local datarow = `datarow' + 1
		local excno = `excno' + 1
	}

	/*row 7: left = Sleep disorder incidence analysis group, right = Sleep disorder free incidence analyis group*/
	local row = 7
	local criterianoleft = 12
	local criterianoright = 19
	local inclusion = 1
	include "$dodir/inc_14.an_flowchart_simplerow.do"

	/*row 8: exclude not matched*/
	use "$resultdir/13.an_matchedcohort_flowchart.dta", clear
	local row = 8
	local criterianoleft = 2
	local criterianoright = 9
	local inclusion = 0
	include "$dodir/inc_14.an_flowchart_simplerow.do"

	/***flowchart labels, numbers and boxes for matched cohort*/

	/*row 9: matched cohort*/
	local row = 9
	local criterianoleft = 3
	local criterianoright = 10
	local inclusion = 1
	include "$dodir/inc_14.an_flowchart_simplerow.do"

	/*row 10: exclude index date after f-up for primary analysis*/
	local row = 10
	local criterianoleft = 4
	local criterianoright = 11
	local inclusion = 0
	include "$dodir/inc_14.an_flowchart_simplerow.do"

	/*row 11: matched cohort for primary analysis*/
	local row = 11
	local criterianoleft = 5
	local criterianoright = 12
	local inclusion = 1
	include "$dodir/inc_14.an_flowchart_simplerow.do"

	if "`linkedtext'" == "linked" {
		/*row 12: exclude not eligible for linkage to other HES datasets*/
		local row = 12
		local criterianoleft = 6
		local criterianoright = 13
		local inclusion = 0
		include "$dodir/inc_14.an_flowchart_simplerow.do"

		/*row 13: matched cohort for additional HES datasets*/
		local row = 13
		local criterianoleft = 7
		local criterianoright = 14
		local inclusion = 1
		include "$dodir/inc_14.an_flowchart_simplerow.do"
	}


	di "second `row1exctot'"
	pause
	
	/**** DIAGRAM:  **************************************/
	* Run this code to produce a similar flowchart to M. Willert's CONSORT-style 
	*   flowchart: http://www.texample.net/tikz/examples/consort-flowchart/
	* It should resemble that flowchart.

	* Initiate a flowchart by specifying the subanalysis data file to write: 


	*flowchart init using "$resultdir/methods--figure-flowchart.data"
	flowchart init using "$resultdir/14.an_flowchart_full_`medcondition'_`database'_`linkedtext'.data"


	* Format: flowchart writerow(rowname): [center-block triplet lines] , [left-block triplet lines]
	*   Triplet Format: "variable_name" n= "Descriptive text."

	flowchart writerow(row1): ///
		"row1start" `row1incno' "`row1incname'", ///
		"row1exc" `row1exctot' "Excluded" ///
			"row1ex1" `row1excno1' "`row1excname1'" ///
			"row1ex2" `row1excno2' "`row1excname2'" ///
			"row1ex3" `row1excno3' "`row1excname3'" ///
			"row1ex4" `row1excno4' "`row1excname4'" ///
			"row1ex5" `row1excno5' "`row1excname5'" ///
			"row1ex6" `row1excno6' "`row1excname6'" 

	flowchart writerow(row2): "row2" `row2incno' "`row2incname'", flowchart_blank // Box with total study population


	/*flowchart writerow(row3): /// split exposed and unexposed
		"row3left" `row3leftno' "`row3leftname'", ///
		"row3right" `row3rightno' "`row3rightname'"*/
	
	flowchart writerow(row3): "row3" `row3incno' "`row3incname'", flowchart_blank // Box with number with coded record
		

	if "`medcondition'" == "OSA" {
	flowchart writerow(row4): /// Exclusions based on index date & follow-up
		"row4leftexc" `row4leftexctot' "`row4leftexcname'" ///
			"row4leftexc1" `row4leftexcno1' "`row4leftexcname1'" ///
			"row4leftexc2" `row4leftexcno2' "`row4leftexcname2'" ///
			"row4leftexc3" `row4leftexcno3' "`row4leftexcname3'" ///
			"row4leftexc4" `row4leftexcno4' "`row4leftexcname4'" ///
			"row4leftexc4" `row4leftexcno5' "`row4leftexcname5'", ///
		"row4rightexctot" `row4rightexctot' "`row4rightexcname'" ///
			"row4rightexc1" `row4rightexcno1' "`row4rightexcname1'" ///
			 "row4rightexc2" `row4rightexcno2' "`row4rightexcname2'" ///
			 "row4rightexc3" `row4rightexcno3' "`row4rightexcname3'" ///
			 "row4rightexc4" `row4rightexcno4' "`row4rightexcname4'" ///
			 "row4rightexc5" `row4rightexcno5' "`row4rightexcname5'"
	}
	
	if "`medcondition'" == "narcolepsy" {
	flowchart writerow(row4): /// Exclusions based on index date & follow-up
		"row4leftexc" `row4leftexctot' "`row4leftexcname'" ///
			"row4leftexc1" `row4leftexcno1' "`row4leftexcname1'" ///
			"row4leftexc2" `row4leftexcno2' "`row4leftexcname2'" ///
			"row4leftexc3" `row4leftexcno3' "`row4leftexcname3'", ///
		"row4rightexctot" `row4rightexctot' "`row4rightexcname'" ///
			"row4rightexc1" `row4rightexcno1' "`row4rightexcname1'" ///
			 "row4rightexc2" `row4rightexcno2' "`row4rightexcname2'" ///
			 "row4rightexc3" `row4rightexcno3' "`row4rightexcname3'"
	}	
		 
	/*flowchart writerow(row5): /// other sleep apnoea
		"row5leftexc" `row5leftexctot' "`row5leftexcname'" ///
			"row5leftexc1" `row5leftexcno1' "`row5leftexcname1'" ///
			"row5leftexc2" `row5leftexcno2' "`row5leftexcname2'", ///
		"row5rightexctot" `row5rightexctot' "`row5rightexcname'" ///
			"row5rightexc1" `row5rightexcno1' "`row5rightexcname1'" */


	flowchart writerow(row5): /// cohort for prevalence analysis
		"row5left" `row5leftno' "`row5leftname'", ///
		"row5right" `row5rightno' "`row5rightname'"
		

	flowchart writerow(row6): /// Exclusions based on diagnosis before index
		"row6leftexc" `row6leftexctot' "`row6leftexcname'" ///
			"row6leftexc1" `row6leftexcno1' "`row6leftexcname1'" ///
			"row6leftexc2" `row6leftexcno2' "`row6leftexcname2'", Flowchart_Blank
			
	flowchart writerow(row7): ///cohort for incidence analysis
		"row7left" `row7leftno' "`row7leftname'", ///
		Flowchart_Blank
		
	flowchart writerow(row8): /// not matched
		"row8left" `row8leftno' "`row8leftname'", ///
		"row8right" `row8rightno' "`row8rightname'"


	if "`linkedtext'" == "primary" local maxrow = 11 /*penultimate row*/
	if "`linkedtext'" == "linked" local maxrow = 13
	forvalues r = 9/`maxrow' {
		flowchart writerow(row`r'): ///
		"row`r'left" `row`r'leftno' "`row`r'leftname'", ///
		"row`r'right" `row`r'rightno' "`row`r'rightname'"
	}



	* Format: rowname_blockorientation rowname_blockorientation
	* This command connects the blocks with arrows by their assigned orientation. 
	*   Use rowname_center for the center-block (first block of triplets), which will appear on the left of the diagram.
	*   Use rowname_left for the left-block (second blow of triplets), which will appear on the right of the diagram.


	flowchart connect row1_center row1_left
	flowchart connect row1_center row2_center
	flowchart connect row2_center row3_center
	
	flowchart connect row3_center row4_center
	flowchart connect row2_center row4_left, arrow(angled)
	
	if "`linkedtext'" == "primary" local penrow = 10 /*penultimate row*/
	if "`linkedtext'" == "linked" local penrow = 12
	local row = 4
	while `row' <= `penrow' {
		local nextrow = `row' + 1
		flowchart connect row`row'_center row`nextrow'_center
		if `row' == 5 flowchart connect row5_left row8_left 
		if `row' < 5 | `row' > 7 flowchart connect row`row'_left row`nextrow'_left
		local row = `nextrow'
		}

	*flowchart finalize, template("$metadir/14.an_flowchart_full.tex") output("$resultdir/14.an_flowchart_full.tikz")

	flowchart finalize, template("$dodir/14.an_flowchart_full.texdoc") output("$resultdir/14.an_flowchart_full_`medcondition'_`database'_`linkedtext'.tikz")
	pause
}
}
}

	describe using "$resultdir\9.cr_studypopulation_an_flowchart.dta"
	notes

	describe using "$datadir_dm/9.cr_studypopulation_an_flowchart_aurum.dta"
	notes

	describe using "$resultdir/13.an_matchedcohort_flowchart.dta"
	notes

* Now, using LaTeX, compile the manuscript.tex file -- This file is already setup to tie all of these files together.
* REMEMBER TO 
* (1) FIND "DOLSIGN" IN TIKZ FILE AND REPLACE WITH "$" 
* (2) FIND "sleep disorder" IN TIKZ FILE AND REPLACE WITH "OSA" or "narcolepsy"
* (3) Specify narcolepsy or OSA in 3 places in the tex file 
*   This file shows you how you would use \input{} to include the new .tikz file as a figure diagram into a 'figure' tex LaTeX document.
*   The preamble in the ancillary manuscript file is a guide on which packages and commands to include in your LaTeX setup.

* THEN RECOMPILE MANUSCRIPT.TEX

/*uploaded files from results file and working directory to overleaf project. compiled manuscript.tex*/

