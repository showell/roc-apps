## SceneShapes puts the things beside the road in the order a frame draws them,
## far to near, and turns them into shapes. Each thing's rendering comes from its
## own kind's module.
import Pixels
import Across
import Along
import Angle
import Distance
import Geom
import Route
import World
import RoadAhead
import SegmentPlace
import Conifer
import GuardRail
import Pipeline
import PosedBird
import Rendered
import Scene
import lib.Shapes

SceneShapes :: [].{

	## The scene's things as shapes, far to near.
	scene_shapes : Scene, RoadAhead.CameraView -> List(Shapes.Shape)
	scene_shapes = |scene, view|
		SceneShapes.scene_renderings(scene, view).join_map(
			|rendering| rendering.picture.to_shapes(),
		)

	## The scene's things, each as the frame draws it, far to near. Things about
	## as far away as each other keep the order the kinds are listed in here
	## through the depth sort, so that order decides which of two tied things is
	## drawn over the other. A critter perched on a tree is drawn over it: a
	## perched bird stands at its tree's own depth, so the trees come before the
	## birds.
	scene_renderings : Scene, RoadAhead.CameraView -> List(Rendered)
	scene_renderings = |scene, view| {
		cam_focal = view.cam_focal
		trucks =
			match scene.truck {
				Ok(truck) => [Pipeline.rendering_of(truck, { cam_focal, context: view.road })]
				Err(NoTruck) | Err(BehindCamera) => []
			}
		renderings = [
			scene.trees.map(|tree| tree_rendering(tree, { trees: scene.trees, cam_focal })),
			scene.birds.map(|bird| Pipeline.rendering_of(bird, { cam_focal, context: {} })),
			scene.towers.map(
				|tower| Pipeline.rendering_of(tower, { cam_focal, context: view.road }),
			),
			scene.billboards.map(
				|billboard| Pipeline.rendering_of(billboard, { cam_focal, context: {} }),
			),
			scene.cats.map(|cat| Pipeline.rendering_of(cat, { cam_focal, context: {} })),
			trucks,
			scene.rails.keep_oks(|quad| GuardRail.quad_rendering(quad, cam_focal)),
		].join()
		Rendered.depth_sorted_renderings(renderings)
	}
}

## How many of `trees` are nearer than `forward`.
nearer_tree_count : List(Pipeline.Sighted(Conifer)), Distance -> U16
nearer_tree_count = |trees, forward| {
	count = trees.count_if(|tree| tree.spot.foot().forward() < forward)
	count.to_u16_try() ?? crash "SceneShapes.nearer_tree_count: more than 65,535 trees in view"
}

## A tree, told how many of `trees` are nearer, which is all it needs of
## the others.
tree_rendering : Pipeline.Sighted(Conifer),
{
	trees : List(Pipeline.Sighted(Conifer)),
	cam_focal : Pixels,
} -> Rendered
tree_rendering = |tree, { trees, cam_focal }| {
	nearer_count = nearer_tree_count(trees, tree.spot.foot().forward())
	Pipeline.rendering_of(tree, { cam_focal, context: { nearer_tree_count: nearer_count } })
}

## The rider at the start of the route, looking straight down the road.
origin : Geom.Vantage
origin = {
	along: Along.metres(0.0),
	across: Across.metres(0.0),
	yaw: Angle.straight_ahead,
}

## The first three segments, seen from `origin`.
first_road : RoadAhead.RoadView
first_road = {
	route: World.route,
	segments_ahead: { first_index: Route.SegmentIndex.first, count: 3 },
	vantage: origin,
}

from_origin : RoadAhead.CameraView
from_origin = { road: first_road, cam_focal: Pixels.of(500.0) }

## Something of `kind` `forward` metres straight ahead of the route's start, as
## its sighting finds it.
sighted_ahead : kind, F64 -> Pipeline.Sighted(kind)
sighted_ahead = |kind, forward|
	Pipeline.sighting_of(
		{
			along: Along.metres(forward),
			across: Across.middle,
			lift: Distance.zero,
			kind,
		},
		{ road: first_road, place: Ahead(SegmentPlace.Position.first) },
	)
		?? crash "SceneShapes: a test's thing is past the near plane"

## A big green tree `forward` metres straight ahead of the route's start.
tree_at : F64 -> Pipeline.Sighted(Conifer)
tree_at = |forward| sighted_ahead(Conifer.Green, forward)

