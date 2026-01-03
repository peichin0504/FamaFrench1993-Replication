/*==============================================================================
    02_summary_statistics.do
    
    Purpose: Generate summary stats (trying to replicate parts of Table 2)
    
    Table 2 in FF1993 has:
    - Mean returns and standard deviations
    - Autocorrelations
    - Correlations among factors
==============================================================================*/

use "$root/data/processed/merged_data.dta", clear

/*------------------------------------------------------------------------------
    Part 1: Summary Stats for the 25 Portfolios (Table 2a style)
------------------------------------------------------------------------------*/

// Set up matrices to store our results
matrix means = J(5, 5, .)
matrix sds = J(5, 5, .)
matrix tstats = J(5, 5, .)

// Loop through each portfolio and calculate mean, sd, t-stat
forvalues size = 1/5 {
    forvalues bm = 1/5 {
        quietly summarize exret`size'`bm'
        local mean = r(mean)
        local sd = r(sd)
        local n = r(N)
        local tstat = `mean' / (`sd' / sqrt(`n'))
        
        matrix means[`size', `bm'] = `mean'
        matrix sds[`size', `bm'] = `sd'
        matrix tstats[`size', `bm'] = `tstat'
    }
}

// Add labels to make the output readable
matrix colnames means = "Low" "2" "3" "4" "High"
matrix rownames means = "Small" "2" "3" "4" "Big"
matrix colnames sds = "Low" "2" "3" "4" "High"
matrix rownames sds = "Small" "2" "3" "4" "Big"
matrix colnames tstats = "Low" "2" "3" "4" "High"
matrix rownames tstats = "Small" "2" "3" "4" "Big"

// Show the results
di _newline(2) "=" * 70
di "TABLE 2a: Mean Monthly Excess Returns (in percent)"
di "25 Portfolios Formed on Size and Book-to-Market"
di "=" * 70
matrix list means, format(%6.2f)

di _newline(2) "=" * 70
di "Standard Deviations of Monthly Excess Returns"
di "=" * 70
matrix list sds, format(%6.2f)

di _newline(2) "=" * 70
di "t-statistics for Mean Returns"
di "=" * 70
matrix list tstats, format(%6.2f)

/*------------------------------------------------------------------------------
    Part 2: Summary Stats for the Factors (Table 2b style)
------------------------------------------------------------------------------*/

di _newline(2) "=" * 70
di "TABLE 2b: Summary Statistics for Explanatory Variables"
di "=" * 70

// Quick summary of all factors
summarize mktrf smb hml rf

// Now let's make a nicer table
di _newline "Detailed Factor Statistics:"
di "-" * 60

foreach var in mktrf smb hml rf {
    quietly summarize `var'
    local mean = r(mean)
    local sd = r(sd)
    local n = r(N)
    local tstat = `mean' / (`sd' / sqrt(`n'))
    
    di "`var':"
    di "  Mean     = " %8.4f `mean'
    di "  Std Dev  = " %8.4f `sd'
    di "  t-stat   = " %8.2f `tstat'
    di ""
}

/*------------------------------------------------------------------------------
    Part 3: Autocorrelations (from Table 2)
------------------------------------------------------------------------------*/

di _newline(2) "=" * 70
di "Autocorrelations of Factors"
di "=" * 70

// Check autocorrelation for each factor
foreach var in mktrf smb hml rf {
    di _newline "`var':"
    corrgram `var', lags(12) noplot
}

/*------------------------------------------------------------------------------
    Part 4: Correlation Matrix (Table 2)
------------------------------------------------------------------------------*/

di _newline(2) "=" * 70
di "TABLE 2c: Correlations among Explanatory Variables"
di "=" * 70

correlate mktrf smb hml

/*------------------------------------------------------------------------------
    Part 5: Export Results to CSV for later use
------------------------------------------------------------------------------*/

// Export the mean returns matrix
preserve
clear
svmat means, names(bm)
gen size = _n
label define size_lbl 1 "Small" 2 "2" 3 "3" 4 "4" 5 "Big", replace
label values size size_lbl
order size
export delimited using "$root/output/tables/table2_mean_returns.csv", replace
restore

// Export standard deviations too
preserve
clear
svmat sds, names(bm)
gen size = _n
order size
export delimited using "$root/output/tables/table2_std_dev.csv", replace
restore

/*------------------------------------------------------------------------------
    Part 6: Extra Stats - Average Returns by Size and BM Groups
------------------------------------------------------------------------------*/

di _newline(2) "=" * 70
di "Average Returns by Size Quintile (across BM)"
di "=" * 70

// For each size group, average across all BM quintiles
forvalues size = 1/5 {
    egen avg_size`size' = rowmean(exret`size'1 exret`size'2 exret`size'3 exret`size'4 exret`size'5)
    quietly summarize avg_size`size'
    di "Size `size': Mean = " %6.3f r(mean) ", SD = " %6.3f r(sd)
}

di _newline(2) "=" * 70
di "Average Returns by BM Quintile (across Size)"
di "=" * 70

// For each BM group, average across all size quintiles
forvalues bm = 1/5 {
    egen avg_bm`bm' = rowmean(exret1`bm' exret2`bm' exret3`bm' exret4`bm' exret5`bm')
    quietly summarize avg_bm`bm'
    di "BM `bm': Mean = " %6.3f r(mean) ", SD = " %6.3f r(sd)
}

/*------------------------------------------------------------------------------
    Part 7: Check Size and Value Spreads
------------------------------------------------------------------------------*/

di _newline(2) "=" * 70
di "Size and Value Spreads"
di "=" * 70

// SMB-like spread: Small stocks minus Big stocks (averaged across BM)
gen smb_check = avg_size1 - avg_size5
summarize smb smb_check
di "Correlation between SMB factor and computed spread:"
correlate smb smb_check

// HML-like spread: High BM minus Low BM (averaged across Size)
gen hml_check = avg_bm5 - avg_bm1
summarize hml hml_check
di "Correlation between HML factor and computed spread:"
correlate hml hml_check

di _newline "Done with summary statistics!"
