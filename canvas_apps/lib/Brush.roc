# Brush is the paint a shape is filled with: a flat colour or one of five
# gradients, with the gradient's geometry in scene coordinates. Safari's
# ScanlineFill shades a brush on the CPU, BrushGlsl on the GPU and
# shapes_canvas.js on a canvas, all from what is here.
#
# Every canvas app paints with it, so it sits in lib/ rather than in safari/.
#
# The tags are the ones shapes_canvas.js reads, and so is what they mean:
# gradients mix unpremultiplied, as the canvas specification says, and an
# offset outside [0, 1] is clamped as shapes_canvas.js clamps it.
import ArgbColor
import RgbColor

Brush :: [].{
	# Red, green and blue in 0..255, alpha in 0..1.
	Rgba : { r : F64, g : F64, b : F64, a : F64 }

	# The start colour up to `start_offset`, the end colour from `end_offset`,
	# and a mix of the two between.
	TwoStops : { start_color : Brush.Rgba, end_color : Brush.Rgba, start_offset : F64, end_offset : F64 }

	Fill : [
		Flat(Brush.Rgba),
		# The edge colour at `left_x` and `right_x`, and the middle colour halfway.
		Span({ edge_color : Brush.Rgba, middle_color : Brush.Rgba, left_x : F64, right_x : F64 }),
		Radial({ inner_color : Brush.Rgba, outer_color : Brush.Rgba, center : { x : F64, y : F64 }, inner_radius : F64, outer_radius : F64 }),
		Linear({ stops : Brush.TwoStops, start_point : { x : F64, y : F64 }, end_point : { x : F64, y : F64 } }),
		# Out from `center` to the ellipse whose half-axes are `axis_u` and `axis_v`.
		Ellipse({ stops : Brush.TwoStops, center : { x : F64, y : F64 }, axis_u : { x : F64, y : F64 }, axis_v : { x : F64, y : F64 } }),
		# The sun's glow: the middle colour at `middle_offset`, strictly between 0
		# and 1, which `Brush.glow` checks.
		Glow(Brush.GlowLook),
	]

	GlowLook : { inner_color : Brush.Rgba, middle_color : Brush.Rgba, outer_color : Brush.Rgba, middle_offset : F64, center : { x : F64, y : F64 }, inner_radius : F64, outer_radius : F64 }

	# The colour a brush gives the scene point (x, y).
	shade : Brush.Fill, F64, F64 -> Brush.Rgba
	shade = |fill, x, y|
		match fill {
			Flat(col) => col
			Span(p) => {
				t = clamp01((x - p.left_x) / (p.right_x - p.left_x))
				if t <= 0.5 {
					mix(p.edge_color, p.middle_color, t * 2.0)
				} else {
					mix(p.middle_color, p.edge_color, (t - 0.5) * 2.0)
				}
			}
			Radial(p) => {
				d = ((x - p.center.x) * (x - p.center.x) + (y - p.center.y) * (y - p.center.y)).sqrt()
				mix(
					p.inner_color,
					p.outer_color,
					if p.outer_radius > p.inner_radius {
						clamp01((d - p.inner_radius) / (p.outer_radius - p.inner_radius))
					} else {
						1.0
					},
				)
			}
			Linear(p) => {
				dx = p.end_point.x - p.start_point.x
				dy = p.end_point.y - p.start_point.y
				two_stop(p.stops, clamp01(((x - p.start_point.x) * dx + (y - p.start_point.y) * dy) / (dx * dx + dy * dy)))
			}
			Ellipse(p) => {
				qx = x - p.center.x
				qy = y - p.center.y
				inverse = ellipse_inverse({ axis_u: p.axis_u, axis_v: p.axis_v })
				ux = inverse.top_row.x * qx + inverse.top_row.y * qy
				uy = inverse.bottom_row.x * qx + inverse.bottom_row.y * qy
				two_stop(p.stops, clamp01((ux * ux + uy * uy).sqrt()))
			}
			Glow(p) => {
				d = ((x - p.center.x) * (x - p.center.x) + (y - p.center.y) * (y - p.center.y)).sqrt()
				t = if p.outer_radius > p.inner_radius {
					clamp01((d - p.inner_radius) / (p.outer_radius - p.inner_radius))
				} else {
					1.0
				}
				m = p.middle_offset
				if t <= m {
					mix(p.inner_color, p.middle_color, t / m)
				} else {
					mix(p.middle_color, p.outer_color, (t - m) / (1.0 - m))
				}
			}
		}

	# The determinant of the matrix whose columns are an ellipse's axes. Near
	# zero, the axes are nearly parallel and the ellipse has no inverse.
	ellipse_determinant : { axis_u : { x : F64, y : F64 }, axis_v : { x : F64, y : F64 } } -> F64
	ellipse_determinant = |{ axis_u, axis_v }| axis_u.x * axis_v.y - axis_u.y * axis_v.x

	# The matrix that takes an offset from an ellipse's center to the unit
	# circle, the inverse of the one whose columns are its axes. An offset
	# (dx, dy) goes to (top_row.x * dx + top_row.y * dy, bottom_row.x * dx +
	# bottom_row.y * dy). Brush.shade and the native player's shader both use it.
	ellipse_inverse : { axis_u : { x : F64, y : F64 }, axis_v : { x : F64, y : F64 } } -> { top_row : { x : F64, y : F64 }, bottom_row : { x : F64, y : F64 } }
	ellipse_inverse = |{ axis_u, axis_v }| {
		det = ellipse_determinant({ axis_u, axis_v })
		{
			top_row: { x: axis_v.y / det, y: (0.0 - axis_v.x) / det },
			bottom_row: { x: (0.0 - axis_u.y) / det, y: axis_u.x / det },
		}
	}

	# An opaque colour as a brush paints it.
	opaque : RgbColor -> Brush.Rgba
	opaque = |color| {
		rgb = color.to_i64()
		{ r: channel(rgb, 16), g: channel(rgb, 8), b: channel(rgb, 0), a: 1.0 }
	}

	# A colour with its alpha byte as a brush paints it, the alpha as a share
	# of 255.
	translucent : ArgbColor -> Brush.Rgba
	translucent = |color| {
		argb = color.to_i64()
		{ r: channel(argb, 16), g: channel(argb, 8), b: channel(argb, 0), a: channel(argb, 24) / 255.0 }
	}

	# An opaque colour made part way see-through by an alpha from 0 to 1, for
	# an alpha chosen as a share rather than as a byte. An alpha byte belongs
	# in an ArgbColor, which goes through `translucent`.
	with_alpha : RgbColor, F64 -> Brush.Rgba
	with_alpha = |color, alpha|
		if alpha < 0.0 or alpha > 1.0 {
			crash "Brush.with_alpha: an alpha outside 0 to 1"
		} else {
			{ ..opaque(color), a: alpha }
		}

	# The glow as a fill, its middle offset checked: at 0 or 1, one half of the
	# glow has no width, and its mix divides by zero.
	glow : Brush.GlowLook -> Brush.Fill
	glow = |look|
		if look.middle_offset <= 0.0 or look.middle_offset >= 1.0 {
			crash "Brush.glow: the middle offset must lie strictly between 0 and 1"
		} else {
			Glow(look)
		}

	mix : Brush.Rgba, Brush.Rgba, F64 -> Brush.Rgba
	mix = |p, q, t| { r: p.r + (q.r - p.r) * t, g: p.g + (q.g - p.g) * t, b: p.b + (q.b - p.b) * t, a: p.a + (q.a - p.a) * t }

	clamp01 : F64 -> F64
	clamp01 = |t| if t < 0.0 {
		0.0
	} else if t > 1.0 {
		1.0
	} else {
		t
	}
}

