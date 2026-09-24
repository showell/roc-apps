# color-test
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/color-test.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     packed=16744448 back=rgb(255,128,0)
#     mid=rgb(127,127,127)
#     blend=rgb(127,0,127)
#     gray=rgb(124,124,124) lum=124
#     inv=rgb(155,55,205)
#     hsl=hsl(0,1000,500) back=rgb(255,0,0)
#     grad=5 mid=rgb(127,0,127)
#     hex=#ff8000

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.Color

# ColorTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

test_pack : CceText
test_pack = ({
	c = Color.rgb(255, 128, 0)
	packed = Color.rgb_to_packed(c)
	back = Color.rgb_from_packed(packed)
	CceText.concat(CceText.concat(CceText.concat("packed=", CceText.show_int(packed)), " back="), Color.format_rgb(back))
})

test_lerp : CceText
test_lerp = ({
	mid = Color.rgb_lerp(Color.rgb_black, Color.rgb_white, 500)
	CceText.concat("mid=", Color.format_rgb(mid))
})

test_blend : CceText
test_blend = ({
	c = Color.rgb_alpha_blend(Color.rgb_red, Color.rgb_blue, 500)
	CceText.concat("blend=", Color.format_rgb(c))
})

test_gray : CceText
test_gray = ({
	c = Color.rgb(200, 100, 50)
	g = Color.rgb_grayscale(c)
	CceText.concat(CceText.concat(CceText.concat("gray=", Color.format_rgb(g)), " lum="), CceText.show_int(Color.rgb_luminance(c)))
})

test_invert : CceText
test_invert = ({
	c = Color.rgb_invert(Color.rgb(100, 200, 50))
	CceText.concat("inv=", Color.format_rgb(c))
})

test_hsl : CceText
test_hsl = ({
	hsl = Color.rgb_to_hsl(Color.rgb_red)
	back = Color.hsl_to_rgb(hsl)
	CceText.concat(CceText.concat(CceText.concat("hsl=", Color.format_hsl(hsl)), " back="), Color.format_rgb(back))
})

test_gradient : CceText
test_gradient = ({
	pal = Color.palette_gradient(Color.rgb_red, Color.rgb_blue, 5)
	CceText.concat(CceText.concat(CceText.concat("grad=", CceText.show_int(U64.to_i64_wrap(List.len(pal)))), " mid="), Color.format_rgb((List.get(pal, I64.to_u64_wrap(2)) ?? crash("list-at out of range"))))
})

test_hex : CceText
test_hex = CceText.concat("hex=", Color.format_hex_color(Color.rgb(255, 128, 0)))

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(test_pack))
	line!(CceText.printed(test_lerp))
	line!(CceText.printed(test_blend))
	line!(CceText.printed(test_gray))
	line!(CceText.printed(test_invert))
	line!(CceText.printed(test_hsl))
	line!(CceText.printed(test_gradient))
	line!(CceText.printed(test_hex))
	Ok({})
}
