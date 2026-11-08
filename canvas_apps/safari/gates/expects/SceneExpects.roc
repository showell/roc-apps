## SceneExpects holds the expects of the scene, the pipeline every kind of
## object takes through a frame, and the depth order.

import Fixtures
import game.Across
import game.Along
import game.BillboardSighting
import game.Clock
import game.Conifer
import game.Distance
import game.Picture
import game.Pipeline
import game.Pixels
import game.PosedBird
import game.RailSighting
import game.Rendered
import game.RoadAhead
import game.Scene
import game.SegmentPlace
import game.TowerSighting
import game.TreeSighting
import game.TruckSighting
import lib.Shapes

SceneExpects :: [].{}

# Scene, on the scene from the start of the route.
scene_facts : Scene.RideFacts
scene_facts = {
	encounter_timing: Unplanned,
	truck: {
		route_position: Distance.metres(500.0),
		lit_truck: { headlights: Off, brake_lights: Off },
	},
	clock: Clock.start,
}

scene : Scene
scene = Scene.scene_in_view(Fixtures.road, { camera: Fixtures.origin_camera, facts: scene_facts })

## The route's start has no cat in view, so the cats come from the second
## segment's, seen as `seen` sees them.
cat_scene : Scene
cat_scene = Scene.scene_in_view(
	Fixtures.cat_road,
	{
		camera: {
			..Fixtures.origin_camera,
			vantage: { ..Fixtures.origin, along: Along.metres(300.0) },
		},
		facts: scene_facts,
	},
)

## The depths of `renderings`, in their order.
depths_of : List(Rendered) -> List(Distance)
depths_of = |renderings| renderings.map(|rendering| rendering.depth())

## How far ahead each of `sightings` stands, in their order.
sighted_depths : List(Pipeline.Sighted(kind)) -> List(Distance)
sighted_depths = |sightings| sightings.map(|sighting| sighting.spot.foot().forward())

# Each field holds what its own sighting found, in the sighting's order, each
# thing at its own depth.
expect
	depths_of(scene.trees)
		== sighted_depths(TreeSighting.trees_in_view(Fixtures.road, Fixtures.origin_camera))
expect
	depths_of(scene.birds)
		== sighted_depths(
			Fixtures.birds_seen_on(
				Fixtures.road,
				{ camera: Fixtures.origin_camera, encounter_timing: Unplanned },
			),
		)
expect
	depths_of(scene.towers)
		== sighted_depths(
			TowerSighting.towers_in_view(
				Fixtures.road,
				{ camera: Fixtures.origin_camera, clock: Clock.start },
			),
		)
expect
	depths_of(scene.billboards)
		== sighted_depths(
			BillboardSighting.billboards_in_view(Fixtures.road, Fixtures.origin_camera),
		)
expect depths_of(cat_scene.cats) == sighted_depths(Fixtures.seen)
expect Fixtures.seen.len() > 0
expect
	scene.rails.len()
		== RailSighting.rail_quads_in_view(Fixtures.road, Fixtures.origin_camera).len()
expect
	depths_of(scene.trucks)
		== sighted_depths(
			TruckSighting.truck_in_view(
				Fixtures.road,
				{ camera: Fixtures.origin_camera, truck: scene_facts.truck },
			)
				.map_ok(|truck| [truck]) ?? [],
		)
expect scene.trucks.len() == 1
expect scene.birds.len() > 0

# The scene's shapes are every field's, the truck's among them.
expect {
	field_renderings = [
		scene.trees,
		scene.birds,
		scene.towers,
		scene.billboards,
		scene.cats,
		scene.trucks,
		scene.rails,
	].join()
	field_shapes = field_renderings.join_map(|rendering| rendering.picture().to_shapes())
	Scene.scene_shapes(scene).len() == field_shapes.len()
}

## A scene with nothing in view.
empty_scene : Scene
empty_scene = {
	trees: [],
	birds: [],
	towers: [],
	billboards: [],
	cats: [],
	trucks: [],
	rails: [],
}

## Something of `kind` `forward` metres straight ahead of the route's start, as
## its sighting finds it.
sighted_ahead : kind, F64 -> Pipeline.Sighted(kind)
sighted_ahead = |kind, forward|
	Pipeline.sighting_of(
		{
			road_point: { along: Along.metres(forward), across: Across.middle },
			lift: Distance.zero,
			kind,
		},
		{
			road: Fixtures.road,
			vantage: Fixtures.origin,
			place: Ahead(SegmentPlace.Position.first),
		},
	)
		?? crash "SceneExpects: a test's thing is past the near plane"

## A kind of object for Pipeline's expects: a post of some height, pictured as
## nothing.
Post := { height : Distance }.{

	scenery_height : Post -> Distance
	scenery_height = |post| post.height

	scenery_picture : Post, Picture.Setting({}) -> Picture
	scenery_picture = |_post, _setting| Picture.from_shapes([])
}

## The road ahead of a rider on a straight route of one segment.
straight_road : RoadAhead.RoadView
straight_road = Fixtures.crafted_road([Fixtures.segment_of([])])

