## StillShapes draws a still, a picture made of polygons, standing on screen.
## A still is drawn in its own frame, which Still.roc describes. StillShapes
## scales it to its height on screen, stands it on its feet, and mirrors it when
## asked.
import Camera
import Distance
import Picture
import Pixels
import Polygon
import Still
import Screen
import lib.Brush
import lib.Shapes

StillShapes :: [].{

	## Which way a still is drawn: as its polygons are, or mirrored left to
	## right.
	Flip : [AsDrawn, Mirrored]

	## Where a still stands on screen: its foot, which way it is drawn, and
	## its height on screen.
	Anchor : {
		foot : Screen.Point,
		flip : StillShapes.Flip,
		height_on_screen : Pixels,
	}

	## Where a point of the still lands on screen: the foot, and the point's
	## step from it.
	screen_point : StillShapes.Anchor, Still.FramePoint -> Screen.Point
	screen_point = |anchor, point| {
		step = screen_vector(anchor, point)
		{ x: anchor.foot.x.plus(step.x), y: anchor.foot.y.plus(step.y) }
	}

	## Where each of a still's `points` lands on screen, in order.
	screen_points : StillShapes.Anchor, List(Still.FramePoint) -> List(Screen.Point)
	screen_points = |anchor, points| points.map(|point| StillShapes.screen_point(anchor, point))

	## A whole still, its polygons in order.
	still_shapes : StillShapes.Anchor, Still -> List(Shapes.Shape)
	still_shapes = |anchor, still|
		still.polygons().map(|polygon| still_polygon(anchor, polygon))

	## Where a still `height` tall stands on screen at the setting's spot: its
	## foot raised as high as the spot says, and its height on screen from
	## there to its top.
	standing_anchor : Picture.Setting({}),
	{
		height : Distance,
		flip : StillShapes.Flip,
	} -> StillShapes.Anchor
	standing_anchor = |{ spot, focal_length, .. }, { height, flip }| {
		upright = Camera.upright_on_screen(spot.base(), { height, focal_length })
		{ foot: upright.foot, flip, height_on_screen: upright.height_on_screen }
	}

	## A still `height` tall, drawn as `flip` says, standing on its foot at the
	## setting's spot.
	standing_still_shapes : Picture.Setting({}),
	{
		height : Distance,
		still : Still,
		flip : StillShapes.Flip,
	} -> List(Shapes.Shape)
	standing_still_shapes = |setting, { height, still, flip }| {
		anchor = StillShapes.standing_anchor(setting, { height, flip })
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
screen_vector : StillShapes.Anchor, Still.FrameVector -> Screen.Point
screen_vector = |anchor, step| {
	x: anchor.height_on_screen.times(x_sign(anchor.flip) * step.x),
	y: anchor.height_on_screen.times(step.y).opposite(),
}

## One polygon of a still, filled with its colour or its gradient.
still_polygon : StillShapes.Anchor, Still.Polygon -> Shapes.Shape
still_polygon = |anchor, polygon| {
	points = StillShapes.screen_points(anchor, polygon.points)
	match polygon.fill {
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
					stops: brush_stops(stops),
					start_point: StillShapes.screen_point(anchor, start),
					end_point: StillShapes.screen_point(anchor, end),
				},
			)
		Radial({ stops, center, axis_u, axis_v }) =>
			Polygon.elliptical_gradient_polygon(
				points,
				{
					stops: brush_stops(stops),
					center_point: StillShapes.screen_point(anchor, center),
					axis_u: screen_vector(anchor, axis_u),
					axis_v: screen_vector(anchor, axis_v),
				},
			)
	}

## A still's colour stops as a brush takes them.
brush_stops : Still.ColorStops -> Brush.TwoStops
brush_stops = |stops| {
	start_color: Brush.translucent(stops.start_color),
	end_color: Brush.translucent(stops.end_color),
	start_offset: stops.start_offset.to_f64(),
	end_offset: stops.end_offset.to_f64(),
}

sample_foot : Screen.Point
sample_foot = Screen.point(100.0, 200.0)

# A still 50 pixels tall, standing on the foot, as drawn.
upright : StillShapes.Anchor
upright = {
	foot: sample_foot,
	flip: AsDrawn,
	height_on_screen: Pixels.of(50.0),
}

# The same still, mirrored.
mirrored : StillShapes.Anchor
mirrored = {
	foot: sample_foot,
	flip: Mirrored,
	height_on_screen: Pixels.of(50.0),
}

expect StillShapes.screen_point(upright, { x: 0.5, y: 0.4 }) == Screen.point(125.0, 180.0)
expect StillShapes.screen_point(mirrored, { x: 0.5, y: 0.4 }) == Screen.point(75.0, 180.0)
expect StillShapes.screen_point(upright, { x: 0.0, y: 0.0 }) == Screen.point(100.0, 200.0)

expect screen_vector(upright, { x: 0.5, y: 0.4 }) == Screen.point(25.0, -20.0)
expect screen_vector(mirrored, { x: 0.5, y: 0.4 }) == Screen.point(-25.0, -20.0)
expect screen_vector(upright, { x: 0.0, y: 0.0 }) == Screen.point(0.0, 0.0)

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
