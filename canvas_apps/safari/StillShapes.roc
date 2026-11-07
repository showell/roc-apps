## StillShapes draws a still, a picture made of polygons, standing on screen.
## A still is drawn in its own frame, which Still.roc describes. StillShapes
## scales it to its height on screen, stands it on its feet, and mirrors it when
## asked.
import Camera
import Distance
import Picture
import Pixels
import Polygon
import lib.Brush
import lib.RgbColor
import Still
import Screen
import lib.Shapes

StillShapes :: [].{

	## Which way a still is drawn: as its polygons are, or mirrored left to
	## right.
	Flip : [AsDrawn, Mirrored]

	## Where a still stands on screen: its feet, which way it is drawn, and
	## its height on screen.
	Anchor : {
		feet : Screen.Point,
		flip : StillShapes.Flip,
		height_on_screen : Pixels,
	}

	## Where a point of the still lands on screen.
	screen_point : StillShapes.Anchor, Still.Vertex -> Screen.Point
	screen_point = |anchor, point| {
		x: anchor.feet.x.plus(anchor.height_on_screen.times(x_sign(anchor.flip) * point.x)),
		y: anchor.feet.y.minus(anchor.height_on_screen.times(point.y)),
	}

	screen_points : StillShapes.Anchor, List(Still.Vertex) -> List(Screen.Point)
	screen_points = |anchor, points| points.map(|point| StillShapes.screen_point(anchor, point))

	## A whole still, its polygons in order.
	still_shapes : StillShapes.Anchor, Still -> List(Shapes.Shape)
	still_shapes = |anchor, still|
		still.polygons().map(|poly| still_polygon(anchor, poly))

	## Where a still `height` tall stands on screen at the setting's spot: its
	## feet raised as high as the spot says, and its height on screen from
	## there to its top.
	standing_anchor : Picture.Setting({}),
	{
		height : Distance,
		flip : StillShapes.Flip,
	} -> StillShapes.Anchor
	standing_anchor = |{ spot, cam_focal, .. }, { height, flip }| {
		projected = |above_ground| Camera.project(spot.foot().at_height(above_ground), cam_focal)
		feet = projected(spot.lift())
		{
			feet,
			flip,
			height_on_screen: feet.y.minus(projected(spot.lift().plus(height)).y),
		}
	}

	## A still `height` tall, as drawn, standing on its feet at the setting's
	## spot.
	standing_still_shapes : Picture.Setting({}),
	{
		height : Distance,
		still : Still,
	} -> List(Shapes.Shape)
	standing_still_shapes = |setting, { height, still }| {
		anchor = StillShapes.standing_anchor(setting, { height, flip: AsDrawn })
		StillShapes.still_shapes(anchor, still)
	}
}

## The sign that a still's x is multiplied by.
x_sign : StillShapes.Flip -> F64
x_sign = |flip|
	match flip {
		AsDrawn => 1.0
		Mirrored => -1.0
	}

## How far, and which way, a step in the still goes on screen.
screen_vector : StillShapes.Anchor, Still.Vertex -> Screen.Point
screen_vector = |anchor, step| {
	x: anchor.height_on_screen.times(x_sign(anchor.flip) * step.x),
	y: anchor.height_on_screen.times(step.y).opposite(),
}

## One polygon of a still, filled with its colour or its gradient.
still_polygon : StillShapes.Anchor, Still.Polygon -> Shapes.Shape
still_polygon = |anchor, poly| {
	points = StillShapes.screen_points(anchor, poly.points)
	match poly.fill {
		Flat(color) => Polygon.flat_polygon(points, color)
		Shaded(gradient) => still_gradient_polygon(anchor, { gradient, points })
	}
}

still_gradient_polygon : StillShapes.Anchor,
{
	gradient : Still.Gradient,
	points : List(Screen.Point),
} -> Shapes.Shape
still_gradient_polygon = |anchor, { gradient, points }|
	match gradient {
		Linear({ stops, start, end }) =>
			Polygon.linear_gradient_polygon(
				points,
				{
					color_stops: stops,
					start_point: StillShapes.screen_point(anchor, start),
					end_point: StillShapes.screen_point(anchor, end),
				},
			)
		Radial({ stops, center, axis_u, axis_v }) =>
			Polygon.elliptical_gradient_polygon(
				points,
				{
					color_stops: stops,
					center_point: StillShapes.screen_point(anchor, center),
					axis_u: screen_vector(anchor, axis_u),
					axis_v: screen_vector(anchor, axis_v),
				},
			)
	}

sample_feet : Screen.Point
sample_feet = Screen.point(100.0, 200.0)

# A still 50 pixels tall, standing on the feet, as drawn.
upright : StillShapes.Anchor
upright = {
	feet: sample_feet,
	flip: AsDrawn,
	height_on_screen: Pixels.of(50.0),
}

# The same still, mirrored.
mirrored : StillShapes.Anchor
mirrored = {
	feet: sample_feet,
	flip: Mirrored,
	height_on_screen: Pixels.of(50.0),
}

expect x_sign(Mirrored) == -1.0
expect x_sign(AsDrawn) == 1.0

expect StillShapes.screen_point(upright, { x: 0.5, y: 0.4 }) == Screen.point(125.0, 180.0)
expect StillShapes.screen_point(mirrored, { x: 0.5, y: 0.4 }) == Screen.point(75.0, 180.0)
expect StillShapes.screen_point(upright, { x: 0.0, y: 0.0 }) == Screen.point(100.0, 200.0)

expect screen_vector(upright, { x: 0.5, y: 0.4 }) == Screen.point(25.0, -20.0)
expect screen_vector(mirrored, { x: 0.5, y: 0.4 }) == Screen.point(-25.0, -20.0)
expect screen_vector(upright, { x: 0.0, y: 0.0 }) == Screen.point(0.0, 0.0)

# A point is the feet plus its vector.
expect {
	point = StillShapes.screen_point(upright, { x: 0.5, y: 0.4 })
	vector = screen_vector(upright, { x: 0.5, y: 0.4 })
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
flat_polygon : U64 -> Still.Polygon
flat_polygon = |count| {
	fill: Flat(RgbColor.of(7)),
	points: List.repeat({ x: 0.0, y: 0.0 }, count),
}

expect
	still_polygon(upright, flat_polygon(3))
		== Poly({
			coordinates: [100.0, 200.0, 100.0, 200.0, 100.0, 200.0],
			fill: Flat(Brush.opaque(RgbColor.of(7))),
		})
