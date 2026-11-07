## TruckAhead is the truck ahead on the road in a frame. Its picture is its
## headlight beams first, then its body, then its brake lights, so each paints
## over the one before.
import Across
import Along
import Chain
import Picture
import Truck
import TruckBody
import TruckLights
import TruckShape
import lib.Shapes

## The position in the chain of the segment the truck is on, how far along and
## across that segment its trailer is centred, and which of its lights are on.
TruckAhead := {
	position : Chain.Position,
	along : Along,
	across : Across,
	lights : Truck.Lights,
}.{

	## How the truck looks. Every point on it is measured on the road, so the
	## road is its context.
	scenery_picture : TruckAhead, Picture.Setting({ road : Chain.RoadView }) -> Picture
	scenery_picture = |truck_ahead, { cam_focal, context, .. }|
		Picture.from_shapes(TruckAhead.truck_shapes(truck_ahead, { road: context.road, cam_focal }))

	## The truck, seen from `view`.
	truck_shapes : TruckAhead, Chain.Viewpoint -> List(Shapes.Shape)
	truck_shapes = |truck_ahead, view| {
		truck = {
			view,
			position: truck_ahead.position,
			box: TruckShape.truck_box({ along: truck_ahead.along, across: truck_ahead.across }),
		}
		beams =
			match truck_ahead.lights.headlights {
				On => TruckLights.headlight_beams(truck)
				Off => []
			}
		brake_lights =
			match truck_ahead.lights.brake_lights {
				On => TruckLights.brake_lights(truck)
				Off => []
			}
		[beams, TruckBody.body_shapes(truck), brake_lights].join()
	}
}
