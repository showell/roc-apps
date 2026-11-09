## SceneExpects holds the expects of the scene, the pipeline every kind of
## object takes through a frame, and the depth order.

import Fixtures
import game.Across
import game.Along
import game.Clock
import game.Conifer
import game.Distance
import game.EncounterSighting
import game.FrameView
import game.Picture
import game.Pipeline
import game.Pixels
import game.Bird
import game.RoadAhead
import game.Scene
import game.SegmentFromRider
import game.Spot
import game.Tour
import game.TowerSighting
import game.TruckSighting
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
			encounter_stage: Waiting,
			truck: {
				route_position: Distance.metres(500.0),
				truck: { headlights: Off, brake_lights: Off },
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
		and Scene.scene_shape_lists(cat_scene).join().len() == field_shapes.len()
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
			place: Ahead(SegmentFromRider.Position.first),
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
one_segment_road : RoadAhead.RoadView
one_segment_road = Fixtures.crafted_road([Fixtures.segment_of([])])

## A post 1 m tall, `along` the one-segment road and 1.5 m right of its middle, as
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
			road: one_segment_road,
			vantage: Fixtures.origin,
			place: Ahead(SegmentFromRider.Position.first),
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
					road: one_segment_road,
					camera: { vantage: Fixtures.origin, focal_length: Pixels.of(128.0) },
					place: Ahead(SegmentFromRider.Position.first),
				},
			).map_ok(|_| Seen)
				== outcome,
	)

# A post 1000 m along stands 5 m below level, where the ground has dropped, and
# the line from the eye that grazes the horizon passes 3.699 m below level there.
# A post 1.4 m tall shows its top over the horizon; one 1.2 m tall is hidden.
expect
	[(Distance.metres(1.2), Err(BelowHorizon)), (Distance.metres(1.4), Ok(Seen))].all(
		|(height, outcome)|
			Pipeline.sighting_above_horizon_of(
				{
					road_point: { along: Along.metres(1000.0), across: Across.metres(1.5) },
					lift: Distance.zero,
					kind: Post.({ height: height }),
				},
				{
					road: one_segment_road,
					vantage: Fixtures.origin,
					place: Ahead(SegmentFromRider.Position.first),
				},
			).map_ok(|_| Seen)
				== outcome,
	)

## A big green tree `forward` metres straight ahead of the route's start.
green_tree_ahead : F64 -> Pipeline.Sighted(Conifer)
green_tree_ahead = |forward| sighted_ahead(Conifer.Green, forward)

## A perched bird `forward` metres straight ahead of the route's start.
perched_bird_ahead : F64 -> Pipeline.Sighted(Bird)
perched_bird_ahead = |forward| sighted_ahead({ pose: Perched }, forward)

## A scene of a lone tree `forward` metres ahead.
lone_tree_scene : F64 -> Scene
lone_tree_scene = |forward| {
	..empty_scene,
	trees: [
		Pipeline.rendering_of(
			green_tree_ahead(forward),
			{
				focal_length: Fixtures.origin_camera.focal_length,
				context: { nearer_tree_count: 0 },
			},
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
			{ focal_length: Fixtures.origin_camera.focal_length, context: {} },
		),
	],
}

## The shapes of a tree and a bird, these many metres ahead, in the order the
## frame draws them.
tree_and_bird_shapes : { tree_ahead : F64, bird_ahead : F64 } -> List(Shapes.Shape)
tree_and_bird_shapes = |{ tree_ahead, bird_ahead }| {
	tree_and_bird = { ..lone_tree_scene(tree_ahead), birds: lone_bird_scene(bird_ahead).birds }
	Scene.scene_shape_lists(tree_and_bird).join()
}

lone_tree_shapes : F64 -> List(Shapes.Shape)
lone_tree_shapes = |forward| Scene.scene_shape_lists(lone_tree_scene(forward)).join()

lone_bird_shapes : F64 -> List(Shapes.Shape)
lone_bird_shapes = |forward| Scene.scene_shape_lists(lone_bird_scene(forward)).join()

