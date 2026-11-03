## TruckDraw draws the truck ahead on the road: its headlight beams first,
## then its body, then its brake lights, so each paints over the one before.
import Paint
import TruckBody
import TruckLights
import TruckShape

TruckDraw :: [].{

	## Which of the truck's lights are on.
	Lights : { headlights : [On, Off], brake_lights : [On, Off] }

	## The truck whose trailer is centred at `center` on `road`.
	draw : { road : TruckShape.Road, center : { along : F64, across : F64 }, lights : TruckDraw.Lights, cam_focal : F64, view_w : F64 } -> List(Paint.DrawCmd)
	draw = |{ road, center, lights, cam_focal, view_w }| {
		truck = { road, box: TruckShape.truck_box(center), cam_focal, view_w }
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
		List.join([beams, TruckBody.draw(truck), brake_lights])
	}
}
