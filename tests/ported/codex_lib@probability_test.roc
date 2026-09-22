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

import cdx.Probability
import cdx.Text

# ProbabilityTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

pb_cdf_0 : List(U8)
pb_cdf_0 = Text.show_int(Probability.normal_cdf(Probability.normal_standard, 0))

pb_cdf_1 : List(U8)
pb_cdf_1 = (if (Probability.normal_cdf(Probability.normal_standard, 1000) > 700) { [15, 32, 16, 33, 13, 73, 10, 3, 3] } else { [23, 16, 27] })

pb_pdf_0 : List(U8)
pb_pdf_0 = (if (Probability.normal_pdf(Probability.normal_standard, 0) > 300) { [15, 32, 16, 33, 13, 73, 6, 3, 3] } else { [23, 16, 27] })

pb_poisson : List(U8)
pb_poisson = Text.show_int(Probability.poisson_pmf(Probability.poisson(3000), 0))

# --- Entry ---

main! = |_args| {
	line!(Text.printed(List.concat([18, 16, 21, 26, 15, 23, 73, 24, 22, 28, 73, 3, 77], pb_cdf_0)))
	line!(Text.printed(List.concat([18, 16, 21, 26, 15, 23, 73, 24, 22, 28, 73, 4, 77], pb_cdf_1)))
	line!(Text.printed(List.concat([18, 16, 21, 26, 15, 23, 73, 24, 22, 28, 73, 18, 13, 29, 4, 77], Text.show_int(Probability.normal_cdf(Probability.normal_standard, (-1000))))))
	line!(Text.printed(List.concat([18, 16, 21, 26, 15, 23, 73, 24, 22, 28, 73, 19, 24, 15, 23, 13, 22, 77], Text.show_int(Probability.normal_cdf(Probability.normal(1000, 2000), 3000)))))
	line!(Text.printed(List.concat([18, 16, 21, 26, 15, 23, 73, 24, 22, 28, 73, 5, 19, 17, 29, 77], Text.show_int(Probability.normal_cdf(Probability.normal_standard, 2000)))))
	line!(Text.printed(List.concat([18, 16, 21, 26, 15, 23, 73, 24, 22, 28, 73, 6, 19, 17, 29, 77], Text.show_int(Probability.normal_cdf(Probability.normal_standard, 3000)))))
	line!(Text.printed(List.concat([18, 16, 21, 26, 15, 23, 73, 24, 22, 28, 73, 18, 13, 29, 6, 19, 17, 29, 77], Text.show_int(Probability.normal_cdf(Probability.normal_standard, (-3000))))))
	line!(Text.printed(List.concat([18, 16, 21, 26, 15, 23, 73, 31, 22, 28, 73, 3, 77], pb_pdf_0)))
	line!(Text.printed(List.concat([13, 36, 31, 18, 13, 29, 73, 4, 77], Text.show_int(Probability.prob_exp_neg(1000)))))
	line!(Text.printed(List.concat([13, 36, 31, 18, 13, 29, 73, 6, 77], Text.show_int(Probability.prob_exp_neg(3000)))))
	line!(Text.printed(List.concat([13, 36, 31, 18, 13, 29, 73, 7, 77], Text.show_int(Probability.prob_exp_neg(4000)))))
	line!(Text.printed(List.concat([13, 36, 31, 18, 13, 29, 73, 9, 77], Text.show_int(Probability.prob_exp_neg(6000)))))
	line!(Text.printed(List.concat([31, 16, 17, 19, 19, 16, 18, 73, 31, 26, 28, 73, 3, 77], pb_poisson)))
	line!(Text.printed(List.concat([31, 16, 17, 19, 19, 16, 18, 73, 31, 26, 28, 73, 4, 77], Text.show_int(Probability.poisson_pmf(Probability.poisson(3000), 1)))))
	line!(Text.printed(List.concat([31, 16, 17, 19, 19, 16, 18, 73, 31, 26, 28, 73, 5, 77], Text.show_int(Probability.poisson_pmf(Probability.poisson(3000), 2)))))
	line!(Text.printed(List.concat([32, 17, 18, 16, 26, 73, 26, 13, 15, 18, 77], Text.show_int(Probability.binomial_mean(Probability.binomial(10, 500))))))
	line!(Text.printed(List.concat([32, 17, 18, 16, 26, 73, 33, 15, 21, 77], Text.show_int(Probability.binomial_variance(Probability.binomial(10, 500))))))
	line!(Text.printed(List.concat([13, 36, 31, 73, 26, 13, 15, 18, 77], Text.show_int(Probability.exponential_mean(Probability.exponential(500))))))
	line!(Text.printed(List.concat([32, 16, 25, 18, 22, 77], Text.show_int(Probability.uniform_bound(10, 20, 37)))))
	line!(Text.printed(List.concat([24, 20, 16, 16, 19, 13, 73, 8, 73, 5, 77], Text.show_int(Probability.prob_choose(5, 2)))))
	line!(Text.printed(List.concat([24, 20, 16, 16, 19, 13, 73, 3, 77], Text.show_int(Probability.prob_choose(5, 0)))))
	Ok({})
}
