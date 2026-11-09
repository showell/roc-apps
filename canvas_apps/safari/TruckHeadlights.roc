## TruckHeadlights is whether the truck's headlights are on, and how they look:
## two beams reaching along the road ahead of the cab, each a little in from
## its side.
import Camera
import Distance
import Fraction
import Picture
import Polygon
import RiderView
import Screen
import TruckPlacement
import TruckShape
import lib.ArgbColor
import lib.Shapes

## Whether the truck's headlights are lit.
TruckHeadlights := [On, Off].{

	is_eq : _

	## The headlights under a sky of `darkness`: on once the sky is dark
	## enough, like a light sensor on the lamps.
	at : Fraction -> TruckHeadlights
	at = |darkness|
		if darkness >= headlights_on_darkness {
			On
		} else {
			Off
		}

	## How the headlights look: their two beams while they are on, and nothing
	## while they are off.
	picture : TruckHeadlights, TruckPlacement.TruckSetting -> Picture
	picture = |headlights, truck|
		match headlights {
			On => Picture.from_shapes(beam_shapes(truck))
			Off => Picture.from_shapes([])
		}
}

## The headlights come on once the sky is 41.2% dark, about when the sun sinks
## behind the west range. The value was measured once, on this ride;
## gates/expects/RideExpects.roc pins the step.
headlights_on_darkness : Fraction
headlights_on_darkness = Fraction.of(0.412)

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

## The two headlight beams, each a little in from its side.
beam_shapes : TruckPlacement.TruckSetting -> List(Shapes.Shape)
beam_shapes = |truck| {
	box = TruckShape.truck_box
	[
		headlight_beam(truck, box.left.plus(headlight_inset)),
		headlight_beam(truck, box.right.minus(headlight_inset)),
	].keep_oks(|beam| beam)
}

## The beam of the headlight `rightward` of the truck's centre line,
## brightest at the lamp. A beam with a corner behind the camera is not
## drawn.
headlight_beam : TruckPlacement.TruckSetting,
Distance -> Try(
	Shapes.Shape,
	[BehindCamera, TooSmall],
)
headlight_beam = |truck, rightward| {
	nose = TruckShape.truck_box.nose
	stance = { spot: truck.spot, heading: truck.heading }
	on_truck = |ahead, height| TruckPlacement.raised_point(stance, { ahead, rightward, height })
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
			gradient_radius: Screen.farthest_distance(on_screen, lamp_on_screen),
		},
	)
}

expect TruckHeadlights.at(Fraction.of(0.4119)) == Off
expect TruckHeadlights.at(headlights_on_darkness) == On
expect TruckHeadlights.at(Fraction.of(0.4121)) == On
expect TruckHeadlights.at(Fraction.zero) == Off
expect TruckHeadlights.at(Fraction.whole) == On

# The headlight's lamp lies on the cab's nose face, above the cab's floor and
# below its hood.
expect headlight_height.minus(beam_half_height_at_lamp) >= TruckShape.cab_bottom
expect headlight_height.plus(beam_half_height_at_lamp) <= TruckShape.hood_height
