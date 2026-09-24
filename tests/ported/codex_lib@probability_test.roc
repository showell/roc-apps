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

pb_cdf_0 : Text
pb_cdf_0 = Text.show_int(Probability.normal_cdf(Probability.normal_standard, 0))

pb_cdf_1 : Text
pb_cdf_1 = (if (Probability.normal_cdf(Probability.normal_standard, 1000) > 700) { "above-700" } else { "low" })

pb_pdf_0 : Text
pb_pdf_0 = (if (Probability.normal_pdf(Probability.normal_standard, 0) > 300) { "above-300" } else { "low" })

pb_poisson : Text
pb_poisson = Text.show_int(Probability.poisson_pmf(Probability.poisson(3000), 0))

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Text.concat("normal-cdf-0=", pb_cdf_0)))
	line!(Text.printed(Text.concat("normal-cdf-1=", pb_cdf_1)))
	line!(Text.printed(Text.concat("normal-cdf-neg1=", Text.show_int(Probability.normal_cdf(Probability.normal_standard, (-1000))))))
	line!(Text.printed(Text.concat("normal-cdf-scaled=", Text.show_int(Probability.normal_cdf(Probability.normal(1000, 2000), 3000)))))
	line!(Text.printed(Text.concat("normal-cdf-2sig=", Text.show_int(Probability.normal_cdf(Probability.normal_standard, 2000)))))
	line!(Text.printed(Text.concat("normal-cdf-3sig=", Text.show_int(Probability.normal_cdf(Probability.normal_standard, 3000)))))
	line!(Text.printed(Text.concat("normal-cdf-neg3sig=", Text.show_int(Probability.normal_cdf(Probability.normal_standard, (-3000))))))
	line!(Text.printed(Text.concat("normal-pdf-0=", pb_pdf_0)))
	line!(Text.printed(Text.concat("expneg-1=", Text.show_int(Probability.prob_exp_neg(1000)))))
	line!(Text.printed(Text.concat("expneg-3=", Text.show_int(Probability.prob_exp_neg(3000)))))
	line!(Text.printed(Text.concat("expneg-4=", Text.show_int(Probability.prob_exp_neg(4000)))))
	line!(Text.printed(Text.concat("expneg-6=", Text.show_int(Probability.prob_exp_neg(6000)))))
	line!(Text.printed(Text.concat("poisson-pmf-0=", pb_poisson)))
	line!(Text.printed(Text.concat("poisson-pmf-1=", Text.show_int(Probability.poisson_pmf(Probability.poisson(3000), 1)))))
	line!(Text.printed(Text.concat("poisson-pmf-2=", Text.show_int(Probability.poisson_pmf(Probability.poisson(3000), 2)))))
	line!(Text.printed(Text.concat("binom-mean=", Text.show_int(Probability.binomial_mean(Probability.binomial(10, 500))))))
	line!(Text.printed(Text.concat("binom-var=", Text.show_int(Probability.binomial_variance(Probability.binomial(10, 500))))))
	line!(Text.printed(Text.concat("exp-mean=", Text.show_int(Probability.exponential_mean(Probability.exponential(500))))))
	line!(Text.printed(Text.concat("bound=", Text.show_int(Probability.uniform_bound(10, 20, 37)))))
	line!(Text.printed(Text.concat("choose-5-2=", Text.show_int(Probability.prob_choose(5, 2)))))
	line!(Text.printed(Text.concat("choose-0=", Text.show_int(Probability.prob_choose(5, 0)))))
	Ok({})
}
