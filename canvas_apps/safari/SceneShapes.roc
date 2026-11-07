## SceneShapes renders the things beside the road, each by its own kind's module,
## and paints them in depth order, far to near.
import Pixels
import Across
import Along
import Angle
import Distance
import Geom
import World
import Chain
import Conifer
import GuardRail
import Picture
import Pipeline
import Rendered
import Scene
import TreeSighting
import TruckAhead
import TruckSighting
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
	## one a tree can't know alone, a critter needs none, and a tower and the
	## truck are measured on the road.
	scene_renderings : Scene, Chain.Viewpoint -> SceneShapes.ThingLists(Rendered)
	scene_renderings = |scene, view| {
		cam_focal = view.cam_focal
		{
			birds: scene.birds.map(|bird| Pipeline.rendering_of(bird, { cam_focal, context: {} })),
			trees: scene.trees.map(
				|tree| SceneShapes.tree_rendering(tree, { trees: scene.trees, cam_focal }),
			),
			towers: scene.towers.map(
				|tower| Pipeline.rendering_of(
					tower,
					{ cam_focal, context: road_context(view, tower) },
				),
			),
			critters: scene.critters.map(
				|critter| Pipeline.rendering_of(critter, { cam_focal, context: {} }),
			),
			cats: scene.cats.map(|cat| Pipeline.rendering_of(cat, { cam_focal, context: {} })),
			trucks: truck_renderings(view, scene.truck),
			rails: scene.rails.keep_oks(|quad| rail_rendering(quad, cam_focal)),
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
	nearer_tree_count : List(Pipeline.Sighted(Conifer)), Distance -> U16
	nearer_tree_count = |trees, forward| trees.count_if(|tree| tree.forward < forward).to_u16_wrap()

	## A tree, told how many of `trees` are nearer, which is all it needs of
	## the others.
	tree_rendering : Pipeline.Sighted(Conifer),
	{
		trees : List(Pipeline.Sighted(Conifer)),
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
}

## A quad of the rail, which doesn't go through `Pipeline`, at its own depth,
## unless it's wholly behind the camera.
rail_rendering : GuardRail.RailQuad, Pixels -> Try(Rendered, [BehindCamera])
rail_rendering = |quad, cam_focal|
	GuardRail.quad_shape(quad, cam_focal).map_ok(
		|shape| { depth: quad.forward, picture: Picture.from_shapes([shape]) },
	)

## What a thing measured on the road draws from: the road in view, and where on it
## `sighting` found the thing.
road_context : Chain.Viewpoint,
Pipeline.Sighted(kind) -> {
	road : Chain.RoadView,
	place : Chain.SegmentPlace,
	along : Along,
	across : Across,
}
road_context = |view, sighting| {
	road: view.road,
	place: sighting.place,
	along: sighting.along,
	across: sighting.across,
}

## The truck, if it is in view, where its sighting found it and with the lights
## its sighting gives it.
truck_renderings : Chain.Viewpoint, TruckSighting.TruckFate -> List(Rendered)
truck_renderings = |view, truck_fate|
	match truck_fate {
		Ok(truck) => [
			Pipeline.rendering_of(
				truck,
				{ cam_focal: view.cam_focal, context: road_context(view, truck) },
			),
		]
		Err(NoTruck) => []
		Err(BehindCamera) => []
	}

tree_at : F64 -> Pipeline.Sighted(Conifer)
tree_at = |forward| {
	place: InChain(Chain.Position.first),
	along: Along.metres(forward),
	across: Across.middle,
	right: Distance.metres(0.0),
	forward: Distance.metres(forward),
	kind: Conifer.BigGreen,
}

spread_trees : List(Pipeline.Sighted(Conifer))
spread_trees = [10.0, 20.0, 30.0, 40.0, 50.0].map(tree_at)

expect SceneShapes.nearer_tree_count(spread_trees, Distance.metres(10.0)) == 0
expect SceneShapes.nearer_tree_count(spread_trees, Distance.metres(30.0)) == 2
expect SceneShapes.nearer_tree_count(spread_trees, Distance.metres(50.0)) == 4
expect SceneShapes.nearer_tree_count(spread_trees, Distance.metres(60.0)) == 5
expect SceneShapes.nearer_tree_count(spread_trees, Distance.metres(5.0)) == 0
expect SceneShapes.nearer_tree_count([], Distance.metres(10.0)) == 0

tied_trees : List(Pipeline.Sighted(Conifer))
tied_trees = List.repeat(tree_at(20.0), 4)

expect SceneShapes.nearer_tree_count(tied_trees, Distance.metres(20.0)) == 0
expect SceneShapes.nearer_tree_count(tied_trees, Distance.metres(20.1)) == 4
expect SceneShapes.nearer_tree_count(tied_trees, Distance.metres(19.9)) == 0

cluster_sightings : List(Pipeline.Sighted(Conifer))
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

## The first three segments, seen from `vantage`.
first_road : Geom.Vantage -> Chain.RoadView
first_road = |vantage| {
	route_segments,
	chain_indices: [0, 1, 2].map(World.SegmentIndex.number),
	vantage,
}

## The first three segments, seen from `vantage` through a camera of focal
## length `cam_focal`.
view_from : Geom.Vantage, Pixels -> Chain.Viewpoint
view_from = |vantage, cam_focal| { road: first_road(vantage), cam_focal }

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

lone_tree : Pipeline.Sighted(Conifer)
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

first_sightings : List(Pipeline.Sighted(Conifer))
first_sightings = TreeSighting.segment_sightings(from_origin, Chain.Position.first)

## The first segment's tree at `i`, in planting order.
roadside_tree : U64 -> Pipeline.Sighted(Conifer)
roadside_tree = |i|
	first_sightings.get(i) ?? crash "SceneShapes: the first segment has 28 trees in view"

expect
	[
		(roadside_tree(0).forward.to_metres(), 6.0),
		(roadside_tree(1).forward.to_metres(), 6.0),
		(roadside_tree(2).forward.to_metres(), 36.0),
		(roadside_tree(0).right.to_metres(), -3.5),
		(roadside_tree(1).right.to_metres(), 3.5),
	].all(|(got, want)| (got - want).abs() <= 0.0001)

expect roadside_tree(0).kind == Conifer.BigGreen
expect roadside_tree(2).kind == Conifer.SmallGreen

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

## What becomes of a truck `lead` metres ahead of a rider at the start of the
## chain, seen from `vantage`, with its lights off.
truck_seen_from : Geom.Vantage, F64 -> TruckSighting.TruckFate
truck_seen_from = |vantage, lead|
	TruckSighting.truck_in_view(
		first_road(vantage),
		{ lead: Distance.metres(lead), lights: { headlights: Off, brake_lights: Off } },
	)

lead_of : F64 -> TruckSighting.TruckFate
lead_of = |lead| truck_seen_from(origin, lead)

## Where the truck is, for a lead that puts it in view.
truck_ahead_of : F64 -> Pipeline.Sighted(TruckAhead)
truck_ahead_of = |lead| lead_of(lead) ?? crash "SceneShapes: this lead puts the truck in view"

expect
	[
		(100.0, True),
		(499.0, True),
		(600.0, True),
		(900.0, True),
		(2000.0, False),
		(0.0, False),
		(-50.0, False),
	].all(|(lead, want)| lead_of(lead).is_ok() == want)

expect
	[
		(100.0, 0),
		(499.0, 0),
		(600.0, 1),
		(900.0, 2),
	].all(|(lead, want)| truck_ahead_of(lead).place == InChain(Chain.Position.number(want)))

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
lights_shown = |lights| {
	truck = TruckSighting.truck_in_view(
		first_road(origin),
		{ lead: Distance.metres(100.0), lights },
	) ?? crash "SceneShapes: this lead puts the truck in view"
	truck.kind.lights
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
		(truck_ahead_of(100.0).right.to_metres(), 0.0),
	].all(|(got, want)| (got - want).abs() <= 0.0001)

expect lead_of(2000.0).is_err()
expect truck_seen_from({ ..origin, along: Along.metres(100.0) }, 0.25).is_err()
expect truck_seen_from({ ..origin, along: Along.metres(100.0) }, 1.0).is_ok()

expect truck_renderings(from_origin, lead_of(100.0)).len() == 1
expect truck_renderings(from_origin, lead_of(2000.0)).len() == 0
expect truck_renderings(from_origin, Err(NoTruck)).len() == 0
expect truck_renderings(from_origin, Err(BehindCamera)).len() == 0
expect
	truck_renderings(from_origin, lead_of(499.0)).map(|rendering| rendering.depth.to_metres())
		== [truck_ahead_of(499.0).forward.to_metres()]
