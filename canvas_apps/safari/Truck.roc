## Truck is the truck as the scene draws it this frame: its lights' states, and
## its picture. Its picture is its headlight beams first, then its body, then
## its brake lights, so each paints over the one before.
import Picture
import TruckBody
import TruckBrakeLights
import TruckHeadlights
import TruckShape

## Which of the truck's lights are on.
Truck := { headlights : TruckHeadlights, brake_lights : TruckBrakeLights }.{

	is_eq : _

	## How the truck looks. Every point on it is measured on the road, from where
	## its trailer is centered, and seen from the camera's vantage, so those are
	## its context.
	scenery_picture : Truck, TruckShape.TruckSetting -> Picture
	scenery_picture = |truck, setting|
		Picture.composite([
			truck.headlights.picture(setting),
			TruckBody.body_picture(setting),
			truck.brake_lights.picture(setting),
		])
}
