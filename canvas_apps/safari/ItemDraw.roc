## ItemDraw paints the things beside the road in depth order, far to near,
## each by its own kind's module.
import CatDraw
import CatPlan
import Critter
import DepthSort
import Frame
import GuardRail
import Render
import SceneLimits
import Tower
import TowerPlan
import Tree
import TreePlan
import TruckDraw
import TruckPlan
import RocBird
import lib.Shapes

ItemDraw :: [].{

	## A tree with fewer than this many trees nearer than it gets a round
	## trunk.
	round_trunk_limit : U32
	round_trunk_limit = 4

	## The scene's things, painted far to near.
	draw : Render.Scene, Frame.Viewpoint -> List(Shapes.Shape)
	draw = |scene, view|
		scene.order.join_map(|depth_key| draw_subject(scene, { view, depth_key }))

	## How many of `trees` are nearer than `forward`.
	nearer_tree_count : List(TreePlan.TreeItem), F64 -> U32
	nearer_tree_count = |trees, forward|
		trees.count_if(|tree| tree.forward < forward).to_u32_wrap()

	## How much a crown is shaded at distance `forward`: fully at the camera,
	## falling evenly to none at SceneLimits.crown_shade_dist.
	crown_shade : F64 -> F64
	crown_shade = |forward| {
		raw = (1.0 - (forward / SceneLimits.crown_shade_dist))
		if (raw < 0.0) 0.0 else if (raw > 1.0) 1.0 else raw
	}

	## A tree, drawn in more detail the nearer it is: its trunk is round when
	## few of `trees` are nearer, and its crown is cones when it is nearer
	## than SceneLimits.detail_dist.
	draw_tree : TreePlan.TreeItem,
	{
		trees : List(TreePlan.TreeItem),
		cam_focal : F64,
	} -> List(Shapes.Shape)
	draw_tree = |tree, { trees, cam_focal }| {
		nearer_trees = ItemDraw.nearer_tree_count(trees, tree.forward)
		Tree.draw({
			right: tree.right,
			forward: tree.forward,
			height: tree.height,
			color: tree.color,
			cam_focal,
			trunk: if (nearer_trees < ItemDraw.round_trunk_limit) RoundCorners else SharpCorners,
			crown: if (tree.forward < SceneLimits.detail_dist) Cones else Triangles,
			shade: ItemDraw.crown_shade(tree.forward),
		})
	}

	## Where a mast's four footprint corners stand in the rider's view.
	tower_footprint : Frame.Viewpoint, TowerPlan.TowerItem -> Tower.Footprint
	tower_footprint = |view, tower| {
		corner_point = |corner| {
			on_road = Tower.base_corner_on_road(
				corner,
				{
					along: tower.along,
					across: tower.across,
					yaw: tower.yaw,
				},
			)
			Frame.rider_point_at(
				view.road,
				{
					place: tower.place,
					along: on_road.along,
					across: on_road.across,
				},
			)
		}
		{
			back_left: corner_point(BackLeft),
			back_right: corner_point(BackRight),
			front_right: corner_point(FrontRight),
			front_left: corner_point(FrontLeft),
		}
	}

	## A mast, its beacon as bright as its plan says.
	draw_tower : Frame.Viewpoint, TowerPlan.TowerItem -> List(Shapes.Shape)
	draw_tower = |view, tower|
		Tower.draw({
			footprint: ItemDraw.tower_footprint(view, tower),
			center: Frame.rider_point_at(
				view.road,
				{
					place: tower.place,
					along: tower.along,
					across: tower.across,
				},
			),
			cam_focal: view.cam_focal,
			beacon_brightness: tower.beacon_brightness,
		})
}

## One thing in the depth order, looked up in its kind's list and drawn.
draw_subject : Render.Scene,
{
	view : Frame.Viewpoint,
	depth_key : DepthSort.DepthKey,
} -> List(Shapes.Shape)
draw_subject = |scene, { view, depth_key }| {
	cam_focal = view.cam_focal
	match depth_key.subject {
		Tree(place) =>
			ItemDraw.draw_tree(
				thing_at(scene.trees, place),
				{ trees: scene.trees, cam_focal },
			)
		Tower(place) => ItemDraw.draw_tower(view, thing_at(scene.towers, place))
		Rail(place) => GuardRail.draw(thing_at(scene.rails, place), cam_focal)
		Critter(place) => Critter.draw(thing_at(scene.critters, place), cam_focal)
		Cat(place) => draw_cat(thing_at(scene.cats, place), cam_focal)
		Truck => draw_truck(view, scene.truck)
		Bird(place) => RocBird.draw(thing_at(scene.birds, place), cam_focal)
	}
}

## The thing at `place` in its kind's list.
thing_at : List(thing), U32 -> thing
thing_at = |things, place|
	things.get(place.to_u64())
		?? crash "ItemDraw.thing_at: the depth order names only places in its lists"

draw_cat : CatPlan.CatItem, F64 -> List(Shapes.Shape)
draw_cat = |cat, cam_focal|
	CatDraw.draw({
		right: cat.right,
		forward: cat.forward,
		height: cat.height,
		pose: cat.pose,
		lift: cat.lift,
		cam_focal,
	})

## The truck, where its plan found it and with the lights its plan gives it.
draw_truck : Frame.Viewpoint, TruckPlan.TruckAt -> List(Shapes.Shape)
draw_truck = |view, truck_at|
	match truck_at {
		Ahead(truck) =>
			TruckDraw.draw({
				view,
				position: truck.position,
				center: { along: truck.along, across: truck.across },
				lights: truck.lights,
			})
		NoTruck => crash "ItemDraw.draw_truck: the truck is in the depth order only in view"
	}
