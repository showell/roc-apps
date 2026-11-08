## LitTruck is how the truck on the road looks in a frame: which of its lights
## are on. Its picture is its headlight beams first, then its body, then its
## brake lights, so each paints over the one before.
import Fraction
import Picture
import Truck
import TruckBody
import TruckLights
import TruckShape
import lib.Shapes

## Which of the truck's lights are on.
LitTruck := { headlights : [On, Off], brake_lights : [On, Off] }.{

	is_eq : _

	## The lights a truck going at `pace` has on under a sky of `darkness`: its
	## headlights once the sky is dark enough, like a light sensor on the lamps,
	## and its brake lights while its last step slowed it.
	at : Truck.Pace, Fraction -> LitTruck
	at = |pace, darkness| {
		headlights: if darkness >= headlights_on_darkness {
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

## The headlights come on at 41.2% of dusk. The value was measured once, so the
## lights come on at the very step they did when they waited for the sun to sink
## behind the west range: the sky is a little darker than this there, and a
## little lighter a step before. gates/expects/RideExpects.roc pins that step.
headlights_on_darkness : Fraction
headlights_on_darkness = Fraction.of(0.412)

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

expect LitTruck.at(NotSlowing, Fraction.of(0.4119)) == { headlights: Off, brake_lights: Off }
expect LitTruck.at(Slowing, Fraction.of(0.4119)) == { headlights: Off, brake_lights: On }
expect LitTruck.at(NotSlowing, headlights_on_darkness) == { headlights: On, brake_lights: Off }
expect LitTruck.at(Slowing, headlights_on_darkness) == { headlights: On, brake_lights: On }
expect LitTruck.at(NotSlowing, Fraction.of(0.4121)) == { headlights: On, brake_lights: Off }
expect LitTruck.at(Slowing, Fraction.zero) == { headlights: Off, brake_lights: On }
expect LitTruck.at(NotSlowing, Fraction.whole) == { headlights: On, brake_lights: Off }
