## TruckLights draws the truck's lights: the beams of its two headlights,
## reaching along the road ahead of the cab, and its two brake lights on the
## back of the trailer, each with a glow around it. A beam or a glow is a
## gradient, whose colours are 0xAARRGGBB, opacity in the top byte; a brake
## lamp is a flat 0xRRGGBB, as the body's faces are.
import Pixels
import Across
import Camera
import Distance
import Geom
import Polygon
import TruckShape
import Screen
import lib.ArgbColor
import lib.Shapes

TruckLights :: [].{

	## The two headlight beams, each a little in from its side.
	headlight_beams : TruckShape.TruckInView -> List(Shapes.Shape)
	headlight_beams = |truck|
		beam_shapes(truck, truck.box.left.plus(headlight_inset)).concat(
			beam_shapes(truck, truck.box.right.minus(headlight_inset)),
		)

	## The two brake lights, one in from each side of the trailer's back.
	brake_lights : TruckShape.TruckInView -> List(Shapes.Shape)
	brake_lights = |truck| {
		box = truck.box
		brake_shapes(
			truck,
			{
				left: box.left.plus(brake_lamp_outer_edge),
				right: box.left.plus(brake_lamp_inner_edge),
			},
		).concat(
			brake_shapes(
				truck,
				{
					left: box.right.minus(brake_lamp_inner_edge),
					right: box.right.minus(brake_lamp_outer_edge),
				},
			),
		)
	}

	## A glow is drawn as a polygon with this many corners.
	glow_sides : I64
	glow_sides = 16

	## Whether any of `points` is at or behind the camera's near plane.
	has_point_behind_camera : List(Geom.RaisedPoint) -> Bool
	has_point_behind_camera = |points| points.any(|point| point.forward <= Geom.near_plane)

	## The point halfway between `from` and `to`.
	midpoint : { from : Geom.RaisedPoint, to : Geom.RaisedPoint } -> Geom.RaisedPoint
	midpoint = |{ from, to }| {
		right: from.right.plus(to.right).divided_by(2.0),
		forward: from.forward.plus(to.forward).divided_by(2.0),
		height: from.height.plus(to.height).divided_by(2.0),
	}

	## The distance between two points on screen.
	distance : { from : Screen.Point, to : Screen.Point } -> Pixels
	distance = |{ from, to }| {
		dx = from.x.minus(to.x).to_f64()
		dy = from.y.minus(to.y).to_f64()
		Pixels.of((dx * dx + dy * dy).sqrt())
	}

	## How far the farthest of `points` is from `center`.
	farthest_from : List(Screen.Point), Screen.Point -> Pixels
	farthest_from = |points, center|
		points.fold_rev(
			Pixels.zero,
			|point, farthest| TruckLights.distance({ from: point, to: center }).max(farthest),
		)

	## The center of a polygon on screen: the mean of its corners. Each sum
	## runs from the last corner to the first; a float sum's rounding depends
	## on its order, and another order can move a pixel.
	center_of : List(Screen.Point) -> Screen.Point
	center_of = |corners| {
		count = corners.len().to_f64()
		{
			x: corners.fold_rev(Pixels.zero, |corner, sum| corner.x.plus(sum)).divided_by(count),
			y: corners.fold_rev(Pixels.zero, |corner, sum| corner.y.plus(sum)).divided_by(count),
		}
	}

	## How far a brake light's glow reaches from `center`, the lamp's
	## center.
	glow_radius : List(Screen.Point), Screen.Point -> Pixels
	glow_radius = |
		lamp_points,
		center,
	| TruckLights.farthest_from(lamp_points, center).times(glow_reach)

	## A circle round `center`, as a polygon of `glow_sides` corners.
	outline_points : { center : Screen.Point, outline_radius : Pixels } -> List(Screen.Point)
	outline_points = |{ center, outline_radius }|
		TruckShape.circle_angles(TruckLights.glow_sides).map(
			|angle| {
				x: center.x.plus(outline_radius.times(angle.cos())),
				y: center.y.plus(outline_radius.times(angle.sin())),
			},
		)
}

## How high the headlights are, and how far in from the truck's sides.
headlight_height : Distance
headlight_height = Distance.metres(1.0)

