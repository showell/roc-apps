## SceneShapes renders the things beside the road, each by its own kind's module,
## and paints them in depth order, far to near.
import Pixels
import CatShapes
import Across
import Along
import Angle
import Distance
import Geom
import World
import CatSighting
import Fraction
import Chain
import Conifer
import GuardRail
import Picture
import Pipeline
import Rendered
import Scene
import Tower
import TowerSighting
import TreeSighting
import TruckPicture
import TruckSighting
import BirdShapes
import lib.Shapes

SceneShapes :: [].{

	## One list for each sort of thing beside the road.
	ThingLists(thing) : {
		birds : List(thing),
		trees : List(thing),
		towers : List(thing),
		critters : List(thing),
		cats : List(thing),
		trucks : List(thing),
		rails : List(thing),
	}

	## The scene's things, painted far to near.
	scene_shapes : Scene, Chain.Viewpoint -> List(Shapes.Shape)
	scene_shapes = |scene, view| {
		renderings = SceneShapes.things_in_tie_order(SceneShapes.scene_renderings(scene, view))
		Rendered.depth_sorted_renderings(renderings).join_map(
			|rendering| rendering.picture.to_shapes(),
		)
	}

	## The scene's things, each as the frame paints it. A tree's context is the
	## one a tree can't know alone, and a critter needs none.
	scene_renderings : Scene, Chain.Viewpoint -> SceneShapes.ThingLists(Rendered)
	scene_renderings = |scene, view| {
		cam_focal = view.cam_focal
		{
			birds: scene.birds.map(
				|bird| rendering_at(bird.forward, BirdShapes.bird_shapes(bird, cam_focal)),
			),
			trees: scene.trees.map(
				|tree| SceneShapes.tree_rendering(tree, { trees: scene.trees, cam_focal }),
			),
			towers: scene.towers.map(
				|tower| rendering_at(tower.forward, SceneShapes.tower_shapes(view, tower)),
			),
			critters: scene.critters.map(
				|critter| Pipeline.rendering_of(critter, { cam_focal, context: {} }),
			),
			cats: scene.cats.map(
				|cat| rendering_at(cat.forward, CatShapes.cat_shapes(cat, cam_focal)),
			),
			trucks: truck_renderings(view, scene.truck),
			rails: scene.rails.map(
				|quad| rendering_at(quad.forward, GuardRail.quad_shapes(quad, cam_focal)),
			),
		}
	}

	## Every list's things in one list. Things about as far away as each other
	## keep this order through the depth sort, so it decides which of two tied
	## things is painted over the other.
	things_in_tie_order : SceneShapes.ThingLists(thing) -> List(thing)
	things_in_tie_order = |lists|
		[
			lists.birds,
			lists.trees,
			lists.towers,
			lists.critters,
			lists.cats,
			lists.trucks,
			lists.rails,
		].join()

	## How many of `trees` are nearer than `forward`.
	nearer_tree_count : List(Geom.Sighted(Conifer)), Distance -> U16
	nearer_tree_count = |trees, forward| trees.count_if(|tree| tree.forward < forward).to_u16_wrap()

	## A tree, told how many of `trees` are nearer, which is all it needs of
	## the others.
	tree_rendering : Geom.Sighted(Conifer),
	{
		trees : List(Geom.Sighted(Conifer)),
		cam_focal : Pixels,
	} -> Rendered
	tree_rendering = |tree, { trees, cam_focal }|
		Pipeline.rendering_of(
			tree,
			{
				cam_focal,
				context: { nearer_tree_count: SceneShapes.nearer_tree_count(trees, tree.forward) },
			},
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

## A thing that doesn't go through `Pipeline`: its shapes, at `depth`.
rendering_at : Distance, List(Shapes.Shape) -> Rendered
rendering_at = |depth, shapes| { depth, picture: Picture.from_shapes(shapes) }

## The truck, if it is in view, where its sighting found it and with the lights
## its sighting gives it.
truck_renderings : Chain.Viewpoint, TruckSighting -> List(Rendered)
truck_renderings = |view, truck_at|
	match truck_at {
		Ahead(truck) => [
			rendering_at(
				truck.forward,
				TruckPicture.truck_shapes({
					view,
					position: truck.position,
					center: { along: truck.along, across: truck.across },
					lights: truck.lights,
				}),
			),
		]
		NoTruck => []
	}

tree_at : F64 -> Geom.Sighted(Conifer)
tree_at = |forward| {
	right: Distance.metres(0.0),
	forward: Distance.metres(forward),
	kind: Conifer.BigGreen,
}

spread_trees : List(Geom.Sighted(Conifer))
spread_trees = [10.0, 20.0, 30.0, 40.0, 50.0].map(tree_at)

expect SceneShapes.nearer_tree_count(spread_trees, Distance.metres(10.0)) == 0
expect SceneShapes.nearer_tree_count(spread_trees, Distance.metres(30.0)) == 2
expect SceneShapes.nearer_tree_count(spread_trees, Distance.metres(50.0)) == 4
expect SceneShapes.nearer_tree_count(spread_trees, Distance.metres(60.0)) == 5
expect SceneShapes.nearer_tree_count(spread_trees, Distance.metres(5.0)) == 0
expect SceneShapes.nearer_tree_count([], Distance.metres(10.0)) == 0

tied_trees : List(Geom.Sighted(Conifer))
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

cluster_sightings : List(Geom.Sighted(Conifer))
cluster_sightings = [10.0, 11.0, 12.0, 13.0, 14.0].map(tree_at)

cluster_shapes : F64 -> List(Shapes.Shape)
cluster_shapes = |forward|
	SceneShapes.tree_rendering(
		tree_at(forward),
		{ trees: cluster_sightings, cam_focal: Pixels.of(500.0) },
	).picture.to_shapes()

second_shape_points : List(Shapes.Shape) -> U64
second_shape_points = |shapes|
	match shapes {
		[_, Poly(polygon), ..] => polygon.coordinates.len()
		_ => crash "a tree in view draws a trunk and tiers"
	}

# A tree's rendering stands at the tree's own depth, and its picture is the
# conifer's, told how many of the others are nearer.
expect
	SceneShapes.tree_rendering(
		tree_at(14.0),
		{ trees: cluster_sightings, cam_focal: Pixels.of(500.0) },
	).depth
		== Distance.metres(14.0)
expect
	cluster_shapes(14.0)
		== Conifer.BigGreen.scenery_picture({
			right: Distance.metres(0.0),
			forward: Distance.metres(14.0),
			cam_focal: Pixels.of(500.0),
			context: { nearer_tree_count: 4 },
		}).to_shapes()

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
		kind: Conifer.BigGreen,
	},
}

lone_tree : Geom.Sighted(Conifer)
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
expect lone_tree.kind == Conifer.BigGreen
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

first_sightings : List(Geom.Sighted(Conifer))
first_sightings = TreeSighting.segment_sightings(from_origin, Chain.Position.first)

## The first segment's tree at `i`, in planting order.
planted_tree : U64 -> Geom.Sighted(Conifer)
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

expect planted_tree(0).kind == Conifer.BigGreen
expect planted_tree(2).kind == Conifer.SmallGreen

# The order that settles a tie, each list in its own order.
expect
	SceneShapes.things_in_tie_order({
		birds: [1, 2],
		trees: [3],
		towers: [4],
		critters: [5, 6],
		cats: [7],
		trucks: [8],
		rails: [9],
	})
		== [1, 2, 3, 4, 5, 6, 7, 8, 9]

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

expect truck_renderings(from_origin, lead_of(100.0)).len() == 1
expect truck_renderings(from_origin, lead_of(2000.0)).len() == 0
expect truck_renderings(from_origin, NoTruck).len() == 0
expect
	truck_renderings(from_origin, lead_of(499.0)).map(|rendering| rendering.depth.to_metres())
		== [truck_ahead_of(499.0).forward.to_metres()]
