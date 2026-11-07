## LitTruck is how the truck on the road looks in a frame: which of its lights
## are on. Its picture is its headlight beams first, then its body, then its
## brake lights, so each paints over the one before.
import RoadAhead
import Picture
import TruckBody
import TruckLights
import TruckShape
import lib.Shapes

## Which of the truck's lights are on.
LitTruck := { headlights : [On, Off], brake_lights : [On, Off] }.{

	is_eq : _

	## How the truck looks. Every point on it is measured on the road, from where
	## its trailer is centred, so the road is its context.
	scenery_picture : LitTruck, Picture.Setting(RoadAhead.RoadView) -> Picture
	scenery_picture = |lit_truck, { spot, cam_focal, context: road }| {
		box = TruckShape.truck_box(spot.road_point())
		Picture.from_shapes(truck_shapes(lit_truck, { spot, cam_focal, context: { road, box } }))
	}
}

## The truck, filling its box.
truck_shapes : LitTruck, Picture.Setting(TruckShape.TruckOnRoad) -> List(Shapes.Shape)
truck_shapes = |lit_truck, truck| {
	beams =
		match lit_truck.headlights {
			On => TruckLights.headlight_beams(truck)
			Off => []
		}
	brake_lights =
		match lit_truck.brake_lights {
			On => TruckLights.brake_lights(truck)
			Off => []
		}
	[beams, TruckBody.body_shapes(truck), brake_lights].join()
}
