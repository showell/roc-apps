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

named : I64 -> Text
named = |i| (if (i == 0) { "terminal" } else { (if (i == 1) { "lcars" } else { "minimal" }) })

pal_of : I64 -> Theme.Palette
pal_of = |i| (if (i == 0) { Theme.palette_terminal } else { (if (i == 1) { Theme.palette_lcars } else { Theme.palette_minimal }) })

report! : I64, I64 => {}
report! = |i, n| (if (i >= n) { line!(Text.printed("")) } else { ({
	({
		p = pal_of(i)
		acc = p.pal_accent
		({
			line!(Text.printed(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(named(i), ": bg luma "), Text.show_int(Theme.theme_luma(p.pal_bg))), ", fg luma "), Text.show_int(Theme.theme_luma(p.pal_fg))), ", accent luma "), Text.show_int(Theme.theme_luma(acc))), " -> ink luma "), Text.show_int(Theme.theme_luma(Theme.theme_ink_on(p, acc))))))
			report!((i + 1), n)
		})
	})
}) })

flips! : I64, I64 => {}
flips! = |i, n| (if (i >= n) { line!(Text.printed("")) } else { ({
	({
		p = pal_of(i)
		on_black = Theme.theme_ink_on(p, black)
		on_white = Theme.theme_ink_on(p, white)
		({
			line!(Text.printed(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat("  ", named(i)), ": on black luma "), Text.show_int(Theme.theme_luma(on_black))), ", on white luma "), Text.show_int(Theme.theme_luma(on_white))), (if (on_black == on_white) { "   SAME, the ground is being ignored" } else { "" }))))
			flips!((i + 1), n)
		})
	})
}) })

# --- Entry ---

main! = |_args| {
	line!(Text.printed("the ink each scheme puts on its own accent:"))
	report!(0, 3)
	line!(Text.printed("the same helper asked for black and for white:"))
	flips!(0, 3)
	Ok({})
}
