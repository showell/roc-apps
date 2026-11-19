## A brush is the paint a shape is filled with. It answers one question: what
## colour does this point of the shape get? A `Fill` is a flat colour or one of
## five gradients, and a gradient's geometry is in the same coordinates as the
## shape it fills. `BrushShade.shade` is the answer, point by point.
##
## A polygon, disc or rectangle has exactly one fill and nothing else. There is
## no stroke: an outline is built from filled shapes, as `Shapes.line` and
## `CurvedShapes.ring_shapes` build it. There is no alpha on the shape either. Each
## colour carries its own alpha, from 0 for invisible to 1 for opaque, and a
## gradient mixes the alpha along with red, green and blue. The colour a point
## gets is then laid over what is already there by the frame's mode
## (`Shapes.Mode`), which paints over it or adds light to it, in proportion to
## that alpha either way.
##
## A CPU painter shades a brush with `BrushShade.shade`, BrushGlsl does it on
## the GPU and shapes_canvas.js on a canvas, all from what is here. The tags are the ones
## shapes_canvas.js reads, and so is what they mean: gradients mix
## unpremultiplied, as the canvas specification says, and an offset outside
## [0, 1] is clamped as shapes_canvas.js clamps it.
##
## Every kind of fill has a maker here, but for the shading across a region's
## width, which `WidthShading` makes, and any region takes any of them.
import ArgbColor
import Pixels
import Point
import RgbColor

