## Render gathers what one frame shows beside the road: the trees, masts,
## critters, cats, guard rails, the truck and the birds in view, each kind
## found by its own plan, and the order to paint them in, far to near.
import Billboards
import BirdPlan
import CatPlan
import Clock
import CritterPlan
import DepthSort
import Frame
import GuardRail
import RailPlan
import TowerPlan
import TreePlan
import Truck
import TruckPlan
import RocBird
import Speed
import World

Render :: [].{

	## The things in view, each kind in its own list, and the depth order
	## that names each by its place in its list.
	Scene : {
		trees : List(TreePlan.TreeItem),
		towers : List(TowerPlan.TowerItem),
		critters : List(Billboards.Billboard),
		cats : List(CatPlan.CatItem),
		rails : List(GuardRail.RailPoly),
		truck : TruckPlan.TruckAt,
		birds : List(RocBird.PlacedBird),
		order : List(DepthSort.DepthKey),
	}

	## The ride at the frame's instant: the rider's speed, where the truck is
	## and which of its lights are on, and the clock.
	RideInstant : {
		speed : Speed,
		truck : { route_position : F64, lights : Truck.Lights },
		clock : Clock,
	}

	## Everything in view from `view`, each kind cut to its plan's cap.
	collect : Frame.Viewpoint, Render.RideInstant -> Render.Scene
	collect = |
		view,
		{
			speed,
			truck,
			clock,
		},
	| {
		road = view.road
		trees = TreePlan.in_view(view).take_first(TreePlan.max_vis_trees.to_u64_wrap())
		towers =
			TowerPlan.in_view({ road, clock })
				.take_first(TowerPlan.max_vis_towers.to_u64_wrap())
		critters =
			Billboards.billboards_in_view(CritterPlan.sightings(road))
				.take_first(CritterPlan.max_vis_critters.to_u64_wrap())
		cats = CatPlan.in_view(view, speed).take_first(CatPlan.max_vis_cats.to_u64_wrap())
		rails = RailPlan.all_rails(road)
		rider_distance = World.distance_along_route(
			road.world,
			{ index: Frame.rider_segment(road), along: road.pose.along },
		)
		truck_at = TruckPlan.in_view({
			road,
			lead: truck.route_position - rider_distance,
			lights: truck.lights,
		})
		birds = BirdPlan.in_view(view)
		# Keys about as far away as each other keep the order they are joined
		# in, so this order decides which of two tied things is painted over
		# the other.
		keys = [
			BirdPlan.depth_keys(birds),
			TreePlan.depth_keys(trees),
			TowerPlan.depth_keys(towers),
			CritterPlan.cow_items(critters),
			CatPlan.depth_keys(cats),
			TruckPlan.depth_keys(truck_at),
			RailPlan.depth_keys(rails),
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