# A bird perched on a tree stands at the tree's depth and is drawn over it.
# A bird at a different depth from the tree is drawn by its own depth: behind a
# nearer tree, and over a farther one.
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

## Step 1,529 of the ride, the frame the book shows with a cat frozen in the
## road. The book states these numbers, and the expects below hold them.
book_tour : Tour
book_tour = Tour.at_step(Clock.at_step(1529))

book_view : FrameView
book_view = FrameView.frame_view_at(book_tour.route(), book_tour.instant())

book_shapes : List(Shapes.Shape)
book_shapes = FrameView.ride_shape_lists(book_view).join()

is_polygon : Shapes.Shape -> Bool
is_polygon = |shape|
	match shape {
		Poly(_) => True
		Disc(_) | Rect(_) | Blend(_) | View(_) | Image(_) | Text(_) => False
	}

is_disc : Shapes.Shape -> Bool
is_disc = |shape|
	match shape {
		Disc(_) => True
		Poly(_) | Rect(_) | Blend(_) | View(_) | Image(_) | Text(_) => False
	}

# The Roadside trees chapter: 136 trees in view. The platform chapter's shapes
# by tag: every one of them is a Poly or a Disc.
expect book_view.scene.trees.len() == 136
expect book_shapes.len() == 2121
expect book_shapes.keep_if(is_polygon).len() == 2113
expect book_shapes.keep_if(is_disc).len() == 8

# The modules chapter's sighting: one cat, frozen on the ground about 0.38 m
# right of the camera and 23.63 m ahead.
expect {
	route = book_tour.route()
	instant = book_tour.instant()
	camera = FrameView.camera_at(route, instant)
	road = RoadAhead.RoadView.ahead_of(route, camera.route_place.segment_index)
	encounter = {
		camera: camera.sighting_camera(),
		encounter_stage: FrameView.ride_facts(route, instant).encounter_stage,
	}
	match EncounterSighting.cats_in_view(road, encounter) {
		[cat] => {
			right = cat.spot.foot().right().to_metres()
			forward = cat.spot.foot().forward().to_metres()
			cat.kind.pose == Frozen
				and cat.spot.lift() == Distance.zero
				and right > 0.375
				and right < 0.385
				and forward > 23.625
				and forward < 23.635
		}
		_ => False
	}
}

## The road ahead at step 1,529.
book_road : RoadAhead.RoadView
book_road = RoadAhead.RoadView.ahead_of(
	book_tour.route(),
	FrameView.camera_at(book_tour.route(), book_tour.instant()).route_place.segment_index,
)

## The camera the sightings of step 1,529 are made through.
book_sighting_camera : Pipeline.SightingCamera
book_sighting_camera = FrameView.camera_at(book_tour.route(), book_tour.instant()).sighting_camera()

## Whether `got` rounds to `want` at the book's two places.
is_near : F64, F64 -> Bool
is_near = |got, want| (got - want).abs() < 0.005

## Every tree on the segments in view at step 1,529: the segment it stands on,
## its kind, where the camera sees its foot, and what its sighting decides.
book_trees : List(
	{
		segments_before : U64,
		kind : Conifer,
		metres_right : F64,
		metres_forward : F64,
		fate : [Drawn, BehindCamera, BelowHorizon, TooSmall],
	},
)
book_trees = RoadAhead.segments_in_view(book_road).join_map(
	|in_view|
		in_view.segment.trees.map(
			|tree| {
				place = in_view.place
				seen = RoadAhead.rider_point_at(
					book_road,
					{ vantage: book_sighting_camera.vantage, place, road_point: tree.road_point },
				)
				sighting = Pipeline.scenery_sighting_of(
					tree,
					{ road: book_road, camera: book_sighting_camera, place },
				)
				fate =
					match sighting {
						Ok(_) => Drawn
						Err(BehindCamera) => BehindCamera
						Err(BelowHorizon) => BelowHorizon
						Err(TooSmall) => TooSmall
					}
				{
					segments_before: in_view.index.count_before(),
					kind: tree.kind,
					metres_right: seen.right.to_metres(),
					metres_forward: seen.forward.to_metres(),
					fate,
				}
			},
		),
)

