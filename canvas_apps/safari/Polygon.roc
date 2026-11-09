## Polygon makes Safari's polygons as values, from screen points and colors,
## each a region with one of Brush's fills. A polygon of fewer than three
## corners is a bug in the code that asked for it, so a maker crashes on one.
## A circular gradient can shrink out of sight as it goes away, so that maker
## answers a `Try`. It also cuts a polygon in the rider's view at the near plane
## and puts it on the screen.
import Camera
import RiderView
import lib.Pixels
import lib.ArgbColor
import lib.Brush
import lib.Fraction
import lib.Point
import lib.RgbColor
import lib.Shapes

Polygon :: [].{

	## Makes a polygon of one flat color.
	flat_polygon : List(Point.Point), RgbColor -> Shapes.Shape
	flat_polygon = |corners, color|
		Polygon({ corners: polygon_corners(corners), fill: Brush.flat(color) })

	## Makes a triangle of one flat color.
	triangle : {
		first_corner : Point.Point,
		second_corner : Point.Point,
		third_corner : Point.Point,
	},
	RgbColor -> Shapes.Shape
	triangle = |{ first_corner, second_corner, third_corner }, color|
		Triangle({
			first: first_corner,
			second: second_corner,
			third: third_corner,
			fill: Brush.flat(color),
		})

	## Makes a polygon shaded across its width, as `Brush.corners_shade` shades it.
	shaded_polygon : List(Point.Point), { color : RgbColor, strength : Fraction } -> Shapes.Shape
	shaded_polygon = |corners, shade|
		Polygon({ corners: polygon_corners(corners), fill: Brush.corners_shade(corners, shade) })

	## Makes a polygon filled by a gradient that spreads in a circle, or
	## `TooSmall` when the radius is too small to see.
	circular_gradient_polygon : List(Point.Point),
	Brush.CircularGradient -> Try(
		Shapes.Shape,
		[TooSmall],
	)
	circular_gradient_polygon = |corners, gradient| {
		fill = Brush.circular_gradient(gradient)?
		Ok(Polygon({ corners: polygon_corners(corners), fill }))
	}

	## Makes a polygon filled by a gradient along a line.
	linear_gradient_polygon : List(Point.Point),
	{
		stops : Brush.TwoStops,
		start_point : Point.Point,
		end_point : Point.Point,
	} -> Shapes.Shape
	linear_gradient_polygon = |corners, line|
		Polygon({ corners: polygon_corners(corners), fill: Brush.linear_gradient(line) })

	## Makes a polygon filled by a gradient on an ellipse, which is `axis_u` and
	## `axis_v` about `center_point`. An ellipse too thin for Brush to invert
	## crashes: a still, the only caller, is never drawn small enough to thin
	## its ellipses past Brush's limit, as `Still.of` checks.
	elliptical_gradient_polygon : List(Point.Point),
	{
		stops : Brush.TwoStops,
		center_point : Point.Point,
		axis_u : Point.Point,
		axis_v : Point.Point,
	} -> Shapes.Shape
	elliptical_gradient_polygon = |corners, { stops, center_point, axis_u, axis_v }| {
		fill =
			match Brush.elliptical_gradient({ stops, center: center_point, axis_u, axis_v }) {
				Ok(gradient) => gradient
				Err(TooThin) => crash "Polygon.elliptical_gradient_polygon: an ellipse too thin for Brush to invert"
			}
		Polygon({ corners: polygon_corners(corners), fill })
	}

	## A polygon of one color, in the rider's view.
	FlatPolygon : { color : RgbColor, corners : List(RiderView.RaisedPoint) }

	## A polygon on screen, cut at the near plane, unless it's wholly behind the
	## camera.
	clipped_polygon : Polygon.FlatPolygon, Pixels -> Try(Shapes.Shape, [BehindCamera])
	clipped_polygon = |{ color, corners }, focal_length| {
		in_front = RiderView.clipped_points(corners)
		if in_front.is_empty() {
			Err(BehindCamera)
		} else {
			Ok(Polygon.flat_polygon(Camera.projected_points(in_front, focal_length), color))
		}
	}
}

## A polygon's corners as the painter reads them. Fewer than three corners
## enclose nothing, so asking for that is a bug, and it crashes.
polygon_corners : List(Point.Point) -> List(Point.Point)
polygon_corners = |corners|
	if corners.len() < 3 {
		crash "Polygon: a polygon needs at least three corners"
	} else {
		corners
	}

three_corners : List(Point.Point)
three_corners = [
	Point.at(1.0, 2.0),
	Point.at(3.0, 4.0),
	Point.at(5.0, 6.0),
]

expect polygon_corners(three_corners) == three_corners

# A triangle keeps its corners in the order given.
expect
	Polygon.triangle(
		{
			first_corner: Point.at(1.0, 2.0),
			second_corner: Point.at(3.0, 4.0),
			third_corner: Point.at(5.0, 6.0),
		},
		RgbColor.of(111),
	)
		== Triangle({
			first: Point.at(1.0, 2.0),
			second: Point.at(3.0, 4.0),
			third: Point.at(5.0, 6.0),
			fill: Flat(Brush.opaque_rgba(RgbColor.of(111))),
		})

expect
	Polygon.flat_polygon(three_corners, RgbColor.of(111))
		== Polygon({ corners: three_corners, fill: Brush.flat(RgbColor.of(111)) })

# A polygon too small to see is none, and one big enough is a polygon in
# Brush's gradient.
expect {
	gradient = {
		center_color: ArgbColor.of(444),
		edge_color: ArgbColor.of(445),
		center: Point.at(10.0, 20.0),
		radius: Pixels.of(30.0),
	}
	fill = Brush.circular_gradient(gradient) ?? crash "Polygon: a radius of 30 px is big enough to see"
	tiny = { ..gradient, radius: Pixels.of(0.1) }
	in_sight = Polygon.circular_gradient_polygon(three_corners, gradient)
	out_of_sight = Polygon.circular_gradient_polygon(three_corners, tiny)
	in_sight == Ok(Polygon({ corners: three_corners, fill })) and out_of_sight == Err(TooSmall)
}
