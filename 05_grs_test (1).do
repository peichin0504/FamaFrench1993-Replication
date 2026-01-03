/*==============================================================================
    05_grs_test.do 
    
    Purpose: Replicate Fama-French (1993) Table 9c
             GRS Test (Gibbons, Ross, Shanken 1989)
             
    Test: H0: All 25 intercepts (alphas) are jointly equal to zero
    
    Author: Pei-Chin
    Date: Started spring 2024, debugged like crazy in summer
    
    Input:  merged_data.dta
    Output: GRS test results (hoping to match published Table 9c!)
    
    Notes: The GRS calculation was a pain - had to read the original 1989 paper
           like 5 times to get the denominator right. Pretty sure it's correct now.
==============================================================================*/

clear all
set more off

global root "/Users/pei-chin/Research/FamaFrench_1993_Replication"

* Load the merged dataset
use "$root/data/processed/merged_data.dta", clear

di ""
di "======================================================================"
di "GRS TEST - Replicating Fama-French (1993) Table 9c"
di "======================================================================"
di ""
di "Gibbons, Ross, and Shanken (1989) Joint Test of Pricing Errors"
di "Null Hypothesis: All portfolio alphas are jointly equal to zero"
di ""
di "Sample period: " %tm date[1] " to " %tm date[_N]
di "Number of months (T): " _N
di "Number of portfolios (N): 25"
di "======================================================================"

// Store sample size - we'll use this a lot
local T = _N
local num_portfolios = 25

/*------------------------------------------------------------------------------
    PART 1: GRS Test for CAPM (Single Factor Model)
    
    The CAPM says all you need is beta. Let's see if that holds up...
------------------------------------------------------------------------------*/

di ""
di "======================================================================"
di "TEST 1: CAPM (Market Factor Only)"
di "======================================================================"
di ""

local K_capm = 1  // number of factors

* Step 1: Run 25 separate regressions and grab the alphas
di "Running 25 CAPM regressions (this takes a sec)..."
forvalues size = 1/5 {
    forvalues bm = 1/5 {
        quietly regress exret`size'`bm' mktrf
        quietly predict resid_capm_`size'`bm', residuals
        
        // Store the intercept (alpha) and its standard error
        local alpha_capm_`size'`bm' = _b[_cons]
        local se_alpha_capm_`size'`bm' = _se[_cons]
    }
}

