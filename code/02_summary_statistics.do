/*==============================================================================
    02_summary_statistics.do
    
    Purpose: Replicate Fama-French (1993) Table 2
             Summary statistics for 25 portfolios and factors
    
    Input:  merged_data.dta
    Output: Summary statistics tables
==============================================================================*/

clear all
set more off

global root "/Users/pei-chin/Research/FamaFrench_1993_Replication"

* Create output directory
cap mkdir "$root/output"
cap mkdir "$root/output/tables"

* Load data
use "$root/data/processed/merged_data.dta", clear

di ""
di "======================================================================"
di "SUMMARY STATISTICS - Replicating Table 2"
di "======================================================================"
di ""
di "Sample period: " %tm date[1] " to " %tm date[_N]
di "Number of months: " _N
di "======================================================================"

/*------------------------------------------------------------------------------
    1. Factor Summary Statistics
------------------------------------------------------------------------------*/

di ""
di "======================================================================"
di "Part 1: Factor Summary Statistics"
di "======================================================================"
di ""

* Calculate statistics for each factor
* Note: Going through the basic factors first
foreach var in mktrf smb hml rf {
    qui sum `var'  // shortened quietly for readability
    local mean_`var' = r(mean)
    local sd_`var' = r(sd)
    local n_`var' = r(N)
    local tstat_`var' = `mean_`var'' / (`sd_`var'' / sqrt(`n_`var''))
}

di "Factor         Mean     Std Dev    t-stat     N"
di "------------------------------------------------------"
di "Mkt-RF      " %8.3f `mean_mktrf' "   " %8.3f `sd_mktrf' "   " %6.2f `tstat_mktrf' "   " `n_mktrf'
di "SMB         " %8.3f `mean_smb' "   " %8.3f `sd_smb' "   " %6.2f `tstat_smb' "   " `n_smb'
di "HML         " %8.3f `mean_hml' "   " %8.3f `sd_hml' "   " %6.2f `tstat_hml' "   " `n_hml'
di "RF          " %8.3f `mean_rf' "   " %8.3f `sd_rf' "   " %6.2f `tstat_rf' "   " `n_rf'
di "------------------------------------------------------"

/*------------------------------------------------------------------------------
    2. Portfolio Mean Excess Returns (5x5 Matrix)
------------------------------------------------------------------------------*/

di ""
di "======================================================================"
di "Part 2: Mean Excess Returns (% per month)"
di "======================================================================"
di ""
di "Rows = Size (1=Small to 5=Big)"
di "Cols = Book-to-Market (1=Low/Growth to 5=High/Value)"
di ""

* Create matrix for mean returns
matrix mean_ret = J(5, 5, .)

// Loop through all portfolio combinations
forvalues size = 1/5 {
    forvalues bm = 1/5 {
        qui sum exret`size'`bm'
        matrix mean_ret[`size', `bm'] = r(mean)
    }
}

* Display matrix nicely formatted
di "            Low BM    BM2       BM3       BM4     High BM"
di "          (Growth)                               (Value)"
di "--------------------------------------------------------------"
forvalues size = 1/5 {
    // Create size labels - probably could clean this up but works for now
    if `size'==1 {
        local size_label = "Small"
    }
    else if `size'==5 {
        local size_label = "Big  "
    }
    else {
        local size_label = "Size`size'"
    }
    di "`size_label'" _col(12) %8.3f mean_ret[`size',1] %8.3f mean_ret[`size',2] %8.3f mean_ret[`size',3] %8.3f mean_ret[`size',4] %8.3f mean_ret[`size',5]
}
di "--------------------------------------------------------------"

* Calculate row and column averages - let's see patterns
di ""
di "Average by Size (across all B/M):"
forvalues size = 1/5 {
    local rowsum = 0
    forvalues bm = 1/5 {
        local rowsum = `rowsum' + mean_ret[`size', `bm']
    }
    local rowavg = `rowsum' / 5
    if `size'==1 {
        local size_label = "Small"
    }
    else if `size'==5 {
        local size_label = "Big"
    }
    else {
        local size_label = "Size`size'"
    }
    di "  `size_label': " %8.3f `rowavg'
}

di ""
di "Average by B/M (across all Size):"
forvalues bm = 1/5 {
    local colsum = 0
    forvalues size = 1/5 {
        local colsum = `colsum' + mean_ret[`size', `bm']
    }
    local colavg = `colsum' / 5
    if `bm'==1 {
        local bm_label = "Low BM"
    }
    else if `bm'==5 {
        local bm_label = "High BM"
    }
    else {
        local bm_label = "BM`bm'"
    }
    di "  `bm_label': " %8.3f `colavg'
}

/*------------------------------------------------------------------------------
    3. Portfolio Standard Deviations (5x5 Matrix)
------------------------------------------------------------------------------*/

di ""
di "======================================================================"
di "Part 3: Standard Deviations of Excess Returns (% per month)"
di "======================================================================"
di ""

matrix sd_ret = J(5, 5, .)

forvalues size = 1/5 {
    forvalues bm = 1/5 {
        qui sum exret`size'`bm'
        matrix sd_ret[`size', `bm'] = r(sd)
    }
}

di "            Low BM    BM2       BM3       BM4     High BM"
di "--------------------------------------------------------------"
forvalues size = 1/5 {
    if `size'==1 {
        local size_label = "Small"
    }
    else if `size'==5 {
        local size_label = "Big  "
    }
    else {
        local size_label = "Size`size'"
    }
    di "`size_label'" _col(12) %8.3f sd_ret[`size',1] %8.3f sd_ret[`size',2] %8.3f sd_ret[`size',3] %8.3f sd_ret[`size',4] %8.3f sd_ret[`size',5]
}
di "--------------------------------------------------------------"

