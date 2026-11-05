## TruckDraw draws the truck ahead on the road: its headlight beams first,
## then its body, then its brake lights, so each paints over the one before.
import Truck
import TruckBody
import TruckLights
import TruckShape
import lib.Shapes

TruckDraw :: [].{

	## The truck whose trailer is centred at `center` on `road`.
	draw : {
		road : TruckShape.Road,
		center : { along : F64, across : F64 },
		lights : Truck.Lights,
		cam_focal : F64,
	} -> List(Shapes.Shape)
	draw = |
		{
			road,
			center,
			lights,
			cam_focal,
		},
	| {
		truck = {
			road,
			box: TruckShape.truck_box(center),
			cam_focal,
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
		List.join([
			beams,
			TruckBody.draw(truck),
			brake_lights,
		])
	}
}
