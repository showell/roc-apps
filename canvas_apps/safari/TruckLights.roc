## TruckLights draws the truck's lights: the beams of its two headlights,
## reaching along the road ahead of the cab, and its two brake lights on the
## back of the trailer, each with a glow around it. A beam or a glow is a
## gradient, whose colours are 0xAARRGGBB, opacity in the top byte; a brake
## lamp is a flat 0xRRGGBB, as the body's faces are.
import Camera
import lib.DeviceMath
import Geom
import Paint
import lib.Trig
import TruckShape
import Screen
import lib.Shapes

TruckLights :: [].{

	## The two headlight beams, each a little in from its side.
	headlight_beams : TruckShape.TruckInView -> List(Shapes.Shape)
	headlight_beams = |truck|
		List.concat(
			beam(truck, (truck.box.left + headlight_inset)),
			beam(truck, (truck.box.right - headlight_inset)),
		)

	## The two brake lights, one in from each side of the trailer's back.
	brake_lights : TruckShape.TruckInView -> List(Shapes.Shape)
	brake_lights = |truck| {
		box = truck.box
		List.concat(
			brake_light(
				truck,
				{
					left: (box.left + brake_lamp_outer_edge),
					right: (box.left + brake_lamp_inner_edge),
				},
			),
			brake_light(
				truck,
				{
					left: (box.right - brake_lamp_inner_edge),
					right: (box.right - brake_lamp_outer_edge),
				},
			),
		)
	}

	## A glow is drawn as a polygon with this many corners.
	glow_sides : I64
	glow_sides = 16

	## Whether any of `points` is at or behind the camera's near plane.
	has_point_behind_camera : List(Geom.SpacePoint) -> Bool
	has_point_behind_camera = |points| points.any(|point| point.forward <= Geom.near_plane)

	## The point halfway between `from` and `to`.
	midpoint : { from : Geom.SpacePoint, to : Geom.SpacePoint } -> Geom.SpacePoint
	midpoint = |{ from, to }| {
		right: ((from.right + to.right) / 2.0),
		forward: ((from.forward + to.forward) / 2.0),
		height: ((from.height + to.height) / 2.0),
	}

	## The distance between two points on screen.
	distance : { from : Screen.Point, to : Screen.Point } -> F64
	distance = |{ from, to }| {
		dx = (from.x - to.x)
		dy = (from.y - to.y)
		DeviceMath.real_sqrt(((dx * dx) + (dy * dy)))
	}

	## How far the farthest of `points` is from `center`.
	farthest_from : List(Screen.Point), Screen.Point -> F64
	farthest_from = |points, center|
		points.fold_rev(
			0.0,
			|point, farthest| DeviceMath.real_max(
				TruckLights.distance({ from: point, to: center }),
				farthest,
			),
		)

	## The center of a polygon on screen: the mean of its corners. Each sum
	## runs from the last corner to the first; a float sum's rounding depends
	## on its order, and another order can move a pixel.
	center_of : List(Screen.Point) -> Screen.Point
	center_of = |corners| {
		count = corners.len().to_f64()
		{
			x: (corners.fold_rev(0.0, |corner, sum| corner.x + sum) / count),
			y: (corners.fold_rev(0.0, |corner, sum| corner.y + sum) / count),
		}
	}

	## How far a brake light's glow reaches from `center`, the lamp's
	## center.
	glow_radius : List(Screen.Point), Screen.Point -> F64
	glow_radius = |lamp, center| (TruckLights.farthest_from(lamp, center) * glow_reach)

	## A circle round `center`, as a polygon of `glow_sides` corners.
	glow_outline : { center : Screen.Point, radius : F64 } -> List(Screen.Point)
	glow_outline = |{ center, radius }|
		TruckShape.circle_angles(TruckLights.glow_sides).map(
			|angle| {
				x: (center.x + (radius * Trig.r_cos(angle))),
				y: (center.y + (radius * Trig.r_sin(angle))),
			},
		)
}

## How high the headlights are, and how far in from the truck's sides.
headlight_height : F64
headlight_height = 1.0

headlight_inset : F64
headlight_inset = 0.3

## A beam is a vertical wedge from its lamp: half a metre tall there, and
## 1.8 m tall, centred 0.7 m above the road, where it ends `beam_length`
## ahead of the cab's nose.
beam_half_height_at_lamp : F64
beam_half_height_at_lamp = 0.25

