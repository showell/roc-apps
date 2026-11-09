## EncounterSighting finds the animals the camera can see in a frame: each cat
## and Roc bird that `EncounterPoses` has placed, if it is in front of the
## camera and tall enough on screen to draw. Where an animal stands and how it is
## posed is decided before any camera looks; this is only the camera's part.
## The sightings are worked out each frame from the rider's camera, the route,
## the encounter plan and the clock.
import Animation
import Distance
import EncounterPoses
import Pipeline
import Bird
import Cat
import RoadAhead

EncounterSighting :: [].{

	## The cats on `road` the camera sees, with the encounter on the rider's
	## segment at `encounter_stage`, in the order of `RoadAhead.segments_in_view`.
	cats_in_view : RoadAhead.RoadView,
	{
		camera : Pipeline.SightingCamera,
		encounter_stage : Animation.Stage,
	} -> List(Pipeline.Sighted(Cat))
	cats_in_view = |road, { camera, encounter_stage }|
		animals_in_view(road, { camera, animals: EncounterPoses.cat_poses(road, encounter_stage) })

	## The birds on `road` the camera sees, with the encounter on the rider's
	## segment at `encounter_stage`, in the order of `RoadAhead.segments_in_view`.
	birds_in_view : RoadAhead.RoadView,
	{
		camera : Pipeline.SightingCamera,
		encounter_stage : Animation.Stage,
	} -> List(Pipeline.Sighted(Bird))
	birds_in_view = |road, { camera, encounter_stage }|
		animals_in_view(road, { camera, animals: EncounterPoses.bird_poses(road, encounter_stage) })
}

## Those of `animals` the camera sees, in their order.
animals_in_view : RoadAhead.RoadView,
{
	camera : Pipeline.SightingCamera,
	animals : List(EncounterPoses.PlacedAnimal(kind)),
} -> List(Pipeline.Sighted(kind))
	where [kind.scenery_height : kind -> Distance]
animals_in_view = |road, { camera, animals }|
	animals.keep_oks(
		|posed| {
			seen_on = { road, camera, place: posed.place }
			Pipeline.scenery_sighting_of(posed.animal, seen_on)
		},
	)
