## The cat as the scene draws it this frame: how it holds itself. It draws as
## the still for its pose, its feet at its spot, raised as high as the spot
## says while it leaps. Its poses and its height are the ride's, in
## CatCrossing.
import CatCrossing
import CatStills
import Distance
import Picture
import StillShapes
import Still

Cat := { pose : CatCrossing.CatPose }.{

	scenery_height : Cat -> Distance
	scenery_height = |_cat| CatCrossing.cat_height

	## A cat on screen, its feet where it is.
	scenery_picture : Cat, Picture.Setting({}) -> Picture
	scenery_picture = |cat, setting|
		Picture.from_shapes(
			StillShapes.standing_still_shapes(
				setting,
				{
					height: CatCrossing.cat_height,
					still: Cat.pose_still(cat.pose),
					flip: AsDrawn,
				},
			),
		)

	## The cat's still in a pose.
	pose_still : CatCrossing.CatPose -> Still
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

	## A pose's name, as a widget captions it.
	pose_name : CatCrossing.CatPose -> Str
	pose_name = |pose|
		match pose {
			Rest => "Rest"
			Stride => "Stride"
			Frozen => "Frozen"
			Coil => "Coil"
			Flight => "Flight"
			Land => "Land"
			Collapse => "Collapse"
		}
}

expect
	[
		(Rest, "Rest"),
		(Stride, "Stride"),
		(Frozen, "Frozen"),
		(Coil, "Coil"),
		(Flight, "Flight"),
		(Land, "Land"),
		(Collapse, "Collapse"),
	].all(|(pose, name)| Cat.pose_name(pose) == name)