Brush :: [].{

	## Red, green and blue in 0..255, alpha in 0..1.
	Rgba : {
		r : F64,
		g : F64,
		b : F64,
		a : F64,
	}

	## The start colour up to `start_offset`, the end colour from `end_offset`,
	## and a mix of the two between.
	TwoStops : {
		start_color : Brush.Rgba,
		end_color : Brush.Rgba,
		start_offset : F64,
		end_offset : F64,
	}

	Fill : [
		Flat(Brush.Rgba),

		## The edge colour at `left_x` and `right_x`, and the middle colour halfway.
		Span(
			{
				edge_color : Brush.Rgba,
				middle_color : Brush.Rgba,
				left_x : Pixels,
				right_x : Pixels,
			},
		),
		Radial(
			{
				inner_color : Brush.Rgba,
				outer_color : Brush.Rgba,
				center : Point,
				inner_radius : Pixels,
				outer_radius : Pixels,
			},
		),
		Linear(
			{
				stops : Brush.TwoStops,
				start_point : Point,
				end_point : Point,
			},
		),

		## Out from `center` to the ellipse whose half-axes are `axis_u` and `axis_v`.
		Ellipse(
			{
				stops : Brush.TwoStops,
				center : Point,
				axis_u : Point,
				axis_v : Point,
			},
		),

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
		center : Point,
		inner_radius : Pixels,
		outer_radius : Pixels,
	}

	## A row of a 2 by 2 matrix, as `ellipse_inverse` gives it.
	MatrixRow : { x : F64, y : F64 }

	## The gradient out from `center` to the ellipse whose half-axes are `axis_u`
	## and `axis_v`, or `TooThin` when the axes are so nearly parallel that the
	## ellipse has no sound inverse to shade with.
	elliptical_gradient : {
		stops : Brush.TwoStops,
		center : Point,
		axis_u : Point,
		axis_v : Point,
	} -> Try(Brush.Fill, [TooThin])
	elliptical_gradient = |look|
		if ellipse_determinant({
			axis_u: look.axis_u,
			axis_v: look.axis_v,
		}).abs() < min_ellipse_determinant {
			Err(TooThin)
		} else {
			Ok(Ellipse(look))
		}

	## The matrix that takes an offset from an ellipse's center to the unit
	## circle, the inverse of the one whose columns are its axes. An offset
	## (dx, dy) goes to (top_row.x * dx + top_row.y * dy, bottom_row.x * dx +
	## bottom_row.y * dy). BrushShade.shade and BrushGlsl's uniforms both use it.
	ellipse_inverse : { axis_u : Point, axis_v : Point } -> {
		top_row : Brush.MatrixRow,
		bottom_row : Brush.MatrixRow,
	}
	ellipse_inverse = |{ axis_u, axis_v }| {
		determinant = ellipse_determinant({ axis_u, axis_v })
		{
			top_row: {
				x: axis_v.y.to_f64() / determinant,
				y: (0.0 - axis_v.x.to_f64()) / determinant,
			},
			bottom_row: {
				x: (0.0 - axis_u.y.to_f64()) / determinant,
				y: axis_u.x.to_f64() / determinant,
			},
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

	## A gradient that spreads in a circle from `center`, from `center_color`
	## there to `edge_color` at `radius`.
	CircularGradient : {
		center_color : ArgbColor,
		edge_color : ArgbColor,
		center : Point,
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
	linear_gradient : {
		stops : Brush.TwoStops,
		start_point : Point,
		end_point : Point,
	} -> Brush.Fill
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
	mix : {
		from : Brush.Rgba,
		to : Brush.Rgba,
		fraction : F64,
	} -> Brush.Rgba
	mix = |{ from, to, fraction }| {
		r: from.r + (to.r - from.r) * fraction,
		g: from.g + (to.g - from.g) * fraction,
		b: from.b + (to.b - from.b) * fraction,
		a: from.a + (to.a - from.a) * fraction,
	}
}

## The determinant of the matrix whose columns are an ellipse's axes. Near
## zero, the axes are nearly parallel and the ellipse has no inverse.
ellipse_determinant : { axis_u : Point, axis_v : Point } -> F64
ellipse_determinant = |
	{ axis_u, axis_v },
| axis_u.x.to_f64() * axis_v.y.to_f64() - axis_u.y.to_f64() * axis_v.x.to_f64()

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

## The ellipse with axes (3, 4) and (5, 6) has determinant -2, and its inverse
## takes each axis back to a unit vector.
sample_inverse : { top_row : Brush.MatrixRow, bottom_row : Brush.MatrixRow }
sample_inverse = Brush.ellipse_inverse({ axis_u: Point.at(3.0, 4.0), axis_v: Point.at(5.0, 6.0) })

expect ellipse_determinant({ axis_u: Point.at(3.0, 4.0), axis_v: Point.at(5.0, 6.0) }) == -2.0
expect sample_inverse == { top_row: { x: -3.0, y: 2.5 }, bottom_row: { x: 2.0, y: -1.5 } }

# An ellipse whose axes span the least area is a gradient, one just under it
# is too thin, either way round, and parallel axes are too thin.
expect {
	stops = {
		start_color: Brush.opaque_rgba(RgbColor.of(0x000000)),
		end_color: Brush.opaque_rgba(RgbColor.of(0xFFFFFF)),
		start_offset: 0.0,
		end_offset: 1.0,
	}
	at_least = {
		stops,
		center: Point.at(0.0, 0.0),
		axis_u: Point.at(0.0001, 0.0),
		axis_v: Point.at(0.0, 1.0),
	}
	under = { ..at_least, axis_u: Point.at(0.00009, 0.0) }
	under_flipped = { ..under, axis_v: Point.at(0.0, -1.0) }
	parallel = {
		..at_least,
		axis_u: Point.at(2.0, 4.0),
		axis_v: Point.at(1.0, 2.0),
	}
	Brush.elliptical_gradient(at_least) == Ok(Ellipse(at_least))
		and Brush.elliptical_gradient(under) == Err(TooThin)
		and Brush.elliptical_gradient(under_flipped) == Err(TooThin)
		and Brush.elliptical_gradient(parallel) == Err(TooThin)
}

expect Brush.translucent(ArgbColor.of(0x80FFE9A8)) == {
	r: 255.0,
	g: 233.0,
	b: 168.0,
	a: 128.0 / 255.0,
}
expect Brush.translucent(ArgbColor.of(0xFF000000)) == {
	r: 0.0,
	g: 0.0,
	b: 0.0,
	a: 1.0,
}

# A colour with no alpha byte is invisible.
expect Brush.translucent(ArgbColor.of(0x00FFE9A8)).a == 0.0

expect Brush.opaque_rgba(RgbColor.of(0xFFE9A8)) == {
	r: 255.0,
	g: 233.0,
	b: 168.0,
	a: 1.0,
}

expect Brush.flat(RgbColor.of(0xFFE9A8)) == Flat({
	r: 255.0,
	g: 233.0,
	b: 168.0,
	a: 1.0,
})

# An alpha share is kept as it is, at either end and between.
expect Brush.with_alpha(RgbColor.of(0xFFC980), 0.85) == {
	r: 255.0,
	g: 201.0,
	b: 128.0,
	a: 0.85,
}
expect Brush.with_alpha(RgbColor.of(0xFFC980), 0.0).a == 0.0
expect Brush.with_alpha(RgbColor.of(0xFFC980), 1.0) == Brush.opaque_rgba(RgbColor.of(0xFFC980))

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
	line = {
		stops,
		start_point: Point.at(1.0, 2.0),
		end_point: Point.at(3.0, 4.0),
	}
	Brush.linear_gradient(line) == Linear(line)
}
