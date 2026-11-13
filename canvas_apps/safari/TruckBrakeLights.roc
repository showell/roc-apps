## TruckBrakeLights is whether the truck's brake lights are on, and how they
## look: two lamps on the back of the trailer, each with a glow around it. They
## are worked out each frame from the truck's progress, which says whether its
## last step slowed it.
import Distance
import Sprite
import lib.Point
import lib.Pixels
import RiderView
import Camera
import Screen
import TruckJourney
import TruckPlacement
import TruckShape
import lib.ArgbColor
import lib.Brush
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
	sprite : TruckBrakeLights, Sprite.Setting -> Sprite
	sprite = |brake_lights, setting|
		match brake_lights {
			On => Sprite.from_shapes(lamp_pair_shapes(setting))
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
lamp_pair_shapes : Sprite.Setting -> List(Shapes.Shape)
lamp_pair_shapes = |setting| {
	box = TruckShape.truck_box
	left_lamp_sides = {
		left: box.left.plus(brake_lamp_outer_edge),
		right: box.left.plus(brake_lamp_inner_edge),
	}
	right_lamp_sides = {
		left: box.right.minus(brake_lamp_inner_edge),
		right: box.right.minus(brake_lamp_outer_edge),
	}
	brake_shapes(setting, left_lamp_sides).concat(brake_shapes(setting, right_lamp_sides))
}

## The center of a polygon on screen: the mean of its corners. Each sum
## runs from the last corner to the first; a float sum's rounding depends
## on its order, and another order can move a pixel.
center_of : List(Point) -> Point
center_of = |corners| {
	count = corners.len().to_f64()
	{
		x: corners.fold_rev(Pixels.zero, |corner, sum| corner.x.plus(sum)).divided_by(count),
		y: corners.fold_rev(Pixels.zero, |corner, sum| corner.y.plus(sum)).divided_by(count),
	}
}

## How far a brake light's glow reaches from `center`, the lamp's
## center.
glow_radius : List(Point), Point -> Pixels
glow_radius = |lamp_points, center| Screen.farthest_distance(lamp_points, center).times(glow_reach)

## A brake light on the back of the trailer, its sides `left` and `right`
## measured rightward of the truck's centre line: its glow, then the lamp
## over the glow.
brake_shapes : Sprite.Setting, { left : Distance, right : Distance } -> List(Shapes.Shape)
brake_shapes = |setting, lamp_sides| {
	rear = TruckShape.truck_box.rear
	lamp =
		TruckShape.strip_corners(
			lamp_sides,
			{
				near: { ahead: rear, height: brake_lamp_bottom },
				far: { ahead: rear, height: brake_lamp_top },
			},
		).map(|corner| TruckPlacement.point_at_height(setting.spot, corner))
	glow_shapes =
		match brake_glow(setting, lamp) {
			Ok(glow) => [glow]
			Err(BehindCamera) | Err(TooSmall) => []
		}
	match Camera.clipped_polygon({ color: brake_color, corners: lamp }, setting.focal_length) {
		Ok(lamp_polygon) => glow_shapes.append(lamp_polygon)
		Err(BehindCamera) => glow_shapes
	}
}

## The glow round a brake lamp. A lamp with a corner behind the camera has
## no glow; the lamp itself is cut at the near plane like the body's faces.
brake_glow : Sprite.Setting,
List(RiderView.PointAtHeight) -> Try(
	Shapes.Shape,
	[BehindCamera, TooSmall],
)
brake_glow = |setting, lamp_points| {
	lamp_ahead = RiderView.points_at_height_ahead(lamp_points)?
	on_screen = Camera.projected_points(lamp_ahead, setting.focal_length)
	center = center_of(on_screen)
	radius = glow_radius(on_screen, center)
	fill = Brush.circular_gradient({
		center_color: glow_core,
		edge_color: glow_edge,
		center,
		radius,
	})?
	Ok(Disc({ center, radius, fill }))
}

expect TruckBrakeLights.at(Slowing) == On
expect TruckBrakeLights.at(NotSlowing) == Off

panel_points : List(Point)
panel_points = [
	Point.at(3.0, 4.0),
	Point.at(6.0, 8.0),
	Point.at(0.0, 0.0),
	Point.at(7.0, 4.0),
]

triangle_points : List(Point)
triangle_points = [
	Point.at(0.0, 0.0),
	Point.at(3.0, 0.0),
	Point.at(0.0, 6.0),
]

expect center_of(panel_points) == Point.at(4.0, 4.0)
expect center_of(triangle_points) == Point.at(1.0, 2.0)
