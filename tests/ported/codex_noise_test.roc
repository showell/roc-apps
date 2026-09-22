# noise-test
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/noise-test.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     v1d: a=254 b=288 c=323
#     v2d: a=975 b=492 c=456
#     continuous=True,True
#     f1=313 f2=687 f2>f1=True
#     fbm-a=43 fbm-b=363 differ=True
#     warped=444 unwarped=492 plain=492
#     map=16 min=21 max=975 range=True

app [main!] { cdx: "./codex/main.roc" }

import cdx.Noise
import cdx.Text

# NoiseTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

test_value_1d : List(U8)
test_value_1d = ({
	a = Noise.value_noise_1d(0)
	b = Noise.value_noise_1d(500)
	c = Noise.value_noise_1d(1000)
	List.concat(List.concat(List.concat(List.concat(List.concat([33, 4, 22, 69, 2, 15, 77], Text.show_int(a)), [2, 32, 77]), Text.show_int(b)), [2, 24, 77]), Text.show_int(c))
})

test_value_2d : List(U8)
test_value_2d = ({
	a = Noise.value_noise_2d(0, 0)
	b = Noise.value_noise_2d(500, 500)
	c = Noise.value_noise_2d(1000, 1000)
	List.concat(List.concat(List.concat(List.concat(List.concat([33, 5, 22, 69, 2, 15, 77], Text.show_int(a)), [2, 32, 77]), Text.show_int(b)), [2, 24, 77]), Text.show_int(c))
})

test_continuity : List(U8)
test_continuity = ({
	a = Noise.value_noise_2d(999, 500)
	b = Noise.value_noise_2d(1000, 500)
	c = Noise.value_noise_2d(1001, 500)
	diff_ab = noise_test_abs((b - a))
	diff_bc = noise_test_abs((c - b))
	List.concat(List.concat(List.concat([24, 16, 18, 14, 17, 18, 25, 16, 25, 19, 77], (if (diff_ab < 50) { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] })), [66]), (if (diff_bc < 50) { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] }))
})

test_worley : List(U8)
test_worley = (match Noise.worley_2d(500, 500) {
	MkTup2(f1, f2) => List.concat(List.concat(List.concat(List.concat(List.concat([28, 4, 77], Text.show_int(f1)), [2, 28, 5, 77]), Text.show_int(f2)), [2, 28, 5, 80, 28, 4, 77]), (if (f2 >= f1) { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] }))
})

test_fbm : List(U8)
test_fbm = ({
	a = Noise.fbm_2d(500, 500, 4, 2000, 500)
	b = Noise.fbm_2d(3000, 3000, 4, 2000, 500)
	List.concat(List.concat(List.concat(List.concat(List.concat([28, 32, 26, 73, 15, 77], Text.show_int(a)), [2, 28, 32, 26, 73, 32, 77]), Text.show_int(b)), [2, 22, 17, 28, 28, 13, 21, 77]), (if (a != b) { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] }))
})

test_warp : List(U8)
test_warp = ({
	a = Noise.warp_2d(500, 500, 500)
	b = Noise.warp_2d(500, 500, 0)
	plain = Noise.value_noise_2d(500, 500)
	List.concat(List.concat(List.concat(List.concat(List.concat([27, 15, 21, 31, 13, 22, 77], Text.show_int(a)), [2, 25, 18, 27, 15, 21, 31, 13, 22, 77]), Text.show_int(b)), [2, 31, 23, 15, 17, 18, 77]), Text.show_int(plain))
})

test_map : List(U8)
test_map = ({
	m = Noise.noise_map_2d(4, 4, 500)
	mn = Noise.noise_map_min(m)
	mx = Noise.noise_map_max(m)
	List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat([26, 15, 31, 77], Text.show_int(U64.to_i64_wrap(List.len(m)))), [2, 26, 17, 18, 77]), Text.show_int(mn)), [2, 26, 15, 36, 77]), Text.show_int(mx)), [2, 21, 15, 18, 29, 13, 77]), (if (mx >= mn) { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] }))
})

noise_test_abs : I64 -> I64
noise_test_abs = |n| (if (n < 0) { (-n) } else { n })

# --- Entry ---

main! = |_args| {
	line!(Text.printed(test_value_1d))
	line!(Text.printed(test_value_2d))
	line!(Text.printed(test_continuity))
	line!(Text.printed(test_worley))
	line!(Text.printed(test_fbm))
	line!(Text.printed(test_warp))
	line!(Text.printed(test_map))
	Ok({})
}
