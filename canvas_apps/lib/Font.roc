# Font gives letters as strokes, so a game or a movie can put words on the
# screen. The games write with this alphabet, on every painter. Words that
# should read well, such as a tutorial widget's, are a `Text` shape in the
# viewer's own typeface; `plotted` here is that shape for a painter that has no
# typefaces, and `room_for` is the room such a line wants.
#
# A letter is a few strokes, and a stroke is a polygon, the same quad
# `Shapes.line` builds. So text needs no new shape, no new brush, and nothing
# new on any wire, and it looks the same on the GPU, on the canvas and in
# ScanlineFill, because by then it is only polygons.
#
# The grid is 5 wide and 6 tall, x 0..4 and y 0..6 with y down. The cap height
# is at 0, the x-height at 2 and the baseline at 6, and descenders reach 8. A
# glyph advances 6. `size` is the height from cap to baseline, so a 24 px label
# has units of 4 px.
#
# It is a plotter's alphabet rather than a typeface: its strokes have one
# width, and they look like what they are.
import Shapes
import Brush
import Point
import RgbColor

Font :: [].{
	# A string, as shapes, with its top-left at `top_left`. `size` is the height
	# of a capital letter; the stroke is a fourteenth of it, which is about what
	# a plotter would give you.
	text_shapes : Str, { top_left : Point.Point, size : F64, color : Brush.Rgba } -> List(Shapes.Shape)
	text_shapes = |str, { top_left, size, color }| {
		unit = size / units
		stroke_width = (size / 14.0).max(1.0)
		str.to_utf8().map_with_index(|b, i| glyph_shapes(b, { top_left: { x: top_left.x + i.to_f64() * advance * unit, y: top_left.y }, unit, stroke_width, color })).join()
	}

	# How wide a string is, for a caller that wants to place one.
	width_of : Str, F64 -> F64
	width_of = |str, size| str.to_utf8().len().to_f64() * advance * (size / units)

	## A string centred on `top_center`, the middle of its top edge, which is
	## what a title, a banner and a hint all want.
	centered : Str, { top_center : Point.Point, size : F64, color : Brush.Rgba } -> List(Shapes.Shape)
	centered = |str, { top_center, size, color }|
		text_shapes(str, { top_left: { x: top_center.x - width_of(str, size) / 2.0, y: top_center.y }, size, color })

	## A line of type as strokes. The strokes' capitals stand as tall as a real
	## typeface's do at the line's size.
	plotted : Shapes.TextLine -> List(Shapes.Shape)
	plotted = |{ text: words, x, y, size, align, color, .. }| {
		cap_height = size * cap_height_share
		top = y - cap_height
		match align {
			Left => text_shapes(words, { top_left: { x, y: top }, size: cap_height, color })
			Center => centered(words, { top_center: { x, y: top }, size: cap_height, color })
		}
	}

	## The width to leave for a line of `size`. A monospace letter is close to
	## 0.6 of the size in every face a viewer's machine might pick, and a line of
	## words in a sans serif comes out narrower.
	room_for : Str, F64 -> F64
	room_for = |words, size| words.to_utf8().len().to_f64() * size * widest_letter_share

	## Whether every byte of `words` has a glyph. Plotting a byte with none
	## crashes, so the words a widget shows are held to this.
	can_plot : Str -> Bool
	can_plot = |words| words.to_utf8().all(|b| glyph_strokes(b).is_ok())
}

# How far the pen moves between glyph origins, in grid units.
advance : F64
advance = 6.0

# The grid is six units from cap to baseline.
units : F64
units = 6.0

widest_letter_share : F64
widest_letter_share = 0.62

# A capital's height as a share of the size, in the common sans serifs.
cap_height_share : F64
cap_height_share = 0.72

# One glyph's strokes, placed and thickened. `unit` is the pixels in one unit
# of the grid.
glyph_shapes : U8, { top_left : Point.Point, unit : F64, stroke_width : F64, color : Brush.Rgba } -> List(Shapes.Shape)
glyph_shapes = |b, { top_left, unit, stroke_width, color }| {
	strokes = strokes_for(b)
	var $out = List.with_capacity(strokes.len())
	for coordinates in strokes {
		for j in 1..<(coordinates.len() // 2) {
			$out = $out.append(
				Shapes.line(
					{
						from: { x: top_left.x + at(coordinates, 2 * (j - 1)) * unit, y: top_left.y + at(coordinates, 2 * (j - 1) + 1) * unit },
						to: { x: top_left.x + at(coordinates, 2 * j) * unit, y: top_left.y + at(coordinates, 2 * j + 1) * unit },
						width: stroke_width,
					},
					Flat(color),
				),
			)
		}
	}
	$out
}

