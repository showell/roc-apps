# Font -- letters as strokes, so a movie can say something.
#
# Hand-written. Nothing in this vocabulary drew a glyph: Safari's critters are
# baked polygons and its `Text.roc` is a Codex Text, not a typeface. roc-ray's
# `capture_plot` draws a title, a status line and a frame count, and that was
# the first thing a second movie asked for that could not be said at all.
#
# **A LETTER IS A FEW STROKES, AND A STROKE IS A POLYGON** -- the same quad
# `Shapes.line` builds -- so text needs no new shape, no new brush, and nothing
# new on any wire. It draws identically on the GPU, on the canvas and in
# Raster, because by the time anyone sees it it is only polygons.
#
# **THE GRID IS 5 WIDE AND 6 TALL**, x 0..4 and y 0..6 with y down: cap at 0,
# x-height at 2, baseline at 6, descenders to 8. A glyph advances 6. `size` is
# the cap-to-baseline height, so a 24 px label has units of 4 px.
#
# It is a plotter's alphabet rather than a typeface, which is honest: these are
# strokes of a constant width, and they look like what they are.
import Shapes
import Brush

Font :: [].{
	# How far the pen moves between glyph origins, in grid units.
	advance : F64
	advance = 6.0

	# The grid is six units from cap to baseline.
	units : F64
	units = 6.0

	# A string, as shapes, with its top-left at (x, y). `size` is the height of
	# a capital letter; the stroke is a fourteenth of it, which is about what a
	# plotter would give you.
	text : List(U8), F64, F64, F64, Brush.Rgba -> List(Shapes.Shape)
	text = |bytes, x, y, size, color| {
		u = size / units
		w = F64.max(size / 14.0, 1.0)
		n = List.len(bytes)
		var $out = List.with_capacity(4 * n)
		var $i = 0
		while $i < n {
			b = List.get(bytes, $i) ?? 32
			$out = List.concat($out, glyph(b, x + I64.to_f64(U64.to_i64_wrap($i)) * advance * u, y, u, w, color))
			$i = $i + 1
		}
		$out
	}

	# How wide a string is, for a caller that wants to place one.
	width_of : List(U8), F64 -> F64
	width_of = |bytes, size| I64.to_f64(U64.to_i64_wrap(List.len(bytes))) * advance * (size / units)

	# One glyph's strokes, placed and thickened.
	glyph : U8, F64, F64, F64, F64, Brush.Rgba -> List(Shapes.Shape)
	glyph = |b, x, y, u, w, color| {
		strokes = strokes_for(b)
		n = List.len(strokes)
		var $out = List.with_capacity(n)
		var $k = 0
		while $k < n {
			pts = List.get(strokes, $k) ?? []
			m = List.len(pts) // 2
			var $j = 1
			while $j < m {
				$out = List.append(
					$out,
					Shapes.line(
						x + at(pts, 2 * ($j - 1)) * u,
						y + at(pts, 2 * ($j - 1) + 1) * u,
						x + at(pts, 2 * $j) * u,
						y + at(pts, 2 * $j + 1) * u,
						w,
						Flat(color),
					),
				)
				$j = $j + 1
			}
			$k = $k + 1
		}
		$out
	}

	at : List(F64), U64 -> F64
	at = |xs, i| List.get(xs, i) ?? 0.0

	# **THE ALPHABET.** Each glyph is a list of strokes; each stroke is a
	# polyline, x and y alternating, on the grid above. A curve is a few
	# segments, which is what a stroke font is.
	strokes_for : U8 -> List(List(F64))
	strokes_for = |b|
		if b == 32 { [] } # space
		else if b == 33 { [[2.0, 0.0, 2.0, 4.2], [2.0, 5.4, 2.0, 6.0]] } # !
		else if b == 45 { [[0.6, 4.5, 3.4, 4.5]] } # -
		else if b == 46 { [[1.8, 5.6, 2.2, 5.6, 2.2, 6.0, 1.8, 6.0, 1.8, 5.6]] } # .
		else if b == 47 { [[0.0, 6.0, 4.0, 0.0]] } # /
		else if b == 58 { [[2.0, 2.6, 2.0, 3.2], [2.0, 5.4, 2.0, 6.0]] } # :
		else if b == 48 { [[1.0, 0.0, 3.0, 0.0, 4.0, 1.0, 4.0, 5.0, 3.0, 6.0, 1.0, 6.0, 0.0, 5.0, 0.0, 1.0, 1.0, 0.0]] } # 0
		else if b == 49 { [[1.0, 1.0, 2.0, 0.0, 2.0, 6.0], [1.0, 6.0, 3.0, 6.0]] } # 1
		else if b == 50 { [[0.0, 1.0, 1.0, 0.0, 3.0, 0.0, 4.0, 1.0, 4.0, 2.0, 0.0, 6.0, 4.0, 6.0]] } # 2
		else if b == 51 { [[0.0, 0.0, 4.0, 0.0, 2.0, 2.5, 4.0, 3.5, 4.0, 5.0, 3.0, 6.0, 1.0, 6.0, 0.0, 5.0]] } # 3
		else if b == 52 { [[3.0, 6.0, 3.0, 0.0, 0.0, 4.0, 4.0, 4.0]] } # 4
		else if b == 53 { [[4.0, 0.0, 0.0, 0.0, 0.0, 2.5, 3.0, 2.5, 4.0, 3.5, 4.0, 5.0, 3.0, 6.0, 1.0, 6.0, 0.0, 5.0]] } # 5
		else if b == 54 { [[4.0, 1.0, 3.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 5.0, 1.0, 6.0, 3.0, 6.0, 4.0, 5.0, 4.0, 4.0, 3.0, 3.0, 1.0, 3.0, 0.0, 4.0]] } # 6
		else if b == 55 { [[0.0, 0.0, 4.0, 0.0, 1.5, 6.0]] } # 7
		else if b == 56 { [[1.0, 3.0, 0.0, 2.0, 0.0, 1.0, 1.0, 0.0, 3.0, 0.0, 4.0, 1.0, 4.0, 2.0, 3.0, 3.0, 1.0, 3.0, 0.0, 4.0, 0.0, 5.0, 1.0, 6.0, 3.0, 6.0, 4.0, 5.0, 4.0, 4.0, 3.0, 3.0]] } # 8
		else if b == 57 { [[0.0, 5.0, 1.0, 6.0, 3.0, 6.0, 4.0, 5.0, 4.0, 1.0, 3.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 2.0, 1.0, 3.0, 3.0, 3.0, 4.0, 2.0]] } # 9
		else if b == 65 { [[0.0, 6.0, 2.0, 0.0, 4.0, 6.0], [0.8, 4.0, 3.2, 4.0]] } # A
		else if b == 66 { [[0.0, 0.0, 0.0, 6.0], [0.0, 0.0, 3.0, 0.0, 4.0, 1.0, 4.0, 2.0, 3.0, 3.0, 0.0, 3.0], [0.0, 3.0, 3.0, 3.0, 4.0, 4.0, 4.0, 5.0, 3.0, 6.0, 0.0, 6.0]] } # B
		else if b == 67 { [[4.0, 1.0, 3.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 5.0, 1.0, 6.0, 3.0, 6.0, 4.0, 5.0]] } # C
		else if b == 68 { [[0.0, 0.0, 0.0, 6.0], [0.0, 0.0, 3.0, 0.0, 4.0, 1.0, 4.0, 5.0, 3.0, 6.0, 0.0, 6.0]] } # D
		else if b == 69 { [[4.0, 0.0, 0.0, 0.0, 0.0, 6.0, 4.0, 6.0], [0.0, 3.0, 3.0, 3.0]] } # E
		else if b == 70 { [[4.0, 0.0, 0.0, 0.0, 0.0, 6.0], [0.0, 3.0, 3.0, 3.0]] } # F
		else if b == 71 { [[4.0, 1.0, 3.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 5.0, 1.0, 6.0, 3.0, 6.0, 4.0, 5.0, 4.0, 3.5, 2.5, 3.5]] } # G
		else if b == 72 { [[0.0, 0.0, 0.0, 6.0], [4.0, 0.0, 4.0, 6.0], [0.0, 3.0, 4.0, 3.0]] } # H
		else if b == 73 { [[1.0, 0.0, 3.0, 0.0], [2.0, 0.0, 2.0, 6.0], [1.0, 6.0, 3.0, 6.0]] } # I
		else if b == 74 { [[3.0, 0.0, 3.0, 5.0, 2.0, 6.0, 1.0, 6.0, 0.0, 5.0]] } # J
		else if b == 75 { [[0.0, 0.0, 0.0, 6.0], [4.0, 0.0, 0.4, 3.6], [1.4, 2.8, 4.0, 6.0]] } # K
		else if b == 76 { [[0.0, 0.0, 0.0, 6.0, 4.0, 6.0]] } # L
		else if b == 77 { [[0.0, 6.0, 0.0, 0.0, 2.0, 2.5, 4.0, 0.0, 4.0, 6.0]] } # M
		else if b == 78 { [[0.0, 6.0, 0.0, 0.0, 4.0, 6.0, 4.0, 0.0]] } # N
		else if b == 79 { [[1.0, 0.0, 3.0, 0.0, 4.0, 1.0, 4.0, 5.0, 3.0, 6.0, 1.0, 6.0, 0.0, 5.0, 0.0, 1.0, 1.0, 0.0]] } # O
		else if b == 80 { [[0.0, 6.0, 0.0, 0.0, 3.0, 0.0, 4.0, 1.0, 4.0, 2.0, 3.0, 3.0, 0.0, 3.0]] } # P
		else if b == 81 { [[1.0, 0.0, 3.0, 0.0, 4.0, 1.0, 4.0, 5.0, 3.0, 6.0, 1.0, 6.0, 0.0, 5.0, 0.0, 1.0, 1.0, 0.0], [2.5, 4.5, 4.0, 6.0]] } # Q
		else if b == 82 { [[0.0, 6.0, 0.0, 0.0, 3.0, 0.0, 4.0, 1.0, 4.0, 2.0, 3.0, 3.0, 0.0, 3.0], [2.0, 3.0, 4.0, 6.0]] } # R
		else if b == 83 { [[4.0, 1.0, 3.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 2.0, 1.0, 3.0, 3.0, 3.0, 4.0, 4.0, 4.0, 5.0, 3.0, 6.0, 1.0, 6.0, 0.0, 5.0]] } # S
		else if b == 84 { [[0.0, 0.0, 4.0, 0.0], [2.0, 0.0, 2.0, 6.0]] } # T
		else if b == 85 { [[0.0, 0.0, 0.0, 5.0, 1.0, 6.0, 3.0, 6.0, 4.0, 5.0, 4.0, 0.0]] } # U
		else if b == 86 { [[0.0, 0.0, 2.0, 6.0, 4.0, 0.0]] } # V
		else if b == 87 { [[0.0, 0.0, 1.0, 6.0, 2.0, 3.0, 3.0, 6.0, 4.0, 0.0]] } # W
		else if b == 88 { [[0.0, 0.0, 4.0, 6.0], [4.0, 0.0, 0.0, 6.0]] } # X
		else if b == 89 { [[0.0, 0.0, 2.0, 3.4, 4.0, 0.0], [2.0, 3.4, 2.0, 6.0]] } # Y
		else if b == 90 { [[0.0, 0.0, 4.0, 0.0, 0.0, 6.0, 4.0, 6.0]] } # Z
		else if b == 97 { [[3.6, 3.0, 1.0, 3.0, 0.0, 4.0, 0.0, 5.0, 1.0, 6.0, 3.0, 6.0, 3.6, 5.4], [3.6, 3.0, 3.6, 6.0]] } # a
		else if b == 98 { [[0.0, 0.0, 0.0, 6.0], [0.0, 4.0, 1.0, 3.0, 3.0, 3.0, 4.0, 4.0, 4.0, 5.0, 3.0, 6.0, 1.0, 6.0, 0.0, 5.0]] } # b
		else if b == 99 { [[3.8, 3.8, 3.0, 3.0, 1.0, 3.0, 0.0, 4.0, 0.0, 5.0, 1.0, 6.0, 3.0, 6.0, 3.8, 5.2]] } # c
		else if b == 100 { [[4.0, 0.0, 4.0, 6.0], [4.0, 4.0, 3.0, 3.0, 1.0, 3.0, 0.0, 4.0, 0.0, 5.0, 1.0, 6.0, 3.0, 6.0, 4.0, 5.0]] } # d
		else if b == 101 { [[0.2, 4.8, 3.8, 4.8, 3.8, 4.0, 3.0, 3.0, 1.0, 3.0, 0.0, 4.0, 0.0, 5.0, 1.0, 6.0, 3.0, 6.0, 3.8, 5.4]] } # e
		else if b == 102 { [[3.0, 0.6, 2.4, 0.0, 1.6, 0.0, 1.0, 0.8, 1.0, 6.0], [0.0, 3.2, 2.6, 3.2]] } # f
		else if b == 103 { [[4.0, 3.0, 4.0, 7.0, 3.0, 8.0, 1.0, 8.0, 0.2, 7.4], [4.0, 4.0, 3.0, 3.0, 1.0, 3.0, 0.0, 4.0, 0.0, 5.0, 1.0, 6.0, 3.0, 6.0, 4.0, 5.0]] } # g
		else if b == 104 { [[0.0, 0.0, 0.0, 6.0], [0.0, 4.0, 1.0, 3.0, 3.0, 3.0, 4.0, 4.0, 4.0, 6.0]] } # h
		else if b == 105 { [[2.0, 1.4, 2.0, 2.0], [2.0, 3.0, 2.0, 6.0]] } # i
		else if b == 106 { [[3.0, 1.4, 3.0, 2.0], [3.0, 3.0, 3.0, 7.0, 2.0, 8.0, 1.0, 8.0, 0.4, 7.4]] } # j
		else if b == 107 { [[0.0, 0.0, 0.0, 6.0], [3.6, 3.0, 0.6, 5.0], [1.6, 4.3, 4.0, 6.0]] } # k
		else if b == 108 { [[1.6, 0.0, 1.6, 5.2, 2.6, 6.0]] } # l
		else if b == 109 { [[0.0, 6.0, 0.0, 3.0], [0.0, 4.0, 1.0, 3.0, 2.0, 4.0, 2.0, 6.0], [2.0, 4.0, 3.0, 3.0, 4.0, 4.0, 4.0, 6.0]] } # m
		else if b == 110 { [[0.0, 6.0, 0.0, 3.0], [0.0, 4.0, 1.0, 3.0, 3.0, 3.0, 4.0, 4.0, 4.0, 6.0]] } # n
		else if b == 111 { [[1.0, 3.0, 3.0, 3.0, 4.0, 4.0, 4.0, 5.0, 3.0, 6.0, 1.0, 6.0, 0.0, 5.0, 0.0, 4.0, 1.0, 3.0]] } # o
		else if b == 112 { [[0.0, 3.0, 0.0, 8.0], [0.0, 4.0, 1.0, 3.0, 3.0, 3.0, 4.0, 4.0, 4.0, 5.0, 3.0, 6.0, 1.0, 6.0, 0.0, 5.0]] } # p
		else if b == 113 { [[4.0, 3.0, 4.0, 8.0], [4.0, 4.0, 3.0, 3.0, 1.0, 3.0, 0.0, 4.0, 0.0, 5.0, 1.0, 6.0, 3.0, 6.0, 4.0, 5.0]] } # q
		else if b == 114 { [[0.0, 6.0, 0.0, 3.0], [0.0, 4.0, 1.0, 3.0, 3.0, 3.0]] } # r
		else if b == 115 { [[3.6, 3.6, 3.0, 3.0, 1.0, 3.0, 0.2, 3.6, 0.8, 4.4, 3.0, 4.8, 3.6, 5.4, 3.0, 6.0, 1.0, 6.0, 0.2, 5.4]] } # s
		else if b == 116 { [[1.6, 0.8, 1.6, 5.2, 2.6, 6.0, 3.6, 5.6], [0.4, 3.2, 3.0, 3.2]] } # t
		else if b == 117 { [[0.0, 3.0, 0.0, 5.0, 1.0, 6.0, 3.0, 6.0, 4.0, 5.0], [4.0, 3.0, 4.0, 6.0]] } # u
		else if b == 118 { [[0.0, 3.0, 2.0, 6.0, 4.0, 3.0]] } # v
		else if b == 119 { [[0.0, 3.0, 1.0, 6.0, 2.0, 4.2, 3.0, 6.0, 4.0, 3.0]] } # w
		else if b == 120 { [[0.0, 3.0, 4.0, 6.0], [4.0, 3.0, 0.0, 6.0]] } # x
		else if b == 121 { [[0.0, 3.0, 2.0, 6.0], [4.0, 3.0, 1.0, 8.0]] } # y
		else if b == 122 { [[0.0, 3.0, 4.0, 3.0, 0.0, 6.0, 4.0, 6.0]] } # z
		else { [] }
}
