## Scene gathers what one frame shows beside the road: the trees, towers,
## cutouts, cats, guard rails, the truck and the birds in view, each kind
## found by its own sighting, and the order to paint them in, far to near.
import Cutouts
import BirdSighting
import CatSighting
import Clock
import CutoutSighting
import DepthSort
import Distance
import Chain
import GuardRail
import RailSighting
import TowerSighting
import TreeSighting
import Truck
import TruckSighting
import BirdDraw
import Speed
import World

## The things in view, each kind in its own list, and the depth order
## that names each by its place in its list.
Scene := {
	trees : List(TreeSighting),
	towers : List(TowerSighting),
	cutouts : List(Cutouts.Cutout),
	cats : List(CatSighting),
	rails : List(GuardRail.RailQuad),
	truck : TruckSighting,
	birds : List(BirdSighting),
	order : List(DepthSort.DepthKey),
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
		cutouts =
			Cutouts.cutouts_in_view(CutoutSighting.critter_placements(road))
				.take_first(CutoutSighting.max_visible_cutouts.to_u64_wrap())
		cats = CatSighting.cats_in_view(view, speed)
		rails = RailSighting.rails_in_view(road)
		rider_distance = World.distance_along_route(
			road.route,
			{ index: Chain.rider_segment(road), along: road.vantage.along },
		)
		truck_at = TruckSighting.truck_in_view({
			road,
			lead: truck.route_position.minus(rider_distance),
			lights: truck.lights,
		})
		birds = BirdSighting.birds_in_view(view)
		# Keys about as far away as each other keep the order they are joined
		# in, so this order decides which of two tied things is painted over
		# the other.
		keys = [
			BirdSighting.depth_keys(birds),
			TreeSighting.depth_keys(trees),
			TowerSighting.depth_keys(towers),
			CutoutSighting.depth_keys(cutouts),
			CatSighting.depth_keys(cats),
			TruckSighting.depth_keys(truck_at),
			RailSighting.depth_keys(rails),
		].join()
		{
			trees,
			towers,
			cutouts,
			cats,
			rails,
			truck: truck_at,
			birds,
			order: DepthSort.sort_by(keys, |key| key.forward),
		}
	}
}

expect TowerSighting.max_visible_towers == 16
