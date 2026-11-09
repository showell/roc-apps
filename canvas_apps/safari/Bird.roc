## The Roc bird as the scene draws it this frame: how it looks. The Roc bird is
## roc-lang.org's logo, sitting on treetops beside the road and flying off as
## the rider comes. BirdFlight says where a bird is and how it looks,
## EncounterSighting finds the birds in view, and BirdStills holds their
## drawings. Its pose is worked out each frame from the encounter plan and the
## clock.
import BirdFlight
import BirdStills
import Sprite
import StillShapes
import Still
import Distance

Bird := { pose : BirdFlight.BirdPose }.{

	scenery_height : Bird -> Distance
	scenery_height = |_bird| bird_height

	## A bird on screen, its feet where it is.
	scenery_sprite : Bird, Sprite.Setting({}) -> Sprite
	scenery_sprite = |bird, setting|
		Sprite.from_shapes(
			# As drawn, never mirrored: BirdFlight's `is_far_side` says why.
			StillShapes.standing_still_shapes(
				setting,
				{
					height: bird_height,
					still: Bird.pose_still(bird.pose),
					flip: AsDrawn,
				},
			),
		)

	## The drawing for a pose.
	pose_still : BirdFlight.BirdPose -> Still
	pose_still = |pose|
		match pose {
			Perched => BirdStills.perched_still
			Side(WingsUp) => BirdStills.side_wings_up_still
			Side(WingsDown) => BirdStills.side_wings_down_still
			Away(WingsUp) => BirdStills.away_wings_up_still
			Away(WingsDown) => BirdStills.away_wings_down_still
			Diving => BirdStills.diving_still
		}

	## A pose's name, as a widget captions it.
	pose_name : BirdFlight.BirdPose -> Str
	pose_name = |pose|
		match pose {
			Perched => "Perched"
			Side(WingsUp) => "Side on, wings up"
			Side(WingsDown) => "Side on, wings down"
			Away(WingsUp) => "Flying away, wings up"
			Away(WingsDown) => "Flying away, wings down"
			Diving => "Diving"
		}
}

expect
	[
		(Perched, "Perched"),
		(Side(WingsUp), "Side on, wings up"),
		(Side(WingsDown), "Side on, wings down"),
		(Away(WingsUp), "Flying away, wings up"),
		(Away(WingsDown), "Flying away, wings down"),
		(Diving, "Diving"),
	].all(|(pose, name)| Bird.pose_name(pose) == name)

## How tall a bird stands, chosen by eye.
bird_height : Distance
bird_height = Distance.metres(2.2)
