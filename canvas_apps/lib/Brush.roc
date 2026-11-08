## A brush is the paint a shape is filled with. It answers one question: what
## colour does this point of the shape get? A `Fill` is a flat colour or one of
## five gradients, and a gradient's geometry is in the same coordinates as the
## shape it fills. `shade` is the answer, point by point.
##
## A polygon, disc or rectangle has exactly one fill and nothing else. There is
## no stroke: an outline is built from filled shapes, as `Shapes.line` and
## `Shapes.ring_shapes` build it. There is no alpha on the shape either. Each
## colour carries its own alpha, from 0 for invisible to 1 for opaque, and a
## gradient mixes the alpha along with red, green and blue. The colour a point
## gets is then laid over what is already there by the frame's mode
## (`Shapes.Mode`), which paints over it or adds light to it, in proportion to
## that alpha either way.
##
## A CPU painter shades a brush with `shade`, BrushGlsl does it on the GPU
## and shapes_canvas.js on a canvas, all from what is here. The tags are the ones
## shapes_canvas.js reads, and so is what they mean: gradients mix
## unpremultiplied, as the canvas specification says, and an offset outside
## [0, 1] is clamped as shapes_canvas.js clamps it.
import ArgbColor
import Point
import RgbColor

Brush :: [].{

	## Red, green and blue in 0..255, alpha in 0..1.
	Rgba : { r : F64, g : F64, b : F64, a : F64 }

	## The start colour up to `start_offset`, the end colour from `end_offset`,
	## and a mix of the two between.
	TwoStops : { start_color : Brush.Rgba, end_color : Brush.Rgba, start_offset : F64, end_offset : F64 }

	Fill : [
		Flat(Brush.Rgba),

		## The edge colour at `left_x` and `right_x`, and the middle colour halfway.
		Span({ edge_color : Brush.Rgba, middle_color : Brush.Rgba, left_x : F64, right_x : F64 }),
		Radial({ inner_color : Brush.Rgba, outer_color : Brush.Rgba, center : Point.Point, inner_radius : F64, outer_radius : F64 }),
		Linear({ stops : Brush.TwoStops, start_point : Point.Point, end_point : Point.Point }),

		## Out from `center` to the ellipse whose half-axes are `axis_u` and `axis_v`.
		Ellipse({ stops : Brush.TwoStops, center : Point.Point, axis_u : Point.Point, axis_v : Point.Point }),

		## A radial gradient of three stops: the inner colour at `inner_radius`,
		## the outer colour at `outer_radius`, and the middle colour at
		## `middle_offset` of the way between, strictly between 0 and 1, which
		## `Brush.glow` checks.
		Glow(Brush.GlowLook),
	]

	GlowLook : { inner_color : Brush.Rgba, middle_color : Brush.Rgba, outer_color : Brush.Rgba, middle_offset : F64, center : Point.Point, inner_radius : F64, outer_radius : F64 }

	## The colour a brush gives a scene point. A gradient with no length, a
	## span whose two edges meet, a line from a point to itself or a ring whose
	## radii meet, gives its far colour everywhere, since there is no distance
	## along it to share out.
	shade : Brush.Fill, Point.Point -> Brush.Rgba
	shade = |fill, { x, y }|
		match fill {
			Flat(color) => color
			Span(p) => {
				t = if p.right_x != p.left_x {
					clamp01((x - p.left_x) / (p.right_x - p.left_x))
				} else {
					1.0
				}
				if t <= 0.5 {
					mix({ from: p.edge_color, to: p.middle_color, fraction: t * 2.0 })
				} else {
					mix({ from: p.middle_color, to: p.edge_color, fraction: (t - 0.5) * 2.0 })
				}
			}
			Radial(p) =>
				mix({
					from: p.inner_color,
					to: p.outer_color,
					fraction: radial_fraction({ x, y }, { center: p.center, inner_radius: p.inner_radius, outer_radius: p.outer_radius }),
				})
			Linear(p) => {
				dx = p.end_point.x - p.start_point.x
				dy = p.end_point.y - p.start_point.y
				length_squared = dx * dx + dy * dy
				two_stop(
					p.stops,
					if length_squared > 0.0 {
						clamp01(((x - p.start_point.x) * dx + (y - p.start_point.y) * dy) / length_squared)
					} else {
						1.0
					},
				)
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
				t = radial_fraction({ x, y }, { center: p.center, inner_radius: p.inner_radius, outer_radius: p.outer_radius })
				m = p.middle_offset
				if t <= m {
					mix({ from: p.inner_color, to: p.middle_color, fraction: t / m })
				} else {
					mix({ from: p.middle_color, to: p.outer_color, fraction: (t - m) / (1.0 - m) })
				}
			}
		}

	## The gradient out from `center` to the ellipse whose half-axes are `axis_u`
	## and `axis_v`, or `TooThin` when the axes are so nearly parallel that the
	## ellipse has no sound inverse to shade with.
	ellipse : { stops : Brush.TwoStops, center : Point.Point, axis_u : Point.Point, axis_v : Point.Point } -> Try(Brush.Fill, [TooThin])
	ellipse = |look|
		if ellipse_determinant({ axis_u: look.axis_u, axis_v: look.axis_v }).abs() < min_ellipse_determinant {
			Err(TooThin)
		} else {
			Ok(Ellipse(look))
		}

	## The matrix that takes an offset from an ellipse's center to the unit
	## circle, the inverse of the one whose columns are its axes. An offset
	## (dx, dy) goes to (top_row.x * dx + top_row.y * dy, bottom_row.x * dx +
	## bottom_row.y * dy). Brush.shade and BrushGlsl's uniforms both use it.
	ellipse_inverse : { axis_u : Point.Point, axis_v : Point.Point } -> { top_row : Point.Point, bottom_row : Point.Point }
	ellipse_inverse = |{ axis_u, axis_v }| {
		det = ellipse_determinant({ axis_u, axis_v })
		{
			top_row: { x: axis_v.y / det, y: (0.0 - axis_v.x) / det },
			bottom_row: { x: (0.0 - axis_u.y) / det, y: axis_u.x / det },
		}
	}

	## An opaque colour as a brush paints it.
	opaque_rgba : RgbColor -> Brush.Rgba
	opaque_rgba = |color| {
		r: color.red().to_f64(),
		g: color.green().to_f64(),
		b: color.blue().to_f64(),
		a: 1.0,
	}

	## An opaque colour as a flat fill.
	flat : RgbColor -> Brush.Fill
	flat = |color| Flat(opaque_rgba(color))

	## A colour with its alpha byte as a brush paints it, the alpha as a share
	## of 255.
	translucent : ArgbColor -> Brush.Rgba
	translucent = |color| { ..opaque_rgba(color.rgb()), a: color.alpha().to_f64() / 255.0 }

	## An opaque colour made part way see-through by an alpha from 0 to 1, for
	## an alpha chosen as a share rather than as a byte. An alpha byte belongs
	## in an ArgbColor, which goes through `translucent`.
	with_alpha : RgbColor, F64 -> Brush.Rgba
	with_alpha = |color, alpha|
		if alpha < 0.0 or alpha > 1.0 {
			crash "Brush.with_alpha: an alpha outside 0 to 1"
		} else {
			{ ..opaque_rgba(color), a: alpha }
		}

	## The glow as a fill, its middle offset checked: at 0 or 1, one half of the
	## glow has no width, and its mix divides by zero.
	glow : Brush.GlowLook -> Brush.Fill
	glow = |look|
		if look.middle_offset <= 0.0 or look.middle_offset >= 1.0 {
			crash "Brush.glow: the middle offset must lie strictly between 0 and 1"
		} else {
			Glow(look)
		}

	## The colour `fraction` of the way from one colour to another.
	mix : { from : Brush.Rgba, to : Brush.Rgba, fraction : F64 } -> Brush.Rgba
	mix = |{ from: p, to: q, fraction: t }| { r: p.r + (q.r - p.r) * t, g: p.g + (q.g - p.g) * t, b: p.b + (q.b - p.b) * t, a: p.a + (q.a - p.a) * t }
}

