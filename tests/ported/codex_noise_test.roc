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

test_value_1d : Text
test_value_1d = ({
	a = Noise.value_noise_1d(0)
	b = Noise.value_noise_1d(500)
	c = Noise.value_noise_1d(1000)
	Text.concat(Text.concat(Text.concat(Text.concat(Text.concat("v1d: a=", Text.show_int(a)), " b="), Text.show_int(b)), " c="), Text.show_int(c))
})

test_value_2d : Text
test_value_2d = ({
	a = Noise.value_noise_2d(0, 0)
	b = Noise.value_noise_2d(500, 500)
	c = Noise.value_noise_2d(1000, 1000)
	Text.concat(Text.concat(Text.concat(Text.concat(Text.concat("v2d: a=", Text.show_int(a)), " b="), Text.show_int(b)), " c="), Text.show_int(c))
})

test_continuity : Text
test_continuity = ({
	a = Noise.value_noise_2d(999, 500)
	b = Noise.value_noise_2d(1000, 500)
	c = Noise.value_noise_2d(1001, 500)
	diff_ab = noise_test_abs((b - a))
	diff_bc = noise_test_abs((c - b))
	Text.concat(Text.concat(Text.concat("continuous=", (if (diff_ab < 50) { "True" } else { "False" })), ","), (if (diff_bc < 50) { "True" } else { "False" }))
})

test_worley : Text
test_worley = (match Noise.worley_2d(500, 500) {
	MkTup2(f1, f2) => Text.concat(Text.concat(Text.concat(Text.concat(Text.concat("f1=", Text.show_int(f1)), " f2="), Text.show_int(f2)), " f2>f1="), (if (f2 >= f1) { "True" } else { "False" }))
})

test_fbm : Text
test_fbm = ({
	a = Noise.fbm_2d(500, 500, 4, 2000, 500)
	b = Noise.fbm_2d(3000, 3000, 4, 2000, 500)
	Text.concat(Text.concat(Text.concat(Text.concat(Text.concat("fbm-a=", Text.show_int(a)), " fbm-b="), Text.show_int(b)), " differ="), (if (a != b) { "True" } else { "False" }))
})

test_warp : Text
test_warp = ({
	a = Noise.warp_2d(500, 500, 500)
	b = Noise.warp_2d(500, 500, 0)
	plain = Noise.value_noise_2d(500, 500)
	Text.concat(Text.concat(Text.concat(Text.concat(Text.concat("warped=", Text.show_int(a)), " unwarped="), Text.show_int(b)), " plain="), Text.show_int(plain))
})

test_map : Text
test_map = ({
	m = Noise.noise_map_2d(4, 4, 500)
	mn = Noise.noise_map_min(m)
	mx = Noise.noise_map_max(m)
	Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat("map=", Text.show_int(U64.to_i64_wrap(List.len(m)))), " min="), Text.show_int(mn)), " max="), Text.show_int(mx)), " range="), (if (mx >= mn) { "True" } else { "False" }))
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