at : List(F64), U64 -> F64
at = |xs, i| xs.get(i) ?? crash "Font.at: an index past the end of the stroke"

# The strokes of one glyph. A byte with no glyph crashes, because `width_of`
# would still leave room for it.
strokes_for : U8 -> List(List(F64))
strokes_for = |b| glyph_strokes(b) ?? crash "Font.strokes_for: no glyph for the byte ${b.to_str()}"

# The strokes of a byte's glyph, if it has one. Each stroke is a polyline, x
# and y alternating, on the grid above, and a curve is a few segments of one.
glyph_strokes : U8 -> Try(List(List(F64)), [NoGlyph])
glyph_strokes = |b|
	match b {
		' ' => Ok([])
		'!' => Ok([[2.0, 0.0, 2.0, 4.2], [2.0, 5.4, 2.0, 6.0]])
		'|' => Ok([[2.0, 0.0, 2.0, 6.0]])
		'%' => Ok([[0.0, 6.0, 4.0, 0.0], [0.4, 0.4, 1.6, 0.4, 1.6, 1.6, 0.4, 1.6, 0.4, 0.4], [2.4, 4.4, 3.6, 4.4, 3.6, 5.6, 2.4, 5.6, 2.4, 4.4]])
		',' => Ok([[2.2, 5.4, 2.2, 6.0, 1.5, 7.2]])
		'-' => Ok([[0.6, 4.5, 3.4, 4.5]])
		'.' => Ok([[1.8, 5.6, 2.2, 5.6, 2.2, 6.0, 1.8, 6.0, 1.8, 5.6]])
		'/' => Ok([[0.0, 6.0, 4.0, 0.0]])
		':' => Ok([[2.0, 2.6, 2.0, 3.2], [2.0, 5.4, 2.0, 6.0]])
		'_' => Ok([[0.0, 6.8, 4.0, 6.8]])
		'(' => Ok([[2.8, 0.0, 1.6, 1.5, 1.6, 4.5, 2.8, 6.0]])
		')' => Ok([[1.2, 0.0, 2.4, 1.5, 2.4, 4.5, 1.2, 6.0]])
		'{' => Ok([[3.0, 0.0, 2.2, 0.0, 1.6, 0.6, 1.6, 2.4, 0.8, 3.0, 1.6, 3.6, 1.6, 5.4, 2.2, 6.0, 3.0, 6.0]])
		'}' => Ok([[1.0, 0.0, 1.8, 0.0, 2.4, 0.6, 2.4, 2.4, 3.2, 3.0, 2.4, 3.6, 2.4, 5.4, 1.8, 6.0, 1.0, 6.0]])
		'=' => Ok([[0.6, 2.4, 3.4, 2.4], [0.6, 4.0, 3.4, 4.0]])
		'0' => Ok([[1.0, 0.0, 3.0, 0.0, 4.0, 1.0, 4.0, 5.0, 3.0, 6.0, 1.0, 6.0, 0.0, 5.0, 0.0, 1.0, 1.0, 0.0]])
		'1' => Ok([[1.0, 1.0, 2.0, 0.0, 2.0, 6.0], [1.0, 6.0, 3.0, 6.0]])
		'2' => Ok([[0.0, 1.0, 1.0, 0.0, 3.0, 0.0, 4.0, 1.0, 4.0, 2.0, 0.0, 6.0, 4.0, 6.0]])
		'3' => Ok([[0.0, 0.0, 4.0, 0.0, 2.0, 2.5, 4.0, 3.5, 4.0, 5.0, 3.0, 6.0, 1.0, 6.0, 0.0, 5.0]])
		'4' => Ok([[3.0, 6.0, 3.0, 0.0, 0.0, 4.0, 4.0, 4.0]])
		'5' => Ok([[4.0, 0.0, 0.0, 0.0, 0.0, 2.5, 3.0, 2.5, 4.0, 3.5, 4.0, 5.0, 3.0, 6.0, 1.0, 6.0, 0.0, 5.0]])
		'6' => Ok([[4.0, 1.0, 3.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 5.0, 1.0, 6.0, 3.0, 6.0, 4.0, 5.0, 4.0, 4.0, 3.0, 3.0, 1.0, 3.0, 0.0, 4.0]])
		'7' => Ok([[0.0, 0.0, 4.0, 0.0, 1.5, 6.0]])
		'8' => Ok([[1.0, 3.0, 0.0, 2.0, 0.0, 1.0, 1.0, 0.0, 3.0, 0.0, 4.0, 1.0, 4.0, 2.0, 3.0, 3.0, 1.0, 3.0, 0.0, 4.0, 0.0, 5.0, 1.0, 6.0, 3.0, 6.0, 4.0, 5.0, 4.0, 4.0, 3.0, 3.0]])
		'9' => Ok([[0.0, 5.0, 1.0, 6.0, 3.0, 6.0, 4.0, 5.0, 4.0, 1.0, 3.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 2.0, 1.0, 3.0, 3.0, 3.0, 4.0, 2.0]])
		'A' => Ok([[0.0, 6.0, 2.0, 0.0, 4.0, 6.0], [0.8, 4.0, 3.2, 4.0]])
		'B' => Ok([[0.0, 0.0, 0.0, 6.0], [0.0, 0.0, 3.0, 0.0, 4.0, 1.0, 4.0, 2.0, 3.0, 3.0, 0.0, 3.0], [0.0, 3.0, 3.0, 3.0, 4.0, 4.0, 4.0, 5.0, 3.0, 6.0, 0.0, 6.0]])
		'C' => Ok([[4.0, 1.0, 3.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 5.0, 1.0, 6.0, 3.0, 6.0, 4.0, 5.0]])
		'D' => Ok([[0.0, 0.0, 0.0, 6.0], [0.0, 0.0, 3.0, 0.0, 4.0, 1.0, 4.0, 5.0, 3.0, 6.0, 0.0, 6.0]])
		'E' => Ok([[4.0, 0.0, 0.0, 0.0, 0.0, 6.0, 4.0, 6.0], [0.0, 3.0, 3.0, 3.0]])
		'F' => Ok([[4.0, 0.0, 0.0, 0.0, 0.0, 6.0], [0.0, 3.0, 3.0, 3.0]])
		'G' => Ok([[4.0, 1.0, 3.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 5.0, 1.0, 6.0, 3.0, 6.0, 4.0, 5.0, 4.0, 3.5, 2.5, 3.5]])
		'H' => Ok([[0.0, 0.0, 0.0, 6.0], [4.0, 0.0, 4.0, 6.0], [0.0, 3.0, 4.0, 3.0]])
		'I' => Ok([[1.0, 0.0, 3.0, 0.0], [2.0, 0.0, 2.0, 6.0], [1.0, 6.0, 3.0, 6.0]])
		'J' => Ok([[3.0, 0.0, 3.0, 5.0, 2.0, 6.0, 1.0, 6.0, 0.0, 5.0]])
		'K' => Ok([[0.0, 0.0, 0.0, 6.0], [4.0, 0.0, 0.4, 3.6], [1.4, 2.8, 4.0, 6.0]])
		'L' => Ok([[0.0, 0.0, 0.0, 6.0, 4.0, 6.0]])
		'M' => Ok([[0.0, 6.0, 0.0, 0.0, 2.0, 2.5, 4.0, 0.0, 4.0, 6.0]])
		'N' => Ok([[0.0, 6.0, 0.0, 0.0, 4.0, 6.0, 4.0, 0.0]])
		'O' => Ok([[1.0, 0.0, 3.0, 0.0, 4.0, 1.0, 4.0, 5.0, 3.0, 6.0, 1.0, 6.0, 0.0, 5.0, 0.0, 1.0, 1.0, 0.0]])
		'P' => Ok([[0.0, 6.0, 0.0, 0.0, 3.0, 0.0, 4.0, 1.0, 4.0, 2.0, 3.0, 3.0, 0.0, 3.0]])
		'Q' => Ok([[1.0, 0.0, 3.0, 0.0, 4.0, 1.0, 4.0, 5.0, 3.0, 6.0, 1.0, 6.0, 0.0, 5.0, 0.0, 1.0, 1.0, 0.0], [2.5, 4.5, 4.0, 6.0]])
		'R' => Ok([[0.0, 6.0, 0.0, 0.0, 3.0, 0.0, 4.0, 1.0, 4.0, 2.0, 3.0, 3.0, 0.0, 3.0], [2.0, 3.0, 4.0, 6.0]])
		'S' => Ok([[4.0, 1.0, 3.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 2.0, 1.0, 3.0, 3.0, 3.0, 4.0, 4.0, 4.0, 5.0, 3.0, 6.0, 1.0, 6.0, 0.0, 5.0]])
		'T' => Ok([[0.0, 0.0, 4.0, 0.0], [2.0, 0.0, 2.0, 6.0]])
		'U' => Ok([[0.0, 0.0, 0.0, 5.0, 1.0, 6.0, 3.0, 6.0, 4.0, 5.0, 4.0, 0.0]])
		'V' => Ok([[0.0, 0.0, 2.0, 6.0, 4.0, 0.0]])
		'W' => Ok([[0.0, 0.0, 1.0, 6.0, 2.0, 3.0, 3.0, 6.0, 4.0, 0.0]])
		'X' => Ok([[0.0, 0.0, 4.0, 6.0], [4.0, 0.0, 0.0, 6.0]])
		'Y' => Ok([[0.0, 0.0, 2.0, 3.4, 4.0, 0.0], [2.0, 3.4, 2.0, 6.0]])
		'Z' => Ok([[0.0, 0.0, 4.0, 0.0, 0.0, 6.0, 4.0, 6.0]])
		'a' => Ok([[3.6, 3.0, 1.0, 3.0, 0.0, 4.0, 0.0, 5.0, 1.0, 6.0, 3.0, 6.0, 3.6, 5.4], [3.6, 3.0, 3.6, 6.0]])
		'b' => Ok([[0.0, 0.0, 0.0, 6.0], [0.0, 4.0, 1.0, 3.0, 3.0, 3.0, 4.0, 4.0, 4.0, 5.0, 3.0, 6.0, 1.0, 6.0, 0.0, 5.0]])
		'c' => Ok([[3.8, 3.8, 3.0, 3.0, 1.0, 3.0, 0.0, 4.0, 0.0, 5.0, 1.0, 6.0, 3.0, 6.0, 3.8, 5.2]])
		'd' => Ok([[4.0, 0.0, 4.0, 6.0], [4.0, 4.0, 3.0, 3.0, 1.0, 3.0, 0.0, 4.0, 0.0, 5.0, 1.0, 6.0, 3.0, 6.0, 4.0, 5.0]])
		'e' => Ok([[0.2, 4.8, 3.8, 4.8, 3.8, 4.0, 3.0, 3.0, 1.0, 3.0, 0.0, 4.0, 0.0, 5.0, 1.0, 6.0, 3.0, 6.0, 3.8, 5.4]])
		'f' => Ok([[3.0, 0.6, 2.4, 0.0, 1.6, 0.0, 1.0, 0.8, 1.0, 6.0], [0.0, 3.2, 2.6, 3.2]])
		'g' => Ok([[4.0, 3.0, 4.0, 7.0, 3.0, 8.0, 1.0, 8.0, 0.2, 7.4], [4.0, 4.0, 3.0, 3.0, 1.0, 3.0, 0.0, 4.0, 0.0, 5.0, 1.0, 6.0, 3.0, 6.0, 4.0, 5.0]])
		'h' => Ok([[0.0, 0.0, 0.0, 6.0], [0.0, 4.0, 1.0, 3.0, 3.0, 3.0, 4.0, 4.0, 4.0, 6.0]])
		'i' => Ok([[2.0, 1.4, 2.0, 2.0], [2.0, 3.0, 2.0, 6.0]])
		'j' => Ok([[3.0, 1.4, 3.0, 2.0], [3.0, 3.0, 3.0, 7.0, 2.0, 8.0, 1.0, 8.0, 0.4, 7.4]])
		'k' => Ok([[0.0, 0.0, 0.0, 6.0], [3.6, 3.0, 0.6, 5.0], [1.6, 4.3, 4.0, 6.0]])
		'l' => Ok([[1.6, 0.0, 1.6, 5.2, 2.6, 6.0]])
		'm' => Ok([[0.0, 6.0, 0.0, 3.0], [0.0, 4.0, 1.0, 3.0, 2.0, 4.0, 2.0, 6.0], [2.0, 4.0, 3.0, 3.0, 4.0, 4.0, 4.0, 6.0]])
		'n' => Ok([[0.0, 6.0, 0.0, 3.0], [0.0, 4.0, 1.0, 3.0, 3.0, 3.0, 4.0, 4.0, 4.0, 6.0]])
		'o' => Ok([[1.0, 3.0, 3.0, 3.0, 4.0, 4.0, 4.0, 5.0, 3.0, 6.0, 1.0, 6.0, 0.0, 5.0, 0.0, 4.0, 1.0, 3.0]])
		'p' => Ok([[0.0, 3.0, 0.0, 8.0], [0.0, 4.0, 1.0, 3.0, 3.0, 3.0, 4.0, 4.0, 4.0, 5.0, 3.0, 6.0, 1.0, 6.0, 0.0, 5.0]])
		'q' => Ok([[4.0, 3.0, 4.0, 8.0], [4.0, 4.0, 3.0, 3.0, 1.0, 3.0, 0.0, 4.0, 0.0, 5.0, 1.0, 6.0, 3.0, 6.0, 4.0, 5.0]])
		'r' => Ok([[0.0, 6.0, 0.0, 3.0], [0.0, 4.0, 1.0, 3.0, 3.0, 3.0]])
		's' => Ok([[3.6, 3.6, 3.0, 3.0, 1.0, 3.0, 0.2, 3.6, 0.8, 4.4, 3.0, 4.8, 3.6, 5.4, 3.0, 6.0, 1.0, 6.0, 0.2, 5.4]])
		't' => Ok([[1.6, 0.8, 1.6, 5.2, 2.6, 6.0, 3.6, 5.6], [0.4, 3.2, 3.0, 3.2]])
		'u' => Ok([[0.0, 3.0, 0.0, 5.0, 1.0, 6.0, 3.0, 6.0, 4.0, 5.0], [4.0, 3.0, 4.0, 6.0]])
		'v' => Ok([[0.0, 3.0, 2.0, 6.0, 4.0, 3.0]])
		'w' => Ok([[0.0, 3.0, 1.0, 6.0, 2.0, 4.2, 3.0, 6.0, 4.0, 3.0]])
		'x' => Ok([[0.0, 3.0, 4.0, 6.0], [4.0, 3.0, 0.0, 6.0]])
		'y' => Ok([[0.0, 3.0, 2.0, 6.0], [4.0, 3.0, 1.0, 8.0]])
		'z' => Ok([[0.0, 3.0, 4.0, 3.0, 0.0, 6.0, 4.0, 6.0]])
		_ => Err(NoGlyph)
	}

