## EncounterSighting finds the animals the camera can see in a frame: each cat
## and Roc bird that `EncounterPoses` has placed, if it is in front of the
## camera and tall enough on screen to draw. Where an animal stands and how it is
## posed is decided before any camera looks; this is only the camera's part.
import Distance
import EncounterPoses
import Geom
import Pipeline
import Pixels
import RoadAhead

EncounterSighting :: [].{

	## Those of `animals` the camera sees, in their order.
	animals_in_view : RoadAhead.RoadView,
	{
		camera : { vantage : Geom.Vantage, cam_focal : Pixels, .. },
		animals : List(EncounterPoses.PosedAnimal(kind)),
	} -> List(Pipeline.Sighted(kind))
		where [kind.scenery_height : kind -> Distance]
	animals_in_view = |road, { camera, animals }|
		animals.keep_oks(
			|posed| {
				seen_on = { road, camera, place: posed.place }
				Pipeline.scenery_sighting_of(posed.animal, seen_on)
			},
		)
}
