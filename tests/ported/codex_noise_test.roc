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

import cdx.CceText
import cdx.Noise

# NoiseTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

test_value_1d : CceText
test_value_1d = ({
	a : I64
	a = Noise.value_noise_1d(0)
	b : I64
	b = Noise.value_noise_1d(500)
	c : I64
	c = Noise.value_noise_1d(1000)
	CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("v1d: a=", CceText.show_int(a)), " b="), CceText.show_int(b)), " c="), CceText.show_int(c))
})

test_value_2d : CceText
test_value_2d = ({
	a : I64
	a = Noise.value_noise_2d(0, 0)
	b : I64
	b = Noise.value_noise_2d(500, 500)
	c : I64
	c = Noise.value_noise_2d(1000, 1000)
	CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("v2d: a=", CceText.show_int(a)), " b="), CceText.show_int(b)), " c="), CceText.show_int(c))
})

test_continuity : CceText
test_continuity = ({
	a : I64
	a = Noise.value_noise_2d(999, 500)
	b : I64
	b = Noise.value_noise_2d(1000, 500)
	c : I64
	c = Noise.value_noise_2d(1001, 500)
	diff_ab : I64
	diff_ab = noise_test_abs((b - a))
	diff_bc : I64
	diff_bc = noise_test_abs((c - b))
	CceText.concat(CceText.concat(CceText.concat("continuous=", (if (diff_ab < 50) { "True" } else { "False" })), ","), (if (diff_bc < 50) { "True" } else { "False" }))
})

test_worley : CceText
test_worley = (match Noise.worley_2d(500, 500) {
	MkTup2(f1, f2) => CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("f1=", CceText.show_int(f1)), " f2="), CceText.show_int(f2)), " f2>f1="), (if (f2 >= f1) { "True" } else { "False" }))
})

test_fbm : CceText
test_fbm = ({
	a : I64
	a = Noise.fbm_2d(500, 500, 4, 2000, 500)
	b : I64
	b = Noise.fbm_2d(3000, 3000, 4, 2000, 500)
	CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("fbm-a=", CceText.show_int(a)), " fbm-b="), CceText.show_int(b)), " differ="), (if (a != b) { "True" } else { "False" }))
})

test_warp : CceText
test_warp = ({
	a : I64
	a = Noise.warp_2d(500, 500, 500)
	b : I64
	b = Noise.warp_2d(500, 500, 0)
	plain : I64
	plain = Noise.value_noise_2d(500, 500)
	CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("warped=", CceText.show_int(a)), " unwarped="), CceText.show_int(b)), " plain="), CceText.show_int(plain))
})

test_map : CceText
test_map = ({
	m : List(I64)
	m = Noise.noise_map_2d(4, 4, 500)
	mn : I64
	mn = Noise.noise_map_min(m)
	mx : I64
	mx = Noise.noise_map_max(m)
	CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("map=", CceText.show_int(U64.to_i64_wrap(List.len(m)))), " min="), CceText.show_int(mn)), " max="), CceText.show_int(mx)), " range="), (if (mx >= mn) { "True" } else { "False" }))
})

noise_test_abs : I64 -> I64
noise_test_abs = |n| (if (n < 0) { (-n) } else { n })

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(test_value_1d))
	line!(CceText.printed(test_value_2d))
	line!(CceText.printed(test_continuity))
	line!(CceText.printed(test_worley))
	line!(CceText.printed(test_fbm))
	line!(CceText.printed(test_warp))
	line!(CceText.printed(test_map))
	Ok({})
}
