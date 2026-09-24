# lib@probability-test
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/lib@probability-test.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     normal-cdf-0=500
#     normal-cdf-1=above-700
#     normal-cdf-neg1=159
#     normal-cdf-scaled=841
#     normal-cdf-2sig=977
#     normal-cdf-3sig=999
#     normal-cdf-neg3sig=1
#     normal-pdf-0=above-300
#     expneg-1=368
#     expneg-3=50
#     expneg-4=18
#     expneg-6=3
#     poisson-pmf-0=50
#     poisson-pmf-1=150
#     poisson-pmf-2=225
#     binom-mean=5
#     binom-var=2
#     exp-mean=2000
#     bound=14
#     choose-5-2=10
#     choose-0=1

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.Probability

# ProbabilityTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

pb_cdf_0 : CceText
pb_cdf_0 = CceText.show_int(Probability.normal_cdf(Probability.normal_standard, 0))

pb_cdf_1 : CceText
pb_cdf_1 = (if (Probability.normal_cdf(Probability.normal_standard, 1000) > 700) { "above-700" } else { "low" })

pb_pdf_0 : CceText
pb_pdf_0 = (if (Probability.normal_pdf(Probability.normal_standard, 0) > 300) { "above-300" } else { "low" })

pb_poisson : CceText
pb_poisson = CceText.show_int(Probability.poisson_pmf(Probability.poisson(3000), 0))

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("normal-cdf-0=", pb_cdf_0)))
	line!(CceText.printed(CceText.concat("normal-cdf-1=", pb_cdf_1)))
	line!(CceText.printed(CceText.concat("normal-cdf-neg1=", CceText.show_int(Probability.normal_cdf(Probability.normal_standard, (-1000))))))
	line!(CceText.printed(CceText.concat("normal-cdf-scaled=", CceText.show_int(Probability.normal_cdf(Probability.normal(1000, 2000), 3000)))))
	line!(CceText.printed(CceText.concat("normal-cdf-2sig=", CceText.show_int(Probability.normal_cdf(Probability.normal_standard, 2000)))))
	line!(CceText.printed(CceText.concat("normal-cdf-3sig=", CceText.show_int(Probability.normal_cdf(Probability.normal_standard, 3000)))))
	line!(CceText.printed(CceText.concat("normal-cdf-neg3sig=", CceText.show_int(Probability.normal_cdf(Probability.normal_standard, (-3000))))))
	line!(CceText.printed(CceText.concat("normal-pdf-0=", pb_pdf_0)))
	line!(CceText.printed(CceText.concat("expneg-1=", CceText.show_int(Probability.prob_exp_neg(1000)))))
	line!(CceText.printed(CceText.concat("expneg-3=", CceText.show_int(Probability.prob_exp_neg(3000)))))
	line!(CceText.printed(CceText.concat("expneg-4=", CceText.show_int(Probability.prob_exp_neg(4000)))))
	line!(CceText.printed(CceText.concat("expneg-6=", CceText.show_int(Probability.prob_exp_neg(6000)))))
	line!(CceText.printed(CceText.concat("poisson-pmf-0=", pb_poisson)))
	line!(CceText.printed(CceText.concat("poisson-pmf-1=", CceText.show_int(Probability.poisson_pmf(Probability.poisson(3000), 1)))))
	line!(CceText.printed(CceText.concat("poisson-pmf-2=", CceText.show_int(Probability.poisson_pmf(Probability.poisson(3000), 2)))))
	line!(CceText.printed(CceText.concat("binom-mean=", CceText.show_int(Probability.binomial_mean(Probability.binomial(10, 500))))))
	line!(CceText.printed(CceText.concat("binom-var=", CceText.show_int(Probability.binomial_variance(Probability.binomial(10, 500))))))
	line!(CceText.printed(CceText.concat("exp-mean=", CceText.show_int(Probability.exponential_mean(Probability.exponential(500))))))
	line!(CceText.printed(CceText.concat("bound=", CceText.show_int(Probability.uniform_bound(10, 20, 37)))))
	line!(CceText.printed(CceText.concat("choose-5-2=", CceText.show_int(Probability.prob_choose(5, 2)))))
	line!(CceText.printed(CceText.concat("choose-0=", CceText.show_int(Probability.prob_choose(5, 0)))))
	Ok({})
}
