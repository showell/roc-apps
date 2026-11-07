## TruckAhead is the truck ahead on the road in a frame. Its picture is its
## headlight beams first, then its body, then its brake lights, so each paints
## over the one before.
import RoadAhead
import Picture
import TruckBody
import TruckLights
import TruckShape
import lib.Shapes

## Which of the truck's lights are on.
TruckAhead := { headlights : [On, Off], brake_lights : [On, Off] }.{

	is_eq : _

	## How the truck looks. Every point on it is measured on the road, so the
	## road and where its trailer is centred there are its context.
	scenery_picture : TruckAhead, Picture.Setting(RoadAhead.RoadContext) -> Picture
	scenery_picture = |truck_ahead, { cam_focal, context, .. }|
		Picture.from_shapes(
			truck_shapes(
				truck_ahead,
				{
					view: { road: context.road, cam_focal },
					place: context.place,
					box: TruckShape.truck_box({ along: context.along, across: context.across }),
				},
			),
		)
}

## The truck, filling its box.
truck_shapes : TruckAhead, TruckShape.TruckInView -> List(Shapes.Shape)
truck_shapes = |truck_ahead, truck| {
	beams =
		match truck_ahead.headlights {
			On => TruckLights.headlight_beams(truck)
			Off => []
		}
	brake_lights =
		match truck_ahead.brake_lights {
			On => TruckLights.brake_lights(truck)
			Off => []
		}
	[beams, TruckBody.body_shapes(truck), brake_lights].join()
}
