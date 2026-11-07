## Scene gathers what one frame shows beside the road: the trees, towers,
## billboards, cats, guard rails, the truck and the birds in view, each kind
## found by its own sighting.
import Billboard
import Clock
import EncounterSighting
import Conifer
import BillboardSighting
import Distance
import RoadAhead
import GuardRail
import Pipeline
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

	## Everything in view from `view`.
	scene_in_view : RoadAhead.CameraView, Scene.RideFacts -> Scene
	scene_in_view = |view, { speed, truck, clock }| {
		road = view.road
		trees = TreeSighting.trees_in_view(view)
		towers = TowerSighting.towers_in_view(road, clock)
		billboards = BillboardSighting.billboards_in_view(road)
		cats = EncounterSighting.cats_in_view(view, speed)
		rails = RailSighting.rails_in_view(road)
		truck_at = TruckSighting.truck_in_view(road, truck)
		birds = EncounterSighting.birds_in_view(view)
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
