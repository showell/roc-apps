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
##
## Every kind of fill has a maker here, and any region takes any of them.
import ArgbColor
import ColorShade
import Fraction
import Pixels
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
		Span({ edge_color : Brush.Rgba, middle_color : Brush.Rgba, left_x : Pixels, right_x : Pixels }),
		Radial({ inner_color : Brush.Rgba, outer_color : Brush.Rgba, center : Point.Point, inner_radius : Pixels, outer_radius : Pixels }),
		Linear({ stops : Brush.TwoStops, start_point : Point.Point, end_point : Point.Point }),

		## Out from `center` to the ellipse whose half-axes are `axis_u` and `axis_v`.
		Ellipse({ stops : Brush.TwoStops, center : Point.Point, axis_u : Point.Point, axis_v : Point.Point }),

		## A radial gradient of three stops: the inner colour at `inner_radius`,
		## the outer colour at `outer_radius`, and the middle colour at
		## `middle_offset` of the way between, strictly between 0 and 1, which
		## `Brush.glow` checks.
		Glow(Brush.GlowLook),
	]

	GlowLook : {
		inner_color : Brush.Rgba,
		middle_color : Brush.Rgba,
		outer_color : Brush.Rgba,
		middle_offset : F64,
		center : Point.Point,
		inner_radius : Pixels,
		outer_radius : Pixels,
	}

	## A row of a 2 by 2 matrix, as `ellipse_inverse` gives it.
	MatrixRow : { x : F64, y : F64 }

	## The colour a brush gives a scene point. A gradient with no length, a
	## span whose two edges meet, a line from a point to itself or a ring whose
	## radii meet, gives its far colour everywhere, since there is no distance
	## along it to share out.
	shade : Brush.Fill, Point.Point -> Brush.Rgba
	shade = |fill, point| {
		x = point.x.to_f64()
		y = point.y.to_f64()
		match fill {
			Flat(color) => color
			Span(p) => {
				left_x = p.left_x.to_f64()
				right_x = p.right_x.to_f64()
				t = if right_x != left_x {
					clamp01((x - left_x) / (right_x - left_x))
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
				start_x = p.start_point.x.to_f64()
				start_y = p.start_point.y.to_f64()
				dx = p.end_point.x.to_f64() - start_x
				dy = p.end_point.y.to_f64() - start_y
				length_squared = dx * dx + dy * dy
				two_stop(
					p.stops,
					if length_squared > 0.0 {
						clamp01(((x - start_x) * dx + (y - start_y) * dy) / length_squared)
					} else {
						1.0
					},
				)
			}
			Ellipse(p) => {
				qx = x - p.center.x.to_f64()
				qy = y - p.center.y.to_f64()
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
	}

	## The gradient out from `center` to the ellipse whose half-axes are `axis_u`
	## and `axis_v`, or `TooThin` when the axes are so nearly parallel that the
	## ellipse has no sound inverse to shade with.
	elliptical_gradient : { stops : Brush.TwoStops, center : Point.Point, axis_u : Point.Point, axis_v : Point.Point } -> Try(Brush.Fill, [TooThin])
	elliptical_gradient = |look|
		if ellipse_determinant({ axis_u: look.axis_u, axis_v: look.axis_v }).abs() < min_ellipse_determinant {
			Err(TooThin)
		} else {
			Ok(Ellipse(look))
		}

	## The matrix that takes an offset from an ellipse's center to the unit
	## circle, the inverse of the one whose columns are its axes. An offset
	## (dx, dy) goes to (top_row.x * dx + top_row.y * dy, bottom_row.x * dx +
	## bottom_row.y * dy). Brush.shade and BrushGlsl's uniforms both use it.
	ellipse_inverse : { axis_u : Point.Point, axis_v : Point.Point } -> { top_row : Brush.MatrixRow, bottom_row : Brush.MatrixRow }
	ellipse_inverse = |{ axis_u, axis_v }| {
		det = ellipse_determinant({ axis_u, axis_v })
		{
			top_row: { x: axis_v.y.to_f64() / det, y: (0.0 - axis_v.x.to_f64()) / det },
			bottom_row: { x: (0.0 - axis_u.y.to_f64()) / det, y: axis_u.x.to_f64() / det },
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

	## How a fill is shaded across a width: its colour, darker at the edges and
	## lighter in the middle by `strength`.
	WidthShade : { color : RgbColor, strength : Fraction }

	## The span of x a region covers. Either end is negative for a region off
	## the left of the screen.
	XSpan : { min_x : Pixels, max_x : Pixels }

	## The fill of a region spanning `span`, shaded across its width, or a flat
	## one where it has no strength or is too narrow to shade.
	width_shade : Brush.XSpan, Brush.WidthShade -> Brush.Fill
	width_shade = |span, { color, strength }|
		if strength <= Fraction.zero or is_too_narrow_to_shade(span) {
			Brush.flat(color)
		} else {
			Span({
				edge_color: Brush.opaque_rgba(width_shade_edge(color, strength)),
				middle_color: Brush.opaque_rgba(width_shade_middle(color, strength)),
				left_x: span.min_x,
				right_x: span.max_x,
			})
		}

	## The fill of the region with these corners, shaded across its width as
	## `width_shade` shades it. A region has a corner, so none crashes.
	corners_shade : List(Point.Point), Brush.WidthShade -> Brush.Fill
	corners_shade = |corners, width_shading| Brush.width_shade(x_span(corners), width_shading)

	## A gradient that spreads in a circle from `center`, from `center_color`
	## there to `edge_color` at `radius`.
	CircularGradient : {
		center_color : ArgbColor,
		edge_color : ArgbColor,
		center : Point.Point,
		radius : Pixels,
	}

	## The fill of a circular gradient, or `TooSmall` when its radius is too
	## small to see, as a distant one can shrink.
	circular_gradient : Brush.CircularGradient -> Try(Brush.Fill, [TooSmall])
	circular_gradient = |gradient|
		if gradient.radius < smallest_gradient_radius {
			Err(TooSmall)
		} else {
			Ok(
				Radial({
					inner_color: Brush.translucent(gradient.center_color),
					outer_color: Brush.translucent(gradient.edge_color),
					center: gradient.center,
					inner_radius: Pixels.zero,
					outer_radius: gradient.radius,
				}),
			)
		}

	## A gradient along the line from `start_point` to `end_point`. A line from
	## a point to itself has no direction, so it crashes.
	linear_gradient : { stops : Brush.TwoStops, start_point : Point.Point, end_point : Point.Point } -> Brush.Fill
	linear_gradient = |{ stops, start_point, end_point }| {
		dx = end_point.x.minus(start_point.x).to_f64()
		dy = end_point.y.minus(start_point.y).to_f64()
		if dx * dx + dy * dy == 0.0 {
			crash "Brush.linear_gradient: a gradient has a length"
		} else {
			Linear({ stops, start_point, end_point })
		}
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
radial_fraction : { x : F64, y : F64 }, { center : Point.Point, inner_radius : Pixels, outer_radius : Pixels } -> F64
radial_fraction = |{ x, y }, ring| {
	cx = ring.center.x.to_f64()
	cy = ring.center.y.to_f64()
	inner = ring.inner_radius.to_f64()
	outer = ring.outer_radius.to_f64()
	distance = ((x - cx) * (x - cx) + (y - cy) * (y - cy)).sqrt()
	if outer > inner {
		clamp01((distance - inner) / (outer - inner))
	} else {
		1.0
	}
}

## The determinant of the matrix whose columns are an ellipse's axes. Near
## zero, the axes are nearly parallel and the ellipse has no inverse.
ellipse_determinant : { axis_u : Point.Point, axis_v : Point.Point } -> F64
ellipse_determinant = |{ axis_u, axis_v }| axis_u.x.to_f64() * axis_v.y.to_f64() - axis_u.y.to_f64() * axis_v.x.to_f64()

## The least area, in square units of the shape's coordinates, that an
## ellipse's two axes may span for `Brush.elliptical_gradient` to give the gradient. Below
## it the axes are all but parallel, the ellipse covers far less than a pixel,
## and its inverse, which divides by this area, has nothing sound to give.
## 0.0001 is a round number chosen well under a pixel, not one tuned to a
## picture.
min_ellipse_determinant : F64
min_ellipse_determinant = 0.0001

## A radial gradient smaller than this is too small to see.
smallest_gradient_radius : Pixels
smallest_gradient_radius = Pixels.of(0.5)

shade_edge_darken : Fraction
shade_edge_darken = Fraction.of(0.4)

shade_middle_lift : Fraction
shade_middle_lift = Fraction.of(0.25)

## A width-shaded fill's colour at its edges.
width_shade_edge : RgbColor, Fraction -> RgbColor
width_shade_edge = |color, strength|
	ColorShade.shade_color(color, Darkened(shade_edge_darken.times(strength)))

## A width-shaded fill's colour in its middle.
width_shade_middle : RgbColor, Fraction -> RgbColor
width_shade_middle = |color, strength|
	ColorShade.shade_color(color, Lightened(shade_middle_lift.times(strength)))

narrowest_shaded_width : Pixels
narrowest_shaded_width = Pixels.of(1.0)

is_too_narrow_to_shade : Brush.XSpan -> Bool
is_too_narrow_to_shade = |span| span.max_x.minus(span.min_x) < narrowest_shaded_width

## The span of x over a region's corners. It has at least one corner.
x_span : List(Point.Point) -> Brush.XSpan
x_span = |corners|
	match corners.map(|corner| corner.x) {
		[first, .. as rest] => {
			min_x: rest.fold(
				first,
				|least, x|
					if x < least {
						x
					} else {
						least
					},
			),
			max_x: rest.fold(
				first,
				|most, x|
					if x > most {
						x
					} else {
						most
					},
			),
		}
		[] => crash "Brush.x_span: a region has a corner"
	}

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
sample_inverse : { top_row : Brush.MatrixRow, bottom_row : Brush.MatrixRow }
sample_inverse = Brush.ellipse_inverse({ axis_u: Point.at(3.0, 4.0), axis_v: Point.at(5.0, 6.0) })

expect ellipse_determinant({ axis_u: Point.at(3.0, 4.0), axis_v: Point.at(5.0, 6.0) }) == -2.0
expect sample_inverse == { top_row: { x: -3.0, y: 2.5 }, bottom_row: { x: 2.0, y: -1.5 } }

# An ellipse whose axes span the least area is a gradient, one just under it
# is too thin, either way round, and parallel axes are too thin.
expect {
	stops = { start_color: Brush.opaque_rgba(RgbColor.of(0x000000)), end_color: Brush.opaque_rgba(RgbColor.of(0xFFFFFF)), start_offset: 0.0, end_offset: 1.0 }
	at_least = { stops, center: Point.at(0.0, 0.0), axis_u: Point.at(0.0001, 0.0), axis_v: Point.at(0.0, 1.0) }
	under = { ..at_least, axis_u: Point.at(0.00009, 0.0) }
	under_flipped = { ..under, axis_v: Point.at(0.0, -1.0) }
	parallel = { ..at_least, axis_u: Point.at(2.0, 4.0), axis_v: Point.at(1.0, 2.0) }
	Brush.elliptical_gradient(at_least) == Ok(Ellipse(at_least))
		and Brush.elliptical_gradient(under) == Err(TooThin)
		and Brush.elliptical_gradient(under_flipped) == Err(TooThin)
		and Brush.elliptical_gradient(parallel) == Err(TooThin)
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
	met = Span({ edge_color: edge, middle_color: middle, left_x: Pixels.of(5.0), right_x: Pixels.of(5.0) })
	wide = Span({ edge_color: edge, middle_color: middle, left_x: Pixels.of(4.0), right_x: Pixels.of(6.0) })
	Brush.shade(met, Point.at(5.0, 0.0)) == edge and Brush.shade(wide, Point.at(5.0, 0.0)) == middle
}

# A line from a point to itself gives its end colour everywhere, and a line
# with any length gives its start colour at its start.
expect {
	stops = { start_color: Brush.opaque_rgba(RgbColor.of(0x000000)), end_color: Brush.opaque_rgba(RgbColor.of(0xFFFFFF)), start_offset: 0.0, end_offset: 1.0 }
	point = Linear({ stops, start_point: Point.at(1.0, 1.0), end_point: Point.at(1.0, 1.0) })
	line = Linear({ stops, start_point: Point.at(1.0, 1.0), end_point: Point.at(1.0, 3.0) })
	Brush.shade(point, Point.at(1.0, 1.0)) == stops.end_color and Brush.shade(line, Point.at(1.0, 1.0)) == stops.start_color
}

sample_color : RgbColor
sample_color = RgbColor.of(0x804020)

expect width_shade_edge(sample_color, Fraction.whole) == RgbColor.of(0x4D2613)
expect width_shade_middle(sample_color, Fraction.whole) == RgbColor.of(0xA05028)
expect width_shade_edge(sample_color, Fraction.of(0.5)) == RgbColor.of(0x66331A)
expect width_shade_middle(sample_color, Fraction.of(0.5)) == RgbColor.of(0x904824)
expect width_shade_edge(sample_color, Fraction.zero) == sample_color
expect width_shade_middle(sample_color, Fraction.zero) == sample_color

# A lift past 255 holds at white.
expect width_shade_middle(RgbColor.of(0xFAFAFA), Fraction.whole) == RgbColor.of(0xFFFFFF)

expect is_too_narrow_to_shade({ min_x: Pixels.of(10.0), max_x: Pixels.of(10.5) })
expect !is_too_narrow_to_shade({ min_x: Pixels.of(10.0), max_x: Pixels.of(11.0) })
expect !is_too_narrow_to_shade({ min_x: Pixels.of(10.0), max_x: Pixels.of(30.0) })

expect x_span(wide_corners) == { min_x: Pixels.of(10.0), max_x: Pixels.of(30.0) }
expect x_span([Point.at(5.0, 99.0)]) == { min_x: Pixels.of(5.0), max_x: Pixels.of(5.0) }

wide_corners : List(Point.Point)
wide_corners = [
	Point.at(10.0, 1.0),
	Point.at(30.0, 2.0),
	Point.at(20.0, 3.0),
]

narrow_corners : List(Point.Point)
narrow_corners = [
	Point.at(10.0, 1.0),
	Point.at(10.5, 2.0),
	Point.at(10.2, 3.0),
]

expect
	Brush.corners_shade(wide_corners, { color: sample_color, strength: Fraction.whole })
		== Span({
			edge_color: Brush.opaque_rgba(RgbColor.of(0x4D2613)),
			middle_color: Brush.opaque_rgba(RgbColor.of(0xA05028)),
			left_x: Pixels.of(10.0),
			right_x: Pixels.of(30.0),
		})

# No strength, or too narrow a region, is a flat fill.
expect Brush.corners_shade(wide_corners, { color: sample_color, strength: Fraction.zero }) == Brush.flat(sample_color)
expect Brush.corners_shade(narrow_corners, { color: sample_color, strength: Fraction.whole }) == Brush.flat(sample_color)

## A circular gradient about the origin, of radius `radius`.
circle_of : Pixels -> Try(Brush.Fill, [TooSmall])
circle_of = |radius|
	Brush.circular_gradient({
		center_color: ArgbColor.of(7),
		edge_color: ArgbColor.of(8),
		center: Point.at(0.0, 0.0),
		radius,
	})

# A gradient is too small just under the limit, and not at it.
expect circle_of(Pixels.of(0.49)) == Err(TooSmall)
expect
	circle_of(Pixels.of(0.5))
		== Ok(
			Radial({
				inner_color: Brush.translucent(ArgbColor.of(7)),
				outer_color: Brush.translucent(ArgbColor.of(8)),
				center: Point.at(0.0, 0.0),
				inner_radius: Pixels.zero,
				outer_radius: Pixels.of(0.5),
			}),
		)

# A line with a length is a linear gradient between its two points.
expect {
	stops = {
		start_color: Brush.translucent(ArgbColor.of(555)),
		end_color: Brush.translucent(ArgbColor.of(556)),
		start_offset: 0.25,
		end_offset: 0.75,
	}
	line = { stops, start_point: Point.at(1.0, 2.0), end_point: Point.at(3.0, 4.0) }
	Brush.linear_gradient(line) == Linear(line)
}
