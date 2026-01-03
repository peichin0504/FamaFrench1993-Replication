/*==============================================================================
    03_capm_regressions.do
    
    Purpose: Replicate Fama-French (1993) Table 4
             Running CAPM regressions for the 25 portfolios
             
    Model: R(i,t) - RF(t) = alpha(i) + beta(i) * [RM(t) - RF(t)] + e(i,t)
    
    Input:  merged_data.dta
    Output: CAPM regression results
==============================================================================*/

clear all
set more off

global root "/Users/pei-chin/Research/FamaFrench_1993_Replication"

// Load the merged data
use "$root/data/processed/merged_data.dta", clear

di ""
di "======================================================================"
di "CAPM REGRESSIONS - Replicating Table 4"
di "======================================================================"
di ""
di "Model: Excess Return = alpha + beta * (Mkt-RF) + error"
di ""
di "Sample period: " %tm date[1] " to " %tm date[_N]
di "Number of months: " _N
di "======================================================================"

/*------------------------------------------------------------------------------
    Step 1: Run CAPM Regressions for All 25 Portfolios
------------------------------------------------------------------------------*/

// Set up matrices to store our results
matrix alpha_capm = J(5, 5, .)
matrix beta_capm = J(5, 5, .)
matrix tstat_alpha = J(5, 5, .)
matrix tstat_beta = J(5, 5, .)
matrix rsq_capm = J(5, 5, .)
matrix se_capm = J(5, 5, .)

