## ItemDraw paints the things beside the road in depth order, far to near,
## each by its own kind's module.
import CatDraw
import CatPlan
import Critter
import DepthSort
import Frame
import GuardRail
import Mountains
import Render
import SceneLimits
import Screen
import Tower
import TowerPlan
import Tree
import TreePlan
import TruckDraw
import TruckPlan
import RocBird
import Scenery
import lib.Shapes

ItemDraw :: [].{

	## What every thing in a frame is drawn with: the road, the camera's focal
	## length, the ride's clock, which sets the masts' beacons and the truck's
	## headlights, and the truck's brake lights.
	Context : {
		road : Frame.RoadView,
		cam_focal : F64,
		clock : F64,
		brake_lights : [On, Off],
	}

	## A tree with fewer than this many trees nearer than it gets a round
	## trunk.
	round_trunk_limit : U32
	round_trunk_limit = 4

	## The scene's things, painted far to near.
	draw : Render.Scene, ItemDraw.Context -> List(Shapes.Shape)
	draw = |scene, context|
		scene.order.join_map(|depth_key| draw_subject(scene, { context, depth_key }))

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
			view_w: Screen.width,
			trunk: if (nearer_trees < ItemDraw.round_trunk_limit) RoundCorners else SharpCorners,
			crown: if (tree.forward < SceneLimits.detail_dist) Cones else Triangles,
			shade: ItemDraw.crown_shade(tree.forward),
		})
	}

	## Where a mast's four footprint corners stand in the rider's view.
	tower_footprint : ItemDraw.Context, TowerPlan.TowerItem -> Tower.Footprint
	tower_footprint = |context, tower| {
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
				context.road,
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

	## A mast, its beacon blinking on the ride's clock.
	draw_tower : ItemDraw.Context, TowerPlan.TowerItem -> List(Shapes.Shape)
	draw_tower = |context, tower|
		Tower.draw({
			footprint: ItemDraw.tower_footprint(context, tower),
			center: Frame.rider_point_at(
				context.road,
				{
					place: tower.place,
					along: tower.along,
					across: tower.across,
				},
			),
			cam_focal: context.cam_focal,
			view_w: Screen.width,
			beacon_phase: (context.clock + tower.beacon_offset),
		})
}

## One thing in the depth order, looked up in its kind's list and drawn.
draw_subject : Render.Scene,
{
	context : ItemDraw.Context,
	depth_key : DepthSort.DepthKey,
} -> List(Shapes.Shape)
draw_subject = |scene, { context, depth_key }| {
	camera = { cam_focal: context.cam_focal, view_w: Screen.width }
	match depth_key.subject {
		Tree(place) =>
			ItemDraw.draw_tree(
				thing_at(scene.trees, place),
				{ trees: scene.trees, cam_focal: context.cam_focal },
			)
		Tower(place) => ItemDraw.draw_tower(context, thing_at(scene.towers, place))
		Rail(place) => GuardRail.draw(thing_at(scene.rails, place), camera)
		Critter(place) => Critter.draw(thing_at(scene.critters, place), camera)
		Cat(place) => draw_cat(thing_at(scene.cats, place), camera)
		Truck => draw_truck(context, scene.truck)
		Bird(place) => RocBird.draw(thing_at(scene.birds, place), camera)
	}
}

## The thing at `place` in its kind's list.
thing_at : List(thing), U32 -> thing
thing_at = |things, place|
	things.get(place.to_u64())
		?? crash "ItemDraw.thing_at: the depth order names only places in its lists"

draw_cat : CatPlan.CatItem, { cam_focal : F64, view_w : F64 } -> List(Shapes.Shape)
draw_cat = |cat, { cam_focal, view_w }|
	CatDraw.draw({
		right: cat.right,
		forward: cat.forward,
		height: cat.height,
		pose: cat.pose,
		lift: cat.lift,
		cam_focal,
		view_w,
	})

## The truck, in the middle of its lane, its headlights on once the sun is
## behind the mountains.
draw_truck : ItemDraw.Context, TruckPlan.TruckAt -> List(Shapes.Shape)
draw_truck = |context, truck_at|
	match truck_at {
		Ahead(truck) =>
			TruckDraw.draw({
				road: {
					world: context.road.world,
					chain: context.road.chain,
					pose: context.road.pose,
					position: truck.position,
				},
				center: {
					along: truck.along,
					across: (Scenery.lane_width / 2.0),
				},
				lights: {
					headlights: if (Mountains.is_sun_behind_mountains(context.clock)) On else Off,
					brake_lights: context.brake_lights,
				},
				cam_focal: context.cam_focal,
				view_w: Screen.width,
			})
		NoTruck => crash "ItemDraw.draw_truck: the truck is in the depth order only in view"
	}
