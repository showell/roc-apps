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

import cdx.Color
import cdx.Text

# ColorTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

test_pack : List(U8)
test_pack = ({
	c = Color.rgb(255, 128, 0)
	packed = Color.rgb_to_packed(c)
	back = Color.rgb_from_packed(packed)
	List.concat(List.concat(List.concat([31, 15, 24, 34, 13, 22, 77], Text.show_int(packed)), [2, 32, 15, 24, 34, 77]), Color.format_rgb(back))
})

test_lerp : List(U8)
test_lerp = ({
	mid = Color.rgb_lerp(Color.rgb_black, Color.rgb_white, 500)
	List.concat([26, 17, 22, 77], Color.format_rgb(mid))
})

test_blend : List(U8)
test_blend = ({
	c = Color.rgb_alpha_blend(Color.rgb_red, Color.rgb_blue, 500)
	List.concat([32, 23, 13, 18, 22, 77], Color.format_rgb(c))
})

test_gray : List(U8)
test_gray = ({
	c = Color.rgb(200, 100, 50)
	g = Color.rgb_grayscale(c)
	List.concat(List.concat(List.concat([29, 21, 15, 30, 77], Color.format_rgb(g)), [2, 23, 25, 26, 77]), Text.show_int(Color.rgb_luminance(c)))
})

test_invert : List(U8)
test_invert = ({
	c = Color.rgb_invert(Color.rgb(100, 200, 50))
	List.concat([17, 18, 33, 77], Color.format_rgb(c))
})

test_hsl : List(U8)
test_hsl = ({
	hsl = Color.rgb_to_hsl(Color.rgb_red)
	back = Color.hsl_to_rgb(hsl)
	List.concat(List.concat(List.concat([20, 19, 23, 77], Color.format_hsl(hsl)), [2, 32, 15, 24, 34, 77]), Color.format_rgb(back))
})

test_gradient : List(U8)
test_gradient = ({
	pal = Color.palette_gradient(Color.rgb_red, Color.rgb_blue, 5)
	List.concat(List.concat(List.concat([29, 21, 15, 22, 77], Text.show_int(U64.to_i64_wrap(List.len(pal)))), [2, 26, 17, 22, 77]), Color.format_rgb((List.get(pal, I64.to_u64_wrap(2)) ?? crash("list-at out of range"))))
})

test_hex : List(U8)
test_hex = List.concat([20, 13, 36, 77], Color.format_hex_color(Color.rgb(255, 128, 0)))

# --- Entry ---

main! = |_args| {
	line!(Text.printed(test_pack))
	line!(Text.printed(test_lerp))
	line!(Text.printed(test_blend))
	line!(Text.printed(test_gray))
	line!(Text.printed(test_invert))
	line!(Text.printed(test_hsl))
	line!(Text.printed(test_gradient))
	line!(Text.printed(test_hex))
	Ok({})
}