## A line of type at 50 px, whose capitals stand 36 px tall.
sample_line : Shapes.TextLine
sample_line = {
	text: "Hi",
	x: 100.0,
	y: 200.0,
	size: 50.0,
	face: Prose,
	align: Left,
	color: Brush.opaque(RgbColor.of(0x202020)),
}

expect
	Font.plotted(sample_line)
		== Font.text_shapes("Hi", { top_left: { x: 100.0, y: 164.0 }, size: 36.0, color: Brush.opaque(RgbColor.of(0x202020)) })
expect
	Font.plotted({ ..sample_line, align: Center })
		== Font.centered("Hi", { top_center: { x: 100.0, y: 164.0 }, size: 36.0, color: Brush.opaque(RgbColor.of(0x202020)) })

# A line's face is for a real typeface, and the strokes have only one.
expect Font.plotted({ ..sample_line, face: Code }) == Font.plotted(sample_line)

expect Font.room_for("", 50.0) == 0.0
expect Font.room_for("Hi", 50.0) == 62.0
expect Font.room_for("Hi", 100.0) == 124.0

# The alphabet's words plot, and one byte outside it is enough to refuse a line.
expect ["", "Cones({ shade: 0.5 })", "Shapes so far: 1,656 of 2,569", "Look depth: 52%"].all(Font.can_plot)
expect ["The rider's gaze", "Why?", "21\u(b0)", "a+b"].all(|words| !Font.can_plot(words))
