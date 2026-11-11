## Truck is the truck as the scene draws it this frame: its lights' states, and
## its sprite. Its sprite is its headlight beams first, then its body, then
## its brake lights, so each paints over the one before. It is worked out each
## frame from the clock and the truck's progress.
import Sprite
import TruckBody
import TruckBrakeLights
import TruckHeadlights

## Which of the truck's lights are on.
Truck := { headlights : TruckHeadlights, brake_lights : TruckBrakeLights }.{

	is_eq : _

	## How the truck looks in `setting`: its beams, its body, then its brake
	## lights.
	scenery_sprite : Truck, Sprite.Setting -> Sprite
	scenery_sprite = |truck, setting|
		Sprite.composite([
			truck.headlights.sprite(setting),
			TruckBody.body_sprite(setting),
			truck.brake_lights.sprite(setting),
		])
}
