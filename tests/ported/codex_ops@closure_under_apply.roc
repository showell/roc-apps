# ops@closure-under-apply
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@closure-under-apply.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     full: 6
#     flat-two: 42
#     split-one-at-a-time: 42
#     split-four: 10
#     half-then-one: 10

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# ClosureUnderApply -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

add3 : I64, I64, I64 -> I64
add3 = |a, b, c| ((a + b) + c)

add4 : I64, I64, I64, I64 -> I64
add4 = |a, b, c, d| (((a + b) + c) + d)

# --- Entry ---

main! = |_args| {
	line!(Text.printed(List.concat([28, 25, 23, 23, 69, 2], Text.show_int(add3(1, 2, 3)))))
	({
		h = ({
			dev__1 = 10
			|dev__2, dev__3| add3(dev__1, dev__2, dev__3)
		})
		({
			line!(Text.printed(List.concat([28, 23, 15, 14, 73, 14, 27, 16, 69, 2], Text.show_int(h(20, 12)))))
			({
				j = ({
					dev__4 = 10
					|dev__5, dev__6| add3(dev__4, dev__5, dev__6)
				})
				g = ({
					dev__7 = 20
					|dev__8| j(dev__7, dev__8)
				})
				({
					line!(Text.printed(List.concat([19, 31, 23, 17, 14, 73, 16, 18, 13, 73, 15, 14, 73, 15, 73, 14, 17, 26, 13, 69, 2], Text.show_int(g(12)))))
					({
						k = ({
							dev__9 = 1
							|dev__10, dev__11, dev__12| add4(dev__9, dev__10, dev__11, dev__12)
						})
						k2 = ({
							dev__13 = 2
							|dev__14, dev__15| k(dev__13, dev__14, dev__15)
						})
						k3 = ({
							dev__16 = 3
							|dev__17| k2(dev__16, dev__17)
						})
						({
							line!(Text.printed(List.concat([19, 31, 23, 17, 14, 73, 28, 16, 25, 21, 69, 2], Text.show_int(k3(4)))))
							({
								m = ({
									dev__18 = 1
									dev__19 = 2
									|dev__20, dev__21| add4(dev__18, dev__19, dev__20, dev__21)
								})
								m2 = ({
									dev__22 = 3
									|dev__23| m(dev__22, dev__23)
								})
								line!(Text.printed(List.concat([20, 15, 23, 28, 73, 14, 20, 13, 18, 73, 16, 18, 13, 69, 2], Text.show_int(m2(4)))))
							})
						})
					})
				})
			})
		})
	})
	Ok({})
}