clamp01 : F64 -> F64
clamp01 = |t| if t < 0.0 {
	0.0
} else if t > 1.0 {
	1.0
} else {
	t
}

## How far a point lies from the inner radius to the outer one, clamped to 0..1,
## or 1 when the radii meet.
radial_fraction : Point.Point, { center : Point.Point, inner_radius : F64, outer_radius : F64 } -> F64
radial_fraction = |{ x, y }, ring| {
	distance = ((x - ring.center.x) * (x - ring.center.x) + (y - ring.center.y) * (y - ring.center.y)).sqrt()
	if ring.outer_radius > ring.inner_radius {
		clamp01((distance - ring.inner_radius) / (ring.outer_radius - ring.inner_radius))
	} else {
		1.0
	}
}

## The determinant of the matrix whose columns are an ellipse's axes. Near
## zero, the axes are nearly parallel and the ellipse has no inverse.
ellipse_determinant : { axis_u : Point.Point, axis_v : Point.Point } -> F64
ellipse_determinant = |{ axis_u, axis_v }| axis_u.x * axis_v.y - axis_u.y * axis_v.x

## The least area, in square units of the shape's coordinates, that an
## ellipse's two axes may span for `Brush.ellipse` to give the gradient. Below
## it the axes are all but parallel, the ellipse covers far less than a pixel,
## and its inverse, which divides by this area, has nothing sound to give.
## 0.0001 is a round number chosen well under a pixel, not one tuned to a
## picture.
min_ellipse_determinant : F64
min_ellipse_determinant = 0.0001

