# forewords@math-cordic-accuracy
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/forewords@math-cordic-accuracy.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#       0 sin 0 true 0   cos 997 true 1000   err 3
#       300 sin 291 true 296   cos 955 true 955   err 5
#       500 sin 480 true 479   cos 875 true 878   err 3
#       785 sin 707 true 707   cos 706 true 707   err 1
#       1000 sin 841 true 841   cos 538 true 540   err 2
#       1571 sin 997 true 1000   cos -2 true 0   err 3
#       1800 sin 974 true 974   cos -227 true -227   err 0
#       2000 sin 908 true 909   cos -415 true -416   err 1
#       2500 sin 598 true 598   cos -800 true -801   err 1
#       3000 sin 140 true 141   cos -988 true -990   err 2
#       3141 sin 0 true 1   cos -997 true -1000   err 3
#       3163 sin -16 true -21   cos -998 true -1000   err 5
#       3255 sin -109 true -113   cos -993 true -994   err 4
#       3500 sin -351 true -351   cos -935 true -936   err 1
#       4000 sin -756 true -757   cos -653 true -654   err 1
#       4712 sin -997 true -1000   cos 0 true 0   err 3
#       5000 sin -959 true -959   cos 283 true 284   err 1
#       5500 sin -704 true -706   cos 709 true 709   err 2
#       6000 sin -276 true -279   cos 960 true 960   err 3
#       6283 sin 0 true 0   cos 997 true 1000   err 3
#     worst absolute error over the sample: 5 of 1000 full scale
#     within 6 of 1000: 20 of 20

app [main!] { cdx: "./codex/main.roc" }

import cdx.Cordic
import cdx.Text

# FwdCordicAccuracyTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

acc_angles : List(I64)
acc_angles = [0, 300, 500, 785, 1000, 1571, 1800, 2000, 2500, 3000, 3141, 3163, 3255, 3500, 4000, 4712, 5000, 5500, 6000, 6283]

acc_true_sin : List(I64)
acc_true_sin = [0, 296, 479, 707, 841, 1000, 974, 909, 598, 141, 1, (-21), (-113), (-351), (-757), (-1000), (-959), (-706), (-279), 0]

acc_true_cos : List(I64)
acc_true_cos = [1000, 955, 878, 707, 540, 0, (-227), (-416), (-801), (-990), (-1000), (-1000), (-994), (-936), (-654), 0, 284, 709, 960, 1000]

acc_abs : I64 -> I64
acc_abs = |x| (if (x < 0) { (0 - x) } else { x })

acc_err_at : I64 -> I64
acc_err_at = |i| ({
	a = (List.get(acc_angles, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
	es = acc_abs((Cordic.cordic_sin(a) - (List.get(acc_true_sin, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))
	ec = acc_abs((Cordic.cordic_cos(a) - (List.get(acc_true_cos, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))
	(if (es > ec) { es } else { ec })
})

acc_worst : I64, I64 -> I64
acc_worst = |i, so_far| (if (i >= U64.to_i64_wrap(List.len(acc_angles))) { so_far } else { ({
	e = acc_err_at(i)
	acc_worst((i + 1), (if (e > so_far) { e } else { so_far }))
}) })

acc_within : I64, I64 -> I64
acc_within = |i, n| (if (i >= U64.to_i64_wrap(List.len(acc_angles))) { n } else { acc_within((i + 1), (if (acc_err_at(i) <= 6) { (n + 1) } else { n })) })

acc_line : I64 -> List(U8)
acc_line = |i| ({
	a = (List.get(acc_angles, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
	List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat([2, 2], Text.show_int(a)), [2, 19, 17, 18, 2]), Text.show_int(Cordic.cordic_sin(a))), [2, 14, 21, 25, 13, 2]), Text.show_int((List.get(acc_true_sin, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))), [2, 2, 2, 24, 16, 19, 2]), Text.show_int(Cordic.cordic_cos(a))), [2, 14, 21, 25, 13, 2]), Text.show_int((List.get(acc_true_cos, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))), [2, 2, 2, 13, 21, 21, 2]), Text.show_int(acc_err_at(i)))
})

acc_report : List(U8)
acc_report = ({
	w = acc_worst(0, 0)
	List.concat(List.concat([27, 16, 21, 19, 14, 2, 15, 32, 19, 16, 23, 25, 14, 13, 2, 13, 21, 21, 16, 21, 2, 16, 33, 13, 21, 2, 14, 20, 13, 2, 19, 15, 26, 31, 23, 13, 69, 2], Text.show_int(w)), [2, 16, 28, 2, 4, 3, 3, 3, 2, 28, 25, 23, 23, 2, 19, 24, 15, 23, 13])
})

acc_count : List(U8)
acc_count = ({
	n = acc_within(0, 0)
	List.concat(List.concat(List.concat([27, 17, 14, 20, 17, 18, 2, 9, 2, 16, 28, 2, 4, 3, 3, 3, 69, 2], Text.show_int(n)), [2, 16, 28, 2]), Text.show_int(U64.to_i64_wrap(List.len(acc_angles))))
})

# --- Entry ---

main! = |_args| {
	line!(Text.printed(acc_line(0)))
	line!(Text.printed(acc_line(1)))
	line!(Text.printed(acc_line(2)))
	line!(Text.printed(acc_line(3)))
	line!(Text.printed(acc_line(4)))
	line!(Text.printed(acc_line(5)))
	line!(Text.printed(acc_line(6)))
	line!(Text.printed(acc_line(7)))
	line!(Text.printed(acc_line(8)))
	line!(Text.printed(acc_line(9)))
	line!(Text.printed(acc_line(10)))
	line!(Text.printed(acc_line(11)))
	line!(Text.printed(acc_line(12)))
	line!(Text.printed(acc_line(13)))
	line!(Text.printed(acc_line(14)))
	line!(Text.printed(acc_line(15)))
	line!(Text.printed(acc_line(16)))
	line!(Text.printed(acc_line(17)))
	line!(Text.printed(acc_line(18)))
	line!(Text.printed(acc_line(19)))
	line!(Text.printed(acc_report))
	line!(Text.printed(acc_count))
	Ok({})
}
