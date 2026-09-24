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

import cdx.CceText
import cdx.ListUtils

# MiniBootstrapTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Color : [Red, Green, Blue(I64)]
Point : { x : I64, y : I64 }

show_color : Color -> CceText
show_color = |c| (match c {
	Red => "red"
	Green => "green"
	Blue(_n) => "blue"
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
	line!(CceText.printed("mini-bootstrap works"))
	Ok({})
}