headlight_inset : Distance
headlight_inset = Distance.metres(0.3)

## A beam is a vertical wedge from its lamp: half a metre tall there, and
## 1.8 m tall, centred 0.7 m above the road, where it ends `beam_length`
## ahead of the cab's nose.
beam_half_height_at_lamp : Distance
beam_half_height_at_lamp = Distance.metres(0.25)

beam_length : Distance
beam_length = Distance.metres(20.4)

beam_far_center : Distance
beam_far_center = Distance.metres(0.7)

beam_far_half_height : Distance
beam_far_half_height = Distance.metres(0.9)

## The beam is one warm white, more opaque at the lamp than at its edge.
beam_core : ArgbColor
beam_core = ArgbColor.of(0xC3FFF8D6)

beam_edge : ArgbColor
beam_edge = ArgbColor.of(0x45FFF8D6)

## A brake lamp spans from a tenth of the truck's width in from its side
## to just over a third, and from a fifth of the way up the trailer's back
## to half way.
brake_lamp_outer_edge : Distance
brake_lamp_outer_edge = TruckShape.truck_width.times(0.1)

brake_lamp_inner_edge : Distance
brake_lamp_inner_edge = TruckShape.truck_width.times(0.36)

trailer_height : Distance
trailer_height = TruckShape.truck_height.minus(TruckShape.trailer_bottom)

brake_lamp_bottom : Distance
brake_lamp_bottom = TruckShape.trailer_bottom.plus(trailer_height.times(0.2))

brake_lamp_top : Distance
brake_lamp_top = TruckShape.trailer_bottom.plus(trailer_height.times(0.5))

brake_color : I64
brake_color = 0xFF2A18

glow_core : ArgbColor
glow_core = ArgbColor.of(0xE6FF503C)

## The glow fades out to the brake lamp's own colour at no opacity:
## `brake_color`'s top byte is 0.
glow_edge : ArgbColor
glow_edge = ArgbColor.of(brake_color)

## A glow reaches this many times as far as its lamp's farthest corner.
glow_reach : F64
glow_reach = 3.2

## The beam of the headlight at `across`, brightest at the lamp. A beam
## with a corner behind the camera is not drawn.
beam_shapes : TruckShape.TruckInView, Across -> List(Shapes.Shape)
beam_shapes = |truck, across| {
	at_lamp = |height| TruckShape.point(truck, { along: truck.box.nose, across, height })
	at_far_end = |height| TruckShape.point(
		truck,
		{ along: truck.box.nose.plus(beam_length), across, height },
	)
	lamp_bottom = at_lamp(headlight_height.minus(beam_half_height_at_lamp))
	lamp_top = at_lamp(headlight_height.plus(beam_half_height_at_lamp))
	far_top = at_far_end(beam_far_center.plus(beam_far_half_height))
	far_bottom = at_far_end(beam_far_center.minus(beam_far_half_height))
	corners = [lamp_bottom, lamp_top, far_top, far_bottom]
	if TruckLights.has_point_behind_camera(corners) {
		[]
	} else {
		on_screen = Camera.projected_points(corners, truck.view.cam_focal)
		lamp = Camera.project(
			TruckLights.midpoint({ from: lamp_bottom, to: lamp_top }),
			truck.view.cam_focal,
		)
		beam_polygon = Polygon.gradient_polygon(
			on_screen,
			{
				center_color: beam_core,
				edge_color: beam_edge,
				gradient_center: lamp,
				gradient_radius: TruckLights.farthest_from(on_screen, lamp),
			},
		)
		match beam_polygon {
			Ok(shape) => [shape]
			Err(TooSmall) => []
		}
	}
}

## A brake light on the back of the trailer, from `left` to `right` across
## it: its glow, then the lamp over the glow.
brake_shapes : TruckShape.TruckInView, { left : Across, right : Across } -> List(Shapes.Shape)
brake_shapes = |truck, { left, right }| {
	rear = truck.box.rear
	lamp =
		[
			{
				along: rear,
				across: left,
				height: brake_lamp_bottom,
			},
			{
				along: rear,
				across: right,
				height: brake_lamp_bottom,
			},
			{
				along: rear,
				across: right,
				height: brake_lamp_top,
			},
			{
				along: rear,
				across: left,
				height: brake_lamp_top,
			},
		].map(|corner| TruckShape.point(truck, corner))
	glow = glow_shapes(truck, lamp)
	match TruckShape.truck_polygon(truck, { color: brake_color, corners: lamp }) {
		Ok(lamp_polygon) => glow.append(lamp_polygon)
		Err(BehindCamera) => glow
	}
}

