
/*********************************************************
# Stata do file:    0.markdown_setup.do
#
# Author:      Helen Strongman
#
# Date:        09/11/2022
#
# Description: Copy markdown settings files to metadata folder.
#				These are needed to format the HTML output for Github
#
#
# Inspired and adapted from: 
# 				N/A
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
to add it before and after each header.

Error messages: these sometimes apply to a much later line of text than first
appears.

error message "attribute : not valid in dd_do tag" appears when an attribute 
(e.g. quietly or nocommands) has been specified
*/