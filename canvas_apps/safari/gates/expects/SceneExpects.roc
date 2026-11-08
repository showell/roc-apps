## SceneExpects holds the expects of the scene, the pipeline every kind of
## object takes through a frame, and the depth order.

import Fixtures
import game.Across
import game.Along
import game.Clock
import game.Conifer
import game.Distance
import game.Picture
import game.Pipeline
import game.Pixels
import game.PosedBird
import game.RoadAhead
import game.Scene
import game.SegmentPlace
import lib.Shapes

SceneExpects :: [].{}

## The scene 300 m into the cat route, where something of every field is in
## view.
cat_scene : Scene
cat_scene = Scene.scene_in_view(
	Fixtures.cat_road,
	{
		camera: {
			..Fixtures.origin_camera,
			vantage: { ..Fixtures.origin, along: Along.metres(300.0) },
		},
		facts: {
			encounter_timing: Unplanned,
			truck: {
				route_position: Distance.metres(500.0),
				lit_truck: { headlights: Off, brake_lights: Off },
			},
			clock: Clock.start,
		},
	},
)

# The scene's shapes are every field's, and no field is empty, so a field the
# scene forgot to draw would show.
expect {
	fields = [
		cat_scene.trees,
		cat_scene.birds,
		cat_scene.towers,
		cat_scene.billboards,
		cat_scene.cats,
		cat_scene.trucks,
		cat_scene.rails,
	]
	field_shapes = fields.join().join_map(|rendering| rendering.picture().to_shapes())
	fields.all(|field| !field.is_empty())
		and Scene.scene_shapes(cat_scene).len() == field_shapes.len()
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
