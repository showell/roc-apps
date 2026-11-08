## Truck is the truck as the scene draws it this frame: its lights' states, and
## its picture. Its picture is its headlight beams first, then its body, then
## its brake lights, so each paints over the one before.
import Angle
import Picture
import Pixels
import Spot
import TruckBody
import TruckBrakeLights
import TruckHeadlights

## Which of the truck's lights are on.
Truck := { headlights : TruckHeadlights, brake_lights : TruckBrakeLights }.{

	is_eq : _

	## The truck as the camera sees it in one frame: where its foot stands,
	## which way it heads against the camera, and which of its lights are on.
	SightedTruck : {
		spot : Spot,
		heading : Angle.Turn,
		lights : Truck,
	}

	## How the truck looks from its sighting, through a lens of
	## `focal_length`. The lens is passed beside the sighting, as every
	## sighting's is: a sighting says where a thing is, and the frame's lens
	## draws it.
	truck_picture : Truck.SightedTruck, Pixels -> Picture
	truck_picture = |{ spot, heading, lights }, focal_length| {
		setting = { spot, heading, focal_length }
		Picture.composite([
			lights.headlights.picture(setting),
			TruckBody.body_picture(setting),
			lights.brake_lights.picture(setting),
		])
	}
}
