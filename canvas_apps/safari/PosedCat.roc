## A cat at one moment of its crossing: how it holds itself. It draws as the
## still for its pose, its feet at its spot, raised as high as the spot says
## while it leaps.
import CatStills
import Distance
import Picture
import StillShapes
import Still

PosedCat := { pose : PosedCat.CatPose }.{

	## How the cat holds itself: walking, it is at rest or mid-stride; then
	## frozen; then its leap, from the coil through flight and landing to the
	## collapse after.
	CatPose : [Rest, Stride, Frozen, Coil, Flight, Land, Collapse]

	cat_height : Distance
	cat_height = Distance.metres(1.7)

	scenery_height : PosedCat -> Distance
	scenery_height = |_cat| PosedCat.cat_height

	## A cat on screen, its feet where it is.
	scenery_picture : PosedCat, Picture.Setting({}) -> Picture
	scenery_picture = |cat, setting|
		Picture.from_shapes(
			StillShapes.standing_still_shapes(
				setting,
				{ height: PosedCat.cat_height, still: PosedCat.pose_still(cat.pose) },
			),
		)

	## The cat's still in a pose.
	pose_still : PosedCat.CatPose -> Still
	pose_still = |pose|
		match pose {
			Rest => CatStills.rest_still
			Stride => CatStills.stride_still
			Frozen => CatStills.frozen_still
			Coil => CatStills.coil_still
			Flight => CatStills.flight_still
			Land => CatStills.land_still
			Collapse => CatStills.collapse_still
		}
}
