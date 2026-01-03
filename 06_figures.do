/*==============================================================================
    06_figures.do
    
    Purpose: Create visualizations for Fama-French (1993) replication
    
    Figures:
    1. Mean returns by Size and B/M
    2. SMB loadings pattern
    3. HML loadings pattern
    4. CAPM vs Three-Factor alphas
    5. R-squared comparison
    6. Factor cumulative returns
    
    Input:  merged_data.dta
    Output: PNG figures
==============================================================================*/

clear all
set more off

global root "/Users/pei-chin/Research/FamaFrench_1993_Replication"

* Create output directory
cap mkdir "$root/output"
cap mkdir "$root/output/figures"

* Set graph scheme
set scheme s2color

* Load data
use "$root/data/processed/merged_data.dta", clear

di ""
di "======================================================================"
di "CREATING FIGURES"
di "======================================================================"

/*------------------------------------------------------------------------------
    1. Run Regressions to Get Coefficients
------------------------------------------------------------------------------*/

* Store results in matrices
matrix mean_ret = J(5, 5, .)
matrix alpha_capm = J(5, 5, .)
matrix alpha_ff3 = J(5, 5, .)
matrix rsq_capm = J(5, 5, .)
matrix rsq_ff3 = J(5, 5, .)
matrix s_smb = J(5, 5, .)
matrix h_hml = J(5, 5, .)

