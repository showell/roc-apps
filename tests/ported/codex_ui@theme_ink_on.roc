# ui@theme-ink-on
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ui@theme-ink-on.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     the ink each scheme puts on its own accent:
#     terminal: bg luma 16, fg luma 204, accent luma 154 -> ink luma 16
#     lcars: bg luma 0, fg luma 255, accent luma 179 -> ink luma 0
#     minimal: bg luma 255, fg luma 32, accent luma 88 -> ink luma 255
#     
#     the same helper asked for black and for white:
#       terminal: on black luma 204, on white luma 16
#       lcars: on black luma 255, on white luma 0
#       minimal: on black luma 255, on white luma 32

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text
import cdx.Theme

# ThemeInkOnTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

black : I64
black = 0

white : I64
white = 16777215

named : I64 -> List(U8)
named = |i| (if (i == 0) { [14, 13, 21, 26, 17, 18, 15, 23] } else { (if (i == 1) { [23, 24, 15, 21, 19] } else { [26, 17, 18, 17, 26, 15, 23] }) })

pal_of : I64 -> Theme.Palette
pal_of = |i| (if (i == 0) { Theme.palette_terminal } else { (if (i == 1) { Theme.palette_lcars } else { Theme.palette_minimal }) })

report! : I64, I64 => {}
report! = |i, n| (if (i >= n) { line!(Text.printed([])) } else { ({
	({
		p = pal_of(i)
		acc = p.pal_accent
		({
			line!(Text.printed(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(named(i), [69, 2, 32, 29, 2, 23, 25, 26, 15, 2]), Text.show_int(Theme.theme_luma(p.pal_bg))), [66, 2, 28, 29, 2, 23, 25, 26, 15, 2]), Text.show_int(Theme.theme_luma(p.pal_fg))), [66, 2, 15, 24, 24, 13, 18, 14, 2, 23, 25, 26, 15, 2]), Text.show_int(Theme.theme_luma(acc))), [2, 73, 80, 2, 17, 18, 34, 2, 23, 25, 26, 15, 2]), Text.show_int(Theme.theme_luma(Theme.theme_ink_on(p, acc))))))
			report!((i + 1), n)
		})
	})
}) })

flips! : I64, I64 => {}
flips! = |i, n| (if (i >= n) { line!(Text.printed([])) } else { ({
	({
		p = pal_of(i)
		on_black = Theme.theme_ink_on(p, black)
		on_white = Theme.theme_ink_on(p, white)
		({
			line!(Text.printed(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat([2, 2], named(i)), [69, 2, 16, 18, 2, 32, 23, 15, 24, 34, 2, 23, 25, 26, 15, 2]), Text.show_int(Theme.theme_luma(on_black))), [66, 2, 16, 18, 2, 27, 20, 17, 14, 13, 2, 23, 25, 26, 15, 2]), Text.show_int(Theme.theme_luma(on_white))), (if (on_black == on_white) { [2, 2, 2, 45, 41, 52, 39, 66, 2, 14, 20, 13, 2, 29, 21, 16, 25, 18, 22, 2, 17, 19, 2, 32, 13, 17, 18, 29, 2, 17, 29, 18, 16, 21, 13, 22] } else { [] }))))
			flips!((i + 1), n)
		})
	})
}) })

# --- Entry ---

main! = |_args| {
	line!(Text.printed([14, 20, 13, 2, 17, 18, 34, 2, 13, 15, 24, 20, 2, 19, 24, 20, 13, 26, 13, 2, 31, 25, 14, 19, 2, 16, 18, 2, 17, 14, 19, 2, 16, 27, 18, 2, 15, 24, 24, 13, 18, 14, 69]))
	report!(0, 3)
	line!(Text.printed([14, 20, 13, 2, 19, 15, 26, 13, 2, 20, 13, 23, 31, 13, 21, 2, 15, 19, 34, 13, 22, 2, 28, 16, 21, 2, 32, 23, 15, 24, 34, 2, 15, 18, 22, 2, 28, 16, 21, 2, 27, 20, 17, 14, 13, 69]))
	flips!(0, 3)
	Ok({})
}
