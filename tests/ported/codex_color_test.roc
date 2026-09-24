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

test_pack : Text
test_pack = ({
	c = Color.rgb(255, 128, 0)
	packed = Color.rgb_to_packed(c)
	back = Color.rgb_from_packed(packed)
	Text.concat(Text.concat(Text.concat("packed=", Text.show_int(packed)), " back="), Color.format_rgb(back))
})

test_lerp : Text
test_lerp = ({
	mid = Color.rgb_lerp(Color.rgb_black, Color.rgb_white, 500)
	Text.concat("mid=", Color.format_rgb(mid))
})

test_blend : Text
test_blend = ({
	c = Color.rgb_alpha_blend(Color.rgb_red, Color.rgb_blue, 500)
	Text.concat("blend=", Color.format_rgb(c))
})

test_gray : Text
test_gray = ({
	c = Color.rgb(200, 100, 50)
	g = Color.rgb_grayscale(c)
	Text.concat(Text.concat(Text.concat("gray=", Color.format_rgb(g)), " lum="), Text.show_int(Color.rgb_luminance(c)))
})

test_invert : Text
test_invert = ({
	c = Color.rgb_invert(Color.rgb(100, 200, 50))
	Text.concat("inv=", Color.format_rgb(c))
})

test_hsl : Text
test_hsl = ({
	hsl = Color.rgb_to_hsl(Color.rgb_red)
	back = Color.hsl_to_rgb(hsl)
	Text.concat(Text.concat(Text.concat("hsl=", Color.format_hsl(hsl)), " back="), Color.format_rgb(back))
})

test_gradient : Text
test_gradient = ({
	pal = Color.palette_gradient(Color.rgb_red, Color.rgb_blue, 5)
	Text.concat(Text.concat(Text.concat("grad=", Text.show_int(U64.to_i64_wrap(List.len(pal)))), " mid="), Color.format_rgb((List.get(pal, I64.to_u64_wrap(2)) ?? crash("list-at out of range"))))
})

test_hex : Text
test_hex = Text.concat("hex=", Color.format_hex_color(Color.rgb(255, 128, 0)))

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