forvalues size = 1/5 {
    forvalues bm = 1/5 {
        * Mean returns
        quietly summarize exret`size'`bm'
        matrix mean_ret[`size', `bm'] = r(mean)
        
        * CAPM
        quietly regress exret`size'`bm' mktrf
        matrix alpha_capm[`size', `bm'] = _b[_cons]
        matrix rsq_capm[`size', `bm'] = e(r2)
        
        * Three-factor
        quietly regress exret`size'`bm' mktrf smb hml
        matrix alpha_ff3[`size', `bm'] = _b[_cons]
        matrix rsq_ff3[`size', `bm'] = e(r2)
        matrix s_smb[`size', `bm'] = _b[smb]
        matrix h_hml[`size', `bm'] = _b[hml]
    }
}

/*------------------------------------------------------------------------------
    Figure 1: Mean Excess Returns by Size
------------------------------------------------------------------------------*/

di ""
di "Creating Figure 1: Mean Returns by Size..."

preserve
clear
set obs 5
gen size = _n
gen mean_return = .

* Calculate average return for each size quintile
forvalues s = 1/5 {
    local sum = 0
    forvalues b = 1/5 {
        local sum = `sum' + mean_ret[`s', `b']
    }
    replace mean_return = `sum'/5 if size == `s'
}

label define size_lbl 1 "Small" 2 "2" 3 "3" 4 "4" 5 "Big"
label values size size_lbl

twoway (bar mean_return size, barwidth(0.7) color(navy)) ///
    (scatter mean_return size, msymbol(none) mlabel(mean_return) mlabformat(%4.2f) mlabposition(12) mlabcolor(black)), ///
    title("Average Monthly Excess Returns by Size Quintile") ///
    subtitle("Size Effect: Small stocks earn higher returns") ///
    ytitle("Mean Excess Return (% per month)") ///
    xtitle("Size Quintile") ///
    xlabel(1 "Small" 2 "2" 3 "3" 4 "4" 5 "Big") ///
    ylabel(0(0.2)1.0) ///
    legend(off) ///
    note("Sample: 1926m7 - 2025m5")

graph export "$root/output/figures/fig1_returns_by_size.png", replace width(1200)
restore

/*------------------------------------------------------------------------------
    Figure 2: Mean Excess Returns by B/M
------------------------------------------------------------------------------*/

di "Creating Figure 2: Mean Returns by B/M..."

preserve
clear
set obs 5
gen bm = _n
gen mean_return = .

* Calculate average return for each B/M quintile
forvalues b = 1/5 {
    local sum = 0
    forvalues s = 1/5 {
        local sum = `sum' + mean_ret[`s', `b']
    }
    replace mean_return = `sum'/5 if bm == `b'
}

twoway (bar mean_return bm, barwidth(0.7) color(maroon)) ///
    (scatter mean_return bm, msymbol(none) mlabel(mean_return) mlabformat(%4.2f) mlabposition(12) mlabcolor(black)), ///
    title("Average Monthly Excess Returns by Book-to-Market Quintile") ///
    subtitle("Value Effect: High B/M stocks earn higher returns") ///
    ytitle("Mean Excess Return (% per month)") ///
    xtitle("Book-to-Market Quintile") ///
    xlabel(1 "Low (Growth)" 2 "2" 3 "3" 4 "4" 5 "High (Value)") ///
    ylabel(0(0.2)1.2) ///
    legend(off) ///
    note("Sample: 1926m7 - 2025m5")

graph export "$root/output/figures/fig2_returns_by_bm.png", replace width(1200)
restore

/*------------------------------------------------------------------------------
    Figure 3: SMB Loadings by Size
------------------------------------------------------------------------------*/

di "Creating Figure 3: SMB Loadings by Size..."

preserve
clear
set obs 5
gen size = _n
gen smb_loading = .

* Calculate average SMB loading for each size quintile
forvalues s = 1/5 {
    local sum = 0
    forvalues b = 1/5 {
        local sum = `sum' + s_smb[`s', `b']
    }
    replace smb_loading = `sum'/5 if size == `s'
}

twoway (bar smb_loading size, barwidth(0.7) color(forest_green)) ///
    (scatter smb_loading size, msymbol(none) mlabel(smb_loading) mlabformat(%4.2f) mlabposition(12) mlabcolor(black)), ///
    title("SMB Factor Loadings by Size Quintile") ///
    subtitle("Small stocks load positively, Big stocks load negatively on SMB") ///
    ytitle("SMB Loading (s)") ///
    xtitle("Size Quintile") ///
    xlabel(1 "Small" 2 "2" 3 "3" 4 "4" 5 "Big") ///
    ylabel(-0.5(0.5)1.5) ///
    yline(0, lcolor(black) lpattern(dash)) ///
    legend(off) ///
    note("From three-factor regressions: R - RF = a + b*MktRF + s*SMB + h*HML")

graph export "$root/output/figures/fig3_smb_loadings.png", replace width(1200)
restore

/*------------------------------------------------------------------------------
    Figure 4: HML Loadings by B/M
------------------------------------------------------------------------------*/

di "Creating Figure 4: HML Loadings by B/M..."

preserve
clear
set obs 5
gen bm = _n
gen hml_loading = .

* Calculate average HML loading for each B/M quintile
forvalues b = 1/5 {
    local sum = 0
    forvalues s = 1/5 {
        local sum = `sum' + h_hml[`s', `b']
    }
    replace hml_loading = `sum'/5 if bm == `b'
}

twoway (bar hml_loading bm, barwidth(0.7) color(dkorange)) ///
    (scatter hml_loading bm, msymbol(none) mlabel(hml_loading) mlabformat(%4.2f) mlabposition(12) mlabcolor(black)), ///
    title("HML Factor Loadings by Book-to-Market Quintile") ///
    subtitle("Growth stocks load negatively, Value stocks load positively on HML") ///
    ytitle("HML Loading (h)") ///
    xtitle("Book-to-Market Quintile") ///
    xlabel(1 "Low (Growth)" 2 "2" 3 "3" 4 "4" 5 "High (Value)") ///
    ylabel(-0.5(0.5)1.0) ///
    yline(0, lcolor(black) lpattern(dash)) ///
    legend(off) ///
    note("From three-factor regressions: R - RF = a + b*MktRF + s*SMB + h*HML")

graph export "$root/output/figures/fig4_hml_loadings.png", replace width(1200)
restore

/*------------------------------------------------------------------------------
    Figure 5: CAPM vs Three-Factor Alphas Comparison
------------------------------------------------------------------------------*/

di "Creating Figure 5: Alpha Comparison..."

preserve
clear
set obs 25
gen portfolio = _n
gen alpha_capm_val = .
gen alpha_ff3_val = .

local i = 1
forvalues size = 1/5 {
    forvalues bm = 1/5 {
        replace alpha_capm_val = alpha_capm[`size', `bm'] if portfolio == `i'
        replace alpha_ff3_val = alpha_ff3[`size', `bm'] if portfolio == `i'
        local i = `i' + 1
    }
}

* Scatter plot
twoway (scatter alpha_ff3_val alpha_capm_val, msymbol(circle) mcolor(navy) msize(medium)) ///
    (function y=x, range(-0.8 0.5) lcolor(red) lpattern(dash)) ///
    (function y=0, range(-0.8 0.5) lcolor(gray) lpattern(dot)), ///
    title("CAPM vs Three-Factor Model Alphas") ///
    subtitle("Three-factor alphas are closer to zero") ///
    ytitle("Three-Factor Alpha (% per month)") ///
    xtitle("CAPM Alpha (% per month)") ///
    ylabel(-0.8(0.2)0.4) ///
    xlabel(-0.8(0.2)0.6) ///
    legend(order(1 "25 Portfolios" 2 "45-degree line") position(5) ring(0)) ///
    note("Points below 45-degree line indicate FF3 alpha < CAPM alpha (in absolute value)")

graph export "$root/output/figures/fig5_alpha_comparison.png", replace width(1200)
restore

/*------------------------------------------------------------------------------
    Figure 6: R-squared Comparison
------------------------------------------------------------------------------*/

di "Creating Figure 6: R-squared Comparison..."

preserve
clear
set obs 25
gen portfolio = _n
gen rsq_capm_val = .
gen rsq_ff3_val = .
gen portfolio_name = ""

local i = 1
forvalues size = 1/5 {
    forvalues bm = 1/5 {
        replace rsq_capm_val = rsq_capm[`size', `bm'] if portfolio == `i'
        replace rsq_ff3_val = rsq_ff3[`size', `bm'] if portfolio == `i'
        local size_label = cond(`size'==1, "S", cond(`size'==5, "B", "`size'"))
        local bm_label = cond(`bm'==1, "L", cond(`bm'==5, "H", "`bm'"))
        replace portfolio_name = "`size_label'`bm_label'" if portfolio == `i'
        local i = `i' + 1
    }
}

* Calculate averages
quietly summarize rsq_capm_val
local avg_rsq_capm = r(mean)
quietly summarize rsq_ff3_val
local avg_rsq_ff3 = r(mean)

* Bar chart for average R-squared
clear
set obs 2
gen model = _n
gen avg_rsq = .
gen model_name = ""

replace model_name = "CAPM" if model == 1
replace avg_rsq = `avg_rsq_capm' if model == 1
replace model_name = "Three-Factor" if model == 2
replace avg_rsq = `avg_rsq_ff3' if model == 2

twoway (bar avg_rsq model, barwidth(0.5) color(navy maroon)) ///
    (scatter avg_rsq model, msymbol(none) mlabel(avg_rsq) mlabformat(%4.3f) mlabposition(12) mlabcolor(black)), ///
    title("Average R-squared: CAPM vs Three-Factor Model") ///
    subtitle("Three-factor model explains substantially more variation") ///
    ytitle("Average R-squared") ///
    xtitle("") ///
    xlabel(1 "CAPM" 2 "Three-Factor") ///
    ylabel(0(0.2)1.0) ///
    legend(off) ///
    note("Average across 25 Size-B/M portfolios")

graph export "$root/output/figures/fig6_rsq_comparison.png", replace width(1200)
restore

/*------------------------------------------------------------------------------
    Figure 7: Cumulative Factor Returns
------------------------------------------------------------------------------*/

di "Creating Figure 7: Cumulative Factor Returns..."

use "$root/data/processed/merged_data.dta", clear

* Calculate cumulative returns (log scale approximation)
gen cum_mktrf = sum(mktrf/100)
gen cum_smb = sum(smb/100)
gen cum_hml = sum(hml/100)

* Convert to percentage growth
replace cum_mktrf = (exp(cum_mktrf) - 1) * 100
replace cum_smb = (exp(cum_smb) - 1) * 100
replace cum_hml = (exp(cum_hml) - 1) * 100

twoway (line cum_mktrf date, lcolor(navy) lwidth(medium)) ///
    (line cum_smb date, lcolor(forest_green) lwidth(medium)) ///
    (line cum_hml date, lcolor(maroon) lwidth(medium)), ///
    title("Cumulative Factor Returns (1926-2025)") ///
    subtitle("Log-scale cumulative returns") ///
    ytitle("Cumulative Return (%)") ///
    xtitle("Date") ///
    legend(order(1 "Market (Mkt-RF)" 2 "Size (SMB)" 3 "Value (HML)") position(11) ring(0) cols(1)) ///
    note("Starting value = 0% in July 1926")

graph export "$root/output/figures/fig7_cumulative_returns.png", replace width(1200)

/*------------------------------------------------------------------------------
    Figure 8: Heatmap of Mean Returns (5x5)
------------------------------------------------------------------------------*/

di "Creating Figure 8: Mean Returns Heatmap..."

preserve
clear
set obs 25
gen size = .
gen bm = .
gen mean_return = .

local i = 1
forvalues s = 1/5 {
    forvalues b = 1/5 {
        replace size = `s' in `i'
        replace bm = `b' in `i'
        replace mean_return = mean_ret[`s', `b'] in `i'
        local i = `i' + 1
    }
}

* Create heatmap using scatter with marker size
twoway (scatter size bm [w=mean_return], msymbol(square) msize(*3) mcolor(navy%70)), ///
    title("Mean Excess Returns: 5x5 Size-B/M Portfolios") ///
    subtitle("Marker size proportional to return magnitude") ///
    ytitle("Size (1=Small, 5=Big)") ///
    xtitle("Book-to-Market (1=Low, 5=High)") ///
    ylabel(1 "Small" 2 "2" 3 "3" 4 "4" 5 "Big", angle(0)) ///
    xlabel(1 "Low" 2 "2" 3 "3" 4 "4" 5 "High") ///
    legend(off) ///
    note("Returns increase from Big/Low (bottom-left) to Small/High (top-right)")

graph export "$root/output/figures/fig8_returns_heatmap.png", replace width(1200)
restore

/*------------------------------------------------------------------------------
    Summary
------------------------------------------------------------------------------*/

di ""
di "======================================================================"
di "FIGURES CREATED SUCCESSFULLY!"
di "======================================================================"
di ""
di "Output files saved to: $root/output/figures/"
di ""
di "  fig1_returns_by_size.png     - Size effect visualization"
di "  fig2_returns_by_bm.png       - Value effect visualization"
di "  fig3_smb_loadings.png        - SMB factor loadings by size"
di "  fig4_hml_loadings.png        - HML factor loadings by B/M"
di "  fig5_alpha_comparison.png    - CAPM vs FF3 alphas scatter"
di "  fig6_rsq_comparison.png      - R-squared comparison"
di "  fig7_cumulative_returns.png  - Factor cumulative returns"
di "  fig8_returns_heatmap.png     - 5x5 returns heatmap"
di ""
di "======================================================================"