spread_trees : List(Pipeline.Sighted(Conifer))
spread_trees = [10.0, 20.0, 30.0, 40.0, 50.0].map(tree_at)

expect nearer_tree_count(spread_trees, Distance.metres(10.0)) == 0
expect nearer_tree_count(spread_trees, Distance.metres(30.0)) == 2
expect nearer_tree_count(spread_trees, Distance.metres(50.0)) == 4
expect nearer_tree_count(spread_trees, Distance.metres(60.0)) == 5
expect nearer_tree_count(spread_trees, Distance.metres(5.0)) == 0
expect nearer_tree_count([], Distance.metres(10.0)) == 0

tied_trees : List(Pipeline.Sighted(Conifer))
tied_trees = List.repeat(tree_at(20.0), 4)

expect nearer_tree_count(tied_trees, Distance.metres(20.0)) == 0
expect nearer_tree_count(tied_trees, Distance.metres(20.1)) == 4
expect nearer_tree_count(tied_trees, Distance.metres(19.9)) == 0

cluster_sightings : List(Pipeline.Sighted(Conifer))
cluster_sightings = [10.0, 11.0, 12.0, 13.0, 14.0].map(tree_at)

cluster_shapes : F64 -> List(Shapes.Shape)
cluster_shapes = |forward|
	tree_rendering(
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
	tree_rendering(tree_at(14.0), { trees: cluster_sightings, cam_focal: Pixels.of(500.0) }).depth
		== Distance.metres(14.0)
expect
	cluster_shapes(14.0)
		== Conifer.Green.scenery_picture({
			spot: tree_at(14.0).spot,
			cam_focal: Pixels.of(500.0),
			context: { nearer_tree_count: 4 },
		}).to_shapes()

# A near tree's tiers are cones, in more detail than a far tree's triangles.
expect cluster_shapes(10.0).len() > 0
expect cluster_shapes(14.0).len() > 0
expect second_shape_points(cluster_shapes(10.0)) > second_shape_points(cluster_shapes(14.0))
expect second_shape_points(cluster_shapes(14.0)) >= 6

## A scene of nothing but the trees `trees` and the birds `birds`.
trees_and_birds : List(Pipeline.Sighted(Conifer)), List(Pipeline.Sighted(PosedBird)) -> Scene
trees_and_birds = |trees, birds| {
	trees,
	towers: [],
	billboards: [],
	cats: [],
	rails: [],
	truck: Err(NoTruck),
	birds,
}

## A perched bird `forward` metres straight ahead of the route's start.
bird_at : F64 -> Pipeline.Sighted(PosedBird)
bird_at = |forward| sighted_ahead({ pose: Perched }, forward)

## The shapes of a tree and a bird, these many metres ahead, in the order the
## frame draws them.
tree_and_bird_shapes : { tree_ahead : F64, bird_ahead : F64 } -> List(Shapes.Shape)
tree_and_bird_shapes = |{ tree_ahead, bird_ahead }|
	SceneShapes.scene_shapes(
		trees_and_birds([tree_at(tree_ahead)], [bird_at(bird_ahead)]),
		from_origin,
	)

## The shapes of a tree alone, `forward` metres ahead.
lone_tree_shapes : F64 -> List(Shapes.Shape)
lone_tree_shapes = |forward|
	SceneShapes.scene_shapes(trees_and_birds([tree_at(forward)], []), from_origin)

## The shapes of a bird alone, `forward` metres ahead.
lone_bird_shapes : F64 -> List(Shapes.Shape)
lone_bird_shapes = |forward|
	SceneShapes.scene_shapes(trees_and_birds([], [bird_at(forward)]), from_origin)

# A bird perched on a tree stands at the tree's depth and is drawn over it.
# A bird that isn't perched is drawn by its own depth: behind a nearer tree,
# and over a farther one.
expect
	tree_and_bird_shapes({ tree_ahead: 40.0, bird_ahead: 40.0 })
		== lone_tree_shapes(40.0).concat(lone_bird_shapes(40.0))
expect
	tree_and_bird_shapes({ tree_ahead: 30.0, bird_ahead: 40.0 })
		== lone_bird_shapes(40.0).concat(lone_tree_shapes(30.0))
expect
	tree_and_bird_shapes({ tree_ahead: 40.0, bird_ahead: 30.0 })
		== lone_tree_shapes(40.0).concat(lone_bird_shapes(30.0))
expect lone_tree_shapes(40.0).len() > 0
expect lone_bird_shapes(40.0).len() > 0
