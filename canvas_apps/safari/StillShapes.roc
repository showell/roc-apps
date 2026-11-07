## StillShapes draws a still, a picture made of polygons, standing on screen.
## A still is drawn in units of its height: its feet at the origin, y up, and
## its height 1. StillShapes scales it to its height in pixels, stands it on its feet,
## and mirrors it when asked.
import Pixels
import Polygon
import lib.Brush
import lib.RgbColor
import Stills
import Screen
import lib.Shapes

StillShapes :: [].{

	## Which way a still is drawn: as its polygons are, or mirrored left to
	## right.
	Flip : [AsDrawn, Mirrored]

	## Where a still stands on screen: its feet, which way it is drawn, and
	## its height in pixels.
	Anchor : {
		feet : Screen.Point,
		flip : StillShapes.Flip,
		height_px : Pixels,
	}

	## The sign that a still's x is multiplied by.
	x_sign : StillShapes.Flip -> F64
	x_sign = |flip|
		match flip {
			AsDrawn => 1.0
			Mirrored => -1.0
		}

	## Where a point of the still lands on screen.
	screen_point : StillShapes.Anchor, Stills.StillPt -> Screen.Point
	screen_point = |anchor, point| {
		x: anchor.feet.x.plus(anchor.height_px.times(x_sign(anchor.flip) * point.x)),
		y: anchor.feet.y.minus(anchor.height_px.times(point.y)),
	}

	## How far, and which way, a step in the still goes on screen.
	screen_vector : StillShapes.Anchor, Stills.StillPt -> Screen.Point
	screen_vector = |anchor, step| {
		x: anchor.height_px.times(x_sign(anchor.flip) * step.x),
		y: anchor.height_px.times(step.y).opposite(),
	}

	screen_points : StillShapes.Anchor, List(Stills.StillPt) -> List(Screen.Point)
	screen_points = |anchor, points| points.map(|point| StillShapes.screen_point(anchor, point))

	## One polygon of a still, filled with its colour or its gradient.
	still_polygon : StillShapes.Anchor, Stills.StillPolygon -> Shapes.Shape
	still_polygon = |anchor, poly| {
		points = StillShapes.screen_points(anchor, poly.points)
		match poly.gradients.first() {
			Ok(gradient) => still_gradient_polygon(anchor, { gradient, points })
			Err(ListWasEmpty) => Polygon.flat_polygon(poly.color, points)
		}
	}

	## A whole still, its polygons in order.
	still_shapes : StillShapes.Anchor, List(Stills.StillPolygon) -> List(Shapes.Shape)
	still_shapes = |anchor, polys| polys.map(|poly| StillShapes.still_polygon(anchor, poly))
}

## A still's gradient is linear when its kind is 1, and radial otherwise.
gradient_shape : Stills.StillGradient -> [Linear, Radial]
gradient_shape = |gradient|
	if gradient.kind == 1 {
		Linear
	} else {
		Radial
	}

## A still's gradient colours and their offsets, as Polygon takes them.
stops_of : Stills.StillGradient -> Polygon.ColorStops
stops_of = |gradient| {
	start_color: gradient.color0,
	end_color: gradient.color1,
	start_offset: gradient.off0,
	end_offset: gradient.off1,
}

still_gradient_polygon : StillShapes.Anchor,
{
	gradient : Stills.StillGradient,
	points : List(Screen.Point),
} -> Shapes.Shape
still_gradient_polygon = |anchor, { gradient, points }|
	match gradient_shape(gradient) {
		Linear => {
			start = StillShapes.screen_point(anchor, { x: gradient.ax, y: gradient.ay })
			stop = StillShapes.screen_point(anchor, { x: gradient.bx, y: gradient.by })
			Polygon.linear_gradient_polygon(
				points,
				{
					color_stops: stops_of(gradient),
					start_point: start,
					end_point: stop,
				},
			)
		}
		Radial => {
			center = StillShapes.screen_point(anchor, { x: gradient.cx, y: gradient.cy })
			u = StillShapes.screen_vector(anchor, { x: gradient.ux, y: gradient.uy })
			v = StillShapes.screen_vector(anchor, { x: gradient.vx, y: gradient.vy })
			Polygon.radial_gradient_polygon(
				points,
				{
					color_stops: stops_of(gradient),
					center_point: center,
					axis_u: u,
					axis_v: v,
				},
			)
		}
	}

sample_feet : Screen.Point
sample_feet = Screen.point(100.0, 200.0)

# A still 50 pixels tall, standing on the feet, as drawn.
upright : StillShapes.Anchor
upright = {
	feet: sample_feet,
	flip: AsDrawn,
	height_px: Pixels.of(50.0),
}

# The same still, mirrored.
mirrored : StillShapes.Anchor
mirrored = {
	feet: sample_feet,
	flip: Mirrored,
	height_px: Pixels.of(50.0),
}

expect StillShapes.x_sign(Mirrored) == -1.0
expect StillShapes.x_sign(AsDrawn) == 1.0

expect StillShapes.screen_point(upright, { x: 0.5, y: 0.4 }) == Screen.point(125.0, 180.0)
expect StillShapes.screen_point(mirrored, { x: 0.5, y: 0.4 }) == Screen.point(75.0, 180.0)
expect StillShapes.screen_point(upright, { x: 0.0, y: 0.0 }) == Screen.point(100.0, 200.0)

expect StillShapes.screen_vector(upright, { x: 0.5, y: 0.4 }) == Screen.point(25.0, -20.0)
expect StillShapes.screen_vector(mirrored, { x: 0.5, y: 0.4 }) == Screen.point(-25.0, -20.0)
expect StillShapes.screen_vector(upright, { x: 0.0, y: 0.0 }) == Screen.point(0.0, 0.0)

# A point is the feet plus its vector.
expect {
	point = StillShapes.screen_point(upright, { x: 0.5, y: 0.4 })
	vector = StillShapes.screen_vector(upright, { x: 0.5, y: 0.4 })
	point.x.minus(vector.x).to_f64() == 100.0 and point.y.minus(vector.y).to_f64() == 200.0
}

expect
	StillShapes.screen_points(
		upright,
		[
			{ x: 0.0, y: 0.0 },
			{ x: 0.5, y: 0.4 },
			{ x: 1.0, y: 1.0 },
		],
	)
		== [
			Screen.point(100.0, 200.0),
			Screen.point(125.0, 180.0),
			Screen.point(150.0, 150.0),
		]

# A solid polygon of colour 7 with `count` points, all at the feet.
flat_polygon : U64 -> Stills.StillPolygon
flat_polygon = |count| {
	color: RgbColor.of(7),
	gradients: [],
	points: List.repeat({ x: 0.0, y: 0.0 }, count),
}

expect
	StillShapes.still_polygon(upright, flat_polygon(3))
		== Poly({
			coordinates: [100.0, 200.0, 100.0, 200.0, 100.0, 200.0],
			fill: Flat(Brush.opaque(RgbColor.of(7))),
		})
