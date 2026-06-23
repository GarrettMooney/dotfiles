---
name: r-bayesian-stats
description: Use when user wants to visualize probability distributions (beta, normal, etc.) or run Bayesian hypothesis tests (t-test, proportion test, binomial test) - generates R code and runs via Rscript
---

# R Bayesian Statistics

## Overview

Generate and execute R code for:
1. **Distribution histograms** - Visualize samples from probability distributions
2. **Bayesian hypothesis tests** - Run Bayesian alternatives to classical NHST using BayesianFirstAid

## When to Use

- User asks to visualize a distribution (beta, normal, gamma, etc.)
- User wants to compare two groups (Bayesian t-test)
- User has proportion/binomial data and wants Bayesian inference
- User mentions "Bayesian" + any classical test name

## Distribution Histograms

Generate histograms from distribution samples.

### Beta Distribution
```r
# Beta(alpha, beta)
hist(rbeta(1e4, 2, 5), main='10,000 samples from Beta(2,5)', xlab='Value', col='#8080ff', border='white')
```

### Normal Distribution
```r
# Normal(mean, sd)
hist(rnorm(1e4, 0, 1), main='10,000 samples from Normal(0,1)', xlab='Value', col='#8080ff', border='white')
```

### Other Distributions
```r
# Gamma(shape, rate)
hist(rgamma(1e4, 2, 1), main='10,000 samples from Gamma(2,1)', xlab='Value', col='#8080ff', border='white')

# Exponential(rate)
hist(rexp(1e4, 0.5), main='10,000 samples from Exp(0.5)', xlab='Value', col='#8080ff', border='white')

# Uniform(min, max)
hist(runif(1e4, 0, 10), main='10,000 samples from Uniform(0,10)', xlab='Value', col='#8080ff', border='white')

# Poisson(lambda)
hist(rpois(1e4, 5), main='10,000 samples from Poisson(5)', xlab='Value', col='#8080ff', border='white')
```

## Bayesian Hypothesis Tests (BayesianFirstAid)

All tests use the `BayesianFirstAid` package. Each returns:
- `summary(m)` - Posterior statistics, credible intervals, model diagnostics
- `plot(m)` - Diagnostic plots and posterior distributions

### Bayesian T-Test
Compare two groups:
```r
library(BayesianFirstAid)

lhs <- c(5.1, 4.9, 4.7, 4.6, 5.0, 5.4, 4.6, 5.0, 4.4, 4.9)
rhs <- c(7.0, 6.4, 6.9, 5.5, 6.5, 5.7, 6.3, 4.9, 6.6, 5.2)

m <- bayes.t.test(lhs, rhs)
summary(m)
plot(m)
```

### Bayesian Proportion Test
Compare proportions across groups:
```r
library(BayesianFirstAid)

numerator <- c(12, 15, 14, 10, 13)
denominator <- c(20, 22, 19, 18, 21)

m <- bayes.prop.test(numerator, denominator)
summary(m)
plot(m)
```

### Bayesian Binomial Test
Single proportion inference:
```r
library(BayesianFirstAid)

successes <- 15
trials <- 50

m <- bayes.binom.test(successes, trials)
summary(m)
plot(m)
```

### Bayesian Correlation Test
```r
library(BayesianFirstAid)

x <- c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
y <- c(2.1, 4.0, 5.8, 8.2, 9.5, 12.1, 14.3, 15.8, 18.0, 20.1)

m <- bayes.cor.test(x, y)
summary(m)
plot(m)
```

### Bayesian Poisson Test
```r
library(BayesianFirstAid)

counts <- 45
time <- 10  # exposure time

m <- bayes.poisson.test(counts, time)
summary(m)
plot(m)
```

## Execution

Run R code via Rscript. For plots, save to a temp file and open:

```bash
# Simple histogram (no packages needed)
Rscript -e "png('/tmp/hist.png', width=800, height=600); hist(rbeta(1e4, 2, 5), main='Beta(2,5)', col='#8080ff', border='white'); dev.off()" && open /tmp/hist.png

# Bayesian test with plot
Rscript -e "
library(BayesianFirstAid)
lhs <- c(5.1, 4.9, 4.7, 4.6, 5.0)
rhs <- c(7.0, 6.4, 6.9, 5.5, 6.5)
m <- bayes.t.test(lhs, rhs)
print(summary(m))
png('/tmp/bayes_plot.png', width=800, height=600)
plot(m)
dev.off()
" && open /tmp/bayes_plot.png
```

## Package Installation

If BayesianFirstAid is not installed:
```r
install.packages("BayesianFirstAid", repos="http://cran.r-project.org")
```

Or from GitHub for latest:
```r
# install.packages("devtools")
devtools::install_github("rasmusab/bayesian_first_aid")
```

## Tips

- Use `1e4` (10,000) samples for smooth histograms
- BayesianFirstAid tests run MCMC - may take a few seconds
- Plots from BayesianFirstAid show posteriors and diagnostics
- Check `model.code(m)` to see the underlying JAGS model
