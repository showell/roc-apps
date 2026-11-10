## Truck is the truck as the scene draws it this frame: its lights' states, and
## its sprite. Its sprite is its headlight beams first, then its body, then
## its brake lights, so each paints over the one before. It is worked out each
## frame from the clock and the truck's progress.
import Sprite
import Spot
import TruckBody
import TruckBrakeLights
import TruckHeadlights

## Which of the truck's lights are on.
Truck := { headlights : TruckHeadlights, brake_lights : TruckBrakeLights }.{

	is_eq : _

	## The truck as the camera sees it in one frame: where it stands, and which
	## of its lights are on.
	SightedTruck : { spot : Spot, lights : Truck }

	## How the truck looks from its sighting, through the frame's lens and in
	## its light. The lens and the light are passed beside the sighting, as
	## every sighting's are: a sighting says where a thing is, and the frame
	## draws it.
	truck_sprite : Truck.SightedTruck, Sprite.LensAndLight -> Sprite
	truck_sprite = |{ spot, lights }, { focal_length, darkness }| {
		setting = { spot, focal_length, darkness }
		Sprite.composite([
			lights.headlights.sprite(setting),
			TruckBody.body_sprite(setting),
			lights.brake_lights.sprite(setting),
		])
	}
}
