## Truck is the truck as the scene draws it this frame: its lamps' states, and
## its picture. Its picture is its headlight beams first, then its body, then
## its brake lights, so each paints over the one before.
import Fraction
import Picture
import TruckBody
import TruckJourney
import TruckLights
import TruckShape
import lib.Shapes

## Which of the truck's lights are on.
Truck := { headlights : Truck.Lamp, brake_lights : Truck.Lamp }.{

	## Whether one of the truck's lamps is lit.
	Lamp : [On, Off]

	is_eq : _

	## The lights a truck going at `pace` has on under a sky of `darkness`: its
	## headlights once the sky is dark enough, like a light sensor on the lamps,
	## and its brake lights while its last step slowed it.
	at : TruckJourney.Pace, Fraction -> Truck
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
	scenery_picture : Truck, TruckShape.TruckSetting -> Picture
	scenery_picture = |truck, setting| Picture.from_shapes(truck_shapes(truck, setting))
}

## The headlights come on once the sky is 41.2% dark, about when the sun sinks
## behind the west range. The value was measured once, on this ride;
## gates/expects/RideExpects.roc pins the step.
headlights_on_darkness : Fraction
headlights_on_darkness = Fraction.of(0.412)

## The truck's shapes: the beams under the body, the brake lights over it.
truck_shapes : Truck, TruckShape.TruckSetting -> List(Shapes.Shape)
truck_shapes = |truck, setting| {
	beams =
		match truck.headlights {
			On => TruckLights.headlight_beam_shapes(setting)
			Off => []
		}
	brake_lights =
		match truck.brake_lights {
			On => TruckLights.brake_light_shapes(setting)
			Off => []
		}
	[beams, TruckBody.body_shapes(setting), brake_lights].join()
}

expect Truck.at(NotSlowing, Fraction.of(0.4119)) == { headlights: Off, brake_lights: Off }
expect Truck.at(Slowing, Fraction.of(0.4119)) == { headlights: Off, brake_lights: On }
expect Truck.at(NotSlowing, headlights_on_darkness) == { headlights: On, brake_lights: Off }
expect Truck.at(Slowing, headlights_on_darkness) == { headlights: On, brake_lights: On }
expect Truck.at(NotSlowing, Fraction.of(0.4121)) == { headlights: On, brake_lights: Off }
expect Truck.at(Slowing, Fraction.zero) == { headlights: Off, brake_lights: On }
expect Truck.at(NotSlowing, Fraction.whole) == { headlights: On, brake_lights: Off }
