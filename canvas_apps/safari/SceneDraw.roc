## SceneDraw paints the things beside the road in depth order, far to near,
## each by its own kind's module.
import CatDraw
import Across
import Along
import Angle
import Distance
import Geom
import World
import CatSighting
import Critter
import DepthSort
import Fraction
import Chain
import GuardRail
import Scene
import Detail
import Tower
import TowerSighting
import Tree
import TreeSighting
import TruckDraw
import TruckSighting
import RocBird
import lib.Shapes

SceneDraw :: [].{

	## A tree with fewer than this many trees nearer than it gets a round
	## trunk.
	round_trunk_limit : U32
	round_trunk_limit = 4

	## The scene's things, painted far to near.
	draw : Scene, Chain.Viewpoint -> List(Shapes.Shape)
	draw = |scene, view|
		scene.order.join_map(|depth_key| draw_subject(scene, { view, depth_key }))

	## How many of `trees` are nearer than `forward`.
	nearer_tree_count : List(TreeSighting), F64 -> U32
	nearer_tree_count = |trees, forward|
		trees.count_if(|tree| tree.forward < forward).to_u32_wrap()

	## How much a crown is shaded at distance `forward`: fully at the camera,
	## falling evenly to none at Detail.crown_shade_reach.
	crown_shade : F64 -> Fraction
	crown_shade = |forward| Fraction.clamp((1.0 - (forward / Detail.crown_shade_reach)))

	## A tree, drawn in more detail the nearer it is: its trunk is round when
	## few of `trees` are nearer, and its crown is cones when it is nearer
	## than Detail.full_detail_reach.
	draw_tree : TreeSighting, { trees : List(TreeSighting), cam_focal : F64 } -> List(Shapes.Shape)
	draw_tree = |tree, { trees, cam_focal }| {
		nearer_trees = SceneDraw.nearer_tree_count(trees, tree.forward)
		Tree.draw({
			right: tree.right,
			forward: tree.forward,
			height: tree.height.to_metres(),
			color: tree.color,
			cam_focal,
			trunk: if nearer_trees < SceneDraw.round_trunk_limit {
				RoundCorners
			} else {
				SharpCorners
			},
			crown: if tree.forward < Detail.full_detail_reach {
				Cones
			} else {
				Triangles
			},
			shade: SceneDraw.crown_shade(tree.forward),
		})
	}

	## Where a mast's four footprint corners stand in the rider's view.
	tower_footprint : Chain.Viewpoint, TowerSighting -> Tower.Footprint
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
			Chain.rider_point_at(
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
	draw_tower : Chain.Viewpoint, TowerSighting -> List(Shapes.Shape)
	draw_tower = |view, tower|
		Tower.draw({
			footprint: SceneDraw.tower_footprint(view, tower),
			center: Chain.rider_point_at(
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
draw_subject : Scene,
{
	view : Chain.Viewpoint,
	depth_key : DepthSort.DepthKey,
} -> List(Shapes.Shape)
draw_subject = |scene, { view, depth_key }| {
	cam_focal = view.cam_focal
	match depth_key.subject {
		Tree(place) =>
			SceneDraw.draw_tree(thing_at(scene.trees, place), { trees: scene.trees, cam_focal })
		Tower(place) => SceneDraw.draw_tower(view, thing_at(scene.towers, place))
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
		?? crash "SceneDraw.thing_at: the depth order names only places in its lists"

draw_cat : CatSighting, F64 -> List(Shapes.Shape)
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
draw_truck : Chain.Viewpoint, TruckSighting -> List(Shapes.Shape)
draw_truck = |view, truck_at|
	match truck_at {
		Ahead(truck) =>
			TruckDraw.draw({
				view,
				position: truck.position,
				center: { along: truck.along, across: truck.across },
				lights: truck.lights,
			})
		NoTruck => crash "SceneDraw.draw_truck: the truck is in the depth order only in view"
	}

expect Detail.crown_shade_reach == 80.0
expect Detail.full_detail_reach == 200.0

tree_at : F64 -> TreeSighting
tree_at = |forward| {
	right: 0.0,
	forward,
	height: Distance.metres(5.85),
	color: 1858082,
}

spread_trees : List(TreeSighting)
spread_trees = [10.0, 20.0, 30.0, 40.0, 50.0].map(tree_at)

expect SceneDraw.nearer_tree_count(spread_trees, 10.0) == 0
expect SceneDraw.nearer_tree_count(spread_trees, 30.0) == 2
expect SceneDraw.nearer_tree_count(spread_trees, 50.0) == 4
expect SceneDraw.nearer_tree_count(spread_trees, 60.0) == 5
expect SceneDraw.nearer_tree_count(spread_trees, 5.0) == 0
expect SceneDraw.nearer_tree_count([], 10.0) == 0

tied_trees : List(TreeSighting)
tied_trees = List.repeat(tree_at(20.0), 4)

expect SceneDraw.nearer_tree_count(tied_trees, 20.0) == 0
expect SceneDraw.nearer_tree_count(tied_trees, 20.1) == 4
expect SceneDraw.nearer_tree_count(tied_trees, 19.9) == 0

expect SceneDraw.crown_shade(0.0).to_f64() == 1.0
expect SceneDraw.crown_shade(20.0).to_f64() == 0.75
expect SceneDraw.crown_shade(40.0).to_f64() == 0.5
expect SceneDraw.crown_shade(80.0).to_f64() == 0.0
expect SceneDraw.crown_shade(200.0).to_f64() == 0.0
expect SceneDraw.crown_shade(-50.0).to_f64() == 1.0

# The rider at the start of the route, at the ride's first step.
start_view : Chain.Viewpoint
start_view = {
	road: {
		world: [0, 1, 2].map(World.route_segment),
		chain: [0, 1, 2].map(World.SegmentIndex.number),
		vantage: {
			along: Along.metres(0.0),
			across: Across.metres(0.0),
			yaw: Angle.straight_ahead,
			half_width: Distance.metres(2.0),
		},
	},
	cam_focal: 500.0,
}

# A mast `along` metres down the first segment, 20 m right of the lane's middle.
tower_along : F64 -> TowerSighting
tower_along = |along| {
	place: InChain(Chain.Position.first),
	along: Along.metres(along),
	across: Across.metres(20.0),
	yaw: Angle.straight_ahead,
	forward: along,
	beacon_brightness: Fraction.zero,
}

expect {
	footprint = SceneDraw.tower_footprint(start_view, tower_along(200.0))
	[
		(footprint.back_left.forward, 194.0),
		(footprint.front_right.forward, 206.0),
		(footprint.back_left.right, 14.0),
		(footprint.back_right.right, 26.0),
	].all(|(got, want)| (got - want).abs() <= 0.0001)
}

expect SceneDraw.draw_tower(start_view, tower_along(200.0)).len() > 0
expect SceneDraw.draw_tower(start_view, tower_along(1000.0)).len() > 0
expect SceneDraw.draw_tower(start_view, tower_along(-100.0)).len() == 0

tree_cluster : List(TreeSighting)
tree_cluster = [10.0, 11.0, 12.0, 13.0, 14.0].map(tree_at)

clustered_tree : F64 -> List(Shapes.Shape)
clustered_tree = |forward|
	SceneDraw.draw_tree(tree_at(forward), { trees: tree_cluster, cam_focal: 500.0 })

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

segs : List(World.Segment)
segs = [
	World.route_segment(0),
	World.route_segment(1),
	World.route_segment(2),
]

origin : Geom.Vantage
origin = {
	along: Along.metres(0.0),
	across: Across.metres(0.0),
	yaw: Angle.straight_ahead,
	half_width: Distance.metres(2.0),
}

up_road : Geom.Vantage
up_road = {
	along: Along.metres(100.0),
	across: Across.metres(0.0),
	yaw: Angle.straight_ahead,
	half_width: Distance.metres(2.0),
}

## The first three segments, seen from `vantage` through a camera of focal
## length `cam_focal`.
view_from : Geom.Vantage, F64 -> Chain.Viewpoint
view_from = |vantage, cam_focal| {
	road: {
		world: segs,
		chain: [0, 1, 2].map(World.SegmentIndex.number),
		vantage,
	},
	cam_focal,
}

from_origin : Chain.Viewpoint
from_origin = view_from(origin, 500.0)

## A green tree `along` metres into the first segment, 3.5 m right of the
## road's middle.
green_tree_at = |along| {
	position: Chain.Position.first,
	tree: {
		along: Along.metres(along),
		across: Across.metres(3.5),
		color: 1858082,
		height: Distance.metres(5.85),
	},
}

expect
	List.concat(segs.map(|seg| seg.trees.len().to_i64_wrap()), [TreeSighting.max_vis_trees])
		== [28, 16, 22, 640]

lone_tree : TreeSighting
lone_tree = TreeSighting.tree_in_view(
	from_origin,
	green_tree_at(120.0),
).first() ?? crash "SceneDraw: a tree 120 m ahead is in view"

expect
	[
		(lone_tree.right, 3.5),
		(lone_tree.forward, 120.0),
		(lone_tree.height.to_metres(), 5.85),
	].all(|(got, want)| (got - want).abs() <= 0.0001)

expect TreeSighting.tree_in_view(from_origin, green_tree_at(120.0)).len() == 1
expect lone_tree.color == 1858082
expect
	[
		(TreeSighting.tree_in_view(from_origin, green_tree_at(0.4)), 0),
		(TreeSighting.tree_in_view(from_origin, green_tree_at(0.5)), 1),
		(TreeSighting.tree_in_view(view_from(origin, 1.0), green_tree_at(120.0)), 0),
		(TreeSighting.tree_in_view(from_origin, green_tree_at(2000.0)), 0),
	].all(|(seen, want)| seen.len().to_i64_wrap() == want)

expect
	[
		(from_origin, 28),
		(view_from(up_road, 500.0), 20),
		(view_from(origin, 1.0), 0),
	].all(
		|(view, want)| {
			trees = TreeSighting.segment_trees(view, Chain.Position.first)
			trees.len().to_i64_wrap() == want
		},
	)

first_segment : List(TreeSighting)
first_segment = TreeSighting.segment_trees(from_origin, Chain.Position.first)

## The first segment's tree at `i`, in planting order.
planted_tree : U64 -> TreeSighting
planted_tree = |i|
	first_segment.get(i) ?? crash "SceneDraw: the first segment has 28 trees in view"

expect
	[
		(planted_tree(0).forward, 6.0),
		(planted_tree(1).forward, 6.0),
		(planted_tree(2).forward, 36.0),
		(planted_tree(0).right, -3.5),
		(planted_tree(1).right, 3.5),
	].all(|(got, want)| (got - want).abs() <= 0.0001)

expect
	[
		(planted_tree(0).height.to_metres(), 5.85),
		(planted_tree(2).height.to_metres(), 4.5),
	].all(|(got, want)| (got - want).abs() <= 0.000000000001)

keys : List(DepthSort.DepthKey)
keys = TreeSighting.depth_keys(first_segment)

## The depth key at `i`.
key_at : U64 -> DepthSort.DepthKey
key_at = |i| keys.get(i) ?? crash "SceneDraw: the first segment has 28 keys"

## The position in the tree list that the key at `i` names.
tree_place_at : U64 -> I64
tree_place_at = |i|
	match key_at(i).subject {
		Tree(position) => position.to_i64()
		Tower(_) | Critter(_) | Cat(_) | Truck | Rail(_) | Bird(_) =>
			crash "SceneDraw: a tree's key names a tree"
	}

expect keys.len() == 28
expect tree_place_at(0) == 0
expect tree_place_at(27) == 27
expect TreeSighting.depth_keys([]).len() == 0
expect
	[
		(key_at(0).forward, 6.0),
		(key_at(2).forward, 36.0),
	].all(|(got, want)| (got - want).abs() <= 0.0001)

expect
	segs.map(|seg| seg.length.to_metres())
		== [500.0, 320.0, 400.0]

## What a truck `lead` metres ahead of a rider at the start of the chain is
## seen from, from `vantage`, with its lights off.
truck_view : Geom.Vantage, F64 -> TruckSighting.Viewpoint
truck_view = |vantage, lead| {
	road: {
		world: segs,
		chain: [0, 1, 2].map(World.SegmentIndex.number),
		vantage,
	},
	lead: Distance.metres(lead),
	lights: { headlights: Off, brake_lights: Off },
}

truck_seen_from : Geom.Vantage, F64 -> TruckSighting
truck_seen_from = |vantage, lead| TruckSighting.in_view(truck_view(vantage, lead))

lead_of : F64 -> TruckSighting
lead_of = |lead| truck_seen_from(origin, lead)

## Whether the truck is in view.
is_ahead : TruckSighting -> Bool
is_ahead = |truck|
	match truck {
		Ahead(_) => True
		NoTruck => False
	}

## Where the truck is, for a lead that puts it in view.
ahead_of = |lead|
	match lead_of(lead) {
		Ahead(truck) => truck
		NoTruck => crash "SceneDraw: this lead puts the truck in view"
	}

expect
	[
		(100.0, True),
		(499.0, True),
		(600.0, True),
		(900.0, True),
		(2000.0, False),
		(0.0, False),
		((0.0 - 50.0), False),
	].all(|(lead, want)| is_ahead(lead_of(lead)) == want)

expect
	[
		(100.0, 0),
		(499.0, 0),
		(600.0, 1),
		(900.0, 2),
	].all(|(lead, want)| ahead_of(lead).position.to_i64() == want)

expect
	[
		(100.0, 100.0),
		(499.0, 499.0),
		(600.0, 100.0),
		(900.0, 80.0),
	].all(|(lead, want)| ahead_of(lead).along.to_metres() == want)

expect
	[
		(100.0, 0.0),
		(499.0, 0.0),
		(600.0, 0.0),
		(900.0, 0.0),
	].all(|(lead, want)| ahead_of(lead).across.to_metres() == want)

## The lights a truck in view shows, when it has `lights` on.
lights_shown = |lights|
	match TruckSighting.in_view({ ..truck_view(origin, 100.0), lights }) {
		Ahead(truck) => truck.lights
		NoTruck => crash "SceneDraw: this lead puts the truck in view"
	}

expect
	[
		{ headlights: Off, brake_lights: Off },
		{ headlights: Off, brake_lights: On },
		{ headlights: On, brake_lights: Off },
		{ headlights: On, brake_lights: On },
	].all(|lights| lights_shown(lights) == lights)

expect
	[
		(ahead_of(100.0).forward, 100.0),
		(ahead_of(499.0).forward, 499.0),
	].all(|(got, want)| (got - want).abs() <= 0.0001)

expect !(is_ahead(NoTruck))
expect !(is_ahead(lead_of(2000.0)))
expect !(is_ahead(truck_seen_from({ ..origin, along: Along.metres(100.0) }, 0.25)))
expect is_ahead(truck_seen_from({ ..origin, along: Along.metres(100.0) }, 1.0))

## The depth key of a truck in view.
key_of : F64 -> DepthSort.DepthKey
key_of = |lead|
	TruckSighting.depth_keys(lead_of(lead)).first()
		?? crash "SceneDraw: a truck in view has a depth key"

expect TruckSighting.depth_keys(lead_of(100.0)).len() == 1
expect TruckSighting.depth_keys(lead_of(2000.0)).len() == 0
expect TruckSighting.depth_keys(NoTruck).len() == 0
expect TruckSighting.depth_keys(lead_of(100.0)).count_if(|key| key.subject == Truck) == 1
expect (key_of(499.0).forward - 499.0).abs() <= 0.0001
