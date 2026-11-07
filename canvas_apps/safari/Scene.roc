## Scene gathers what one frame shows beside the road: the trees, towers,
## billboards, cats, guard rails, the truck and the birds in view, each kind
## found by its own sighting.
import Billboard
import Clock
import EncounterSighting
import Conifer
import BillboardSighting
import Distance
import Geom
import RoadAhead
import GuardRail
import Pipeline
import Pixels
import PosedBird
import PosedCat
import RailSighting
import Tower
import TowerSighting
import TreeSighting
import LitTruck
import TruckSighting
import Speed

## The things in view, each kind in its own list.
Scene := {
	trees : List(Pipeline.Sighted(Conifer)),
	towers : List(Pipeline.Sighted(Tower)),
	billboards : List(Pipeline.Sighted(Billboard)),
	cats : List(Pipeline.Sighted(PosedCat)),
	rails : List(GuardRail.RailQuad),
	truck : TruckSighting.TruckFate,
	birds : List(Pipeline.Sighted(PosedBird)),
}.{

	## What the sightings read beyond the road: the rider's speed, where the
	## truck is and how it looks, and the clock.
	RideFacts : {
		speed : Speed,
		truck : { route_position : Distance, lit_truck : LitTruck },
		clock : Clock,
	}

	## Everything `camera` sees of `road`.
	scene_in_view : RoadAhead.RoadView,
	{
		camera : { vantage : Geom.Vantage, cam_focal : Pixels, .. },
		facts : Scene.RideFacts,
	} -> Scene
	scene_in_view = |road, { camera, facts }| {
		trees = TreeSighting.trees_in_view(road, camera)
		towers = TowerSighting.towers_in_view(road, { camera, clock: facts.clock })
		billboards = BillboardSighting.billboards_in_view(road, camera)
		cats = EncounterSighting.cats_in_view(road, { camera, speed: facts.speed })
		rails = RailSighting.rail_quads_in_view(road, camera)
		truck_at = TruckSighting.truck_in_view(
			road,
			{
				camera,
				route_position: facts.truck.route_position,
				lit_truck: facts.truck.lit_truck,
			},
		)
		birds = EncounterSighting.birds_in_view(road, camera)
		{
			trees,
			towers,
			billboards,
			cats,
			rails,
			truck: truck_at,
			birds,
		}
	}
}
