## EncounterSighting finds the animals the camera can see in a frame: each cat
## and Roc bird of `EncountersAhead`, already placed where its crossing or
## flight has got to, if it is in front of the camera and tall enough on screen
## to draw.
import Distance
import EncountersAhead
import RoadAhead
import Geom
import Pipeline
import Pixels
import PosedBird
import PosedCat

EncounterSighting :: [].{

	## The cats of `encounters` in view, in their order.
	cats_in_view : RoadAhead.RoadView,
	{
		camera : { vantage : Geom.Vantage, cam_focal : Pixels, .. },
		encounters : EncountersAhead,
	} -> List(Pipeline.Sighted(PosedCat))
	cats_in_view = |road, { camera, encounters }|
		encounters.cats.keep_oks(|cat| animal_in_view(road, { camera, animal: cat }))

	## The birds of `encounters` in view, in their order.
	birds_in_view : RoadAhead.RoadView,
	{
		camera : { vantage : Geom.Vantage, cam_focal : Pixels, .. },
		encounters : EncountersAhead,
	} -> List(Pipeline.Sighted(PosedBird))
	birds_in_view = |road, { camera, encounters }|
		encounters.birds.keep_oks(|bird| animal_in_view(road, { camera, animal: bird }))
}

## `animal` as the camera sees it, if it is in view.
animal_in_view : RoadAhead.RoadView,
{
	camera : { vantage : Geom.Vantage, cam_focal : Pixels, .. },
	animal : EncountersAhead.AnimalAhead(kind),
} -> Try(Pipeline.Sighted(kind), [BehindCamera, TooSmall])
	where [kind.scenery_height : kind -> Distance]
animal_in_view = |road, { camera, animal }|
	Pipeline.scenery_sighting_of(animal.placed, { road, camera, place: animal.place })
