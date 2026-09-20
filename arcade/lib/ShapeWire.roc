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
#   kind    0 poly, 1 disc, 2 rect, 3 blend, 4 view, 5 image
#   mode    which brush (0 flat, 1 span, 2 radial, 3 linear, 4 ellipse, 5 glow)
#   brush   its colours (0xRRGGBB, then alpha) and its geometry
#   shape   poly: count, then x, y pairs · disc: x, y, r, then a clip
#           rect: x, y, w, h
#
# The two marks are the exception and carry no brush. A blend is the kind and
# the mode it switches to. A view is the kind and then a space: 0 for the
# screen, or 1 and then the camera's target, offset, rotation and zoom.
#
# An image is the kind, its cols and rows, its rectangle, and then one word a
# PIXEL, 0xAARRGGBB. A brush's colour takes two words -- a packed RGB and the
# alpha as a float -- because a brush is a handful of colours and the float is
# what every painter shades with; a picture is thousands of them and bytes are
# what one is made of.
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
	# Not a shape: a mark that changes how the shapes after it are combined.
	kind_blend : U32
	kind_blend = 3
	# Not a shape either: a mark that changes where they are.
	kind_view : U32
	kind_view = 4
	kind_image : U32
	kind_image = 5

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
			# A mark, not a shape: one word for the kind and one for the mode.
			Blend(m) => [kind_blend, if m == Add { 1 } else { 0 }]
			View(l) => List.concat([kind_view], space(l))
			Image(i) => List.concat(
				List.concat([kind_image, U64.to_u32_wrap(i.cols), U64.to_u32_wrap(i.rows)], nums([i.x, i.y, i.w, i.h])),
				List.map(i.pixels, pixel),
			)
			# **THE PAGE IS NEVER SENT PIECES.** A canvas fills a concave
			# polygon itself, so nothing here cuts one up; see `Shapes.cut`,
			# which is the step roc-ray asks for and this does not.
			Pieces(_) => crash("ShapeWire: a page is never sent Pieces; do not cut a frame it will draw")
		}

	# One pixel, 0xAARRGGBB: the bytes a picture is made of, in the order
	# `putImageData` wants them read back out.
	pixel : Brush.Rgba -> U32
	pixel = |c|
		U32.bitwise_or(
			U32.bitwise_or(U32.shl_wrap(byte(c.a * 255.0), 24), U32.shl_wrap(byte(c.r), 16)),
			U32.bitwise_or(U32.shl_wrap(byte(c.g), 8), byte(c.b)),
		)

	# A space: 0 for the screen, or 1 and the camera's four settings. The same
	# shape as a clip, and for the same reason -- the word that says which
	# says how many follow.
	space : Shapes.Space -> List(U32)
	space = |l|
		match l {
			Screen => [0]
			World(c) => List.concat([1], nums([c.target.x, c.target.y, c.offset.x, c.offset.y, c.rotation, c.zoom]))
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