beam_length : F64
beam_length = 20.4

beam_far_center : F64
beam_far_center = 0.7

beam_far_half_height : F64
beam_far_half_height = 0.9

## The beam is one warm white, more opaque at the lamp than at its edge.
beam_core : I64
beam_core = 0xC3FFF8D6

beam_edge : I64
beam_edge = 0x45FFF8D6

## A brake lamp spans from a tenth of the truck's width in from its side
## to just over a third, and from a fifth of the way up the trailer's back
## to half way.
brake_lamp_outer_edge : F64
brake_lamp_outer_edge = (0.1 * TruckShape.truck_width)

brake_lamp_inner_edge : F64
brake_lamp_inner_edge = (0.36 * TruckShape.truck_width)

trailer_height : F64
trailer_height = (TruckShape.truck_height - TruckShape.trailer_bottom)

brake_lamp_bottom : F64
brake_lamp_bottom = (TruckShape.trailer_bottom + (0.2 * trailer_height))

brake_lamp_top : F64
brake_lamp_top = (TruckShape.trailer_bottom + (0.5 * trailer_height))

brake_color : I64
brake_color = 0xFF2A18

glow_core : I64
glow_core = 0xE6FF503C

## The glow fades out to the brake lamp's own colour at no opacity:
## `brake_color`'s top byte is 0.
glow_edge : I64
glow_edge = brake_color

## A glow reaches this many times as far as its lamp's farthest corner.
glow_reach : F64
glow_reach = 3.2

## The beam of the headlight at `across`, brightest at the lamp. A beam
## with a corner behind the camera is not drawn.
beam : TruckShape.TruckInView, F64 -> List(Shapes.Shape)
beam = |truck, across| {
	at_lamp = |height| TruckShape.point(
		truck,
		{
			along: truck.box.nose,
			across,
			height,
		},
	)
	at_far_end = |height| TruckShape.point(
		truck,
		{
			along: (truck.box.nose + beam_length),
			across,
			height,
		},
	)
	lamp_bottom = at_lamp((headlight_height - beam_half_height_at_lamp))
	lamp_top = at_lamp((headlight_height + beam_half_height_at_lamp))
	far_top = at_far_end((beam_far_center + beam_far_half_height))
	far_bottom = at_far_end((beam_far_center - beam_far_half_height))
	corners = [
		lamp_bottom,
		lamp_top,
		far_top,
		far_bottom,
	]
	if TruckLights.has_point_behind_camera(corners) {
		[]
	} else {
		on_screen = Camera.project_all(
			corners,
			truck.view.cam_focal,
		)
		lamp = Camera.project(
			TruckLights.midpoint({ from: lamp_bottom, to: lamp_top }),
			truck.view.cam_focal,
		)
		Paint.push_grad_poly(
			on_screen,
			{
				center_rgba: beam_core,
				edge_rgba: beam_edge,
				gradient_center: lamp,
				gradient_radius: TruckLights.farthest_from(on_screen, lamp),
			},
		)
	}
}

## A brake light on the back of the trailer, from `left` to `right` across
## it: its glow, then the lamp over the glow.
brake_light : TruckShape.TruckInView, { left : F64, right : F64 } -> List(Shapes.Shape)
brake_light = |truck, { left, right }| {
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
	List.concat(glow(truck, lamp), TruckShape.fill(truck, { color: brake_color, corners: lamp }))
}

## The glow round a brake lamp. A lamp with a corner behind the camera has
## no glow; the lamp itself is cut at the near plane like the body's faces.
glow : TruckShape.TruckInView, List(Geom.SpacePoint) -> List(Shapes.Shape)
glow = |truck, lamp|
	if TruckLights.has_point_behind_camera(lamp) {
		[]
	} else {
		on_screen = Camera.project_all(lamp, truck.view.cam_focal)
		center = TruckLights.center_of(on_screen)
		radius = TruckLights.glow_radius(on_screen, center)
		Paint.push_grad_poly(
			TruckLights.glow_outline({ center, radius }),
			{
				center_rgba: glow_core,
				edge_rgba: glow_edge,
				gradient_center: center,
				gradient_radius: radius,
			},
		)
	}
