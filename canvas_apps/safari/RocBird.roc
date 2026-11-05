## The Roc bird is roc-lang.org's logo, sitting on treetops beside the road
## and flying off as the rider comes. BirdFlight says where a bird is and how
## it looks, BirdPlan finds the birds in view, and BirdStills holds their
## drawings. This module says how big a bird is, and draws one.
import BirdFlight
import BirdStills
import Camera
import Critter
import lib.Shapes

RocBird :: [].{

	## A bird placed in the rider's view: where it is, how high its feet are,
	## and how it looks.
	PlacedBird : {
		right : F64,
		forward : F64,
		lift : F64,
		pose : BirdFlight.Pose,
	}

	## How tall a bird stands, in metres.
	bird_height : F64
	bird_height = 2.2

	## How tall a bird `forward` metres ahead is on screen.
	height_px : { forward : F64, cam_focal : F64 } -> F64
	height_px = |{ forward, cam_focal }| (bird_height / forward) * cam_focal

	## A bird on screen, its feet where it is. Its still is unflipped: a bird
	## from a left-hand tree crosses the road toward +x, the way its beak points.
	draw : RocBird.PlacedBird, Camera.View -> List(Shapes.Shape)
	draw = |bird, camera| {
		feet = Camera.project(
			{
				right: bird.right,
				forward: bird.forward,
				height: bird.lift,
			},
			camera,
		)
		Critter.draw_still(
			{
				feet,
				flip: AsDrawn,
				height_px: height_px({ forward: bird.forward, cam_focal: camera.cam_focal }),
			},
			BirdStills.pose_polys(bird.pose),
		)
	}
}