## A post 1 m tall, `along` the straight road and 1.5 m right of its middle, as
## a camera at `origin` sees it.
post_sighting : F64 -> Try(Pipeline.Sighted(Post), [BehindCamera])
post_sighting = |along|
	Pipeline.sighting_of(
		{
			road_point: { along: Along.metres(along), across: Across.metres(1.5) },
			lift: Distance.zero,
			kind: Post.({ height: Distance.metres(1.0) }),
		},
		{
			road: straight_road,
			vantage: Fixtures.origin,
			place: Ahead(SegmentPlace.Position.first),
		},
	)

# The near plane is 0.4 m ahead.
expect
	[
		(0.39, Err(BehindCamera)),
		(0.4, Ok(Seen)),
		(0.41, Ok(Seen)),
	].all(|(along, outcome)| post_sighting(along).map_ok(|_| Seen) == outcome)

# A sighting on a straight road keeps the post's place, road point and lift,
# and has its foot as far right of a camera on the middle as the post is of
# the middle, and as far ahead as it is along.
expect
	match post_sighting(20.0) {
		Ok({ spot, .. }) => {
			spot.place() == Ahead(SegmentPlace.Position.first)
				and spot.road_point() == { along: Along.metres(20.0), across: Across.metres(1.5) }
				and spot.lift() == Distance.zero
				and spot.foot().right() == Distance.metres(1.5)
				and spot.foot().forward() == Distance.metres(20.0)
		}
		Err(BehindCamera) => False
	}

# A post 1 m tall, 64 m ahead, stands exactly 2 pixels tall through a lens of
# 128 pixels, the smallest height drawn.
expect
	[
		(Distance.metres(0.99), Err(TooSmall)),
		(Distance.metres(1.0), Ok(Seen)),
		(Distance.metres(1.01), Ok(Seen)),
	].all(
		|(height, outcome)|
			Pipeline.scenery_sighting_of(
				{
					road_point: { along: Along.metres(64.0), across: Across.metres(1.5) },
					lift: Distance.zero,
					kind: Post.({ height: height }),
				},
				{
					road: straight_road,
					camera: { vantage: Fixtures.origin, cam_focal: Pixels.of(128.0) },
					place: Ahead(SegmentPlace.Position.first),
				},
			).map_ok(|_| Seen)
				== outcome,
	)

# A rendering's depth is how far ahead its sighting stands.
expect
	[30.0, 64.0].all(
		|along| {
			sighting = post_sighting(along) ?? crash "SceneExpects: a post 30 m or more ahead is in view"
			rendered = Pipeline.rendering_of(sighting, { cam_focal: Pixels.of(512.0), context: {} })
			rendered.depth() == Distance.metres(along)
		},
	)

## A big green tree `forward` metres straight ahead of the route's start.
green_tree_ahead : F64 -> Pipeline.Sighted(Conifer)
green_tree_ahead = |forward| sighted_ahead(Conifer.Green, forward)

## A perched bird `forward` metres straight ahead of the route's start.
perched_bird_ahead : F64 -> Pipeline.Sighted(PosedBird)
perched_bird_ahead = |forward| sighted_ahead({ pose: Perched }, forward)

## A scene of a lone tree `forward` metres ahead.
lone_tree_scene : F64 -> Scene
lone_tree_scene = |forward| {
	..empty_scene,
	trees: [
		Pipeline.rendering_of(
			green_tree_ahead(forward),
			{ cam_focal: Fixtures.origin_camera.cam_focal, context: { nearer_tree_count: 0 } },
		),
	],
}

## A scene of a lone perched bird `forward` metres ahead.
lone_bird_scene : F64 -> Scene
lone_bird_scene = |forward| {
	..empty_scene,
	birds: [
		Pipeline.rendering_of(
			perched_bird_ahead(forward),
			{ cam_focal: Fixtures.origin_camera.cam_focal, context: {} },
		),
	],
}

## The shapes of a tree and a bird, these many metres ahead, in the order the
## frame draws them.
tree_and_bird_shapes : { tree_ahead : F64, bird_ahead : F64 } -> List(Shapes.Shape)
tree_and_bird_shapes = |{ tree_ahead, bird_ahead }| {
	tree_and_bird = { ..lone_tree_scene(tree_ahead), birds: lone_bird_scene(bird_ahead).birds }
	Scene.scene_shapes(tree_and_bird)
}

lone_tree_shapes : F64 -> List(Shapes.Shape)
lone_tree_shapes = |forward| Scene.scene_shapes(lone_tree_scene(forward))

lone_bird_shapes : F64 -> List(Shapes.Shape)
lone_bird_shapes = |forward| Scene.scene_shapes(lone_bird_scene(forward))

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

expect scene.trees.len() > 0
expect scene.towers.len() > 0
expect scene.billboards.len() > 0
expect scene.rails.len() > 0

# A segment of the road ahead shows at most two towers, the one past its end and
# the one halfway along, and the segment just behind shows one.
expect scene.towers.len() <= 2 * Fixtures.road.segments_ahead().count.to_u64() + 1