## The glow round a brake lamp. A lamp with a corner behind the camera has
## no glow; the lamp itself is cut at the near plane like the body's faces.
glow_shapes : TruckShape.TruckInView, List(Geom.RaisedPoint) -> List(Shapes.Shape)
glow_shapes = |truck, lamp_points|
	if TruckLights.has_point_behind_camera(lamp_points) {
		[]
	} else {
		on_screen = Camera.projected_points(lamp_points, truck.view.cam_focal)
		center = TruckLights.center_of(on_screen)
		radius = TruckLights.glow_radius(on_screen, center)
		glow_polygon = Polygon.gradient_polygon(
			TruckLights.outline_points({ center, outline_radius: radius }),
			{
				center_color: glow_core,
				edge_color: glow_edge,
				gradient_center: center,
				gradient_radius: radius,
			},
		)
		match glow_polygon {
			Ok(shape) => [shape]
			Err(TooSmall) => []
		}
	}

panel_points : List(Screen.Point)
panel_points = [
	Screen.point(3.0, 4.0),
	Screen.point(6.0, 8.0),
	Screen.point(0.0, 0.0),
	Screen.point(7.0, 4.0),
]

triangle_points : List(Screen.Point)
triangle_points = [
	Screen.point(0.0, 0.0),
	Screen.point(3.0, 0.0),
	Screen.point(0.0, 6.0),
]

origin : Screen.Point
origin = Screen.point(0.0, 0.0)

expect TruckLights.center_of(panel_points) == Screen.point(4.0, 4.0)
expect TruckLights.center_of(triangle_points) == Screen.point(1.0, 2.0)
expect
	TruckLights.distance({ from: Screen.point(3.0, 4.0), to: Screen.point(0.0, 0.0) }).to_f64()
		== 5.0
expect TruckLights.distance({ from: origin, to: Screen.point(3.0, 4.0) }).to_f64() == 5.0
expect TruckLights.distance({ from: Screen.point(3.0, 4.0), to: origin }).to_f64() == 5.0
expect TruckLights.distance({ from: origin, to: origin }).to_f64() == 0.0

expect TruckLights.farthest_from(panel_points, Screen.point(0.0, 0.0)).to_f64() == 10.0
expect TruckLights.glow_radius(panel_points, Screen.point(0.0, 0.0)).to_f64() == 32.0

expect
	TruckLights.outline_points({
		center: Screen.point(0.0, 0.0),
		outline_radius: Pixels.of(10.0),
	}).len()
		== 16
expect TruckLights.glow_sides == 16

point_ahead : F64 -> Geom.RaisedPoint
point_ahead = |forward| {
	right: Distance.zero,
	forward: Distance.metres(forward),
	height: Distance.zero,
}

expect
	!TruckLights.has_point_behind_camera([
		point_ahead(10.0),
		point_ahead(20.0),
		point_ahead(30.0),
	])
expect
	TruckLights.has_point_behind_camera([
		point_ahead(10.0),
		point_ahead(0.2),
		point_ahead(30.0),
	])
expect
	TruckLights.has_point_behind_camera([
		point_ahead(10.0),
		point_ahead(0.4),
		point_ahead(30.0),
	])
expect !TruckLights.has_point_behind_camera([point_ahead(0.41)])
expect !TruckLights.has_point_behind_camera([])

expect
	TruckLights.midpoint({
		from: {
			right: Distance.metres(1.0),
			forward: Distance.metres(2.0),
			height: Distance.metres(3.0),
		},
		to: {
			right: Distance.metres(5.0),
			forward: Distance.metres(8.0),
			height: Distance.metres(11.0),
		},
	})
		== {
			right: Distance.metres(3.0),
			forward: Distance.metres(5.0),
			height: Distance.metres(7.0),
		}