# One eight-bit channel of a packed colour, as a float.
channel : I64, U8 -> F64
channel = |packed, shift| packed.shr_wrap(shift).bitwise_and(255).to_f64()

# The colour the stops give at `t`, for offsets start_offset <= end_offset.
two_stop : Brush.TwoStops, F64 -> Brush.Rgba
two_stop = |stops, t| if t <= stops.start_offset {
	stops.start_color
} else if t >= stops.end_offset {
	stops.end_color
} else {
	Brush.mix(stops.start_color, stops.end_color, (t - stops.start_offset) / (stops.end_offset - stops.start_offset))
}

# The ellipse with axes (3, 4) and (5, 6) has determinant -2, and its inverse
# takes each axis back to a unit vector.
sample_inverse : { top_row : { x : F64, y : F64 }, bottom_row : { x : F64, y : F64 } }
sample_inverse = Brush.ellipse_inverse({ axis_u: { x: 3.0, y: 4.0 }, axis_v: { x: 5.0, y: 6.0 } })

expect Brush.ellipse_determinant({ axis_u: { x: 3.0, y: 4.0 }, axis_v: { x: 5.0, y: 6.0 } }) == -2.0
expect sample_inverse == { top_row: { x: -3.0, y: 2.5 }, bottom_row: { x: 2.0, y: -1.5 } }

expect Brush.translucent(ArgbColor.of(0x80FFE9A8)) == { r: 255.0, g: 233.0, b: 168.0, a: 128.0 / 255.0 }
expect Brush.translucent(ArgbColor.of(0xFF000000)) == { r: 0.0, g: 0.0, b: 0.0, a: 1.0 }

# A colour with no alpha byte is invisible.
expect Brush.translucent(ArgbColor.of(0x00FFE9A8)).a == 0.0

expect Brush.opaque(RgbColor.of(0xFFE9A8)) == { r: 255.0, g: 233.0, b: 168.0, a: 1.0 }

# An alpha share is kept as it is, at either end and between.
expect Brush.with_alpha(RgbColor.of(0xFFC980), 0.85) == { r: 255.0, g: 201.0, b: 128.0, a: 0.85 }
expect Brush.with_alpha(RgbColor.of(0xFFC980), 0.0).a == 0.0
expect Brush.with_alpha(RgbColor.of(0xFFC980), 1.0) == Brush.opaque(RgbColor.of(0xFFC980))