// Run the regressions and store results
forvalues size = 1/5 {
    forvalues bm = 1/5 {
        quietly regress exret`size'`bm' mktrf
        
        // Store the coefficients and stats
        matrix alpha_capm[`size', `bm'] = _b[_cons]
        matrix beta_capm[`size', `bm'] = _b[mktrf]
        matrix tstat_alpha[`size', `bm'] = _b[_cons] / _se[_cons]
        matrix tstat_beta[`size', `bm'] = _b[mktrf] / _se[mktrf]
        matrix rsq_capm[`size', `bm'] = e(r2)
        matrix se_capm[`size', `bm'] = e(rmse)
    }
}

/*------------------------------------------------------------------------------
    Step 2: Show Beta Results
------------------------------------------------------------------------------*/

di ""
di "======================================================================"
di "Part 1: CAPM Betas"
di "======================================================================"
di ""
di "            Low BM    BM2       BM3       BM4     High BM"
di "          (Growth)                               (Value)"
di "--------------------------------------------------------------"
forvalues size = 1/5 {
    local size_label = cond(`size'==1, "Small", cond(`size'==5, "Big  ", "Size`size'"))
    di "`size_label'" _col(12) %8.3f beta_capm[`size',1] %8.3f beta_capm[`size',2] %8.3f beta_capm[`size',3] %8.3f beta_capm[`size',4] %8.3f beta_capm[`size',5]
}
di "--------------------------------------------------------------"

/*------------------------------------------------------------------------------
    Step 3: Show Alpha Results (This is the key part!)
------------------------------------------------------------------------------*/

di ""
di "======================================================================"
di "Part 2: CAPM Alphas (Intercepts) - % per month"
di "======================================================================"
di ""
di "If CAPM works, all alphas should be close to zero."
di ""
di "            Low BM    BM2       BM3       BM4     High BM"
di "--------------------------------------------------------------"
forvalues size = 1/5 {
    local size_label = cond(`size'==1, "Small", cond(`size'==5, "Big  ", "Size`size'"))
    di "`size_label'" _col(12) %8.3f alpha_capm[`size',1] %8.3f alpha_capm[`size',2] %8.3f alpha_capm[`size',3] %8.3f alpha_capm[`size',4] %8.3f alpha_capm[`size',5]
}
di "--------------------------------------------------------------"

/*------------------------------------------------------------------------------
    Step 4: t-Statistics for the Alphas
------------------------------------------------------------------------------*/

di ""
di "======================================================================"
di "Part 3: t-Statistics for Alphas"
di "======================================================================"
di ""
di "(|t| > 1.96 means significant at 5% level)"
di ""
di "            Low BM    BM2       BM3       BM4     High BM"
di "--------------------------------------------------------------"
forvalues size = 1/5 {
    local size_label = cond(`size'==1, "Small", cond(`size'==5, "Big  ", "Size`size'"))
    di "`size_label'" _col(12) %8.2f tstat_alpha[`size',1] %8.2f tstat_alpha[`size',2] %8.2f tstat_alpha[`size',3] %8.2f tstat_alpha[`size',4] %8.2f tstat_alpha[`size',5]
}
di "--------------------------------------------------------------"

// Count how many alphas are statistically significant
local sig_count = 0
forvalues size = 1/5 {
    forvalues bm = 1/5 {
        if abs(tstat_alpha[`size', `bm']) > 1.96 {
            local sig_count = `sig_count' + 1
        }
    }
}
di ""
di "Number of significant alphas (|t| > 1.96): `sig_count' out of 25"
di "(By pure chance at 5% level, we'd expect about 1.25)"

/*------------------------------------------------------------------------------
    Step 5: R-squared Values
------------------------------------------------------------------------------*/

di ""
di "======================================================================"
di "Part 4: R-squared Values"
di "======================================================================"
di ""
di "            Low BM    BM2       BM3       BM4     High BM"
di "--------------------------------------------------------------"
forvalues size = 1/5 {
    local size_label = cond(`size'==1, "Small", cond(`size'==5, "Big  ", "Size`size'"))
    di "`size_label'" _col(12) %8.3f rsq_capm[`size',1] %8.3f rsq_capm[`size',2] %8.3f rsq_capm[`size',3] %8.3f rsq_capm[`size',4] %8.3f rsq_capm[`size',5]
}
di "--------------------------------------------------------------"

// Calculate average R-squared across all portfolios
local rsq_sum = 0
forvalues size = 1/5 {
    forvalues bm = 1/5 {
        local rsq_sum = `rsq_sum' + rsq_capm[`size', `bm']
    }
}
local avg_rsq = `rsq_sum' / 25
di ""
di "Average R-squared: " %5.3f `avg_rsq'

/*------------------------------------------------------------------------------
    Step 6: Look for Patterns in the Alphas
------------------------------------------------------------------------------*/

di ""
di "======================================================================"
di "Part 5: Pattern Analysis"
di "======================================================================"
di ""

// Average alpha by size quintile
di "Average Alpha by Size:"
forvalues size = 1/5 {
    local rowsum = 0
    forvalues bm = 1/5 {
        local rowsum = `rowsum' + alpha_capm[`size', `bm']
    }
    local rowavg = `rowsum' / 5
    local size_label = cond(`size'==1, "Small", cond(`size'==5, "Big", "Size`size'"))
    di "  `size_label': " %8.3f `rowavg' "% per month"
}

di ""

// Average alpha by B/M quintile
di "Average Alpha by B/M:"
forvalues bm = 1/5 {
    local colsum = 0
    forvalues size = 1/5 {
        local colsum = `colsum' + alpha_capm[`size', `bm']
    }
    local colavg = `colsum' / 5
    local bm_label = cond(`bm'==1, "Low BM", cond(`bm'==5, "High BM", "BM`bm'"))
    di "  `bm_label': " %8.3f `colavg' "% per month"
}

/*------------------------------------------------------------------------------
    Step 7: Detailed Output for the Corner Portfolios
------------------------------------------------------------------------------*/

di ""
di "======================================================================"
di "Part 6: Detailed Results for Corner Portfolios"
di "======================================================================"

di ""
di "--- Small/Low BM (p11) ---"
regress exret11 mktrf

di ""
di "--- Small/High BM (p15) ---"
regress exret15 mktrf

di ""
di "--- Big/Low BM (p51) ---"
regress exret51 mktrf

di ""
di "--- Big/High BM (p55) ---"
regress exret55 mktrf

/*------------------------------------------------------------------------------
    Step 8: Export the Results
------------------------------------------------------------------------------*/

// Export alpha matrix to CSV
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
    replace lowbm = alpha_capm[`size', 1] if size == `size'
    replace bm2 = alpha_capm[`size', 2] if size == `size'
    replace bm3 = alpha_capm[`size', 3] if size == `size'
    replace bm4 = alpha_capm[`size', 4] if size == `size'
    replace highbm = alpha_capm[`size', 5] if size == `size'
}

export delimited "$root/output/tables/table4_capm_alphas.csv", replace
restore

// Export R-squared matrix
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
    replace lowbm = rsq_capm[`size', 1] if size == `size'
    replace bm2 = rsq_capm[`size', 2] if size == `size'
    replace bm3 = rsq_capm[`size', 3] if size == `size'
    replace bm4 = rsq_capm[`size', 4] if size == `size'
    replace highbm = rsq_capm[`size', 5] if size == `size'
}

export delimited "$root/output/tables/table4_capm_rsq.csv", replace
restore

/*------------------------------------------------------------------------------
    Step 9: Summary of Findings
------------------------------------------------------------------------------*/

di ""
di "======================================================================"
di "CAPM REGRESSION SUMMARY"
di "======================================================================"
di ""
di "KEY FINDING: CAPM FAILS to explain the cross-section of returns!"
di ""
di "Evidence:"
di "1. `sig_count' out of 25 alphas are statistically significant"
di "2. Alphas show systematic patterns:"
di "   - Small stocks have HIGHER alphas than big stocks"
di "   - High B/M stocks have HIGHER alphas than low B/M stocks"
di "3. Average R-squared: " %5.3f `avg_rsq' " (market factor alone isn't enough)"
di ""
di "This is why we need additional factors (SMB and HML)!"
di ""
di "Output files saved:"
di "  - $root/output/tables/table4_capm_alphas.csv"
di "  - $root/output/tables/table4_capm_rsq.csv"
di "======================================================================"

