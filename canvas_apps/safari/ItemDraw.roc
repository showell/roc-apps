## ItemDraw paints the things beside the road in depth order, far to near,
## each by its own kind's module.
import CatDraw
import CatPlan
import Critter
import DepthSort
import Frame
import GuardRail
import Mountains
import Paint
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
import World

ItemDraw :: [].{

	## What every thing in a frame is drawn with: the world, the chain of
	## segments ahead (indexes into `world`, the rider's own first), the
	## rider's pose, the camera's focal length, the ride's clock, which sets
	## the masts' beacons and the truck's headlights, and the truck's brake
	## lights.
	Context : {
		world : List(World.Segment),
		chain : List(I64),
		pose : Frame.Pose,
		cam_focal : F64,
		clock : F64,
		brake_lights : [On, Off],
	}

	## A tree with fewer than this many trees nearer than it gets a round
	## trunk.
	round_trunks : U64
	round_trunks = 4

	## The scene's things, painted far to near.
	draw : Render.Scene, ItemDraw.Context -> List(Paint.DrawCmd)
	draw = |scene, context| scene.order.join_map(|key| draw_one(scene, context, key))

	## How many of `trees` are nearer than `forward`.
	nearer_count : List(TreePlan.TreeItem), F64 -> U64
	nearer_count = |trees, forward| trees.count_if(|tree| tree.fwd < forward)

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
	draw_tree : TreePlan.TreeItem, { trees : List(TreePlan.TreeItem), cam_focal : F64 } -> List(Paint.DrawCmd)
	draw_tree = |tree, { trees, cam_focal }|
		Tree.draw({
			right: tree.right,
			forward: tree.fwd,
			height: tree.height,
			color: tree.color,
			cam_focal,
			view_w: Screen.width,
			trunk: if (ItemDraw.nearer_count(trees, tree.fwd) < ItemDraw.round_trunks) RoundCorners else SharpCorners,
			crown: if (tree.fwd < SceneLimits.detail_dist) Cones else Triangles,
			shade: ItemDraw.crown_shade(tree.fwd),
		})

	## Where a mast's four footprint corners stand in the rider's view.
	tower_footprint : ItemDraw.Context, TowerPlan.TowerItem -> Tower.Footprint
	tower_footprint = |context, tower| {
		corner_point = |corner| {
			on_map = Tower.base_corner_ax(corner, tower.along, tower.across, tower.yaw)
			Frame.map_pt(context.world, context.chain, context.pose, tower.map, on_map.a, on_map.x)
		}
		{
			back_left: corner_point(BackLeft),
			back_right: corner_point(BackRight),
			front_right: corner_point(FrontRight),
			front_left: corner_point(FrontLeft),
		}
	}

	## A mast, its beacon blinking on the ride's clock.
	draw_tower : ItemDraw.Context, TowerPlan.TowerItem -> List(Paint.DrawCmd)
	draw_tower = |context, tower|
		Tower.draw({
			footprint: ItemDraw.tower_footprint(context, tower),
			center: Frame.map_pt(context.world, context.chain, context.pose, tower.map, tower.along, tower.across),
			cam_focal: context.cam_focal,
			view_w: Screen.width,
			beacon_phase: (context.clock + tower.beacon_offset),
		})
}

## One thing in the depth order, looked up in its kind's list and drawn.
draw_one : Render.Scene, ItemDraw.Context, DepthSort.DepthKey -> List(Paint.DrawCmd)
draw_one = |scene, context, key| {
	camera = { cam_focal: context.cam_focal, view_w: Screen.width }
	match key.subject {
		Tree(place) => ItemDraw.draw_tree(at_place(scene.trees, place), { trees: scene.trees, cam_focal: context.cam_focal })
		Tower(place) => ItemDraw.draw_tower(context, at_place(scene.towers, place))
		Rail(place) => GuardRail.draw(at_place(scene.rails, place), camera)
		Critter(place) => Critter.draw(at_place(scene.critters, place), camera)
		Cat(place) => draw_cat(at_place(scene.cats, place), camera)
		Truck => draw_truck(context, scene.truck)
		Bird(place) => RocBird.draw_one(at_place(scene.birds, place), context.cam_focal, Screen.width)
	}
}

## The thing at `place` in its kind's list.
at_place : List(thing), U64 -> thing
at_place = |things, place| things.get(place) ?? crash "ItemDraw.at_place: the depth order names only places in its lists"

draw_cat : CatPlan.CatItem, { cam_focal : F64, view_w : F64 } -> List(Paint.DrawCmd)
draw_cat = |cat, { cam_focal, view_w }|
	CatDraw.draw({
		right: cat.right,
		forward: cat.fwd,
		height: cat.height,
		pose: cat.pose,
		lift: cat.lift,
		cam_focal,
		view_w,
	})

## The truck, in the middle of its lane, its headlights on once the sun is
## behind the mountains.
draw_truck : ItemDraw.Context, TruckPlan.TruckAt -> List(Paint.DrawCmd)
draw_truck = |context, truck_at|
	match truck_at {
		Ahead(truck) =>
			TruckDraw.draw({
				road: { world: context.world, chain: context.chain, pose: context.pose, segment: truck.place },
				center: {
					along: truck.along,
					across: (Scenery.lane_width / 2.0),
				},
				lights: {
					headlights: if Mountains.is_sun_behind_mountains(context.clock) On else Off,
					brake_lights: context.brake_lights,
				},
				cam_focal: context.cam_focal,
				view_w: Screen.width,
			})
		NoTruck => crash "ItemDraw.draw_truck: the depth order holds a truck only when one is in view"
	}
