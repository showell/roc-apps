## ItemDraw paints the things beside the road in depth order, far to near,
## each by its own kind's module.
import CatDraw
import Across
import Along
import Angle
import Distance
import World
import CatSighting
import Critter
import DepthSort
import Fraction
import Frame
import GuardRail
import Render
import SceneLimits
import Tower
import TowerSighting
import Tree
import TreeSighting
import TruckDraw
import TruckSighting
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
	nearer_tree_count : List(TreeSighting.TreeItem), F64 -> U32
	nearer_tree_count = |trees, forward|
		trees.count_if(|tree| tree.forward < forward).to_u32_wrap()

	## How much a crown is shaded at distance `forward`: fully at the camera,
	## falling evenly to none at SceneLimits.crown_shade_dist.
	crown_shade : F64 -> Fraction
	crown_shade = |forward| Fraction.clamp((1.0 - (forward / SceneLimits.crown_shade_dist)))

	## A tree, drawn in more detail the nearer it is: its trunk is round when
	## few of `trees` are nearer, and its crown is cones when it is nearer
	## than SceneLimits.detail_dist.
	draw_tree : TreeSighting.TreeItem,
	{
		trees : List(TreeSighting.TreeItem),
		cam_focal : F64,
	} -> List(Shapes.Shape)
	draw_tree = |tree, { trees, cam_focal }| {
		nearer_trees = ItemDraw.nearer_tree_count(trees, tree.forward)
		Tree.draw({
			right: tree.right,
			forward: tree.forward,
			height: tree.height.to_metres(),
			color: tree.color,
			cam_focal,
			trunk: if (nearer_trees < ItemDraw.round_trunk_limit) RoundCorners else SharpCorners,
			crown: if (tree.forward < SceneLimits.detail_dist) Cones else Triangles,
			shade: ItemDraw.crown_shade(tree.forward),
		})
	}

	## Where a mast's four footprint corners stand in the rider's view.
	tower_footprint : Frame.Viewpoint, TowerSighting.TowerItem -> Tower.Footprint
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

	## A mast, its beacon as bright as its sighting says.
	draw_tower : Frame.Viewpoint, TowerSighting.TowerItem -> List(Shapes.Shape)
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

draw_cat : CatSighting.CatItem, F64 -> List(Shapes.Shape)
draw_cat = |cat, cam_focal|
	CatDraw.draw({
		right: cat.right,
		forward: cat.forward,
		height: cat.height.to_metres(),
		pose: cat.pose,
		lift: cat.lift,
		cam_focal,
	})

## The truck, where its sighting found it and with the lights its sighting
## gives it.
draw_truck : Frame.Viewpoint, TruckSighting.TruckAt -> List(Shapes.Shape)
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

expect SceneLimits.crown_shade_dist == 80.0
expect SceneLimits.detail_dist == 200.0

tree_at : F64 -> TreeSighting.TreeItem
tree_at = |forward| {
	right: 0.0,
	forward,
	height: Distance.metres(5.85),
	color: 1858082,
}

spread_trees : List(TreeSighting.TreeItem)
spread_trees = [10.0, 20.0, 30.0, 40.0, 50.0].map(tree_at)

expect ItemDraw.nearer_tree_count(spread_trees, 10.0) == 0
expect ItemDraw.nearer_tree_count(spread_trees, 30.0) == 2
expect ItemDraw.nearer_tree_count(spread_trees, 50.0) == 4
expect ItemDraw.nearer_tree_count(spread_trees, 60.0) == 5
expect ItemDraw.nearer_tree_count(spread_trees, 5.0) == 0
expect ItemDraw.nearer_tree_count([], 10.0) == 0

tied_trees : List(TreeSighting.TreeItem)
tied_trees = List.repeat(tree_at(20.0), 4)

expect ItemDraw.nearer_tree_count(tied_trees, 20.0) == 0
expect ItemDraw.nearer_tree_count(tied_trees, 20.1) == 4
expect ItemDraw.nearer_tree_count(tied_trees, 19.9) == 0

expect ItemDraw.crown_shade(0.0).to_f64() == 1.0
expect ItemDraw.crown_shade(20.0).to_f64() == 0.75
expect ItemDraw.crown_shade(40.0).to_f64() == 0.5
expect ItemDraw.crown_shade(80.0).to_f64() == 0.0
expect ItemDraw.crown_shade(200.0).to_f64() == 0.0
expect ItemDraw.crown_shade(-50.0).to_f64() == 1.0

# The rider at the start of the route, at the ride's first step.
start_view : Frame.Viewpoint
start_view = {
	road: {
		world: [0, 1, 2].map(World.route_segment),
		chain: [0, 1, 2].map(World.SegmentIndex.number),
		pose: {
			along: Along.metres(0.0),
			across: Across.metres(0.0),
			yaw: Angle.straight_ahead,
			half_width: Distance.metres(2.0),
		},
	},
	cam_focal: 500.0,
}

# A mast `along` metres down the first segment, 20 m right of the lane's middle.
tower_along : F64 -> TowerSighting.TowerItem
tower_along = |along| {
	place: InChain(Frame.ChainPosition.first),
	along: Along.metres(along),
	across: Across.metres(20.0),
	yaw: Angle.straight_ahead,
	forward: along,
	beacon_brightness: Fraction.zero,
}

expect {
	footprint = ItemDraw.tower_footprint(start_view, tower_along(200.0))
	[
		(footprint.back_left.forward, 194.0),
		(footprint.front_right.forward, 206.0),
		(footprint.back_left.right, 14.0),
		(footprint.back_right.right, 26.0),
	].all(|(got, want)| (got - want).abs() <= 0.0001)
}

expect ItemDraw.draw_tower(start_view, tower_along(200.0)).len() > 0
expect ItemDraw.draw_tower(start_view, tower_along(1000.0)).len() > 0
expect ItemDraw.draw_tower(start_view, tower_along(-100.0)).len() == 0

tree_cluster : List(TreeSighting.TreeItem)
tree_cluster = [10.0, 11.0, 12.0, 13.0, 14.0].map(tree_at)

clustered_tree : F64 -> List(Shapes.Shape)
clustered_tree = |forward|
	ItemDraw.draw_tree(tree_at(forward), { trees: tree_cluster, cam_focal: 500.0 })

second_shape_points : List(Shapes.Shape) -> U64
second_shape_points = |shapes|
	match shapes {
		[_, Poly(polygon), ..] => polygon.pts.len()
		_ => crash "a tree in view draws a trunk and tiers"
	}

# A near tree's tiers are cones, in more detail than a far tree's triangles.
expect clustered_tree(10.0).len() > 0
expect clustered_tree(14.0).len() > 0
expect second_shape_points(clustered_tree(10.0)) > second_shape_points(clustered_tree(14.0))
expect second_shape_points(clustered_tree(14.0)) >= 6
