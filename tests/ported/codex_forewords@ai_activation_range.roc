# forewords@ai-activation-range
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/forewords@ai-activation-range.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     sigmoid, which must rise and stay inside (0, 1000):
#       sigmoid 0 = 500  true 500 exact, and the control: no error can move it
#       sigmoid 2000 = 881  true 881
#       sigmoid 3000 = 953  true 953
#       sigmoid 5000 = 994  true 993
#       sigmoid -3000 = 47  true 47
#     
#     no cliff where the old guard sat, at 6000:
#       sigmoid 5999 = 998  true 998
#       sigmoid 6001 = 998  true 998
#     
#     tanh, which must rise and stay inside (-1000, 1000):
#       tanh 1000 = 762  true 762
#       tanh 2000 = 964  true 964
#       tanh 3000 = 996  true 995
#       tanh -2000 = -966  true -964
#     
#     exp on NEGATIVE arguments, which is the only side softmax ever
#     asks for, because it shifts by the maximum first:
#       exp 0 = 1000  true 1000 exact, the control
#       exp -1000 = 367  true 368
#       exp -2000 = 135  true 135
#       exp -3000 = 49  true 50
#     
#     gelu, which asks the sigmoid for 1.702x and so reaches the old
#     broken region sooner than the sigmoid itself did:
#       gelu 2000 = 1936  true 1955
#       gelu 3000 = 2982  true 2996
#     
#     monotonicity, counted rather than eyeballed. Both were false
#     before: the sigmoid turned over at z=2 and exp at z=-1.
#       sigmoid non-decreasing over z=0..12: 13 of 13
#       exp non-decreasing over z=0..12:     13 of 13

app [main!] { cdx: "./codex/main.roc" }

import cdx.Activation
import cdx.Text

# AiActivationRange -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

r : List(U8), I64, I64, List(U8) -> List(U8)
r = |what, x, got, want| List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat([2, 2], what), [2]), Text.show_int(x)), [2, 77, 2]), Text.show_int(got)), [2, 2, 14, 21, 25, 13, 2]), want)

mono : I64, I64, I64, I64 -> I64
mono = |i, n, prev, acc| (if (i > n) { acc } else { ({
	v = Activation.act_sigmoid_val((i * 1000))
	mono((i + 1), n, v, (if (v >= prev) { (acc + 1) } else { acc }))
}) })

mono_exp : I64, I64, I64, I64 -> I64
mono_exp = |i, n, prev, acc| (if (i > n) { acc } else { ({
	v = Activation.act_exp_approx((i * 1000))
	mono_exp((i + 1), n, v, (if (v >= prev) { (acc + 1) } else { acc }))
}) })

# --- Entry ---

