## The Roc bird is roc-lang.org's logo, sitting on treetops beside the road
## and flying off as the rider comes. BirdFlight says where a bird is and how
## it looks, BirdSighting finds the birds in view, and BirdStills holds their
## drawings. This module says how big a bird is, and draws one.
import BirdFlight
import BirdStills
import Camera
import Critter
import Distance
import lib.Shapes

RocBird :: [].{

	## A bird placed in the rider's view: where it is, how high its feet are,
	## and how it looks.
	PlacedBird : {
		right : F64,
		forward : F64,
		lift : Distance,
		pose : BirdFlight.Pose,
	}

	## How tall a bird stands.
	bird_height : Distance
	bird_height = Distance.metres(2.2)

	## How tall a bird `forward` metres ahead is on screen.
	height_px : { forward : F64, cam_focal : F64 } -> F64
	height_px = |{ forward, cam_focal }| (bird_height.to_metres() / forward) * cam_focal

	## A bird on screen, its feet where it is. Its still is unflipped: a bird
	## from a left-hand tree crosses the road toward +x, the way its beak points.
	draw : RocBird.PlacedBird, F64 -> List(Shapes.Shape)
	draw = |bird, cam_focal| {
		feet = Camera.project(
			{
				right: bird.right,
				forward: bird.forward,
				height: bird.lift.to_metres(),
			},
			cam_focal,
		)
		Critter.draw_still(
			{
				feet,
				flip: AsDrawn,
				height_px: height_px({ forward: bird.forward, cam_focal }),
			},
			BirdStills.pose_polys(bird.pose),
		)
	}
}
