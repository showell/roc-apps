## StillShapes draws a still, a sprite made of polygons, standing on screen.
## A still is drawn in its own frame, which Still.roc describes. StillShapes
## scales it to its height on screen, stands it on its feet, and mirrors it when
## asked.
import Camera
import Distance
import Sky
import Sprite
import lib.ArgbColor
import lib.Fraction
import lib.Point
import lib.Pixels
import lib.RgbColor
import Still
import lib.Brush
import lib.Shapes

StillShapes :: [].{

	## Which way a still is drawn: as its polygons are, or mirrored left to
	## right.
	Flip : [AsDrawn, Mirrored]

	## Where a still stands on screen: its foot, which way it is drawn, and
	## its height on screen.
	Anchor : {
		foot : Point,
		flip : StillShapes.Flip,
		height_on_screen : Pixels,
	}

	## Where a point of the still lands on screen: the foot, and the point's
	## step from it.
	screen_point : StillShapes.Anchor, Still.FramePoint -> Point
	screen_point = |anchor, point| {
		step = screen_vector(anchor, point)
		{ x: anchor.foot.x.plus(step.x), y: anchor.foot.y.plus(step.y) }
	}

	## Where each of a still's `points` lands on screen, in order.
	screen_points : StillShapes.Anchor, List(Still.FramePoint) -> List(Point)
	screen_points = |anchor, points| points.map(|point| StillShapes.screen_point(anchor, point))

	## A whole still, its polygons in order.
	still_shapes : StillShapes.Anchor, Still -> List(Shapes.Shape)
	still_shapes = |anchor, still|
		still.polygons().map(|polygon| still_polygon(anchor, polygon))

	## Where a still `height` tall stands on screen at the setting's spot: its
	## foot raised as high as the spot says, and its height on screen from
	## there to its top.
	standing_anchor : Sprite.Setting,
	{
		height : Distance,
		flip : StillShapes.Flip,
	} -> StillShapes.Anchor
	standing_anchor = |{ spot, focal_length, .. }, { height, flip }| {
		upright = Camera.upright_on_screen(spot.base(), { height, focal_length })
		{ foot: upright.foot, flip, height_on_screen: upright.height_on_screen }
	}

	## A still `height` tall, drawn as `flip` says, standing on its foot at the
	## setting's spot, its colours dimmed as far as the setting's sky is dark.
	standing_still_shapes : Sprite.Setting,
	{
		height : Distance,
		still : Still,
		flip : StillShapes.Flip,
	} -> List(Shapes.Shape)
	standing_still_shapes = |setting, { height, still, flip }| {
		anchor = StillShapes.standing_anchor(setting, { height, flip })
		still.polygons().map(
			|polygon| still_polygon(anchor, polygon_at_darkness(polygon, setting.darkness)),
		)
	}
}

## A still's polygon under a sky `darkness` dark: every colour dimmed, each
## gradient stop keeping its alpha.
polygon_at_darkness : Still.Polygon, Fraction -> Still.Polygon
polygon_at_darkness = |polygon, darkness| {
	dimmed = |color| Sky.color_at_darkness(color, darkness)
	dimmed_stops = |stops| {
		..stops,
		start_color: ArgbColor.from_rgb(
			dimmed(stops.start_color.rgb()),
			{ alpha: stops.start_color.alpha() },
		),
		end_color: ArgbColor.from_rgb(
			dimmed(stops.end_color.rgb()),
			{ alpha: stops.end_color.alpha() },
		),
	}
	fill =
		match polygon.fill {
			Flat(color) => Flat(dimmed(color))
			Shaded(Linear(gradient)) => Shaded(
				Linear({ ..gradient, stops: dimmed_stops(gradient.stops) }),
			)
			Shaded(Radial(gradient)) => Shaded(
				Radial({ ..gradient, stops: dimmed_stops(gradient.stops) }),
			)
		}
	{ ..polygon, fill }
}

## The sign that a still's x is multiplied by.
x_sign : StillShapes.Flip -> F64
x_sign = |flip|
	match flip {
		AsDrawn => 1.0
		Mirrored => -1.0
	}

## How far, and which way, a step in the still goes on screen.
screen_vector : StillShapes.Anchor, Still.FrameVector -> Point
screen_vector = |anchor, step| {
	x: anchor.height_on_screen.times(x_sign(anchor.flip) * step.x),
	y: anchor.height_on_screen.times(step.y).opposite(),
}

