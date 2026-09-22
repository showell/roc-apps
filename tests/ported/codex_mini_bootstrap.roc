# mini-bootstrap
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/mini-bootstrap.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     mini-bootstrap works

app [main!] { cdx: "./codex/main.roc" }

import cdx.ListUtils
import cdx.Text

# MiniBootstrapTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Color : [Red, Green, Blue(I64)]
Point : { x : I64, y : I64 }

show_color : Color -> List(U8)
show_color = |c| (match c {
	Red => [21, 13, 22]
	Green => [29, 21, 13, 13, 18]
	Blue(_n) => [32, 23, 25, 13]
})

get_x : Point -> I64
get_x = |p| p.x

add_points : Point, Point -> Point
add_points = |a, b| { x: (a.x + b.x), y: (a.y + b.y) }

use_map : List(Point) -> List(I64)
use_map = |pts| ListUtils.map_list(get_x, pts)

eq_Color : Color, Color -> Bool
eq_Color = |ex, ey| (match ex {
	Red => (match ey {
		Red => True
		_ => False
	})
	Green => (match ey {
		Green => True
		_ => False
	})
	Blue(exf0) => (match ey {
		Blue(eyf0) => (exf0 == eyf0)
		_ => False
	})
})

# --- Entry ---

main! = |_args| {
	line!(Text.printed([26, 17, 18, 17, 73, 32, 16, 16, 14, 19, 14, 21, 15, 31, 2, 27, 16, 21, 34, 19]))
	Ok({})
}
