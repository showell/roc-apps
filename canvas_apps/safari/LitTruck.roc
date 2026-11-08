## LitTruck is how the truck on the road looks in a frame: which of its lights
## are on. Its picture is its headlight beams first, then its body, then its
## brake lights, so each paints over the one before.
import Clock
import Mountains
import Picture
import Truck
import TruckBody
import TruckLights
import TruckShape
import lib.Shapes

## Which of the truck's lights are on.
LitTruck := { headlights : [On, Off], brake_lights : [On, Off] }.{

	is_eq : _

	## The lights a truck going at `pace` has on at `clock`: its headlights once
	## the sun is behind the mountains, and its brake lights while its last step
	## slowed it.
	at : Truck.Pace, Clock -> LitTruck
	at = |pace, clock| {
		headlights: if Mountains.is_sun_behind_mountains(clock) {
			On
		} else {
			Off
		},
		brake_lights: match pace {
			Slowing => On
			NotSlowing => Off
		},
	}

	## How the truck looks. Every point on it is measured on the road, from where
	## its trailer is centered, and seen from the camera's vantage, so those are
	## its context.
	scenery_picture : LitTruck, TruckShape.TruckSetting -> Picture
	scenery_picture = |lit_truck, setting| Picture.from_shapes(truck_shapes(lit_truck, setting))
}

## The truck, filling its box.
truck_shapes : LitTruck, TruckShape.TruckSetting -> List(Shapes.Shape)
truck_shapes = |lit_truck, setting| {
	beams =
		match lit_truck.headlights {
			On => TruckLights.headlight_beam_shapes(setting)
			Off => []
		}
	brake_lights =
		match lit_truck.brake_lights {
			On => TruckLights.brake_light_shapes(setting)
			Off => []
		}
	[beams, TruckBody.body_shapes(setting), brake_lights].join()
}

## A clock with the sun behind the mountains.
after_sunset : Clock
after_sunset = Clock.at_step(5700)

expect LitTruck.at(NotSlowing, Clock.start) == { headlights: Off, brake_lights: Off }
expect LitTruck.at(Slowing, Clock.start) == { headlights: Off, brake_lights: On }
expect LitTruck.at(NotSlowing, after_sunset) == { headlights: On, brake_lights: Off }
expect LitTruck.at(Slowing, after_sunset) == { headlights: On, brake_lights: On }
