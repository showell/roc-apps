## Scene gathers what one frame shows beside the road: the trees, towers,
## critters, cats, guard rails, the truck and the birds in view, each kind
## found by its own sighting.
import Billboard
import BirdSighting
import CatSighting
import Clock
import Conifer
import BillboardSighting
import Distance
import Chain
import Geom
import GuardRail
import RailSighting
import Tower
import TowerSighting
import TreeSighting
import Truck
import TruckSighting
import BirdShapes
import Speed
import World

## The things in view, each kind in its own list.
Scene := {
	trees : List(Geom.Sighted(Conifer)),
	towers : List(Geom.Sighted(Tower)),
	critters : List(Geom.Sighted(Billboard)),
	cats : List(CatSighting),
	rails : List(GuardRail.RailQuad),
	truck : TruckSighting.TruckFate,
	birds : List(BirdSighting),
}.{

	## What the sightings read beyond the road: the rider's speed, where the
	## truck is and which of its lights are on, and the clock.
	RideFacts : {
		speed : Speed,
		truck : { route_position : Distance, lights : Truck.Lights },
		clock : Clock,
	}

	## Everything in view from `view`, each kind that has a cap cut to it.
	scene_in_view : Chain.Viewpoint, Scene.RideFacts -> Scene
	scene_in_view = |view, { speed, truck, clock }| {
		road = view.road
		trees = TreeSighting.trees_in_view(view)
		towers =
			TowerSighting.towers_in_view({ road, clock })
				.take_first(TowerSighting.max_visible_towers.to_u64_wrap())
		critters = BillboardSighting.critters_to_draw(BillboardSighting.critter_fates(road))
		cats = CatSighting.cats_in_view(view, speed)
		rails = RailSighting.rails_in_view(road)
		rider_distance = World.distance_along_route(
			road.route_segments,
			{ index: Chain.rider_segment(road), along: road.vantage.along },
		)
		truck_at = TruckSighting.truck_in_view({
			road,
			lead: truck.route_position.minus(rider_distance),
			lights: truck.lights,
		})
		birds = BirdSighting.birds_in_view(view)
		{
			trees,
			towers,
			critters,
			cats,
			rails,
			truck: truck_at,
			birds,
		}
	}
}

expect TowerSighting.max_visible_towers == 16
