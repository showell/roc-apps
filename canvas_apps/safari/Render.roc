## Render gathers what one frame shows beside the road: the trees, masts,
## critters, cats, guard rails, the truck and the birds in view, each kind
## found by its own plan, and the order to paint them in, far to near.
import Billboards
import BirdPlan
import CatPlan
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

	## Where the frame is seen from: the world, the chain of segments ahead
	## (indexes into `world`, the rider's own first), the rider's pose, the
	## camera's focal length, where along the route the rider is, where the
	## truck is and which of its lights are on, and the ride's clock.
	Viewpoint : {
		world : List(World.Segment),
		chain : List(World.SegmentIndex),
		pose : Frame.Pose,
		cam_focal : F64,
		rider_segment : World.SegmentIndex,
		rider_along : F64,
		speed : Speed,
		truck : { route_position : F64, lights : Truck.Lights },
		clock : F64,
	}

	## Everything in view from `viewpoint`, each kind cut to its plan's cap.
	collect : Render.Viewpoint -> Render.Scene
	collect = |
		{
			world,
			chain,
			pose,
			cam_focal,
			rider_segment,
			rider_along,
			speed,
			truck,
			clock,
		},
	| {
		road = {
			world,
			chain,
			pose,
		}
		trees =
			TreePlan.in_view({
				world,
				chain,
				pose,
				cam_focal,
			})
				.take_first(TreePlan.max_vis_trees.to_u64_wrap())
		towers =
			TowerPlan.in_view({
				world,
				chain,
				pose,
				rider_segment,
				clock,
			})
				.take_first(TowerPlan.max_vis_towers.to_u64_wrap())
		critters =
			Billboards.billboards_in_view(CritterPlan.sightings(road, rider_segment))
				.take_first(CritterPlan.max_vis_critters.to_u64_wrap())
		cats =
			CatPlan.in_view({
				world,
				chain,
				pose,
				cam_focal,
				rider_along,
				speed,
			})
				.take_first(CatPlan.max_vis_cats.to_u64_wrap())
		rails = RailPlan.all_rails(road, rider_segment)
		rider_distance = World.distance_along_route(
			world,
			{ index: rider_segment, along: rider_along },
		)
		truck_at = TruckPlan.in_view({
			world,
			chain,
			pose,
			rider_along,
			lead: truck.route_position - rider_distance,
			lights: truck.lights,
		})
		birds = BirdPlan.in_view({
			world,
			chain,
			pose,
			cam_focal,
			rider_along,
		})
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
