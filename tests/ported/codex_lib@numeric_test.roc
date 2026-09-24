# lib@numeric-test
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/lib@numeric-test.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     bisect=2000
#     newton=2001
#     trap=8999
#     simpson=8998
#     rk4-t=100
#     rk4-y=decaying
#     rk4-steps=11

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.Numeric

# NumericTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

test_f : I64 -> I64
test_f = |x| (I64.div_trunc_by((x * x), 1000) - 4000)

test_df : I64 -> I64
test_df = |x| (2 * x)

test_ode : I64, I64 -> I64
test_ode = |_t, y| (0 - y)

lam_0 : I64 -> I64
lam_0 = |x| I64.div_trunc_by((x * x), 1000)

lam_1 : I64 -> I64
lam_1 = |x| I64.div_trunc_by((x * x), 1000)

# --- Entry ---

main! = |_args| {
	({
		root = Numeric.bisect(test_f, 0, 4000, 50)
		({
			line!(CceText.printed(CceText.concat("bisect=", CceText.show_int(root))))
			({
				newton_root = Numeric.newton(test_f, test_df, 3000, 20)
				({
					line!(CceText.printed(CceText.concat("newton=", CceText.show_int(newton_root))))
					({
						trap = Numeric.integrate_trapezoid(lam_0, 0, 3000, 100)
						({
							line!(CceText.printed(CceText.concat("trap=", CceText.show_int(trap))))
							({
								simp = Numeric.integrate_simpson(lam_1, 0, 3000, 100)
								({
									line!(CceText.printed(CceText.concat("simpson=", CceText.show_int(simp))))
									({
										step = Numeric.rk4_step(test_ode, 0, 1000, 100)
										({
											line!(CceText.printed(CceText.concat("rk4-t=", CceText.show_int(step.rk_t))))
											({
												rk_ok = (if (step.rk_y < 1000) { "decaying" } else { "wrong" })
												({
													line!(CceText.printed(CceText.concat("rk4-y=", rk_ok)))
													({
														solution = Numeric.rk4_solve(test_ode, 0, 1000, 1, 10)
														line!(CceText.printed(CceText.concat("rk4-steps=", CceText.show_int(U64.to_i64_wrap(List.len(solution))))))
													})
												})
											})
										})
									})
								})
							})
						})
					})
				})
			})
		})
	})
	Ok({})
}
