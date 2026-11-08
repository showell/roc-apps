## The Roc bird as the scene draws it this frame: how it looks. The Roc bird is
## roc-lang.org's logo, sitting on treetops beside the road and flying off as
## the rider comes. BirdFlight says where a bird is and how it looks,
## EncounterSighting finds the birds in view, and BirdStills holds their
## drawings.
import BirdStills
import Picture
import StillShapes
import Still
import Distance

Bird := { pose : Bird.BirdPose }.{

	## Where the wings are in a beat.
	WingBeat : [WingsUp, WingsDown]

	## How the bird looks: sitting; side on as it takes off; seen from behind
	## as it flies off; and dropping onto its tree.
	BirdPose : [
		Perched,
		Side(Bird.WingBeat),
		Away(Bird.WingBeat),
		Diving,
	]

	scenery_height : Bird -> Distance
	scenery_height = |_bird| bird_height

	## A bird on screen, its feet where it is.
	scenery_picture : Bird, Picture.Setting({}) -> Picture
	scenery_picture = |bird, setting|
		Picture.from_shapes(
			# As drawn, never mirrored: BirdFlight's `is_far_side` says why.
			StillShapes.standing_still_shapes(
				setting,
				{ height: bird_height, still: Bird.pose_still(bird.pose) },
			),
		)

	## The drawing for a pose.
	pose_still : Bird.BirdPose -> Still
	pose_still = |pose|
		match pose {
			Perched => BirdStills.perched_still
			Side(WingsUp) => BirdStills.side_wings_up_still
			Side(WingsDown) => BirdStills.side_wings_down_still
			Away(WingsUp) => BirdStills.away_wings_up_still
			Away(WingsDown) => BirdStills.away_wings_down_still
			Diving => BirdStills.diving_still
		}
}

## How tall a bird stands, chosen by eye.
bird_height : Distance
bird_height = Distance.metres(2.2)