## The colour the stops give at `t`, for offsets start_offset <= end_offset.
two_stop : Brush.TwoStops, F64 -> Brush.Rgba
two_stop = |stops, t| if t <= stops.start_offset {
	stops.start_color
} else if t >= stops.end_offset {
	stops.end_color
} else {
	Brush.mix({ from: stops.start_color, to: stops.end_color, fraction: (t - stops.start_offset) / (stops.end_offset - stops.start_offset) })
}

## The ellipse with axes (3, 4) and (5, 6) has determinant -2, and its inverse
## takes each axis back to a unit vector.
sample_inverse : { top_row : Point.Point, bottom_row : Point.Point }
sample_inverse = Brush.ellipse_inverse({ axis_u: { x: 3.0, y: 4.0 }, axis_v: { x: 5.0, y: 6.0 } })

expect ellipse_determinant({ axis_u: { x: 3.0, y: 4.0 }, axis_v: { x: 5.0, y: 6.0 } }) == -2.0
expect sample_inverse == { top_row: { x: -3.0, y: 2.5 }, bottom_row: { x: 2.0, y: -1.5 } }

# An ellipse whose axes span the least area is a gradient, one just under it
# is too thin, either way round, and parallel axes are too thin.
expect {
	stops = { start_color: Brush.opaque_rgba(RgbColor.of(0x000000)), end_color: Brush.opaque_rgba(RgbColor.of(0xFFFFFF)), start_offset: 0.0, end_offset: 1.0 }
	at_least = { stops, center: { x: 0.0, y: 0.0 }, axis_u: { x: 0.0001, y: 0.0 }, axis_v: { x: 0.0, y: 1.0 } }
	under = { ..at_least, axis_u: { x: 0.00009, y: 0.0 } }
	under_flipped = { ..under, axis_v: { x: 0.0, y: -1.0 } }
	parallel = { ..at_least, axis_u: { x: 2.0, y: 4.0 }, axis_v: { x: 1.0, y: 2.0 } }
	Brush.ellipse(at_least) == Ok(Ellipse(at_least))
		and Brush.ellipse(under) == Err(TooThin)
		and Brush.ellipse(under_flipped) == Err(TooThin)
		and Brush.ellipse(parallel) == Err(TooThin)
}

expect Brush.translucent(ArgbColor.of(0x80FFE9A8)) == { r: 255.0, g: 233.0, b: 168.0, a: 128.0 / 255.0 }
expect Brush.translucent(ArgbColor.of(0xFF000000)) == { r: 0.0, g: 0.0, b: 0.0, a: 1.0 }

# A colour with no alpha byte is invisible.
expect Brush.translucent(ArgbColor.of(0x00FFE9A8)).a == 0.0

expect Brush.opaque_rgba(RgbColor.of(0xFFE9A8)) == { r: 255.0, g: 233.0, b: 168.0, a: 1.0 }

expect Brush.flat(RgbColor.of(0xFFE9A8)) == Flat({ r: 255.0, g: 233.0, b: 168.0, a: 1.0 })

# An alpha share is kept as it is, at either end and between.
expect Brush.with_alpha(RgbColor.of(0xFFC980), 0.85) == { r: 255.0, g: 201.0, b: 128.0, a: 0.85 }
expect Brush.with_alpha(RgbColor.of(0xFFC980), 0.0).a == 0.0
expect Brush.with_alpha(RgbColor.of(0xFFC980), 1.0) == Brush.opaque_rgba(RgbColor.of(0xFFC980))

# A span whose edges meet gives its edge colour everywhere, and one with any
# width still gives its middle colour halfway.
expect {
	edge = Brush.opaque_rgba(RgbColor.of(0x000000))
	middle = Brush.opaque_rgba(RgbColor.of(0xFFFFFF))
	met = Span({ edge_color: edge, middle_color: middle, left_x: 5.0, right_x: 5.0 })
	wide = Span({ edge_color: edge, middle_color: middle, left_x: 4.0, right_x: 6.0 })
	Brush.shade(met, { x: 5.0, y: 0.0 }) == edge and Brush.shade(wide, { x: 5.0, y: 0.0 }) == middle
}

# A line from a point to itself gives its end colour everywhere, and a line
# with any length gives its start colour at its start.
expect {
	stops = { start_color: Brush.opaque_rgba(RgbColor.of(0x000000)), end_color: Brush.opaque_rgba(RgbColor.of(0xFFFFFF)), start_offset: 0.0, end_offset: 1.0 }
	point = Linear({ stops, start_point: { x: 1.0, y: 1.0 }, end_point: { x: 1.0, y: 1.0 } })
	line = Linear({ stops, start_point: { x: 1.0, y: 1.0 }, end_point: { x: 1.0, y: 3.0 } })
	Brush.shade(point, { x: 1.0, y: 1.0 }) == stops.end_color and Brush.shade(line, { x: 1.0, y: 1.0 }) == stops.start_color
}