## Whether one of the book's trees stands where the sightings table says.
has_book_tree : {
	segments_before : U64,
	kind : Conifer,
	metres_right : F64,
	metres_forward : F64,
	fate : [Drawn, BehindCamera, BelowHorizon, TooSmall],
} -> Bool
has_book_tree = |want|
	book_trees.any(
		|tree|
			tree.segments_before == want.segments_before
				and tree.kind == want.kind
				and is_near(tree.metres_right, want.metres_right)
				and is_near(tree.metres_forward, want.metres_forward)
				and tree.fate == want.fate,
	)

## Whether no tree of the book's that met `fate` stands nearer ahead than
## `metres_forward`, at the book's rounding.
is_nearest_ahead : [Drawn, BehindCamera, BelowHorizon, TooSmall], F64 -> Bool
is_nearest_ahead = |fate, metres_forward|
	book_trees.all(|tree| tree.fate != fate or tree.metres_forward > metres_forward - 0.005)

## Whether `spot` is `metres_right` and `metres_forward` from the camera, at
## the book's rounding.
is_seen_at : Spot, { metres_right : F64, metres_forward : F64 } -> Bool
is_seen_at = |spot, { metres_right, metres_forward }| {
	foot = spot.foot()
	is_near(foot.right().to_metres(), metres_right)
		and is_near(foot.forward().to_metres(), metres_forward)
}

# The modules chapter's table of step 1,529: 214 trees on the segments in view,
# 136 drawn, 30 behind the camera, 48 below the horizon and none too small.
expect book_trees.len() == 214
expect book_trees.count_if(|tree| tree.fate == Drawn) == 136
expect book_trees.count_if(|tree| tree.fate == BehindCamera) == 30
expect book_trees.count_if(|tree| tree.fate == BelowHorizon) == 48
expect book_trees.count_if(|tree| tree.fate == TooSmall) == 0

# The table's trees: the nearest drawn, the nearest behind the camera, the
# nearest below the horizon, and a taller one just past it that shows.
expect
	has_book_tree({
		segments_before: 3,
		kind: Conifer.Green,
		metres_right: 3.45,
		metres_forward: 21.63,
		fate: Drawn,
	})
expect is_nearest_ahead(Drawn, 21.63)
expect
	has_book_tree({
		segments_before: 3,
		kind: Conifer.Gold,
		metres_right: -8.09,
		metres_forward: -8.36,
		fate: BehindCamera,
	})
expect book_trees.all(|tree| tree.fate != BehindCamera or tree.metres_forward < -8.36 + 0.005)
expect
	has_book_tree({
		segments_before: 8,
		kind: Conifer.SmallGreen,
		metres_right: -1433.43,
		metres_forward: 446.0,
		fate: BelowHorizon,
	})
expect is_nearest_ahead(BelowHorizon, 446.0)
expect
	has_book_tree({
		segments_before: 8,
		kind: Conifer.Green,
		metres_right: -1446.07,
		metres_forward: 473.21,
		fate: Drawn,
	})

# The table's tower, the one past the end of the rider's segment, which comes
# first, and the truck.
expect {
	clock = book_tour.instant().clock
	vantage = book_sighting_camera.vantage
	match TowerSighting.towers_in_view(book_road, { vantage, clock }) {
		[tower, ..] => is_seen_at(tower.spot, { metres_right: 20.4, metres_forward: 355.61 })
		[] => False
	}
}
expect {
	truck = FrameView.ride_facts(book_tour.route(), book_tour.instant()).truck
	vantage = book_sighting_camera.vantage
	match TruckSighting.truck_in_view(book_road, { vantage, truck }) {
		Ok(sighted) => is_seen_at(sighted.spot, { metres_right: 92.19, metres_forward: 489.15 })
		Err(_) => False
	}
}
