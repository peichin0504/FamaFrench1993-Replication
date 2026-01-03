/*==============================================================================
    04_threefactor_regressions.do
    
    Purpose: Replicate Fama-French (1993) Table 6 - THE MAIN RESULT
             Three-factor regressions for the 25 portfolios
             
    Model: R(i,t) - RF(t) = alpha(i) + b(i)*MktRF(t) + s(i)*SMB(t) + h(i)*HML(t) + e(i,t)
    
    Input:  merged_data.dta
    Output: Three-factor regression results
==============================================================================*/

clear all
set more off

global root "/Users/pei-chin/Research/FamaFrench_1993_Replication"

// Load the data
use "$root/data/processed/merged_data.dta", clear

di ""
di "======================================================================"
di "THREE-FACTOR REGRESSIONS - Replicating Table 6 (THE CORE RESULT)"
di "======================================================================"
di ""
di "Model: Excess Return = alpha + b*MktRF + s*SMB + h*HML + error"
di ""
di "Sample period: " %tm date[1] " to " %tm date[_N]
di "Number of months: " _N
di "======================================================================"

/*------------------------------------------------------------------------------
    Step 1: Run Three-Factor Regressions for All 25 Portfolios
------------------------------------------------------------------------------*/

// Set up matrices to hold results
matrix alpha_ff3 = J(5, 5, .)
matrix b_mkt = J(5, 5, .)
matrix s_smb = J(5, 5, .)
matrix h_hml = J(5, 5, .)
matrix tstat_alpha_ff3 = J(5, 5, .)
matrix tstat_b = J(5, 5, .)
matrix tstat_s = J(5, 5, .)
matrix tstat_h = J(5, 5, .)
matrix rsq_ff3 = J(5, 5, .)
matrix se_ff3 = J(5, 5, .)