main! = |_args| {
	line!(Text.printed([19, 17, 29, 26, 16, 17, 22, 66, 2, 27, 20, 17, 24, 20, 2, 26, 25, 19, 14, 2, 21, 17, 19, 13, 2, 15, 18, 22, 2, 19, 14, 15, 30, 2, 17, 18, 19, 17, 22, 13, 2, 74, 3, 66, 2, 4, 3, 3, 3, 75, 69]))
	line!(Text.printed(r([19, 17, 29, 26, 16, 17, 22], 0, Activation.act_sigmoid_val(0), [8, 3, 3, 2, 13, 36, 15, 24, 14, 66, 2, 15, 18, 22, 2, 14, 20, 13, 2, 24, 16, 18, 14, 21, 16, 23, 69, 2, 18, 16, 2, 13, 21, 21, 16, 21, 2, 24, 15, 18, 2, 26, 16, 33, 13, 2, 17, 14])))
	line!(Text.printed(r([19, 17, 29, 26, 16, 17, 22], 2000, Activation.act_sigmoid_val(2000), [11, 11, 4])))
	line!(Text.printed(r([19, 17, 29, 26, 16, 17, 22], 3000, Activation.act_sigmoid_val(3000), [12, 8, 6])))
	line!(Text.printed(r([19, 17, 29, 26, 16, 17, 22], 5000, Activation.act_sigmoid_val(5000), [12, 12, 6])))
	line!(Text.printed(r([19, 17, 29, 26, 16, 17, 22], (0 - 3000), Activation.act_sigmoid_val((0 - 3000)), [7, 10])))
	line!(Text.printed([]))
	line!(Text.printed([18, 16, 2, 24, 23, 17, 28, 28, 2, 27, 20, 13, 21, 13, 2, 14, 20, 13, 2, 16, 23, 22, 2, 29, 25, 15, 21, 22, 2, 19, 15, 14, 66, 2, 15, 14, 2, 9, 3, 3, 3, 69]))
	line!(Text.printed(r([19, 17, 29, 26, 16, 17, 22], 5999, Activation.act_sigmoid_val(5999), [12, 12, 11])))
	line!(Text.printed(r([19, 17, 29, 26, 16, 17, 22], 6001, Activation.act_sigmoid_val(6001), [12, 12, 11])))
	line!(Text.printed([]))
	line!(Text.printed([14, 15, 18, 20, 66, 2, 27, 20, 17, 24, 20, 2, 26, 25, 19, 14, 2, 21, 17, 19, 13, 2, 15, 18, 22, 2, 19, 14, 15, 30, 2, 17, 18, 19, 17, 22, 13, 2, 74, 73, 4, 3, 3, 3, 66, 2, 4, 3, 3, 3, 75, 69]))
	line!(Text.printed(r([14, 15, 18, 20], 1000, Activation.act_tanh_val(1000), [10, 9, 5])))
	line!(Text.printed(r([14, 15, 18, 20], 2000, Activation.act_tanh_val(2000), [12, 9, 7])))
	line!(Text.printed(r([14, 15, 18, 20], 3000, Activation.act_tanh_val(3000), [12, 12, 8])))
	line!(Text.printed(r([14, 15, 18, 20], (0 - 2000), Activation.act_tanh_val((0 - 2000)), [73, 12, 9, 7])))
	line!(Text.printed([]))
	line!(Text.printed([13, 36, 31, 2, 16, 18, 2, 44, 39, 55, 41, 40, 43, 59, 39, 2, 15, 21, 29, 25, 26, 13, 18, 14, 19, 66, 2, 27, 20, 17, 24, 20, 2, 17, 19, 2, 14, 20, 13, 2, 16, 18, 23, 30, 2, 19, 17, 22, 13, 2, 19, 16, 28, 14, 26, 15, 36, 2, 13, 33, 13, 21]))
	line!(Text.printed([15, 19, 34, 19, 2, 28, 16, 21, 66, 2, 32, 13, 24, 15, 25, 19, 13, 2, 17, 14, 2, 19, 20, 17, 28, 14, 19, 2, 32, 30, 2, 14, 20, 13, 2, 26, 15, 36, 17, 26, 25, 26, 2, 28, 17, 21, 19, 14, 69]))
	line!(Text.printed(r([13, 36, 31], 0, Activation.act_exp_approx(0), [4, 3, 3, 3, 2, 13, 36, 15, 24, 14, 66, 2, 14, 20, 13, 2, 24, 16, 18, 14, 21, 16, 23])))
	line!(Text.printed(r([13, 36, 31], (0 - 1000), Activation.act_exp_approx((0 - 1000)), [6, 9, 11])))
	line!(Text.printed(r([13, 36, 31], (0 - 2000), Activation.act_exp_approx((0 - 2000)), [4, 6, 8])))
	line!(Text.printed(r([13, 36, 31], (0 - 3000), Activation.act_exp_approx((0 - 3000)), [8, 3])))
	line!(Text.printed([]))
	line!(Text.printed([29, 13, 23, 25, 66, 2, 27, 20, 17, 24, 20, 2, 15, 19, 34, 19, 2, 14, 20, 13, 2, 19, 17, 29, 26, 16, 17, 22, 2, 28, 16, 21, 2, 4, 65, 10, 3, 5, 36, 2, 15, 18, 22, 2, 19, 16, 2, 21, 13, 15, 24, 20, 13, 19, 2, 14, 20, 13, 2, 16, 23, 22]))
	line!(Text.printed([32, 21, 16, 34, 13, 18, 2, 21, 13, 29, 17, 16, 18, 2, 19, 16, 16, 18, 13, 21, 2, 14, 20, 15, 18, 2, 14, 20, 13, 2, 19, 17, 29, 26, 16, 17, 22, 2, 17, 14, 19, 13, 23, 28, 2, 22, 17, 22, 69]))
	line!(Text.printed(r([29, 13, 23, 25], 2000, Activation.act_gelu_val(2000), [4, 12, 8, 8])))
	line!(Text.printed(r([29, 13, 23, 25], 3000, Activation.act_gelu_val(3000), [5, 12, 12, 9])))
	line!(Text.printed([]))
	line!(Text.printed([26, 16, 18, 16, 14, 16, 18, 17, 24, 17, 14, 30, 66, 2, 24, 16, 25, 18, 14, 13, 22, 2, 21, 15, 14, 20, 13, 21, 2, 14, 20, 15, 18, 2, 13, 30, 13, 32, 15, 23, 23, 13, 22, 65, 2, 58, 16, 14, 20, 2, 27, 13, 21, 13, 2, 28, 15, 23, 19, 13]))
	line!(Text.printed([32, 13, 28, 16, 21, 13, 69, 2, 14, 20, 13, 2, 19, 17, 29, 26, 16, 17, 22, 2, 14, 25, 21, 18, 13, 22, 2, 16, 33, 13, 21, 2, 15, 14, 2, 38, 77, 5, 2, 15, 18, 22, 2, 13, 36, 31, 2, 15, 14, 2, 38, 77, 73, 4, 65]))
	line!(Text.printed(List.concat(List.concat([2, 2, 19, 17, 29, 26, 16, 17, 22, 2, 18, 16, 18, 73, 22, 13, 24, 21, 13, 15, 19, 17, 18, 29, 2, 16, 33, 13, 21, 2, 38, 77, 3, 65, 65, 4, 5, 69, 2], Text.show_int(mono(0, 12, (0 - 1), 0))), [2, 16, 28, 2, 4, 6])))
	line!(Text.printed(List.concat(List.concat([2, 2, 13, 36, 31, 2, 18, 16, 18, 73, 22, 13, 24, 21, 13, 15, 19, 17, 18, 29, 2, 16, 33, 13, 21, 2, 38, 77, 3, 65, 65, 4, 5, 69, 2, 2, 2, 2, 2], Text.show_int(mono_exp(0, 12, (0 - 1), 0))), [2, 16, 28, 2, 4, 6])))
	Ok({})
}
