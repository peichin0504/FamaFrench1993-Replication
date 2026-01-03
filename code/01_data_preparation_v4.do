/*==============================================================================
    01_data_preparation_v4.do
    
    Purpose: Import and prep the data for Fama-French (1993) replication
    
    Note: The 25 Portfolios file from Ken French has multiple sections in it:
    - Value-weighted returns (this is what we need)
    - Equal-weighted returns
    - Other stuff
    We're just grabbing the first section (value-weighted).
==============================================================================*/

clear all
set more off

// Main project directory
global root "/Users/pei-chin/Research/FamaFrench_1993_Replication"

// Make sure we have the folders we need
cap mkdir "$root/data"
cap mkdir "$root/data/processed"

/*------------------------------------------------------------------------------
    Step 1: Import the 25 Portfolios (Value-Weighted Section Only)
------------------------------------------------------------------------------*/

di ""
di "======================================================================"
di "Step 1: Loading 25 Portfolios data..."
di "======================================================================"

// First let's see what the file structure looks like
import delimited "$root/data/raw/25_Portfolios_5x5.csv", clear stringcols(_all) varnames(nonames)

// Try to find rows that are section headers (they have text instead of numbers)
// Look for words like "Equal" or "Annual" - those mark new sections
gen rownum = _n
gen is_header = regexm(v1, "[A-Za-z]")
gen is_date = regexm(v1, "^[0-9]{6}$")

// Show me which rows might be section breaks
di "These rows might be section headers:"
list rownum v1 v2 if is_header == 1 & rownum > 10 in 1/50

// Find where the first section ends
summarize rownum if is_header == 1 & rownum > 15
local section_end = r(min) - 1

di ""
di "First data section looks like it ends at row: `section_end'"

// OK now let's import just the value-weighted part
clear
import delimited "$root/data/raw/25_Portfolios_5x5.csv", clear rowrange(11:`section_end') varnames(10)

// Rename the first variable to yyyymm for date
ds
local allvars `r(varlist)'
local firstvar : word 1 of `allvars'
rename `firstvar' yyyymm

// Clean up the date variable
destring yyyymm, replace force
drop if yyyymm == .
drop if yyyymm < 100000  // Remove weird values

// Check if we have any duplicate dates (shouldn't happen but let's verify)
duplicates report yyyymm
duplicates list yyyymm if yyyymm != .

// Now rename the 25 portfolio columns
ds yyyymm, not
local portvars `r(varlist)'
local nvars : word count `portvars'
di "Number of portfolio variables found: `nvars'"

// Loop through and rename as p11, p12, ... p55
local i = 1
foreach var of local portvars {
    local size = ceil(`i'/5)
    local bm = `i' - (`size'-1)*5
    rename `var' p`size'`bm'
    local i = `i' + 1
}

// Convert to numeric and clean
foreach var of varlist p* {
    cap destring `var', replace force
}

// Get rid of obvious missing value codes
foreach var of varlist p* {
    replace `var' = . if `var' < -90
}

// Create proper date variables for Stata
gen year = floor(yyyymm/100)
gen month = yyyymm - year*100
gen date = ym(year, month)
format date %tm

sort date

// Make sure dates are unique
isid date
di "Portfolio data loaded: " _N " observations (unique by date)"
di "Date range goes from: " yyyymm[1] " to " yyyymm[_N]

// Save this temporarily
save "$root/data/processed/portfolios_temp.dta", replace

/*------------------------------------------------------------------------------
    Step 2: Import Fama-French Factor Data
------------------------------------------------------------------------------*/

di ""
di "======================================================================"
di "Step 2: Loading Fama-French Factors..."
di "======================================================================"

clear
import delimited "$root/data/raw/F-F_Research_Data_Factors.csv", clear rowrange(5) varnames(4)

// Rename first variable to date
ds
local allvars `r(varlist)'
local firstvar : word 1 of `allvars'
rename `firstvar' yyyymm

// Clean the date variable
destring yyyymm, replace force
drop if yyyymm == .
drop if yyyymm < 100000
drop if yyyymm > 209912  // Keep it reasonable

// Convert factor variables to numeric
foreach var in mktrf smb hml rf {
    cap destring `var', replace force
    cap replace `var' = . if `var' < -90  // Remove missing codes
}

// Make Stata date variables
gen year = floor(yyyymm/100)
gen month = yyyymm - year*100
gen date = ym(year, month)
format date %tm

keep date yyyymm year month mktrf smb hml rf
sort date

// Check for duplicate dates here too
duplicates report date
bysort date: keep if _n == 1  // Just keep first if duplicates exist

di "Factor data loaded: " _N " observations"

/*------------------------------------------------------------------------------
    Step 3: Merge the Two Datasets Together
------------------------------------------------------------------------------*/

di ""
di "======================================================================"
di "Step 3: Merging the datasets..."
di "======================================================================"

merge 1:1 date using "$root/data/processed/portfolios_temp.dta", nogen keep(match)
sort date

di "Merged dataset has: " _N " observations"
di "Date range: " %tm date[1] " to " %tm date[_N]

// Clean up temporary file
cap erase "$root/data/processed/portfolios_temp.dta"

/*------------------------------------------------------------------------------
    Step 4: Calculate Excess Returns for Portfolios
------------------------------------------------------------------------------*/

di ""
di "======================================================================"
di "Step 4: Calculating excess returns..."
di "======================================================================"

// Create excess return = portfolio return - risk free rate
forvalues size = 1/5 {
    forvalues bm = 1/5 {
        gen exret`size'`bm' = p`size'`bm' - rf
    }
}

di "Created 25 excess return variables"

/*------------------------------------------------------------------------------
    Step 5: Save the Final Clean Dataset
------------------------------------------------------------------------------*/

order date yyyymm year month mktrf smb hml rf p* exret*
compress
save "$root/data/processed/merged_data.dta", replace

/*------------------------------------------------------------------------------
    Step 6: Print Summary Info
------------------------------------------------------------------------------*/

di ""
di "======================================================================"
di "DATA PREP DONE!"
di "======================================================================"
di ""
di "Saved to: $root/data/processed/merged_data.dta"
di "Sample period: " %tm date[1] " to " %tm date[_N]
di "Total months: " _N
di ""
di "Factor Summary Stats:"
summarize mktrf smb hml rf

di ""
di "Portfolio Excess Returns (just the corners):"
summarize exret11 exret15 exret51 exret55

di ""
di "======================================================================"
