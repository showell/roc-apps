## TruckLights gives the shapes of the truck's lights: the beams of its two
## headlights, reaching along the road ahead of the cab, and its two brake
## lights on the back of the trailer, each with a glow around it.
import Pixels
import Camera
import Distance
import RiderView
import Polygon
import TruckShape
import Screen
import lib.ArgbColor
import lib.RgbColor
import lib.Shapes

TruckLights :: [].{

	## The two headlight beams, each a little in from its side.
	headlight_beam_shapes : TruckShape.TruckSetting -> List(Shapes.Shape)
	headlight_beam_shapes = |truck| {
		box = TruckShape.truck_box
		[
			headlight_beam(truck, box.left.plus(headlight_inset)),
			headlight_beam(truck, box.right.minus(headlight_inset)),
		].keep_oks(|beam| beam)
	}

	## The two brake lights, one in from each side of the trailer's back.
	brake_light_shapes : TruckShape.TruckSetting -> List(Shapes.Shape)
	brake_light_shapes = |truck| {
		box = TruckShape.truck_box
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
}

## How high the headlights are, and how far in from the truck's sides.
headlight_height : Distance
headlight_height = Distance.metres(1.0)

headlight_inset : Distance
headlight_inset = Distance.metres(0.3)

## A beam is a vertical wedge from its lamp, widening to where it ends
## `beam_length` ahead of the cab's nose.
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

## A brake lamp sits near a side of the trailer's back, in its lower half,
## where a real trailer carries its lamps. Its edges are set as shares of
## the truck's size, chosen by eye, so the lamps keep their place on the
## back as the truck's measurements change.
brake_lamp_outer_edge : Distance
brake_lamp_outer_edge = TruckShape.truck_width.times(0.1)

brake_lamp_inner_edge : Distance
brake_lamp_inner_edge = TruckShape.truck_width.times(0.36)

brake_lamp_bottom : Distance
brake_lamp_bottom = TruckShape.trailer_bottom.plus(TruckShape.trailer_height.times(0.2))

brake_lamp_top : Distance
brake_lamp_top = TruckShape.trailer_bottom.plus(TruckShape.trailer_height.times(0.5))

brake_color : RgbColor
brake_color = RgbColor.of(0xFF2A18)

glow_core : ArgbColor
glow_core = ArgbColor.of(0xE6FF503C)

## The glow fades out to the brake lamp's own colour at no opacity.
glow_edge : ArgbColor
glow_edge = ArgbColor.from_rgb(brake_color, { alpha: 0 })

## A glow reaches this many times as far as its lamp's farthest corner, a
## reach chosen by eye.
glow_reach : F64
glow_reach = 3.2

## A glow is drawn as a polygon with this many corners.
glow_sides : I64
glow_sides = 16

## How far the farthest of `points` is from `center`.
farthest_from : List(Screen.Point), Screen.Point -> Pixels
farthest_from = |points, center|
	points.fold_rev(
		Pixels.zero,
		|point, farthest| Screen.distance({ from: point, to: center }).max(farthest),
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
glow_radius = |lamp_points, center| farthest_from(lamp_points, center).times(glow_reach)

## A circle round `center`, as a polygon of `glow_sides` corners.
outline_points : { center : Screen.Point, outline_radius : Pixels } -> List(Screen.Point)
outline_points = |{ center, outline_radius }|
	TruckShape.circle_angles(glow_sides).map(
		|angle| {
			x: center.x.plus(outline_radius.times(angle.cos())),
			y: center.y.plus(outline_radius.times(angle.sin())),
		},
	)

## The beam of the headlight `rightward` of the truck's centre line,
## brightest at the lamp. A beam with a corner behind the camera is not
## drawn.
headlight_beam : TruckShape.TruckSetting, Distance -> Try(Shapes.Shape, [BehindCamera, TooSmall])
headlight_beam = |truck, rightward| {
	nose = TruckShape.truck_box.nose
	on_truck = |ahead, height| TruckShape.raised_point_on_truck(truck, { ahead, rightward, height })
	at_lamp = |height| on_truck(nose, height)
	at_far_end = |height| on_truck(nose.plus(beam_length), height)
	lamp_bottom = at_lamp(headlight_height.minus(beam_half_height_at_lamp))
	lamp_top = at_lamp(headlight_height.plus(beam_half_height_at_lamp))
	far_top = at_far_end(beam_far_center.plus(beam_far_half_height))
	far_bottom = at_far_end(beam_far_center.minus(beam_far_half_height))
	corners = RiderView.raised_points_ahead([lamp_bottom, lamp_top, far_top, far_bottom])?
	lamp = RiderView.raised_point_ahead(at_lamp(headlight_height))?
	on_screen = Camera.projected_points(corners, truck.focal_length)
	lamp_on_screen = Camera.project(lamp, truck.focal_length)
	Polygon.circular_gradient_polygon(
		on_screen,
		{
			center_color: beam_core,
			edge_color: beam_edge,
			gradient_center: lamp_on_screen,
			gradient_radius: farthest_from(on_screen, lamp_on_screen),
		},
	)
}

## A brake light on the back of the trailer, its sides `left` and `right`
## measured rightward of the truck's centre line: its glow, then the lamp
## over the glow.
brake_shapes : TruckShape.TruckSetting, { left : Distance, right : Distance } -> List(Shapes.Shape)
brake_shapes = |truck, lamp_sides| {
	rear = TruckShape.truck_box.rear
	lamp =
		TruckShape.strip_corners(
			lamp_sides,
			{
				near: { ahead: rear, height: brake_lamp_bottom },
				far: { ahead: rear, height: brake_lamp_top },
			},
		).map(|corner| TruckShape.raised_point_on_truck(truck, corner))
	glow = [brake_glow(truck, lamp)].keep_oks(|shape| shape)
	match Polygon.clipped_polygon({ color: brake_color, corners: lamp }, truck.focal_length) {
		Ok(lamp_polygon) => glow.append(lamp_polygon)
		Err(BehindCamera) => glow
	}
}

## The glow round a brake lamp. A lamp with a corner behind the camera has
## no glow; the lamp itself is cut at the near plane like the body's faces.
brake_glow : TruckShape.TruckSetting,
List(RiderView.RaisedPoint) -> Try(
	Shapes.Shape,
	[BehindCamera, TooSmall],
)
brake_glow = |truck, lamp_points| {
	lamp_ahead = RiderView.raised_points_ahead(lamp_points)?
	on_screen = Camera.projected_points(lamp_ahead, truck.focal_length)
	center = center_of(on_screen)
	radius = glow_radius(on_screen, center)
	Polygon.circular_gradient_polygon(
		outline_points({ center, outline_radius: radius }),
		{
			center_color: glow_core,
			edge_color: glow_edge,
			gradient_center: center,
			gradient_radius: radius,
		},
	)
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

expect center_of(panel_points) == Screen.point(4.0, 4.0)
expect center_of(triangle_points) == Screen.point(1.0, 2.0)

expect farthest_from(panel_points, Screen.point(0.0, 0.0)).to_f64() == 10.0

# The headlight's lamp lies on the cab's nose face, above the cab's floor and
# below its hood.
expect headlight_height.minus(beam_half_height_at_lamp) >= TruckShape.cab_bottom
expect headlight_height.plus(beam_half_height_at_lamp) <= TruckShape.hood_height
