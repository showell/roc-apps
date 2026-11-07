## SceneShapes paints the things beside the road in depth order, far to near,
## each by its own kind's module.
import Pixels
import CatShapes
import Across
import Along
import Angle
import Distance
import Geom
import World
import CatSighting
import StillShapes
import DepthSort
import Fraction
import Chain
import Conifer
import GuardRail
import Scene
import Tower
import TowerSighting
import TreeShapes
import TreeSighting
import TruckPicture
import TruckSighting
import BirdShapes
import lib.Shapes

SceneShapes :: [].{

	## The scene's things, painted far to near.
	scene_shapes : Scene, Chain.Viewpoint -> List(Shapes.Shape)
	scene_shapes = |scene, view|
		scene.order_keys.join_map(|depth_key| subject_shapes(scene, { view, depth_key }))

	## How many of `trees` are nearer than `forward`.
	nearer_tree_count : List(TreeSighting), Distance -> U16
	nearer_tree_count = |trees, forward| trees.count_if(|tree| tree.forward < forward).to_u16_wrap()

	## A tree, told how many of `trees` are nearer, which is all it needs of
	## the others.
	tree_shapes : TreeSighting,
	{
		trees : List(TreeSighting),
		cam_focal : Pixels,
	} -> List(Shapes.Shape)
	tree_shapes = |tree, { trees, cam_focal }|
		TreeShapes.tree_shapes(
			{ tree, nearer_tree_count: SceneShapes.nearer_tree_count(trees, tree.forward) },
			cam_focal,
		)

	## Where a tower's four footprint corners stand in the rider's view.
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

	## A tower, its beacon as bright as its sighting says.
	tower_shapes : Chain.Viewpoint, TowerSighting -> List(Shapes.Shape)
	tower_shapes = |view, tower|
		Tower.tower_shapes({
			footprint: SceneShapes.tower_footprint(view, tower),
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
subject_shapes : Scene,
{
	view : Chain.Viewpoint,
	depth_key : DepthSort.DepthKey,
} -> List(Shapes.Shape)
subject_shapes = |scene, { view, depth_key }| {
	cam_focal = view.cam_focal
	match depth_key.subject {
		Tree(place) =>
			SceneShapes.tree_shapes(thing_at(scene.trees, place), { trees: scene.trees, cam_focal })
		Tower(place) => SceneShapes.tower_shapes(view, thing_at(scene.towers, place))
		Rail(place) => GuardRail.quad_shapes(thing_at(scene.rails, place), cam_focal)
		Cutout(place) => StillShapes.cutout_shapes(thing_at(scene.cutouts, place), cam_focal)
		Cat(place) => CatShapes.cat_shapes(thing_at(scene.cats, place), cam_focal)
		Truck => truck_shapes(view, scene.truck)
		Bird(place) => BirdShapes.bird_shapes(thing_at(scene.birds, place), cam_focal)
	}
}

## The thing at `place` in its kind's list.
thing_at : List(thing), U32 -> thing
thing_at = |things, place|
	things.get(place.to_u64())
		?? crash "SceneShapes.thing_at: the depth order names only places in its lists"

## The truck, where its sighting found it and with the lights its sighting
## gives it.
truck_shapes : Chain.Viewpoint, TruckSighting -> List(Shapes.Shape)
truck_shapes = |view, truck_at|
	match truck_at {
		Ahead(truck) =>
			TruckPicture.truck_shapes({
				view,
				position: truck.position,
				center: { along: truck.along, across: truck.across },
				lights: truck.lights,
			})
		NoTruck => crash "SceneShapes.truck_shapes: the truck is in the depth order only in view"
	}

tree_at : F64 -> TreeSighting
tree_at = |forward| {
	right: Distance.metres(0.0),
	forward: Distance.metres(forward),
	conifer: Conifer.BigGreen,
}

spread_trees : List(TreeSighting)
spread_trees = [10.0, 20.0, 30.0, 40.0, 50.0].map(tree_at)

expect SceneShapes.nearer_tree_count(spread_trees, Distance.metres(10.0)) == 0
expect SceneShapes.nearer_tree_count(spread_trees, Distance.metres(30.0)) == 2
expect SceneShapes.nearer_tree_count(spread_trees, Distance.metres(50.0)) == 4
expect SceneShapes.nearer_tree_count(spread_trees, Distance.metres(60.0)) == 5
expect SceneShapes.nearer_tree_count(spread_trees, Distance.metres(5.0)) == 0
expect SceneShapes.nearer_tree_count([], Distance.metres(10.0)) == 0

tied_trees : List(TreeSighting)
tied_trees = List.repeat(tree_at(20.0), 4)

expect SceneShapes.nearer_tree_count(tied_trees, Distance.metres(20.0)) == 0
expect SceneShapes.nearer_tree_count(tied_trees, Distance.metres(20.1)) == 4
expect SceneShapes.nearer_tree_count(tied_trees, Distance.metres(19.9)) == 0

# The rider at the start of the route, at the ride's first step.
start_view : Chain.Viewpoint
start_view = {
	road: {
		route_segments: [0, 1, 2].map(World.route_segment),
		chain_indices: [0, 1, 2].map(World.SegmentIndex.number),
		vantage: {
			along: Along.metres(0.0),
			across: Across.metres(0.0),
			yaw: Angle.straight_ahead,
			half_width: Distance.metres(2.0),
		},
	},
	cam_focal: Pixels.of(500.0),
}

# A tower `along` metres down the first segment, 20 m right of the road's middle.
tower_along : F64 -> TowerSighting
tower_along = |along| {
	place: InChain(Chain.Position.first),
	along: Along.metres(along),
	across: Across.metres(20.0),
	yaw: Angle.straight_ahead,
	forward: Distance.metres(along),
	beacon_brightness: Fraction.zero,
}

expect {
	footprint = SceneShapes.tower_footprint(start_view, tower_along(200.0))
	[
		(footprint.back_left.forward.to_metres(), 194.0),
		(footprint.front_right.forward.to_metres(), 206.0),
		(footprint.back_left.right.to_metres(), 14.0),
		(footprint.back_right.right.to_metres(), 26.0),
	].all(|(got, want)| (got - want).abs() <= 0.0001)
}

expect SceneShapes.tower_shapes(start_view, tower_along(200.0)).len() > 0
expect SceneShapes.tower_shapes(start_view, tower_along(1000.0)).len() > 0
expect SceneShapes.tower_shapes(start_view, tower_along(-100.0)).len() == 0

cluster_sightings : List(TreeSighting)
cluster_sightings = [10.0, 11.0, 12.0, 13.0, 14.0].map(tree_at)

cluster_shapes : F64 -> List(Shapes.Shape)
cluster_shapes = |forward|
	SceneShapes.tree_shapes(
		tree_at(forward),
		{ trees: cluster_sightings, cam_focal: Pixels.of(500.0) },
	)

second_shape_points : List(Shapes.Shape) -> U64
second_shape_points = |shapes|
	match shapes {
		[_, Poly(polygon), ..] => polygon.points.len()
		_ => crash "a tree in view draws a trunk and tiers"
	}

# A near tree's tiers are cones, in more detail than a far tree's triangles.
expect cluster_shapes(10.0).len() > 0
expect cluster_shapes(14.0).len() > 0
expect second_shape_points(cluster_shapes(10.0)) > second_shape_points(cluster_shapes(14.0))
expect second_shape_points(cluster_shapes(14.0)) >= 6

route_segments : List(World.Segment)
route_segments = [
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
view_from : Geom.Vantage, Pixels -> Chain.Viewpoint
view_from = |vantage, cam_focal| {
	road: {
		route_segments,
		chain_indices: [0, 1, 2].map(World.SegmentIndex.number),
		vantage,
	},
	cam_focal,
}

from_origin : Chain.Viewpoint
from_origin = view_from(origin, Pixels.of(500.0))

## A green tree `along` metres into the first segment, 3.5 m right of the
## road's middle.
green_tree_at = |along| {
	position: Chain.Position.first,
	tree: {
		along: Along.metres(along),
		across: Across.metres(3.5),
		conifer: Conifer.BigGreen,
	},
}

lone_tree : TreeSighting
lone_tree = TreeSighting.sighting_of(
	from_origin,
	green_tree_at(120.0),
) ?? crash "SceneShapes: a tree 120 m ahead is in view"

expect
	[
		(lone_tree.right.to_metres(), 3.5),
		(lone_tree.forward.to_metres(), 120.0),
	].all(|(got, want)| (got - want).abs() <= 0.0001)

expect TreeSighting.sighting_of(from_origin, green_tree_at(120.0)).is_ok()
expect lone_tree.conifer == Conifer.BigGreen
expect
	[
		(TreeSighting.sighting_of(from_origin, green_tree_at(0.4)), False),
		(TreeSighting.sighting_of(from_origin, green_tree_at(0.5)), True),
		(TreeSighting.sighting_of(view_from(origin, Pixels.of(1.0)), green_tree_at(120.0)), False),
		(TreeSighting.sighting_of(from_origin, green_tree_at(2000.0)), False),
	].all(|(seen, want)| seen.is_ok() == want)

expect
	[
		(from_origin, 28),
		(view_from(up_road, Pixels.of(500.0)), 20),
		(view_from(origin, Pixels.of(1.0)), 0),
	].all(
		|(view, want)| {
			trees = TreeSighting.segment_sightings(view, Chain.Position.first)
			trees.len().to_i64_wrap() == want
		},
	)

first_sightings : List(TreeSighting)
first_sightings = TreeSighting.segment_sightings(from_origin, Chain.Position.first)

## The first segment's tree at `i`, in planting order.
planted_tree : U64 -> TreeSighting
planted_tree = |i|
	first_sightings.get(i) ?? crash "SceneShapes: the first segment has 28 trees in view"

expect
	[
		(planted_tree(0).forward.to_metres(), 6.0),
		(planted_tree(1).forward.to_metres(), 6.0),
		(planted_tree(2).forward.to_metres(), 36.0),
		(planted_tree(0).right.to_metres(), -3.5),
		(planted_tree(1).right.to_metres(), 3.5),
	].all(|(got, want)| (got - want).abs() <= 0.0001)

expect planted_tree(0).conifer == Conifer.BigGreen
expect planted_tree(2).conifer == Conifer.SmallGreen

keys : List(DepthSort.DepthKey)
keys = TreeSighting.depth_keys(first_sightings)

## The depth key at `i`.
key_at : U64 -> DepthSort.DepthKey
key_at = |i| keys.get(i) ?? crash "SceneShapes: the first segment has 28 keys"

## The position in the tree list that the key at `i` names.
tree_place_at : U64 -> I64
tree_place_at = |i|
	match key_at(i).subject {
		Tree(position) => position.to_i64()
		Tower(_) | Cutout(_) | Cat(_) | Truck | Rail(_) | Bird(_) =>
			crash "SceneShapes: a tree's key names a tree"
	}

expect keys.len() == 28
expect tree_place_at(0) == 0
expect tree_place_at(27) == 27
expect TreeSighting.depth_keys([]).len() == 0
expect
	[
		(key_at(0).forward.to_metres(), 6.0),
		(key_at(2).forward.to_metres(), 36.0),
	].all(|(got, want)| (got - want).abs() <= 0.0001)

expect
	route_segments.map(|seg| seg.length.to_metres())
		== [500.0, 320.0, 400.0]

## What a truck `lead` metres ahead of a rider at the start of the chain is
## seen from, from `vantage`, with its lights off.
truck_view : Geom.Vantage, F64 -> TruckSighting.Viewpoint
truck_view = |vantage, lead| {
	road: {
		route_segments,
		chain_indices: [0, 1, 2].map(World.SegmentIndex.number),
		vantage,
	},
	lead: Distance.metres(lead),
	lights: { headlights: Off, brake_lights: Off },
}

truck_seen_from : Geom.Vantage, F64 -> TruckSighting
truck_seen_from = |vantage, lead| TruckSighting.truck_in_view(truck_view(vantage, lead))

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
truck_ahead_of = |lead|
	match lead_of(lead) {
		Ahead(truck) => truck
		NoTruck => crash "SceneShapes: this lead puts the truck in view"
	}

expect
	[
		(100.0, True),
		(499.0, True),
		(600.0, True),
		(900.0, True),
		(2000.0, False),
		(0.0, False),
		(-50.0, False),
	].all(|(lead, want)| is_ahead(lead_of(lead)) == want)

expect
	[
		(100.0, 0),
		(499.0, 0),
		(600.0, 1),
		(900.0, 2),
	].all(|(lead, want)| truck_ahead_of(lead).position.to_i64() == want)

expect
	[
		(100.0, 100.0),
		(499.0, 499.0),
		(600.0, 100.0),
		(900.0, 80.0),
	].all(|(lead, want)| truck_ahead_of(lead).along.to_metres() == want)

expect
	[
		(100.0, 0.0),
		(499.0, 0.0),
		(600.0, 0.0),
		(900.0, 0.0),
	].all(|(lead, want)| truck_ahead_of(lead).across.to_metres() == want)

## The lights a truck in view shows, when it has `lights` on.
lights_shown = |lights|
	match TruckSighting.truck_in_view({ ..truck_view(origin, 100.0), lights }) {
		Ahead(truck) => truck.lights
		NoTruck => crash "SceneShapes: this lead puts the truck in view"
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
		(truck_ahead_of(100.0).forward.to_metres(), 100.0),
		(truck_ahead_of(499.0).forward.to_metres(), 499.0),
	].all(|(got, want)| (got - want).abs() <= 0.0001)

expect !is_ahead(NoTruck)
expect !is_ahead(lead_of(2000.0))
expect !is_ahead(truck_seen_from({ ..origin, along: Along.metres(100.0) }, 0.25))
expect is_ahead(truck_seen_from({ ..origin, along: Along.metres(100.0) }, 1.0))

## The depth key of a truck in view.
key_of : F64 -> DepthSort.DepthKey
key_of = |lead|
	TruckSighting.depth_keys(lead_of(lead)).first()
		?? crash "SceneShapes: a truck in view has a depth key"

expect TruckSighting.depth_keys(lead_of(100.0)).len() == 1
expect TruckSighting.depth_keys(lead_of(2000.0)).len() == 0
expect TruckSighting.depth_keys(NoTruck).len() == 0
expect TruckSighting.depth_keys(lead_of(100.0)).count_if(|key| key.subject == Truck) == 1
expect (key_of(499.0).forward.to_metres() - 499.0).abs() <= 0.0001