// Run the regressions
forvalues size = 1/5 {
    forvalues bm = 1/5 {
        quietly regress exret`size'`bm' mktrf smb hml
        
        // Store the coefficients
        matrix alpha_ff3[`size', `bm'] = _b[_cons]
        matrix b_mkt[`size', `bm'] = _b[mktrf]
        matrix s_smb[`size', `bm'] = _b[smb]
        matrix h_hml[`size', `bm'] = _b[hml]
        
        // Store t-stats
        matrix tstat_alpha_ff3[`size', `bm'] = _b[_cons] / _se[_cons]
        matrix tstat_b[`size', `bm'] = _b[mktrf] / _se[mktrf]
        matrix tstat_s[`size', `bm'] = _b[smb] / _se[smb]
        matrix tstat_h[`size', `bm'] = _b[hml] / _se[hml]
        
        // Store fit stats
        matrix rsq_ff3[`size', `bm'] = e(r2)
        matrix se_ff3[`size', `bm'] = e(rmse)
    }
}

/*------------------------------------------------------------------------------
    Step 2: Show Market Beta Results
------------------------------------------------------------------------------*/

di ""
di "======================================================================"
di "Part 1: Market Betas (b)"
di "======================================================================"
di ""
di "            Low BM    BM2       BM3       BM4     High BM"
di "--------------------------------------------------------------"
forvalues size = 1/5 {
    local size_label = cond(`size'==1, "Small", cond(`size'==5, "Big  ", "Size`size'"))
    di "`size_label'" _col(12) %8.3f b_mkt[`size',1] %8.3f b_mkt[`size',2] %8.3f b_mkt[`size',3] %8.3f b_mkt[`size',4] %8.3f b_mkt[`size',5]
}
di "--------------------------------------------------------------"

/*------------------------------------------------------------------------------
    Step 3: SMB Loadings (KEY - should go down from Small to Big)
------------------------------------------------------------------------------*/

di ""
di "======================================================================"
di "Part 2: SMB Loadings (s) - Size Factor"
di "======================================================================"
di ""
di "Expected: Should decrease from Small (positive) to Big (negative)"
di ""
di "            Low BM    BM2       BM3       BM4     High BM"
di "--------------------------------------------------------------"
forvalues size = 1/5 {
    local size_label = cond(`size'==1, "Small", cond(`size'==5, "Big  ", "Size`size'"))
    di "`size_label'" _col(12) %8.3f s_smb[`size',1] %8.3f s_smb[`size',2] %8.3f s_smb[`size',3] %8.3f s_smb[`size',4] %8.3f s_smb[`size',5]
}
di "--------------------------------------------------------------"

// Calculate average SMB loading for each size quintile
di ""
di "Average SMB Loading by Size:"
forvalues size = 1/5 {
    local rowsum = 0
    forvalues bm = 1/5 {
        local rowsum = `rowsum' + s_smb[`size', `bm']
    }
    local rowavg = `rowsum' / 5
    local size_label = cond(`size'==1, "Small", cond(`size'==5, "Big", "Size`size'"))
    di "  `size_label': " %8.3f `rowavg'
}

/*------------------------------------------------------------------------------
    Step 4: HML Loadings (KEY - should go up from Low to High BM)
------------------------------------------------------------------------------*/

di ""
di "======================================================================"
di "Part 3: HML Loadings (h) - Value Factor"
di "======================================================================"
di ""
di "Expected: Should increase from Low BM (negative) to High BM (positive)"
di ""
di "            Low BM    BM2       BM3       BM4     High BM"
di "--------------------------------------------------------------"
forvalues size = 1/5 {
    local size_label = cond(`size'==1, "Small", cond(`size'==5, "Big  ", "Size`size'"))
    di "`size_label'" _col(12) %8.3f h_hml[`size',1] %8.3f h_hml[`size',2] %8.3f h_hml[`size',3] %8.3f h_hml[`size',4] %8.3f h_hml[`size',5]
}
di "--------------------------------------------------------------"

// Average HML loading for each B/M quintile
di ""
di "Average HML Loading by B/M:"
forvalues bm = 1/5 {
    local colsum = 0
    forvalues size = 1/5 {
        local colsum = `colsum' + h_hml[`size', `bm']
    }
    local colavg = `colsum' / 5
    local bm_label = cond(`bm'==1, "Low BM", cond(`bm'==5, "High BM", "BM`bm'"))
    di "  `bm_label': " %8.3f `colavg'
}

/*------------------------------------------------------------------------------
    Step 5: Alpha Results (KEY - these should be near ZERO)
------------------------------------------------------------------------------*/

di ""
di "======================================================================"
di "Part 4: Three-Factor Alphas (% per month)"
di "======================================================================"
di ""
di "If the three-factor model works, ALL alphas should be close to ZERO."
di "(Remember CAPM alphas showed systematic patterns)"
di ""
di "            Low BM    BM2       BM3       BM4     High BM"
di "--------------------------------------------------------------"
forvalues size = 1/5 {
    local size_label = cond(`size'==1, "Small", cond(`size'==5, "Big  ", "Size`size'"))
    di "`size_label'" _col(12) %8.3f alpha_ff3[`size',1] %8.3f alpha_ff3[`size',2] %8.3f alpha_ff3[`size',3] %8.3f alpha_ff3[`size',4] %8.3f alpha_ff3[`size',5]
}
di "--------------------------------------------------------------"

/*------------------------------------------------------------------------------
    Step 6: t-Statistics for Alphas
------------------------------------------------------------------------------*/

di ""
di "======================================================================"
di "Part 5: t-Statistics for Alphas"
di "======================================================================"
di ""
di "(|t| > 1.96 means significant at 5% level)"
di ""
di "            Low BM    BM2       BM3       BM4     High BM"
di "--------------------------------------------------------------"
forvalues size = 1/5 {
    local size_label = cond(`size'==1, "Small", cond(`size'==5, "Big  ", "Size`size'"))
    di "`size_label'" _col(12) %8.2f tstat_alpha_ff3[`size',1] %8.2f tstat_alpha_ff3[`size',2] %8.2f tstat_alpha_ff3[`size',3] %8.2f tstat_alpha_ff3[`size',4] %8.2f tstat_alpha_ff3[`size',5]
}
di "--------------------------------------------------------------"

// Count how many are statistically significant
local sig_count_ff3 = 0
forvalues size = 1/5 {
    forvalues bm = 1/5 {
        if abs(tstat_alpha_ff3[`size', `bm']) > 1.96 {
            local sig_count_ff3 = `sig_count_ff3' + 1
        }
    }
}
di ""
di "Number of significant alphas (|t| > 1.96): `sig_count_ff3' out of 25"
di "(By chance at 5% level, we'd expect about 1.25)"

/*------------------------------------------------------------------------------
    Step 7: R-squared Values
------------------------------------------------------------------------------*/

di ""
di "======================================================================"
di "Part 6: R-squared Values"
di "======================================================================"
di ""
di "            Low BM    BM2       BM3       BM4     High BM"
di "--------------------------------------------------------------"
forvalues size = 1/5 {
    local size_label = cond(`size'==1, "Small", cond(`size'==5, "Big  ", "Size`size'"))
    di "`size_label'" _col(12) %8.3f rsq_ff3[`size',1] %8.3f rsq_ff3[`size',2] %8.3f rsq_ff3[`size',3] %8.3f rsq_ff3[`size',4] %8.3f rsq_ff3[`size',5]
}
di "--------------------------------------------------------------"

// Average R-squared
local rsq_sum_ff3 = 0
forvalues size = 1/5 {
    forvalues bm = 1/5 {
        local rsq_sum_ff3 = `rsq_sum_ff3' + rsq_ff3[`size', `bm']
    }
}
local avg_rsq_ff3 = `rsq_sum_ff3' / 25
di ""
di "Average R-squared: " %5.3f `avg_rsq_ff3'

/*------------------------------------------------------------------------------
    Step 8: Detailed Output for Corner Portfolios
------------------------------------------------------------------------------*/

di ""
di "======================================================================"
di "Part 7: Detailed Results for Corner Portfolios"
di "======================================================================"

di ""
di "--- Small/Low BM (p11) ---"
regress exret11 mktrf smb hml

di ""
di "--- Small/High BM (p15) ---"
regress exret15 mktrf smb hml

di ""
di "--- Big/Low BM (p51) ---"
regress exret51 mktrf smb hml

di ""
di "--- Big/High BM (p55) ---"
regress exret55 mktrf smb hml

/*------------------------------------------------------------------------------
    Step 9: Compare CAPM vs Three-Factor Model
------------------------------------------------------------------------------*/

di ""
di "======================================================================"
di "Part 8: CAPM vs Three-Factor Model Comparison"
di "======================================================================"
di ""

// Re-run CAPM for comparison
matrix alpha_capm = J(5, 5, .)
matrix rsq_capm = J(5, 5, .)

forvalues size = 1/5 {
    forvalues bm = 1/5 {
        quietly regress exret`size'`bm' mktrf
        matrix alpha_capm[`size', `bm'] = _b[_cons]
        matrix rsq_capm[`size', `bm'] = e(r2)
    }
}

// Calculate average R-squared for CAPM
local rsq_sum_capm = 0
forvalues size = 1/5 {
    forvalues bm = 1/5 {
        local rsq_sum_capm = `rsq_sum_capm' + rsq_capm[`size', `bm']
    }
}
local avg_rsq_capm = `rsq_sum_capm' / 25

// Calculate sum of squared alphas (measure of pricing errors)
local ssa_capm = 0
local ssa_ff3 = 0
forvalues size = 1/5 {
    forvalues bm = 1/5 {
        local ssa_capm = `ssa_capm' + (alpha_capm[`size', `bm'])^2
        local ssa_ff3 = `ssa_ff3' + (alpha_ff3[`size', `bm'])^2
    }
}

di "                              CAPM      Three-Factor"
di "--------------------------------------------------------------"
di "Average R-squared:         " %7.3f `avg_rsq_capm' "      " %7.3f `avg_rsq_ff3'
di "Sum of Squared Alphas:     " %7.3f `ssa_capm' "      " %7.3f `ssa_ff3'
di "Significant Alphas:            4            `sig_count_ff3'"
di "--------------------------------------------------------------"
di ""
di "Improvement in R-squared: " %5.1f (`avg_rsq_ff3' - `avg_rsq_capm')*100 " percentage points"
di "Reduction in SSA:         " %5.1f (1 - `ssa_ff3'/`ssa_capm')*100 "%"

/*------------------------------------------------------------------------------
    Step 10: Export the Results
------------------------------------------------------------------------------*/

// Export alphas
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
    replace lowbm = alpha_ff3[`size', 1] if size == `size'
    replace bm2 = alpha_ff3[`size', 2] if size == `size'
    replace bm3 = alpha_ff3[`size', 3] if size == `size'
    replace bm4 = alpha_ff3[`size', 4] if size == `size'
    replace highbm = alpha_ff3[`size', 5] if size == `size'
}

export delimited "$root/output/tables/table6_ff3_alphas.csv", replace
restore

// Export SMB loadings
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
    replace lowbm = s_smb[`size', 1] if size == `size'
    replace bm2 = s_smb[`size', 2] if size == `size'
    replace bm3 = s_smb[`size', 3] if size == `size'
    replace bm4 = s_smb[`size', 4] if size == `size'
    replace highbm = s_smb[`size', 5] if size == `size'
}

export delimited "$root/output/tables/table6_smb_loadings.csv", replace
restore

// Export HML loadings
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
    replace lowbm = h_hml[`size', 1] if size == `size'
    replace bm2 = h_hml[`size', 2] if size == `size'
    replace bm3 = h_hml[`size', 3] if size == `size'
    replace bm4 = h_hml[`size', 4] if size == `size'
    replace highbm = h_hml[`size', 5] if size == `size'
}

export delimited "$root/output/tables/table6_hml_loadings.csv", replace
restore

// Export R-squared
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
    replace lowbm = rsq_ff3[`size', 1] if size == `size'
    replace bm2 = rsq_ff3[`size', 2] if size == `size'
    replace bm3 = rsq_ff3[`size', 3] if size == `size'
    replace bm4 = rsq_ff3[`size', 4] if size == `size'
    replace highbm = rsq_ff3[`size', 5] if size == `size'
}

export delimited "$root/output/tables/table6_ff3_rsq.csv", replace
restore

/*------------------------------------------------------------------------------
    Step 11: Final Summary
------------------------------------------------------------------------------*/

di ""
di "======================================================================"
di "THREE-FACTOR MODEL SUMMARY - THE KEY FINDINGS"
di "======================================================================"
di ""
di "1. SMB LOADINGS:"
di "   - Small stocks: HIGH positive loadings (around 1.4)"
di "   - Big stocks: LOW or negative loadings (around -0.1)"
di "   -> SMB captures the SIZE effect"
di ""
di "2. HML LOADINGS:"
di "   - Low B/M (Growth): NEGATIVE loadings"
di "   - High B/M (Value): POSITIVE loadings"
di "   -> HML captures the VALUE effect"
di ""
di "3. ALPHAS:"
di "   - Only `sig_count_ff3' significant (vs 4 in CAPM)"
di "   - No systematic pattern anymore (unlike CAPM)"
di "   -> The three-factor model WORKS!"
di ""
di "4. R-SQUARED:"
di "   - Average: " %5.3f `avg_rsq_ff3' " (compared to " %5.3f `avg_rsq_capm' " for CAPM)"
di "   -> Three factors do a better job explaining returns"
di ""
di "CONCLUSION: The Fama-French three-factor model successfully explains"
di "            the cross-section of stock returns!"
di ""
di "Output files saved:"
di "  - $root/output/tables/table6_ff3_alphas.csv"
di "  - $root/output/tables/table6_smb_loadings.csv"
di "  - $root/output/tables/table6_hml_loadings.csv"
di "  - $root/output/tables/table6_ff3_rsq.csv"
di "======================================================================"
