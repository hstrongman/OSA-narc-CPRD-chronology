# Codelists, data management and analysis scripts for OSA and narcolepsy studies

## Purpose

Project: Chronology of healthcare resource use and comorbidities in people with obstructive sleep apnoea and narcolepsy before and after diagnosis: a descriptive study
Protocol: The protocol for this project has been approved through CPRD's Research Data Governance process (https://github.com/user-attachments/assets/669f07ea-297a-4799-9259-7e85f6b009c6). The porocol is registered here: (https://osf.io/f5ukw)
Funder: Helen Strongman, NIHR Advanced Fellowship NIHR301730, is funded by the National Institute for Health and Care Research (NIHR) for this research project. The views expressed in associated publications are those of the author(s) and not necessarily those of the NIHR, NHS or the UK Department of Health and Social Care (https://github.com/user-attachments/assets/b597ec50-84f4-4041-9953-d7447c5cc57f)
(https://fundingawards.nihr.ac.uk/award/NIHR301730). 

This repository will be updated as components of this protocol and completed and published as pre-prints and peer-reviewed manuscripts. DOIs will be available following peer-review.
There is a separate repository for the validation study as this was completed using a different CPRD database release (hstrongman/OSA-narc-CPRD-validation).

## Untracked files
Repositories should only contain non-disclosive files, that is, code without file paths, and summary statistics. This template is set up so only files that are safe to upload to Github, such as code, are uploaded by default. This means all files ending in `.csv`, all Stata output, and all files in the `data/` and `paths/` folders (except README) are untracked, i.e. they will not be uploaded to GitHub. Edit the `.gitignore` file to ignore or allow (with `!`) specific files or file types. 

## File tree
We recommend that you use this file structure as the `.gitignore` is set up to ignore specific folders. You can add subfolders as needed, for example for different types of outputs (logs, images, tables), or remove folders that are not used. 


```
template-stata/
├── codelists/
│   ├── README.md
│   ├── codelist_1.csv
│   └── codelist_1_metadata.txt
├── data/
│   ├── README.md
│   ├── cleaned_data_1.csv (untracked)
│   └── cleaned_data_2.csv (untracked)
├── docs/
│   ├── README.md
│   ├── document1.docx
│   ├── document1.html
│   └── document1.Rmd
├── paths/
│   ├── README.md
│   └── paths.do (untracked)
├── results/
│   ├── README.md
│   └── result_1.csv
├── do-files/
│   ├── README.md
│   ├── script1.do
│   └── script2.do
├── logs/
│   ├── README.md
│   ├── log1.log
│   └── log2.log
└── README.md
```

## Publishing the repository
Once you are ready to make the contents of this repository public:
1. Create a new repository, e.g. "study_name_public"
2. Copy the contents of this private repository to the new repository (make sure to copy the .gitignore file, but do not copy the hidden .git folder; what is hidden may vary by operating system)
3. Before publishing the new repository make sure it doesn't contain:
	* any raw data
	* any derrived data (e.g. cleaned intermediate data)
	* any disclosive results
	* any file paths to locations on secure network drives
4. Commit the changes and publish the new repository (e.g. in Github Desktop first "Commit to main", then "Publish repository" and untick "Keep this code private"
5. See [this guide](https://docs.github.com/en/repositories/archiving-a-github-repository/referencing-and-citing-content) on issuing a DOI and making your new public repository citable 
