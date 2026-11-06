## Render gathers what one frame shows beside the road: the trees, masts,
## critters, cats, guard rails, the truck and the birds in view, each kind
## found by its own sighting, and the order to paint them in, far to near.
import Billboards
import BirdSighting
import CatSighting
import Clock
import CritterSighting
import DepthSort
import Distance
import Frame
import GuardRail
import RailSighting
import TowerSighting
import TreeSighting
import Truck
import TruckSighting
import RocBird
import Speed
import World

Render :: [].{

	## The things in view, each kind in its own list, and the depth order
	## that names each by its place in its list.
	Scene : {
		trees : List(TreeSighting.TreeItem),
		towers : List(TowerSighting.TowerItem),
		critters : List(Billboards.Billboard),
		cats : List(CatSighting.CatItem),
		rails : List(GuardRail.RailPoly),
		truck : TruckSighting.TruckAt,
		birds : List(RocBird.PlacedBird),
		order : List(DepthSort.DepthKey),
	}

	## What the sightings read beyond the road: the rider's speed, where the
	## truck is and which of its lights are on, and the clock.
	MovingParts : {
		speed : Speed,
		truck : { route_position : Distance, lights : Truck.Lights },
		clock : Clock,
	}

	## Everything in view from `view`, each kind cut to its sighting's cap.
	collect : Frame.Viewpoint, Render.MovingParts -> Render.Scene
	collect = |view, { speed, truck, clock }| {
		road = view.road
		trees = TreeSighting.in_view(view).take_first(TreeSighting.max_vis_trees.to_u64_wrap())
		towers =
			TowerSighting.in_view({ road, clock })
				.take_first(TowerSighting.max_vis_towers.to_u64_wrap())
		critters =
			Billboards.billboards_in_view(CritterSighting.sightings(road))
				.take_first(CritterSighting.max_vis_critters.to_u64_wrap())
		cats = CatSighting.in_view(view, speed).take_first(CatSighting.max_vis_cats.to_u64_wrap())
		rails = RailSighting.all_rails(road)
		rider_distance = World.distance_along_route(
			road.world,
			{ index: Frame.rider_segment(road), along: road.pose.along },
		)
		truck_at = TruckSighting.in_view({
			road,
			lead: truck.route_position.minus(rider_distance),
			lights: truck.lights,
		})
		birds = BirdSighting.in_view(view)
		# Keys about as far away as each other keep the order they are joined
		# in, so this order decides which of two tied things is painted over
		# the other.
		keys = [
			BirdSighting.depth_keys(birds),
			TreeSighting.depth_keys(trees),
			TowerSighting.depth_keys(towers),
			CritterSighting.cow_items(critters),
			CatSighting.depth_keys(cats),
			TruckSighting.depth_keys(truck_at),
			RailSighting.depth_keys(rails),
		].join()
		{
			trees,
			towers,
			critters,
			cats,
			rails,
			truck: truck_at,
			birds,
			order: DepthSort.sort_by(keys, |key| key.forward),
		}
	}
}

expect TreeSighting.max_vis_trees == 640
expect TowerSighting.max_vis_towers == 16
expect CatSighting.max_vis_cats == 8