* Step 2: Put all the alphas into a vector (Nx1 matrix)
matrix alpha_capm = J(25, 1, .)
local counter = 1
forvalues size = 1/5 {
    forvalues bm = 1/5 {
        matrix alpha_capm[`counter', 1] = `alpha_capm_`size'`bm''
        local counter = `counter' + 1
    }
}

* Step 3: Calculate the covariance matrix of residuals (Sigma)
// This is the tricky part - need all 25 residual series
local all_resids ""
forvalues size = 1/5 {
    forvalues bm = 1/5 {
        local all_resids "`all_resids' resid_capm_`size'`bm'"
    }
}

quietly correlate `all_resids', covariance
matrix Sigma_capm = r(C)

* Step 4: Factor statistics (just market for CAPM)
quietly summarize mktrf
local mean_mktrf = r(mean)
local variance_mktrf = r(Var)

* Step 5: Calculate the GRS F-statistic
// Formula: GRS = (T/N) * ((T-N-K)/(T-K-1)) * (alpha' * Sigma^-1 * alpha) / (1 + mu'*Omega^-1*mu)
// For single factor, denominator simplifies to: 1 + (mean^2 / variance)

matrix Sigma_capm_inv = invsym(Sigma_capm)
matrix quad_form_capm = alpha_capm' * Sigma_capm_inv * alpha_capm
local numerator_part = quad_form_capm[1,1]

// Sharpe ratio squared (for single factor case)
local sharpe_ratio_sq = (`mean_mktrf'^2) / `variance_mktrf'
local denominator = 1 + `sharpe_ratio_sq'

// Put it all together
local df_numerator = `num_portfolios'
local df_denominator = `T' - `num_portfolios' - `K_capm'
local grs_capm = (`T' / `num_portfolios') * (`df_denominator' / (`T' - `K_capm' - 1)) * (`numerator_part' / `denominator')

// Get p-value from F-distribution
local pval_capm = Ftail(`df_numerator', `df_denominator', `grs_capm')

di "CAPM Results:"
di "  GRS F-statistic: " %10.4f `grs_capm'
di "  Degrees of freedom: (" `df_numerator' ", " `df_denominator' ")"
di "  P-value: " %10.6f `pval_capm'
di ""

if `pval_capm' < 0.05 {
    di "  ==> REJECT H0 at 5% level"
    di "      The CAPM alphas are jointly significantly different from zero"
    di "      (Not surprising - CAPM is too simple)"
}
else {
    di "  ==> FAIL TO REJECT H0 at 5% level"
    di "      (Would be shocking if CAPM actually worked this well!)"
}

// Clean up the workspace - don't need these residuals anymore
drop resid_capm_*

/*------------------------------------------------------------------------------
    PART 2: GRS Test for Fama-French Three-Factor Model
    
    Now let's see if adding SMB and HML helps explain the cross-section better
------------------------------------------------------------------------------*/

di ""
di "======================================================================"
di "TEST 2: Fama-French Three-Factor Model (MKT + SMB + HML)"
di "======================================================================"
di ""

local K_ff3 = 3  // three factors now

* Step 1: Run 25 three-factor regressions
di "Running 25 three-factor regressions..."
forvalues size = 1/5 {
    forvalues bm = 1/5 {
        quietly regress exret`size'`bm' mktrf smb hml
        quietly predict resid_ff3_`size'`bm', residuals
        local alpha_ff3_`size'`bm' = _b[_cons]
    }
}

* Step 2: Alpha vector for three-factor model
matrix alpha_ff3 = J(25, 1, .)
local counter = 1
forvalues size = 1/5 {
    forvalues bm = 1/5 {
        matrix alpha_ff3[`counter', 1] = `alpha_ff3_`size'`bm''
        local counter = `counter' + 1
    }
}

* Step 3: Residual covariance matrix
local all_resids_ff3 ""
forvalues size = 1/5 {
    forvalues bm = 1/5 {
        local all_resids_ff3 "`all_resids_ff3' resid_ff3_`size'`bm'"
    }
}

quietly correlate `all_resids_ff3', covariance
matrix Sigma_ff3 = r(C)

* Step 4: Factor statistics (now we have 3 factors)
quietly summarize mktrf
local mu_mkt = r(mean)
quietly summarize smb
local mu_smb = r(mean)
quietly summarize hml  
local mu_hml = r(mean)

// Put means into a vector
matrix mu_vec = (`mu_mkt' \ `mu_smb' \ `mu_hml')

// Factor covariance matrix (Omega in GRS paper)
quietly correlate mktrf smb hml, covariance
matrix Omega = r(C)

* Step 5: Calculate GRS for three-factor model
matrix Sigma_ff3_inv = invsym(Sigma_ff3)
matrix quad_alpha = alpha_ff3' * Sigma_ff3_inv * alpha_ff3
local numerator_ff3 = quad_alpha[1,1]

// Multi-factor Sharpe ratio: mu' * Omega^-1 * mu
matrix Omega_inv = invsym(Omega)
matrix sharpe_quad_ff3 = mu_vec' * Omega_inv * mu_vec
local sharpe_sq_ff3 = sharpe_quad_ff3[1,1]
local denominator_ff3 = 1 + `sharpe_sq_ff3'

// GRS statistic
local df_denom_ff3 = `T' - `num_portfolios' - `K_ff3'
local grs_ff3 = (`T' / `num_portfolios') * (`df_denom_ff3' / (`T' - `K_ff3' - 1)) * (`numerator_ff3' / `denominator_ff3')

// P-value
local pval_ff3 = Ftail(`df_numerator', `df_denom_ff3', `grs_ff3')

di "Three-Factor Model Results:"
di "  GRS F-statistic: " %10.4f `grs_ff3'
di "  Degrees of freedom: (" `df_numerator' ", " `df_denom_ff3' ")"
di "  P-value: " %10.6f `pval_ff3'
di ""

if `pval_ff3' < 0.05 {
    di "  ==> REJECT H0 at 5% level"
    di "      Still some pricing errors left (but much better than CAPM)"
}
else {
    di "  ==> FAIL TO REJECT H0 at 5% level"
    di "      Three-factor model does a good job pricing these 25 portfolios!"
}

// Clean up
drop resid_ff3_*

/*------------------------------------------------------------------------------
    PART 3: Additional Diagnostics
    
    Let's look at some other metrics to see how much the 3-factor model helps
------------------------------------------------------------------------------*/

di ""
di "======================================================================"
di "ADDITIONAL DIAGNOSTICS"
di "======================================================================"
di ""

* Calculate average absolute alpha (intuitive measure of pricing errors)
local sum_abs_alpha_capm = 0
local sum_abs_alpha_ff3 = 0

forvalues i = 1/25 {
    local sum_abs_alpha_capm = `sum_abs_alpha_capm' + abs(alpha_capm[`i', 1])
    local sum_abs_alpha_ff3 = `sum_abs_alpha_ff3' + abs(alpha_ff3[`i', 1])
}

local avg_abs_alpha_capm = `sum_abs_alpha_capm' / 25
local avg_abs_alpha_ff3 = `sum_abs_alpha_ff3' / 25

* Sum of squared alphas (another common metric)
local sum_sq_alpha_capm = 0
local sum_sq_alpha_ff3 = 0

forvalues i = 1/25 {
    local sum_sq_alpha_capm = `sum_sq_alpha_capm' + (alpha_capm[`i', 1])^2
    local sum_sq_alpha_ff3 = `sum_sq_alpha_ff3' + (alpha_ff3[`i', 1])^2
}

// Display comparison table
di "                                    CAPM      Three-Factor"
di "--------------------------------------------------------------"
di "Average |alpha| (% per month):   " %8.4f `avg_abs_alpha_capm' "     " %8.4f `avg_abs_alpha_ff3'
di "Sum of Squared Alphas:           " %8.4f `sum_sq_alpha_capm' "     " %8.4f `sum_sq_alpha_ff3'
di "GRS F-statistic:                 " %8.4f `grs_capm' "     " %8.4f `grs_ff3'
di "GRS p-value:                     " %8.6f `pval_capm' "   " %8.6f `pval_ff3'
di "--------------------------------------------------------------"

/*------------------------------------------------------------------------------
    PART 4: How Much Improvement?
    
    Calculate percentage reductions in pricing errors
------------------------------------------------------------------------------*/

di ""
di "======================================================================"
di "MODEL IMPROVEMENT METRICS"
di "======================================================================"
di ""

local improvement_grs = (1 - `grs_ff3'/`grs_capm') * 100
local improvement_ssa = (1 - `sum_sq_alpha_ff3'/`sum_sq_alpha_capm') * 100
local improvement_avg = (1 - `avg_abs_alpha_ff3'/`avg_abs_alpha_capm') * 100

di "Going from CAPM to Three-Factor Model:"
di "  - GRS F-statistic drops by: " %5.1f `improvement_grs' "%"
di "  - Sum of Squared Alphas drops by: " %5.1f `improvement_ssa' "%"
di "  - Average |alpha| drops by: " %5.1f `improvement_avg' "%"
di ""
di "(Basically, SMB and HML do a lot of heavy lifting!)"

/*------------------------------------------------------------------------------
    PART 5: Save Results to CSV
    
    Export for LaTeX table later
------------------------------------------------------------------------------*/

preserve

clear
set obs 2

gen str30 model = ""
gen grs_fstat = .
gen df_num = .
gen df_denom = .
gen p_value = .
gen avg_abs_alpha = .
gen sum_sq_alpha = .

// Row 1: CAPM results
replace model = "CAPM" in 1
replace grs_fstat = `grs_capm' in 1
replace df_num = `df_numerator' in 1
replace df_denom = `df_denominator' in 1
replace p_value = `pval_capm' in 1
replace avg_abs_alpha = `avg_abs_alpha_capm' in 1
replace sum_sq_alpha = `sum_sq_alpha_capm' in 1

// Row 2: Three-factor results
replace model = "Three-Factor" in 2
replace grs_fstat = `grs_ff3' in 2
replace df_num = `df_numerator' in 2
replace df_denom = `df_denom_ff3' in 2
replace p_value = `pval_ff3' in 2
replace avg_abs_alpha = `avg_abs_alpha_ff3' in 2
replace sum_sq_alpha = `sum_sq_alpha_ff3' in 2

export delimited "$root/output/tables/table9c_grs_test.csv", replace

restore

/*------------------------------------------------------------------------------
    FINAL SUMMARY
------------------------------------------------------------------------------*/

di ""
di "======================================================================"
di "GRS TEST SUMMARY - FINAL VERDICT"
di "======================================================================"
di ""
di "The GRS test checks whether all 25 portfolio alphas are jointly zero."
di "If we reject, it means the model leaves systematic pricing errors."
di ""
di "--------------------------------------------------------------"
di "Model             GRS F-stat    p-value      Decision"
di "--------------------------------------------------------------"
di "CAPM              " %8.2f `grs_capm' "     " %8.6f `pval_capm' "   " cond(`pval_capm'<0.05, "REJECT H0", "FAIL TO REJECT")
di "Three-Factor      " %8.2f `grs_ff3' "     " %8.6f `pval_ff3' "   " cond(`pval_ff3'<0.05, "REJECT H0", "FAIL TO REJECT")
di "--------------------------------------------------------------"
di ""
di "Bottom Line:"
di "  - GRS F drops by " %4.1f `improvement_grs' "% (from " %5.2f `grs_capm' " to " %5.2f `grs_ff3' ")"
di "  - Three-factor model is a MAJOR improvement over CAPM"
di "  - SMB and HML capture size and value effects that CAPM misses"
di ""
di "Output saved to: $root/output/tables/table9c_grs_test.csv"
di "======================================================================"

/*
POST-RUN NOTES:

1. The GRS formula was the hardest part of this whole project. Had to check
   against several sources to make sure I got it right:
   - Gibbons, Ross, Shanken (1989) original paper
   - Cochrane (2005) Asset Pricing textbook
   - Some random guy's replication code on GitHub
   
2. Things to double-check:
   - Are the degrees of freedom correct? (Pretty sure they are)
   - Should I be using robust standard errors somewhere? (Don't think so for GRS)
   - Is the factor covariance matrix properly specified? (Looks good)

3. If the results don't match Table 9c exactly, could be:
   - Different sample period (check date range)
   - Different portfolio construction (check 05_portfolios.do)
   - Rounding differences (probably fine)
   
4. TODO: Maybe add a plot showing individual alphas for CAPM vs FF3?
   Would be nice to visualize which portfolios have the biggest improvements.

*/
