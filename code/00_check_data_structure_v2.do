/*==============================================================================
    00_check_data_structure.do 
    
    Purpose: Quick diagnostic check of CSV file structure before importing
    
    NOTE: Run this first to see what we're dealing with!
==============================================================================*/

clear all
set more off

// Setting up the main project folder path
global root "/Users/pei-chin/Research/FamaFrench_1993_Replication"

/*------------------------------------------------------------------------------
    Part 1: Checking the 25 Portfolios File
------------------------------------------------------------------------------*/

di ""
di ""
di "======================================================================"
di "NOW CHECKING: 25_Portfolios_5x5.csv"
di "======================================================================"

// Import everything as strings first - easier to see what's going on
import delimited "$root/data/raw/25_Portfolios_5x5.csv", clear stringcols(_all) varnames(nonames)

// Let's see what variables we got
describe, short

// Display the first bunch of rows so we can eyeball the structure
di ""
di "Here are the first 20 rows:"
list v1 v2 v3 v4 v5 in 1/20, clean noobs

// Just checking how many rows total
di ""
di "Total number of rows: " _N

/*------------------------------------------------------------------------------
    Part 2: Now Let's Check the Factors File
------------------------------------------------------------------------------*/

di ""
di ""
di "======================================================================"
di "NOW CHECKING: F-F_Research_Data_Factors.csv"
di "======================================================================"

// Same approach - import as strings to see the raw data
import delimited "$root/data/raw/F-F_Research_Data_Factors.csv", clear stringcols(_all) varnames(nonames)

// Show me the first 20 rows again
di ""
di "First 20 rows look like this:"
list v1 v2 v3 v4 v5 in 1/20, clean noobs

// Total row count
di ""
di "Total number of rows: " _N

/*------------------------------------------------------------------------------
    Part 3: What to Do Next
------------------------------------------------------------------------------*/

di ""
di ""
di "======================================================================"
di "WHAT I NEED TO DO NEXT:"
di "======================================================================"
di "1. Check the output above and figure out:"
di "   - Where are the actual column headers?"
di "   - What row does the real data start on?"
di ""
di "2. Once know that, fix the import script"
di "======================================================================"
