

/*******************************************************************************
# Stata do file:    0.inc_longshortlabels.do
#
# Author:      Helen Strongman
#
# Date:        31/08/2022
#
# Description: 	This inclusion do file is used in multiple do files. It 
#				replaces short value labels with long value labels and vice
#				versa.
#
# Locals needed: categoryshort or categorylong, direction
#
# Inspired and adapted from: 
# 				Krishan Bhaskaran's do files linking locals to graph titles.
*******************************************************************************/



if "`direction'" == "shorttolong" {
	if "`categoryshort'"=="narcolepsy" local categorylong = "Narcolepsy"
	if "`categoryshort'"=="cataplexy" local categorylong = "Cataplexy only"
	
	if "`categoryshort'"=="OSA" local categorylong = "Obstructive Sleep Apnoea"
	if "`categoryshort'"=="OSAS" local categorylong = "Obstructive sleep apnoea syndrome"
	if "`categoryshort'"=="SA" local categorylong = "Sleep apnoea NOS"
	if "`categoryshort'"=="SAS" local categorylong =  "Sleep apnoea syndrome NOS"
	if "`categoryshort'"=="central" local categorylong = "Central sleep apnoea"
	if "`categoryshort'"=="primary" local categorylong = "Primary sleep apnoea"
	}

if "`direction'" == "longtoshort" {
	if "`categorylong'"=="Narcolepsy" local categoryshort = "narcolepsy"
	if "`categorylong'"=="Cataplexy only" local categoryshort = "cataplexy"
	
	if "`categorylong'"=="Obstructive Sleep Apnoea" local categoryshort = "OSA"
	if "`categorylong'"=="Obstructive sleep apnoea syndrome" local categoryshort = "OSAS"
	if "`categorylong'"=="Sleep apnoea NOS" local categoryshort = "SA"
	if "`categorylong'"=="Sleep apnoea syndrome NOS" local categoryshort = "SAS"
	if "`categorylong'"=="Central sleep apnoea" local categoryshort = "central"
	if "`categorylong'"=="Primary sleep apnoea" local categoryshort = "primary"
	}


