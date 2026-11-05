## TruckDraw draws the truck ahead on the road: its headlight beams first,
## then its body, then its brake lights, so each paints over the one before.
import Frame
import Truck
import TruckBody
import TruckLights
import TruckShape
import lib.Shapes

TruckDraw :: [].{

	## The truck on the segment at `position` in the chain, seen from `view`,
	## with its trailer centred at `center` on that segment.
	draw : {
		view : Frame.Viewpoint,
		position : Frame.ChainPosition,
		center : { along : F64, across : F64 },
		lights : Truck.Lights,
	} -> List(Shapes.Shape)
	draw = |
		{
			view,
			position,
			center,
			lights,
		},
	| {
		truck = {
			view,
			position,
			box: TruckShape.truck_box(center),
		}
		beams =
			match lights.headlights {
				On => TruckLights.headlight_beams(truck)
				Off => []
			}
		brake_lights =
			match lights.brake_lights {
				On => TruckLights.brake_lights(truck)
				Off => []
			}
		[
			beams,
			TruckBody.draw(truck),
			brake_lights,
		].join()
	}
}
