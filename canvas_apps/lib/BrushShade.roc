## BrushShade gives the colour a `Brush.Fill` paints at one point of its shape,
## for a painter that fills pixel by pixel on the CPU. BrushGlsl is the same
## arithmetic on a GPU and shapes_canvas.js on a canvas, case for case, so all
## three paint a fill alike: gradients mix unpremultiplied, and an offset
## outside [0, 1] is clamped, as the canvas specification says.
import Brush
import Pixels
import Point
import RgbColor

BrushShade :: [].{

	## The colour a brush gives a scene point. A gradient with no length, a
	## span whose two edges meet, a line from a point to itself or a ring whose
	## radii meet, gives its far colour everywhere, since there is no distance
	## along it to share out.
	shade : Brush.Fill, Point -> Brush.Rgba
	shade = |fill, point| {
		x = point.x.to_f64()
		y = point.y.to_f64()
		match fill {
			Flat(color) => color
			Span(span) => {
				left_x = span.left_x.to_f64()
				right_x = span.right_x.to_f64()
				fraction = if right_x != left_x {
					clamp01((x - left_x) / (right_x - left_x))
				} else {
					1.0
				}
				if fraction <= 0.5 {
					Brush.mix({
						from: span.edge_color,
						to: span.middle_color,
						fraction: fraction * 2.0,
					})
				} else {
					Brush.mix({
						from: span.middle_color,
						to: span.edge_color,
						fraction: (fraction - 0.5) * 2.0,
					})
				}
			}
			Radial(radial) =>
				Brush.mix({
					from: radial.inner_color,
					to: radial.outer_color,
					fraction: radial_fraction(
						{ x, y },
						{
							center: radial.center,
							inner_radius: radial.inner_radius,
							outer_radius: radial.outer_radius,
						},
					),
				})
			Linear(linear) => {
				start_x = linear.start_point.x.to_f64()
				start_y = linear.start_point.y.to_f64()
				dx = linear.end_point.x.to_f64() - start_x
				dy = linear.end_point.y.to_f64() - start_y
				length_squared = dx * dx + dy * dy
				two_stop(
					linear.stops,
					if length_squared > 0.0 {
						clamp01(((x - start_x) * dx + (y - start_y) * dy) / length_squared)
					} else {
						1.0
					},
				)
			}
			Ellipse(ellipse) => {
				qx = x - ellipse.center.x.to_f64()
				qy = y - ellipse.center.y.to_f64()
				inverse = Brush.ellipse_inverse({ axis_u: ellipse.axis_u, axis_v: ellipse.axis_v })
				ux = inverse.top_row.x * qx + inverse.top_row.y * qy
				uy = inverse.bottom_row.x * qx + inverse.bottom_row.y * qy
				two_stop(ellipse.stops, clamp01((ux * ux + uy * uy).sqrt()))
			}
			Glow(glow) => {
				fraction = radial_fraction(
					{ x, y },
					{
						center: glow.center,
						inner_radius: glow.inner_radius,
						outer_radius: glow.outer_radius,
					},
				)
				middle = glow.middle_offset
				if fraction <= middle {
					Brush.mix({
						from: glow.inner_color,
						to: glow.middle_color,
						fraction: fraction / middle,
					})
				} else {
					Brush.mix({
						from: glow.middle_color,
						to: glow.outer_color,
						fraction: (fraction - middle) / (1.0 - middle),
					})
				}
			}
		}
	}
}

clamp01 : F64 -> F64
clamp01 = |ratio|
	if ratio < 0.0 {
		0.0
	} else if ratio > 1.0 {
		1.0
	} else {
		ratio
	}

## How far a point lies from the inner radius to the outer one, clamped to 0..1,
## or 1 when the radii meet.
radial_fraction : { x : F64, y : F64 },
{
	center : Point,
	inner_radius : Pixels,
	outer_radius : Pixels,
} -> F64
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

## The colour the stops give at `offset`, for offsets start_offset <= end_offset.
two_stop : Brush.TwoStops, F64 -> Brush.Rgba
two_stop = |stops, offset|
	if offset <= stops.start_offset {
		stops.start_color
	} else if offset >= stops.end_offset {
		stops.end_color
	} else {
		Brush.mix({
			from: stops.start_color,
			to: stops.end_color,
			fraction: (offset - stops.start_offset) / (stops.end_offset - stops.start_offset),
		})
	}

# A span whose edges meet gives its edge colour everywhere, and one with any
# width still gives its middle colour halfway.
expect {
	edge = Brush.opaque_rgba(RgbColor.of(0x000000))
	middle = Brush.opaque_rgba(RgbColor.of(0xFFFFFF))
	met = Span({
		edge_color: edge,
		middle_color: middle,
		left_x: Pixels.of(5.0),
		right_x: Pixels.of(5.0),
	})
	wide = Span({
		edge_color: edge,
		middle_color: middle,
		left_x: Pixels.of(4.0),
		right_x: Pixels.of(6.0),
	})
	at_met = BrushShade.shade(met, Point.at(5.0, 0.0))
	at_wide = BrushShade.shade(wide, Point.at(5.0, 0.0))
	at_met == edge and at_wide == middle
}

# A line from a point to itself gives its end colour everywhere, and a line
# with any length gives its start colour at its start.
expect {
	stops = {
		start_color: Brush.opaque_rgba(RgbColor.of(0x000000)),
		end_color: Brush.opaque_rgba(RgbColor.of(0xFFFFFF)),
		start_offset: 0.0,
		end_offset: 1.0,
	}
	point = Linear({
		stops,
		start_point: Point.at(1.0, 1.0),
		end_point: Point.at(1.0, 1.0),
	})
	line = Linear({
		stops,
		start_point: Point.at(1.0, 1.0),
		end_point: Point.at(1.0, 3.0),
	})
	BrushShade.shade(
		point,
		Point.at(1.0, 1.0),
	) == stops.end_color and BrushShade.shade(line, Point.at(1.0, 1.0)) == stops.start_color
}