## One polygon of a still, filled with its colour or its gradient.
still_polygon : StillShapes.Anchor, Still.Polygon -> Shapes.Shape
still_polygon = |anchor, polygon| {
	points = StillShapes.screen_points(anchor, polygon.points)
	match polygon.fill {
		Flat(color) => Shapes.region_from_corners(points, Brush.flat(color))
		Shaded(gradient) => still_gradient_polygon(anchor, { gradient, points })
	}
}

still_gradient_polygon : StillShapes.Anchor,
{
	gradient : Still.Gradient,
	points : List(Point),
} -> Shapes.Shape
still_gradient_polygon = |anchor, { gradient, points }|
	match gradient {
		Linear({ stops, start, end }) => {
			fill = Brush.linear_gradient({
				stops: brush_stops(stops),
				start_point: StillShapes.screen_point(anchor, start),
				end_point: StillShapes.screen_point(anchor, end),
			})
			Shapes.region_from_corners(points, fill)
		}
		Radial({ stops, center, axis_u, axis_v }) => {
			ellipse = Brush.elliptical_gradient({
				stops: brush_stops(stops),
				center: StillShapes.screen_point(anchor, center),
				axis_u: screen_vector(anchor, axis_u),
				axis_v: screen_vector(anchor, axis_v),
			})
			# A still is never drawn small enough to thin its ellipses past
			# Brush's limit, as `Still.of` checks.
			fill =
				match ellipse {
					Ok(gradient_fill) => gradient_fill
					Err(TooThin) => crash "StillShapes.still_gradient_polygon: an ellipse too thin for Brush to invert"
				}
			Shapes.region_from_corners(points, fill)
		}
	}

## A still's colour stops as a brush takes them.
brush_stops : Still.ColorStops -> Brush.TwoStops
brush_stops = |stops| {
	start_color: Brush.translucent(stops.start_color),
	end_color: Brush.translucent(stops.end_color),
	start_offset: stops.start_offset.to_f64(),
	end_offset: stops.end_offset.to_f64(),
}

sample_foot : Point
sample_foot = Point.at(100.0, 200.0)

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

## A shaded polygon whose stops are half see-through grey and opaque white.
shaded_sample : Still.Polygon
shaded_sample = {
	fill: Shaded(
		Linear({
			stops: {
				start_color: ArgbColor.of(0x80808080),
				end_color: ArgbColor.of(0xFFFFFFFF),
				start_offset: Fraction.zero,
				end_offset: Fraction.whole,
			},
			start: { x: 0.0, y: 0.0 },
			end: { x: 1.0, y: 0.0 },
		}),
	),
	points: [{ x: 0.0, y: 0.0 }, { x: 1.0, y: 0.0 }, { x: 0.0, y: 1.0 }],
}

## The two stops' colours of `polygon`, as whole numbers, if it is shaded.
stop_colors : Still.Polygon -> List(I64)
stop_colors = |polygon|
	match polygon.fill {
		Shaded(Linear({ stops, .. })) | Shaded(Radial({ stops, .. })) => [
			stops.start_color.to_i64(),
			stops.end_color.to_i64(),
		]
		Flat(_) => []
	}

# By day a still keeps its colours; at full night a flat colour and each stop
# lose half their light, and the stops keep their alpha.
expect
	[shaded_sample, { ..shaded_sample, fill: Flat(RgbColor.of(0x4A8F43)) }].all(
		|polygon| polygon_at_darkness(polygon, Fraction.zero) == polygon,
	)
expect polygon_at_darkness(
	{ ..shaded_sample, fill: Flat(RgbColor.of(0x4A8F43)) },
	Fraction.whole,
).fill == Flat(RgbColor.of(0x254822))
expect stop_colors(polygon_at_darkness(shaded_sample, Fraction.whole)) == [0x80404040, 0xFF808080]

expect StillShapes.screen_point(upright, { x: 0.5, y: 0.4 }) == Point.at(125.0, 180.0)
expect StillShapes.screen_point(mirrored, { x: 0.5, y: 0.4 }) == Point.at(75.0, 180.0)
expect StillShapes.screen_point(upright, { x: 0.0, y: 0.0 }) == Point.at(100.0, 200.0)

expect screen_vector(upright, { x: 0.5, y: 0.4 }) == Point.at(25.0, -20.0)
expect screen_vector(mirrored, { x: 0.5, y: 0.4 }) == Point.at(-25.0, -20.0)
expect screen_vector(upright, { x: 0.0, y: 0.0 }) == Point.at(0.0, 0.0)

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
			Point.at(100.0, 200.0),
			Point.at(125.0, 180.0),
			Point.at(150.0, 150.0),
		]
