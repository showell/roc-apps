# ShapeWire -- a frame's shapes as words a page can read.
#
# Hand-written, the web's half of what BrushGlsl is to roc-ray: one frame,
# packed into the linear memory a browser reads, in the vocabulary every
# painter here already speaks. **THE MODES ARE BrushGlsl's** -- 0 flat, 1 span,
# 2 radial, 3 linear, 4 ellipse, 5 glow -- so a brush means one thing whether
# it is shaded on a CPU (Raster), on a GPU (BrushGlsl) or on a canvas.
#
# What used to go over this wire was draw commands, and the page painted the
# sky, the grass and the sun itself from six more exports. A page cannot do
# that for a movie it does not know, so the backdrop comes over the wire like
# everything else and the page paints what it is given.
#
# The layout, all 32-bit words, floats as bit patterns:
#
#   kind    0 poly, 1 disc, 2 rect
#   mode    which brush
#   brush   its colours (0xRRGGBB, then alpha) and its geometry
#   shape   poly: count, then x, y pairs · disc: x, y, r, then a clip
#           rect: x, y, w, h
#
# A clip is a word that is 0, or 1 and then x, y, w, h.
import Brush
import Shapes

ShapeWire :: [].{
	kind_poly : U32
	kind_poly = 0
	kind_disc : U32
	kind_disc = 1
	kind_rect : U32
	kind_rect = 2

	pack : List(Shapes.Shape) -> List(U32)
	pack = |shapes| {
		n = List.len(shapes)
		var $out = List.with_capacity(16 * n)
		var $k = 0
		while $k < n {
			$out = List.concat($out, one(List.get(shapes, $k) ?? crash("shape out of range")))
			$k = $k + 1
		}
		$out
	}

	one : Shapes.Shape -> List(U32)
	one = |shape|
		match shape {
			Poly(p) => List.concat(List.concat([kind_poly], brush(p.fill)), points(p.pts))
			Rect(r) => List.concat(List.concat([kind_rect], brush(r.fill)), nums([r.x, r.y, r.w, r.h]))
			Disc(d) => List.concat(
				List.concat(List.concat([kind_disc], brush(d.fill)), nums([d.x, d.y, d.r])),
				clip(d.clip),
			)
			# **THE PAGE IS NEVER SENT PIECES.** A canvas fills a concave
			# polygon itself, so nothing here cuts one up; see `Shapes.cut`,
			# which is the step roc-ray asks for and this does not.
			Pieces(_) => []
		}

	clip : Shapes.Clip -> List(U32)
	clip = |c|
		match c {
			Anywhere => [0]
			Within(r) => List.concat([1], nums([r.x, r.y, r.w, r.h]))
		}

	points : List(F64) -> List(U32)
	points = |pts| List.concat([U64.to_u32_wrap(List.len(pts) // 2)], nums(pts))

	# A brush: its mode, then its colours and geometry in the order the mode
	# says. BrushGlsl.mode_of names the same numbers for the same fills.
	brush : Brush.Fill -> List(U32)
	brush = |fill|
		match fill {
			Skip => List.concat([0], color({ r: 0.0, g: 0.0, b: 0.0, a: 0.0 }))
			Flat(c) => List.concat([0], color(c))
			Span(p) => List.concat(List.concat([1], color(p.edge)), List.concat(color(p.middle), nums([p.x0, p.x1])))
			Radial(p) => List.concat(List.concat([2], color(p.inner)), List.concat(color(p.outer), nums([p.x, p.y, p.r0, p.r1])))
			Linear(p) => List.concat(List.concat([3], color(p.c0)), List.concat(color(p.c1), nums([p.o0, p.o1, p.ax, p.ay, p.dx, p.dy])))
			Ellipse(p) => List.concat(List.concat([4], color(p.c0)), List.concat(color(p.c1), nums([p.o0, p.o1, p.x, p.y, p.ia, p.ib, p.ic, p.id])))
			Glow(p) => List.concat(
				List.concat([5], color(p.c0)),
				List.concat(List.concat(color(p.c1), color(p.c2)), nums([p.x, p.y, p.r0, p.r1])),
			)
		}

	# 0xRRGGBB, then the alpha as a float. The channels are rounded to bytes
	# because that is what every painter does with them in the end.
	color : Brush.Rgba -> List(U32)
	color = |c|
		[
			U32.bitwise_or(
				U32.bitwise_or(U32.shl_wrap(byte(c.r), 16), U32.shl_wrap(byte(c.g), 8)),
				byte(c.b),
			),
			num(c.a),
		]

	byte : F64 -> U32
	byte = |v| {
		n = F64.to_i64_wrap(v + 0.5)
		I64.to_u32_wrap(if n < 0 { 0 } else if n > 255 { 255 } else { n })
	}

	num : F64 -> U32
	num = |v| F32.to_bits(F64.to_f32_wrap(v))

	nums : List(F64) -> List(U32)
	nums = |vs| List.map(vs, num)
}
