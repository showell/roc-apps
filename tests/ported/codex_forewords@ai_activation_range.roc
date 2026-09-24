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

r : Text, I64, I64, Text -> Text
r = |what, x, got, want| Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat("  ", what), " "), Text.show_int(x)), " = "), Text.show_int(got)), "  true "), want)

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
	line!(Text.printed("sigmoid, which must rise and stay inside (0, 1000):"))
	line!(Text.printed(r("sigmoid", 0, Activation.act_sigmoid_val(0), "500 exact, and the control: no error can move it")))
	line!(Text.printed(r("sigmoid", 2000, Activation.act_sigmoid_val(2000), "881")))
	line!(Text.printed(r("sigmoid", 3000, Activation.act_sigmoid_val(3000), "953")))
	line!(Text.printed(r("sigmoid", 5000, Activation.act_sigmoid_val(5000), "993")))
	line!(Text.printed(r("sigmoid", (0 - 3000), Activation.act_sigmoid_val((0 - 3000)), "47")))
	line!(Text.printed(""))
	line!(Text.printed("no cliff where the old guard sat, at 6000:"))
	line!(Text.printed(r("sigmoid", 5999, Activation.act_sigmoid_val(5999), "998")))
	line!(Text.printed(r("sigmoid", 6001, Activation.act_sigmoid_val(6001), "998")))
	line!(Text.printed(""))
	line!(Text.printed("tanh, which must rise and stay inside (-1000, 1000):"))
	line!(Text.printed(r("tanh", 1000, Activation.act_tanh_val(1000), "762")))
	line!(Text.printed(r("tanh", 2000, Activation.act_tanh_val(2000), "964")))
	line!(Text.printed(r("tanh", 3000, Activation.act_tanh_val(3000), "995")))
	line!(Text.printed(r("tanh", (0 - 2000), Activation.act_tanh_val((0 - 2000)), "-964")))
	line!(Text.printed(""))
	line!(Text.printed("exp on NEGATIVE arguments, which is the only side softmax ever"))
	line!(Text.printed("asks for, because it shifts by the maximum first:"))
	line!(Text.printed(r("exp", 0, Activation.act_exp_approx(0), "1000 exact, the control")))
	line!(Text.printed(r("exp", (0 - 1000), Activation.act_exp_approx((0 - 1000)), "368")))
	line!(Text.printed(r("exp", (0 - 2000), Activation.act_exp_approx((0 - 2000)), "135")))
	line!(Text.printed(r("exp", (0 - 3000), Activation.act_exp_approx((0 - 3000)), "50")))
	line!(Text.printed(""))
	line!(Text.printed("gelu, which asks the sigmoid for 1.702x and so reaches the old"))
	line!(Text.printed("broken region sooner than the sigmoid itself did:"))
	line!(Text.printed(r("gelu", 2000, Activation.act_gelu_val(2000), "1955")))
	line!(Text.printed(r("gelu", 3000, Activation.act_gelu_val(3000), "2996")))
	line!(Text.printed(""))
	line!(Text.printed("monotonicity, counted rather than eyeballed. Both were false"))
	line!(Text.printed("before: the sigmoid turned over at z=2 and exp at z=-1."))
	line!(Text.printed(Text.concat(Text.concat("  sigmoid non-decreasing over z=0..12: ", Text.show_int(mono(0, 12, (0 - 1), 0))), " of 13")))
	line!(Text.printed(Text.concat(Text.concat("  exp non-decreasing over z=0..12:     ", Text.show_int(mono_exp(0, 12, (0 - 1), 0))), " of 13")))
	Ok({})
}