/*------------------------------------------------------------------------------
    4. t-Statistics for Mean Returns
------------------------------------------------------------------------------*/

di ""
di "======================================================================"
di "Part 4: t-Statistics for Mean Excess Returns"
di "======================================================================"
di ""
di "(Testing H0: mean = 0)"
di ""

matrix tstat_ret = J(5, 5, .)
local T = _N  // Total number of observations

// Computing t-stats for each portfolio
forvalues size = 1/5 {
    forvalues bm = 1/5 {
        local tstat = mean_ret[`size', `bm'] / (sd_ret[`size', `bm'] / sqrt(`T'))
        matrix tstat_ret[`size', `bm'] = `tstat'
    }
}

di "            Low BM    BM2       BM3       BM4     High BM"
di "--------------------------------------------------------------"
forvalues size = 1/5 {
    if `size'==1 {
        local size_label = "Small"
    }
    else if `size'==5 {
        local size_label = "Big  "
    }
    else {
        local size_label = "Size`size'"
    }
    di "`size_label'" _col(12) %8.2f tstat_ret[`size',1] %8.2f tstat_ret[`size',2] %8.2f tstat_ret[`size',3] %8.2f tstat_ret[`size',4] %8.2f tstat_ret[`size',5]
}
di "--------------------------------------------------------------"

/*------------------------------------------------------------------------------
    5. Size and Value Spreads
------------------------------------------------------------------------------*/

di ""
di "======================================================================"
di "Part 5: Size and Value Spreads"
di "======================================================================"
di ""

* SMB-like spread: Average Small - Average Big
* Calculate average for small stocks (size quintile 1)
local small_avg = (mean_ret[1,1] + mean_ret[1,2] + mean_ret[1,3] + mean_ret[1,4] + mean_ret[1,5]) / 5
* Calculate average for big stocks (size quintile 5)
local big_avg = (mean_ret[5,1] + mean_ret[5,2] + mean_ret[5,3] + mean_ret[5,4] + mean_ret[5,5]) / 5
local size_spread = `small_avg' - `big_avg'

di "Size Spread (Small - Big):"
di "  Average Small portfolio return: " %8.3f `small_avg'
di "  Average Big portfolio return:   " %8.3f `big_avg'
di "  Size spread:                    " %8.3f `size_spread'

di ""

* HML-like spread: Average High BM - Average Low BM
local highbm_avg = (mean_ret[1,5] + mean_ret[2,5] + mean_ret[3,5] + mean_ret[4,5] + mean_ret[5,5]) / 5
local lowbm_avg = (mean_ret[1,1] + mean_ret[2,1] + mean_ret[3,1] + mean_ret[4,1] + mean_ret[5,1]) / 5
local value_spread = `highbm_avg' - `lowbm_avg'

di "Value Spread (High B/M - Low B/M):"
di "  Average High B/M portfolio return: " %8.3f `highbm_avg'
di "  Average Low B/M portfolio return:  " %8.3f `lowbm_avg'
di "  Value spread:                      " %8.3f `value_spread'

/*------------------------------------------------------------------------------
    6. Factor Correlations
------------------------------------------------------------------------------*/

di ""
di "======================================================================"
di "Part 6: Factor Correlations"
di "======================================================================"
di ""

// Check how factors correlate with each other
corr mktrf smb hml

/*------------------------------------------------------------------------------
    7. Export Results to CSV
------------------------------------------------------------------------------*/

di ""
di "======================================================================"
di "Exporting results to CSV..."
di "======================================================================"

* Export mean returns matrix
preserve
clear
set obs 5
gen size = _n
gen lowbm = .
gen bm2 = .
gen bm3 = .
gen bm4 = .
gen highbm = .

// Fill in the values from our matrix
forvalues size = 1/5 {
    replace lowbm = mean_ret[`size', 1] if size == `size'
    replace bm2 = mean_ret[`size', 2] if size == `size'
    replace bm3 = mean_ret[`size', 3] if size == `size'
    replace bm4 = mean_ret[`size', 4] if size == `size'
    replace highbm = mean_ret[`size', 5] if size == `size'
}

label define size_lbl 1 "Small" 2 "Size2" 3 "Size3" 4 "Size4" 5 "Big"
label values size size_lbl

export delimited "$root/output/tables/table2_mean_returns.csv", replace
restore

* Export standard deviations matrix
preserve
clear
set obs 5
gen size = _n
gen lowbm = .
gen bm2 = .
gen bm3 = .
gen bm4 = .
gen highbm = .

forvalues size = 1/5 {
    replace lowbm = sd_ret[`size', 1] if size == `size'
    replace bm2 = sd_ret[`size', 2] if size == `size'
    replace bm3 = sd_ret[`size', 3] if size == `size'
    replace bm4 = sd_ret[`size', 4] if size == `size'
    replace highbm = sd_ret[`size', 5] if size == `size'
}

export delimited "$root/output/tables/table2_std_dev.csv", replace
restore

di ""
di "======================================================================"
di "SUMMARY STATISTICS COMPLETE!"
di "======================================================================"
di ""
di "Key Findings:"
di "1. Size Effect: Small stocks earn " %5.3f `size_spread' "% more per month than big stocks"
di "2. Value Effect: High B/M stocks earn " %5.3f `value_spread' "% more per month than low B/M"
di ""
di "Output files:"
di "  - $root/output/tables/table2_mean_returns.csv"
di "  - $root/output/tables/table2_std_dev.csv"
di "======================================================================"