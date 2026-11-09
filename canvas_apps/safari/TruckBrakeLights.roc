## TruckBrakeLights is whether the truck's brake lights are on, and how they
## look: two lamps on the back of the trailer, each with a glow around it. They
## are worked out each frame from the truck's progress, which says whether its
## last step slowed it.
import Distance
import Sprite
import Pixels
import Polygon
import RiderView
import Camera
import Screen
import TruckJourney
import TruckPlacement
import TruckShape
import lib.ArgbColor
import lib.RgbColor
import lib.Shapes

## Whether the truck's brake lights are lit.
TruckBrakeLights := [On, Off].{

	is_eq : _

	## The brake lights of a truck going at `pace`: on while its last step
	## slowed it.
	at : TruckJourney.Pace -> TruckBrakeLights
	at = |pace|
		match pace {
			Slowing => On
			NotSlowing => Off
		}

	## How the brake lights look: the two lamps and their glows while they are
	## on, and nothing while they are off.
	sprite : TruckBrakeLights, TruckPlacement.TruckSetting -> Sprite
	sprite = |brake_lights, truck|
		match brake_lights {
			On => Sprite.from_shapes(lamp_pair_shapes(truck))
			Off => Sprite.from_shapes([])
		}
}

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

## The two brake lights, one in from each side of the trailer's back.
lamp_pair_shapes : TruckPlacement.TruckSetting -> List(Shapes.Shape)
lamp_pair_shapes = |truck| {
	box = TruckShape.truck_box
	brake_shapes(
		truck,
		{ left: box.left.plus(brake_lamp_outer_edge), right: box.left.plus(brake_lamp_inner_edge) },
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
glow_radius = |lamp_points, center| Screen.farthest_distance(lamp_points, center).times(glow_reach)

## A brake light on the back of the trailer, its sides `left` and `right`
## measured rightward of the truck's centre line: its glow, then the lamp
## over the glow.
brake_shapes : TruckPlacement.TruckSetting,
{
	left : Distance,
	right : Distance,
} -> List(Shapes.Shape)
brake_shapes = |truck, lamp_sides| {
	rear = TruckShape.truck_box.rear
	lamp =
		TruckShape.strip_corners(
			lamp_sides,
			{
				near: { ahead: rear, height: brake_lamp_bottom },
				far: { ahead: rear, height: brake_lamp_top },
			},
		).map(|corner| TruckPlacement.raised_point(truck.spot, corner))
	glow = [brake_glow(truck, lamp)].keep_oks(|shape| shape)
	match Polygon.clipped_polygon({ color: brake_color, corners: lamp }, truck.focal_length) {
		Ok(lamp_polygon) => glow.append(lamp_polygon)
		Err(BehindCamera) => glow
	}
}

## The glow round a brake lamp. A lamp with a corner behind the camera has
## no glow; the lamp itself is cut at the near plane like the body's faces.
brake_glow : TruckPlacement.TruckSetting,
List(RiderView.RaisedPoint) -> Try(
	Shapes.Shape,
	[BehindCamera, TooSmall],
)
brake_glow = |truck, lamp_points| {
	lamp_ahead = RiderView.raised_points_ahead(lamp_points)?
	on_screen = Camera.projected_points(lamp_ahead, truck.focal_length)
	center = center_of(on_screen)
	radius = glow_radius(on_screen, center)
	fill = Polygon.circular_gradient_fill({
		center_color: glow_core,
		edge_color: glow_edge,
		gradient_center: center,
		gradient_radius: radius,
	})?
	Ok(
		Disc({
			center: { x: center.x.to_f64(), y: center.y.to_f64() },
			radius: radius.to_f64(),
			fill,
		}),
	)
}

expect TruckBrakeLights.at(Slowing) == On
expect TruckBrakeLights.at(NotSlowing) == Off

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
