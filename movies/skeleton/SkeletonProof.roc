# Does it look like a skeleton? Natively, as ASCII art, one frame at a time.
#
# Hand-written, the same trick FontProof plays: the shapes are painted with
# Raster and printed coarse enough to read in a terminal, because a pose is
# hand-authored angles and an angle that is wrong is invisible in the source.
#
#   roc build --opt=dev SkeletonProof.roc --output=<bin>; <bin> 0
import Skeleton
import Shapes
import Raster
import Brush

main! = |args| {
	tick = I64.from_str(List.get(args, 0) ?? "0") ?? 0
	shapes = Skeleton.shapes({ tick: tick })
	view = Raster.view_of(0.0)
	px = paint(List.repeat(0, Raster.width * Raster.height), view, shapes, 0)
	# Eight by fourteen: a terminal's cells are tall, so this comes out roughly
	# square at the skeleton's own 640 by 480.
	var $out = Str.concat("tick ", Str.concat(I64.to_str(tick), "\n"))
	var $row = 0
	while $row < 34 {
		var $line = ""
		var $col = 0
		while $col < 80 {
			$line = Str.concat($line, if lit(px, 8 * $col, 14 * $row) { "#" } else { "." })
			$col = $col + 1
		}
		$out = Str.concat($out, Str.concat($line, "\n"))
		$row = $row + 1
	}
	echo!($out)
	Ok({})
}

# Bone against night: anything not the background colour counts as drawn.
lit : List(U32), I64, I64 -> Bool
lit = |px, x0, y0| {
	var $hit = Bool.False
	var $dy = 0
	while $dy < 14 {
		var $dx = 0
		while $dx < 8 {
			i = (y0 + $dy) * U64.to_i64_wrap(Raster.width) + (x0 + $dx)
			v = if i >= 0 and i < U64.to_i64_wrap(List.len(px)) { List.get(px, I64.to_u64_wrap(i)) ?? 0 } else { 0 }
			$hit = if v > 1000000 { Bool.True } else { $hit }
			$dx = $dx + 1
		}
		$dy = $dy + 1
	}
	$hit
}

# Raster fills polygons, so a disc and a rectangle become one first.
paint : List(U32), Raster.View, List(Shapes.Shape), U64 -> List(U32)
paint = |px, view, shapes, i|
	if i >= List.len(shapes) { px } else {
		next = match List.get(shapes, i) ?? crash("shape") {
			Poly(p) => Raster.fill_polygon(px, view, p.pts, p.fill)
			Rect(r) => Raster.fill_polygon(px, view, [r.x, r.y, r.x + r.w, r.y, r.x + r.w, r.y + r.h, r.x, r.y + r.h], r.fill)
			Disc(d) => Raster.fill_polygon(px, view, ring(d.x, d.y, d.r, 0, []), d.fill)
			_ => px
		}
		paint(next, view, shapes, i + 1)
	}

ring : F64, F64, F64, I64, List(F64) -> List(F64)
ring = |x, y, r, k, acc|
	if k >= 20 { acc } else {
		a = 6.283185307179586 * I64.to_f64(k) / 20.0
		ring(x, y, r, k + 1, List.concat(acc, [x + r * sin_(a + 1.5707963267948966), y + r * sin_(a)]))
	}

sin_ : F64 -> F64
sin_ = |a| {
	u = a - 6.283185307179586 * I64.to_f64(F64.to_i64_wrap(a / 6.283185307179586))
	v = if u > 3.141592653589793 { u - 6.283185307179586 } else { u }
	v2 = v * v
	v * (1.0 - v2 / 6.0 * (1.0 - v2 / 20.0 * (1.0 - v2 / 42.0)))
}
