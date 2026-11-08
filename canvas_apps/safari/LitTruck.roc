## LitTruck is how the truck on the road looks in a frame: which of its lights
## are on. Its picture is its headlight beams first, then its body, then its
## brake lights, so each paints over the one before.
import Clock
import Geom
import Mountains
import RoadAhead
import Picture
import Truck
import TruckBody
import TruckLights
import TruckShape
import lib.Shapes

## Which of the truck's lights are on.
LitTruck := { headlights : [On, Off], brake_lights : [On, Off] }.{

	is_eq : _

	## The lights `truck` has on at `clock`: its headlights once the sun is
	## behind the mountains, and its brake lights while its last step slowed it.
	at : Truck, Clock -> LitTruck
	at = |truck, clock| {
		headlights: if Mountains.is_sun_behind_mountains(clock) {
			On
		} else {
			Off
		},
		brake_lights: match truck.pace {
			Slowing => On
			NotSlowing => Off
		},
	}

	## How the truck looks. Every point on it is measured on the road, from where
	## its trailer is centred, and seen from the camera's vantage, so those are
	## its context.
	scenery_picture : LitTruck,
	Picture.Setting(
		{ road : RoadAhead.RoadView, vantage : Geom.Vantage },
	) -> Picture
	scenery_picture = |lit_truck, truck| Picture.from_shapes(truck_shapes(lit_truck, truck))
}

## The truck, filling its box.
truck_shapes : LitTruck, Picture.Setting(TruckShape.TruckOnRoad) -> List(Shapes.Shape)
truck_shapes = |lit_truck, truck| {
	beams =
		match lit_truck.headlights {
			On => TruckLights.headlight_beam_shapes(truck)
			Off => []
		}
	brake_lights =
		match lit_truck.brake_lights {
			On => TruckLights.brake_light_shapes(truck)
			Off => []
		}
	[beams, TruckBody.body_shapes(truck), brake_lights].join()
}

## A clock with the sun behind the mountains.
after_sunset : Clock
after_sunset = Clock.at_step(5700)

## The truck's lights at `clock`, with the truck's pace as given.
lights_at : { clock : Clock, pace : [Slowing, NotSlowing] } -> LitTruck
lights_at = |{ clock, pace }| LitTruck.at({ ..Truck.initial, pace }, clock)

expect lights_at({ clock: Clock.start, pace: NotSlowing }) == { headlights: Off, brake_lights: Off }
expect lights_at({ clock: Clock.start, pace: Slowing }) == { headlights: Off, brake_lights: On }
expect lights_at({ clock: after_sunset, pace: NotSlowing }) == { headlights: On, brake_lights: Off }
expect lights_at({ clock: after_sunset, pace: Slowing }) == { headlights: On, brake_lights: On }
