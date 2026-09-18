# Does the alphabet say what it is supposed to say? Natively, as ASCII art.
#
# Hand-written. Font's glyphs are hand-authored numbers, and a mistake in them
# is invisible in the source and obvious on a screen -- which is no help on a
# box with no screen. So the string is painted with Raster, the one painter
# that answers in pixels, and printed coarse enough to read here.
#
#   roc build --opt=dev FontProof.roc --output=<bin>; <bin> "0123456789"
import Font
import Brush
import Raster
import Shapes

main! = |args| {
	msg = List.get(args, 0) ?? "0123456789 /."
	size = 48.0
	bytes = Str.to_utf8(msg)
	shapes = Font.text(bytes, 20.0, 20.0, size, Brush.opaque(0xffffff))
	view = Raster.view_of(0.0)
	blank = List.repeat(0, Raster.width * Raster.height)
	px = paint(blank, view, shapes, 0)

	# One character cell per 3 by 6 pixels: tall cells, because a terminal's
	# are, so the letters come out roughly square. Fine enough to proofread a
	# handful of glyphs at a time.
	wide = 8 + F64.to_i64_wrap(Font.width_of(bytes, size) / 3.0)
	tall = 4 + F64.to_i64_wrap(size / 6.0) * 2
	var $out = ""
	var $row = 0
	while $row < tall {
		var $line = ""
		var $col = 0
		while $col < wide {
			$line = Str.concat($line, if lit(px, 3 * $col, 6 * $row) { "#" } else { "." })
			$col = $col + 1
		}
		$out = Str.concat($out, Str.concat($line, "\n"))
		$row = $row + 1
	}
	echo!($out)
	Ok({})
}

# Any pixel set in the cell, so a thin stroke still shows.
lit : List(U32), I64, I64 -> Bool
lit = |px, x0, y0| {
	var $hit = Bool.False
	var $dy = 0
	while $dy < 6 {
		var $dx = 0
		while $dx < 3 {
			i = (y0 + $dy) * U64.to_i64_wrap(Raster.width) + (x0 + $dx)
			$hit = if i >= 0 and i < U64.to_i64_wrap(List.len(px)) and (List.get(px, I64.to_u64_wrap(i)) ?? 0) != 0 { Bool.True } else { $hit }
			$dx = $dx + 1
		}
		$dy = $dy + 1
	}
	$hit
}

paint : List(U32), Raster.View, List(Shapes.Shape), U64 -> List(U32)
paint = |px, view, shapes, i|
	if i >= List.len(shapes) { px } else {
		next = match List.get(shapes, i) ?? crash("shape") {
			Poly(p) => Raster.fill_polygon(px, view, p.pts, p.fill)
			_ => px
		}
		paint(next, view, shapes, i + 1)
	}
