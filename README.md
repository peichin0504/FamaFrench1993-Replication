# Fama-French (1993) Replication

This repo contains my replication of Fama and French's classic 1993 paper "Common Risk Factors in the Returns on Stocks and Bonds" published in the Journal of Financial Economics.

## What's this about?

The Fama-French three-factor model is one of the most influential papers in finance. It basically says that CAPM isn't enough — you need two more factors (size and value) to explain why some stocks earn higher returns than others.

I replicated their main results using Stata with data from Ken French's website, covering July 1926 to May 2025 (almost 100 years of data).

## Main findings

The three-factor model works way better than CAPM:

|  | CAPM | Three-Factor |
|--|------|--------------|
| Avg R² | 0.77 | 0.91 |
| Avg pricing error | 0.15%/month | 0.12%/month |

So adding SMB and HML really does help explain returns.

## Repo structure

```
code/           <- Stata do-files (run these in order)
paper/          <- My write-up of the results
output/         <- Where the tables go when you run the code
```

## Data

Everything comes from Ken French's Data Library:
- 25 portfolios sorted on size and book-to-market
- The three factors (Mkt-RF, SMB, HML)

## How to run

1. Download the data from Ken French's website
2. Change the file path in each do-file to wherever you saved the data
3. Run the do-files in order (01, 02, 03...)

## Files

| File | What it does |
|------|--------------|
| 01_data_preparation.do | Imports and cleans the data |
| 02_summary_statistics.do | Summary stats for factors and portfolios |
| 03_capm_regressions.do | Runs CAPM for all 25 portfolios |
| 04_threefactor_regressions.do | Runs FF3 model (the main result) |
| 05_grs_test.do | GRS test to see if alphas are jointly zero |
| 06_figures.do | Makes some charts |

## References

Fama, E. F., & French, K. R. (1993). Common risk factors in the returns on stocks and bonds. *Journal of Financial Economics*, 33(1), 3-56.
