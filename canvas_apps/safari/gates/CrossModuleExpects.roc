## CrossModuleExpects holds the expects that can't sit beside their code. A road
## view needs a place along the road, a place across it and a turn, and most
## sightings import none of them; the scene and a ride that has finished need more
## again. No module of the game sees all of what these checks do, and the game
## shouldn't import a module for a test, so they sit here, where the gate reaches
## them as one of its roots.
app [main!] { game: "../game.roc", lib: "../../lib/main.roc" }

import game.Pixels
import game.Across
import game.Along
import game.Angle
import game.Animation
import game.EncounterPlan
import game.Attention
import game.Beacon
import game.BendInView
import game.Billboard
import game.BirdFlight
import game.BirdStills
import game.Camera
import game.Cat
import game.CatCrossing
import game.Clock
import game.Coast
import game.Conifer
import game.EncounterPoses
import game.EncounterSighting
import game.BillboardSighting
import game.Distance
import game.EmojiStills
import game.EncounterReaction
import game.Fraction
import game.FrameView
import game.Gawking
import game.Gaze
import game.RoadAhead
import game.Route
import game.Segment
import game.SegmentPlace
import game.Geom
import game.Motorcycle
import game.Mountains
import game.LeanSearch
import game.Lens
import game.LitTruck
import game.GroundPatch
import game.GroundSighting
import game.Picture
import game.Pipeline
import game.Pond
import game.PosedBird
import game.PosedCat
import game.RailSighting
import game.Rendered
import game.Scene
import game.RideInstant
import game.RiderCamera
import game.RiderState
import game.Screen
import game.Sky
import game.Speed
import game.Spot
import game.Steps
import game.Still
import game.StillShapes
import game.Sun
import game.Throttle
import game.Tour
import game.Tower
import game.TowerSighting
import game.TreeSighting
import game.TruckSighting
import game.Trees
import game.VehicleLimits
import game.Wildlife
import game.World
import lib.Brush
import lib.RgbColor
import lib.Shapes

main! = |_args| Ok({})

## The rider at the start of a segment, in the middle of the road, looking
## straight down it.
origin : Geom.Vantage
origin = {
	along: Along.metres(0.0),
	across: Across.metres(0.0),
	yaw: Angle.straight_ahead,
}

## The camera at `origin`, with a focal length of 500 pixels.
origin_camera : { vantage : Geom.Vantage, cam_focal : Pixels }
origin_camera = { vantage: origin, cam_focal: Pixels.of(500.0) }

## The road ahead of a rider on the world's segment `number`.
world_road_at : U32 -> RoadAhead.RoadView
world_road_at = |number| RoadAhead.RoadView.ahead_of(World.route, Route.SegmentIndex.number(number))

## The road ahead of a rider on the route's first segment.
road : RoadAhead.RoadView
road = world_road_at(0)

## The segment after the rider's own on the road ahead.
second_position : SegmentPlace.Position
second_position = SegmentPlace.Position.first.next()

# Positions count along the road ahead from the rider's segment, not along the
# route from its start.
expect {
	from_third = world_road_at(2)
	length_at = |position| RoadAhead.segment_at(from_third, position).length
	length_of = |number| World.route.segment_at(Route.SegmentIndex.number(number)).length
	length_of(2) != length_of(0)
		and length_of(3) != length_of(1)
		and length_at(SegmentPlace.Position.first) == length_of(2)
		and length_at(SegmentPlace.Position.first.next()) == length_of(3)
}

# The road ahead holds as many segments as the rider can see, seven, or the rest
# of the route. Here the route has nine.
expect {
	nine_segments = List.repeat(going_straight_on(segment_of([])), 8).append(segment_of([]))
	route = Route.from_segments(nine_segments)
	[
		(0, 7),
		(2, 7),
		(3, 6),
		(5, 4),
		(8, 1),
	].all(
		|(number, want)| {
			road_view = RoadAhead.RoadView.ahead_of(route, Route.SegmentIndex.number(number))
			road_view.segments_ahead().count == want
		},
	)
}

expect [
	(0, 0),
	(3, 3),
].all(|(first, want)| RoadAhead.rider_segment_index(world_road_at(first)).to_i64() == want)

## The route's number of the segment in view just behind a rider on the
## world's segment `first`, or -1 at the route's start.
number_behind : U32 -> I64
number_behind = |first| {
	behind = RoadAhead.segments_in_view(world_road_at(first)).find_last(
		|in_view|
			match in_view.place {
				JustBehind => True
				Ahead(_) => False
			},
	)
	match behind {
		Ok(in_view) => in_view.index.to_i64()
		Err(NotFound) => -1
	}
}

expect
	[
		(0, -1),
		(1, 0),
		(3, 2),
	].all(|(input, want)| number_behind(input) == want)

## A camera 100 m along the rider's segment, 1 m right of the middle, turned
## 0.2 radians to the right.
turned_vantage : Geom.Vantage
turned_vantage = {
	along: Along.metres(100.0),
	across: Across.metres(1.0),
	yaw: Angle.Turn.radians(0.2),
}

## The point 50 m along and 1 m right on the segment at `place` on `road_view`,
## as `turned_vantage` sees it.
turned_point_at : RoadAhead.RoadView, SegmentPlace -> Geom.RiderPoint
turned_point_at = |road_view, place|
	RoadAhead.rider_point_at(
		road_view,
		{
			vantage: turned_vantage,
			place,
			road_point: { along: Along.metres(50.0), across: Across.metres(1.0) },
		},
	)

expect {
	at_d0 = turned_point_at(road, Ahead(SegmentPlace.Position.first))
	second_segment_point = turned_point_at(road, Ahead(second_position))
	[
		(at_d0.right.to_metres(), 9.933466539753061),
		(at_d0.forward.to_metres(), -49.00332889206208),
		(second_segment_point.right.to_metres(), -48.11621135085446),
		(second_segment_point.forward.to_metres(), 431.95658232777186),
	].all(|(got, want)| (got - want).abs() <= 0.00000005 * want.abs().max(1.0))
}

left_turn : Angle.Turn
left_turn = Angle.Turn.radians(-1.2217304763960306)

right_turn : Angle.Turn
right_turn = Angle.Turn.radians(0.8726646259971648)

## The road ahead of a rider on the second of two segments, the first 300 m
## long and bending by `turn` into the second.
road_past_bend : Angle.Turn -> RoadAhead.RoadView
road_past_bend = |turn|
	RoadAhead.RoadView.ahead_of(
		Route.from_segments([
			{
				..segment_of([]),
				length: Distance.metres(300.0),
				ending: Bends({ turn, bend_life: Quiet }),
			},
			segment_of([]),
		]),
		Route.SegmentIndex.number(1),
	)

expect
	[
		(
			turned_point_at(road_past_bend(left_turn), JustBehind).right.to_metres(),
			-194.76069932822074,
		),
		(
			turned_point_at(road_past_bend(left_turn), JustBehind).forward.to_metres(),
			-231.63435691739767,
		),
		(
			turned_point_at(road_past_bend(right_turn), JustBehind).right.to_metres(),
			239.9883995667414,
		),
		(
			turned_point_at(road_past_bend(right_turn), JustBehind).forward.to_metres(),
			-218.13274420105967,
		),
	].all(|(got, want)| (got - want).abs() <= 0.0000001 * want.abs().max(1.0))

## The segment in view just behind the rider on `road_view`, which must have
## one.
segment_in_view_behind : RoadAhead.RoadView -> RoadAhead.SegmentInView
segment_in_view_behind = |road_view|
	match RoadAhead.segments_in_view(road_view).last() {
		Ok(in_view) if in_view.place == JustBehind => in_view
		_ => crash "CrossModuleExpects.segment_in_view_behind: this rider has a segment behind"
	}

## The apex of a bend from a segment 300 m long, just behind the rider's, as
## `turned_vantage` sees it.
apex_after_turn : Angle.Turn -> Geom.RiderPoint
apex_after_turn = |turn| {
	road_view = road_past_bend(turn)
	bend_in_view = BendInView.of_in_view(segment_in_view_behind(road_view))
	RoadAhead.rider_point_at(
		road_view,
		{
			vantage: turned_vantage,
			place: bend_in_view.place_before(),
			road_point: bend_in_view.outer_corner().apex,
		},
	)
}

# Each is within 1e-7 of its want, scaled up by a want past 1.
expect
	[
		(apex_after_turn(right_turn).right.to_metres(), 17.297297467543466),
		(apex_after_turn(right_turn).forward.to_metres(), -100.43071597950589),
		(apex_after_turn(left_turn).right.to_metres(), 21.403438709482494),
		(apex_after_turn(left_turn).forward.to_metres(), -100.55298847633645),
	].all(|(got, want)| (got - want).abs() <= 0.0000001 * want.abs().max(1.0))

polygon_of : Shapes.Shape -> { coordinates : List(F64), fill : Brush.Fill }
polygon_of = |shape|
	match shape {
		Poly(polygon) => polygon
		Disc(_) | Rect(_) | Blend(_) | View(_) | Image(_) | Text(_) =>
			crash "CrossModuleExpects.polygon_of: this shape is not a polygon"
	}

## A polygon's coordinates, flat as x0, y0, x1, y1, ...
coordinates_of : Shapes.Shape -> List(F64)
coordinates_of = |shape| polygon_of(shape).coordinates

## A flat polygon's colour.
flat_color_of : Shapes.Shape -> RgbColor
flat_color_of = |shape|
	match polygon_of(shape).fill {
		Flat(color) => {
			red = color.r.to_i64_wrap()
			green = color.g.to_i64_wrap()
			blue = color.b.to_i64_wrap()
			RgbColor.of(red * 65536 + green * 256 + blue)
		}
		Span(_) | Radial(_) | Linear(_) | Ellipse(_) | Glow(_) =>
			crash "CrossModuleExpects.flat_color_of: this polygon is not flat"
	}

# EncounterSighting's birds, on a straight segment with its fifth left tree 100 m along: a bird
# sits, flies and lands as the rider comes, stays where no tree is far enough to
# fly to, and is left out with no tree for it, behind the near plane or too small
# to draw.
tree_at : F64, F64 -> Trees.RoadsideTree
tree_at = |along, across| {
	road_point: { along: Along.metres(along), across: Across.metres(across) },
	lift: Distance.zero,
	kind: Conifer.Red,
}

left_trees : List(Trees.RoadsideTree)
left_trees = [20.0, 40.0, 60.0, 80.0, 100.0].map(|along| tree_at(along, -6.0))

far_tree : Trees.RoadsideTree
far_tree = { ..tree_at(130.0, 6.0), kind: Conifer.Gold }

## How high a bird perches on a left tree, and on the far tree.
left_top : F64
left_top = Conifer.Red.scenery_height().to_metres()

far_top : F64
far_top = Conifer.Gold.scenery_height().to_metres()

# Every segment the route plans with a bird has a tree for it to start on and
# one to fly to, or building the segment crashes: every bird flies, and each
# segment meets what its plan says.
expect
	World.route.route_segments().map(
		|segment|
			match segment.encounter {
				CatCrosses(_) => CatCrosses
				BirdHere(_) => BirdHere
				QuietRoad => QuietRoad
			},
	)
		== World.segment_plans.map(|plan| plan.encounter)

## A segment 200 m long holding only `trees`, with a quiet road, which ends a
## route.
segment_of : List(Trees.RoadsideTree) -> Segment
segment_of = |trees| {
	..World.route.segment_at(Route.SegmentIndex.first),
	length: Distance.metres(200.0),
	trees,
	ending: RouteEnds,
	encounter: QuietRoad,
}

## The road ahead of a rider on the first of `segments`, a route of their own.
crafted_road : List(Segment) -> RoadAhead.RoadView
crafted_road = |segments|
	RoadAhead.RoadView.ahead_of(Route.from_segments(segments), Route.SegmentIndex.first)

## `segment`, bending straight on into another.
going_straight_on : Segment -> Segment
going_straight_on = |segment| {
	..segment,
	ending: Bends({ turn: Angle.straight_ahead, bend_life: Animal(Elephant) }),
}

## The trees of a segment with a bird: five on the left, and one on the far
## side to fly to.
bird_trees : List(Trees.RoadsideTree)
bird_trees = left_trees.append(far_tree)

## The flight of a bird on `bird_trees`, from the fifth left tree to the far
## one.
bird_flight : BirdFlight.Flight
bird_flight = { from: tree_at(100.0, -6.0), to: far_tree }

## A segment of `bird_trees` with its bird.
bird_segment : Segment
bird_segment = { ..segment_of(bird_trees), encounter: BirdHere(bird_flight) }

## A flight that started at step 100, at step `now`.
flight_at_step : U32 -> EncounterPlan.Timing
flight_at_step = |now| EncounterPlan.timing_of(StartsAt(Clock.at_step(100)), Clock.at_step(now))

# Each segment ends where the lengths before it and its own add up to.
expect {
	stretches =
		Route.from_segments([
			{ ..going_straight_on(segment_of([])), length: Distance.metres(300.0) },
			{ ..going_straight_on(segment_of([])), length: Distance.metres(150.0) },
			{ ..segment_of([]), length: Distance.metres(50.0) },
		]).segments_with_ends()
	lengths = stretches.map(|stretch| stretch.segment.length.to_metres())
	ends = stretches.map(|stretch| stretch.end.to_metres())
	lengths == [300.0, 150.0, 50.0] and ends == [300.0, 450.0, 500.0]
}

## The birds on `segment`, alone on its route, for a rider `rider_along` metres
## into it, seen through a focal length of `cam_focal`, with the bird's flight
## at `encounter_timing`.
birds_on : Segment,
{
	rider_along : F64,
	cam_focal : Pixels,
	encounter_timing : EncounterPlan.Timing,
} -> List(Pipeline.Sighted(PosedBird))
birds_on = |segment, { rider_along, cam_focal, encounter_timing }|
	birds_seen_on(
		RoadAhead.RoadView.ahead_of(Route.from_segments([segment]), Route.SegmentIndex.first),
		{
			camera: { vantage: { ..origin, along: Along.metres(rider_along) }, cam_focal },
			encounter_timing,
		},
	)

## The one bird that a rider `rider_along` metres in sees, with its flight at
## `encounter_timing`.
bird_at : F64, EncounterPlan.Timing -> Pipeline.Sighted(PosedBird)
bird_at = |rider_along, encounter_timing|
	birds_on(bird_segment, { rider_along, cam_focal: Pixels.of(500.0), encounter_timing }).first()
		?? crash "CrossModuleExpects: this rider sees a bird"

## How far off a bird is, across the road and up.
place_numbers : Pipeline.Sighted(PosedBird) -> List(F64)
place_numbers = |bird| [
	bird.spot.foot().right().to_metres(),
	bird.spot.foot().forward().to_metres(),
	bird.spot.lift().to_metres(),
]

# Before its flight the bird sits on the fifth left tree, wherever the rider is,
# and after it on the far tree.
expect place_numbers(bird_at(0.0, Unplanned)) == [-6.0, 100.0, left_top]
expect place_numbers(bird_at(40.0, flight_at_step(99))) == [-6.0, 60.0, left_top]
expect place_numbers(bird_at(85.0, flight_at_step(136))) == [6.0, 45.0, far_top]
expect bird_at(40.0, flight_at_step(99)).kind.pose == Perched
expect bird_at(85.0, flight_at_step(136)).kind.pose == Perched

# In flight, the bird is where its flight's frame for the step says.
expect {
	bird = bird_at(40.0, flight_at_step(118))
	frame = BirdFlight.instant_at(bird_flight, Playing(Steps.of(18)))
	[
		(bird.spot.foot().right().to_metres(), frame.location.across.to_metres()),
		(bird.spot.foot().forward().to_metres(), frame.location.along.to_metres() - 40.0),
		(bird.spot.lift().to_metres(), frame.location.lift.to_metres()),
	].all(|(got, want)| (got - want).abs() <= 0.000000001)
		and bird.kind.pose == frame.pose
		and bird.kind.pose != Perched
}

## How many birds a rider sees on `bird_segment` for each rider and focal
## length, before the flight.
bird_count : { rider_along : F64, cam_focal : Pixels } -> I64
bird_count = |{ rider_along, cam_focal }| {
	birds = birds_on(bird_segment, { rider_along, cam_focal, encounter_timing: Unplanned })
	birds.len().to_i64_wrap()
}

## A segment where a cat crosses, with the same trees: it has no bird.
segment_with_cat : Segment
segment_with_cat = {
	..segment_of(bird_trees),
	encounter: World.route.segment_at(Route.SegmentIndex.number(3)).encounter,
}

expect bird_count({ rider_along: 0.0, cam_focal: Pixels.of(500.0) }) == 1
expect bird_count({ rider_along: 99.5, cam_focal: Pixels.of(500.0) }) == 1
expect bird_count({ rider_along: 99.7, cam_focal: Pixels.of(500.0) }) == 0
expect bird_count({ rider_along: 120.0, cam_focal: Pixels.of(500.0) }) == 0
expect bird_count({ rider_along: 0.0, cam_focal: Pixels.of(91.0) }) == 1
expect bird_count({ rider_along: 0.0, cam_focal: Pixels.of(90.0) }) == 0
expect
	birds_seen_on(
		RoadAhead.RoadView.ahead_of(
			Route.from_segments([segment_with_cat]),
			Route.SegmentIndex.first,
		),
		{ camera: origin_camera, encounter_timing: Unplanned },
	).len()
		== 0

## Two segments on the road ahead, the rider at the start of the first, whose
## bird is in flight.
two_segments : List(Pipeline.Sighted(PosedBird))
two_segments = birds_seen_on(
	RoadAhead.RoadView.ahead_of(
		Route.from_segments([going_straight_on(bird_segment), bird_segment]),
		Route.SegmentIndex.first,
	),
	{ camera: origin_camera, encounter_timing: flight_at_step(118) },
)

# Only the rider's own segment plays its encounter: the bird ahead still sits.
expect
	match two_segments.map(|bird| bird.kind.pose) {
		[near, far] => near != Perched and far == Perched
		_ => crash "CrossModuleExpects: each of two segments has a bird in view"
	}

# TreeSighting looks at the segment just behind the rider too. A tree 5 m short
# of the bend out of it stands in front of a rider at the bend once the bend is
# sharper than a right angle, and behind the rider at a gentle bend.
## The trees in view of a rider at the start of the second of two segments,
## the first holding one tree 5 m short of its bend of `degrees`.
past_bend_trees : F64 -> List(Pipeline.Sighted(Conifer))
past_bend_trees = |degrees| {
	segment_road_past_segment = {
		..segment_of([tree_at(195.0, 0.0)]),
		ending: Bends({ turn: Angle.Turn.degrees(degrees), bend_life: Animal(Elephant) }),
		encounter: QuietRoad,
	}
	rider_segment = { ..segment_of([]), encounter: QuietRoad }
	TreeSighting.trees_in_view(
		RoadAhead.RoadView.ahead_of(
			Route.from_segments([segment_road_past_segment, rider_segment]),
			Route.SegmentIndex.number(1),
		),
		origin_camera,
	)
}

## Whether `trees` is one tree, sighted on the segment just behind the rider.
is_one_tree_behind : List(Pipeline.Sighted(Conifer)) -> Bool
is_one_tree_behind = |trees|
	match trees.map(|tree| tree.spot.place()) {
		[JustBehind] => True
		_ => False
	}

expect is_one_tree_behind(past_bend_trees(150.0))
expect is_one_tree_behind(past_bend_trees(-150.0))
expect past_bend_trees(30.0).len() == 0
expect past_bend_trees(-80.0).len() == 0

# RailSighting: the rail at a bend runs along the outer edge, from 10 m before
# the bend on the segment before it to 10 m into the segment after it. On a
# 300 m segment turning right by a right angle, the outer edge is the left one.
## The road ahead of a rider at the start of a 300 m segment that turns right by
## a right angle into another.
right_angle_road : RoadAhead.RoadView
right_angle_road = crafted_road([
	{
		..segment_of([]),
		length: Distance.metres(300.0),
		ending: Bends({ turn: Angle.Turn.degrees(90.0), bend_life: Quiet }),
	},
	segment_of([]),
])

## Where the rail's path starts and ends, as the rider sees it. Each bar joins
## two points of the path, and the posts follow the bars, one at each point, so
## a path of `n` points makes `2n - 1` quads, and the last bar ends the path.
rail_ends : { start : Geom.RaisedPoint, end : Geom.RaisedPoint }
rail_ends = {
	quads = RailSighting.rail_quads_in_view(right_angle_road, { vantage: origin })
	last_bar = (quads.len() - 1) / 2 - 1
	corners_of = |quad_index|
		match quads.get(quad_index) {
			Ok(quad) => quad.corners
			Err(OutOfBounds) => crash "CrossModuleExpects: the rail has a bar at each end of its path"
		}
	{ start: corners_of(0).low_start, end: corners_of(last_bar).low_end }
}

## The point on the left edge `along` metres into the segment at `place` on the
## right-angle road, as the rider sees it.
left_edge_point : SegmentPlace, F64 -> Geom.RiderPoint
left_edge_point = |place, along|
	RoadAhead.rider_point_at(
		right_angle_road,
		{
			vantage: origin,
			place,
			road_point: { along: Along.metres(along), across: Geom.left_edge },
		},
	)

expect {
	start = left_edge_point(Ahead(SegmentPlace.Position.first), 290.0)
	end = left_edge_point(Ahead(second_position), 10.0)
	[
		(rail_ends.start.right, start.right),
		(rail_ends.start.forward, start.forward),
		(rail_ends.end.right, end.right),
		(rail_ends.end.forward, end.forward),
	].all(|(got, want)| (got.to_metres() - want.to_metres()).abs() <= 0.000001)
		and start.right.to_metres() == -2.0
		and start.forward.to_metres() == 290.0
}

# TreeSighting keeps each segment's trees in the order they were planted,
# leaving out those behind the camera and those too small to draw, and goes
# through the segments in view in turn.
## Where each tree in view stands for a rider 10 m into `segments`, seen through
## `cam_focal`: right of the camera, then ahead of it.
tree_places : List(Segment), Pixels -> List((F64, F64))
tree_places = |segments, cam_focal|
	TreeSighting.trees_in_view(
		crafted_road(segments),
		{ vantage: { ..origin, along: Along.metres(10.0) }, cam_focal },
	).map(|tree| (tree.spot.foot().right().to_metres(), tree.spot.foot().forward().to_metres()))

## A tree behind the rider, then a far one, then a near pair.
planted_out_of_order : Segment
planted_out_of_order = segment_of([
	tree_at(5.0, -3.5),
	tree_at(46.0, 3.5),
	tree_at(16.0, -3.5),
	tree_at(16.0, 3.5),
])

expect
	tree_places([planted_out_of_order], Pixels.of(500.0))
		== [
			(3.5, 36.0),
			(-3.5, 6.0),
			(3.5, 6.0),
		]
expect tree_places([planted_out_of_order], Pixels.of(1.0)) == []
expect
	tree_places(
		[going_straight_on(segment_of([tree_at(46.0, 3.5)])), segment_of([tree_at(16.0, -3.5)])],
		Pixels.of(500.0),
	)
		== [(3.5, 36.0), (-3.5, 206.0)]

# EncounterSighting's cats: which cats are in view as the rider comes on them.
## The second segment, with a cat crossing it.
cat_segment : Segment
cat_segment = {
	..World.route.segment_at(Route.SegmentIndex.number(1)),
	encounter: World.route.segment_at(Route.SegmentIndex.number(3)).encounter,
}

## The route's first three segments, a route of their own, with a cat crossing
## the second.
cat_route : Route
cat_route = Route.from_segments([
	World.route.segment_at(Route.SegmentIndex.first),
	cat_segment,
	{ ..World.route.segment_at(Route.SegmentIndex.number(2)), ending: RouteEnds },
])

## The road ahead of a rider on the cat route's first segment.
cat_road : RoadAhead.RoadView
cat_road = RoadAhead.RoadView.ahead_of(cat_route, Route.SegmentIndex.first)

## The birds the camera sees on `road_view`, with the encounter on the
## rider's segment at `encounter_timing`.
birds_seen_on : RoadAhead.RoadView,
{
	camera : { vantage : Geom.Vantage, cam_focal : Pixels },
	encounter_timing : EncounterPlan.Timing,
} -> List(Pipeline.Sighted(PosedBird))
birds_seen_on = |road_view, { camera, encounter_timing }|
	EncounterSighting.animals_in_view(
		road_view,
		{ camera, animals: EncounterPoses.bird_poses(road_view, encounter_timing) },
	)

## The cats the camera sees on `road_view`, with the encounter on the rider's
## segment at `encounter_timing`.
cats_seen_on : RoadAhead.RoadView,
{
	camera : { vantage : Geom.Vantage, cam_focal : Pixels },
	encounter_timing : EncounterPlan.Timing,
} -> List(Pipeline.Sighted(PosedCat))
cats_seen_on = |road_view, { camera, encounter_timing }|
	EncounterSighting.animals_in_view(
		road_view,
		{ camera, animals: EncounterPoses.cat_poses(road_view, encounter_timing) },
	)

expect cat_route.route_segments().map(World.has_cat) == [False, True, False]

## The cats in view for a rider `along` metres into the first segment.
ride_sightings : F64 -> List(Pipeline.Sighted(PosedCat))
ride_sightings = |along| cats_seen_on(
	cat_road,
	{
		camera: { ..origin_camera, vantage: { ..origin, along: Along.metres(along) } },
		encounter_timing: Unplanned,
	},
)

seen : List(Pipeline.Sighted(PosedCat))
seen = ride_sightings(300.0)

## The first cat in view for a rider `along` metres in.
first_cat : F64 -> Pipeline.Sighted(PosedCat)
first_cat = |along|
	ride_sightings(along).first() ?? crash "CrossModuleExpects: the second segment's cat is in view"

## How far ahead the first cat in view is for a rider `along` metres in.
cat_forward : F64 -> Distance
cat_forward = |along| first_cat(along).spot.foot().forward()

## How far right of the camera the first cat in view is for a rider `along`
## metres in.
cat_right : F64 -> Distance
cat_right = |along| first_cat(along).spot.foot().right()

expect seen.len() == 1
# The cat route's one cat is on its second segment.
expect
	EncounterPoses.cat_poses(cat_road, Unplanned).map(|cat| cat.place)
		== [Ahead(second_position)]
expect first_cat(300.0).spot.lift().to_metres() == 0.0
expect first_cat(300.0).kind.pose == Rest
expect
	[
		(cat_forward(300.0).minus(cat_forward(200.0)).to_metres(), -100.0),
		(cat_forward(400.0).minus(cat_forward(300.0)).to_metres(), -100.0),
		(cat_right(300.0).minus(cat_right(200.0)).to_metres(), 0.0),
	].all(|(got, want)| (got - want).abs() <= 0.0001)

expect ride_sightings(0.0).len() == 0
expect ride_sightings(200.0).len() == 1
expect ride_sightings(500.0).len() == 1
expect ride_sightings(600.0).len() == 0

# The sighting plays only the rider's own segment's encounter, and the ride
# plans that encounter only once the rider is on its segment. They agree because
# an animation is planned on its own segment: even at top speed its planning gap
# is shorter than the critter is from the segment's start, and a rider comes onto
# a segment no further along than that.
## The cats of the route, each with its segment.
route_cats : List({ segment : Segment, crossing : CatCrossing })
route_cats = World.route.route_segments().join_map(
	|segment|
		match segment.encounter {
			CatCrosses(crossing) => [{ segment, crossing }]
			BirdHere(_) | QuietRoad => []
		},
)

## The flights of the route.
route_flights : List(BirdFlight.Flight)
route_flights = World.route.route_segments().join_map(
	|segment|
		match segment.encounter {
			BirdHere(flight) => [flight]
			CatCrosses(_) | QuietRoad => []
		},
)

## How far short of a cat its crossing is planned for the fastest rider.
cat_planning_gap : Distance
cat_planning_gap = EncounterPlan.planning_gap(Cat.crossing_span, VehicleLimits.top_speed)

## How far short of a bird's perch its flight is planned for the fastest rider.
bird_planning_gap : Distance
bird_planning_gap = EncounterPlan.planning_gap(BirdFlight.flight_span, VehicleLimits.top_speed)

expect route_cats.len() == 3
expect route_cats.all(|{ crossing, .. }| cat_planning_gap < crossing.along.from_start())
expect route_flights.len() == 4
expect route_flights.all(|{ from, .. }| bird_planning_gap < from.road_point.along.from_start())

# EncounterPlan.steady_approach_timing: a rider coming at 1.25 m a step from
# 75 m off sees the bird take off at 60 m, perched a step before, and land at
# 15 m.

## Where the bird's flight has got to, for that rider `gap` metres short of
## its perch.
steady_flight_stage : F64 -> Animation.Stage
steady_flight_stage = |gap|
	BirdFlight.flight_stage(
		EncounterPlan.steady_approach_timing(
			BirdFlight.flight_span,
			{
				gap_at_start: Distance.metres(75.0),
				speed: Speed.metres_a_step(1.25),
				gap: Distance.metres(gap),
			},
		),
	)

expect steady_flight_stage(60.0) == Playing(Steps.zero)
expect steady_flight_stage(60.125) == Waiting
expect steady_flight_stage(15.0) == Past(Steps.zero)
expect steady_flight_stage(15.125) == Playing(Steps.of(35))

# BillboardSighting: which billboards are in view, on a road of one segment
# holding one grown cow and nothing else.
one_cow_segment : Segment
one_cow_segment = {
	..segment_of([]),
	pigs: NoPigs,
	cows: { herd: { ..segment_of([]).cows.herd, cow_count: 1 }, bull: NoBull },
}

lone_cow : Geom.RoadPoint
lone_cow = match one_cow_segment.segment_cows() {
	[cow] => cow.road_point
	_ => crash "CrossModuleExpects: the one-cow segment holds one cow"
}

## Whether the rider sees the lone cow from `forward` metres short of it and
## 2.5 m to its left.
is_cow_seen_from : F64 -> Bool
is_cow_seen_from = |forward| {
	rider = {
		along: Along.metres(lone_cow.along.to_metres() - forward),
		across: Across.metres(lone_cow.across.to_metres() - 2.5),
		yaw: Angle.straight_ahead,
	}
	cow_road = crafted_road([one_cow_segment])
	camera = { vantage: rider, cam_focal: Lens.resting_focal }
	BillboardSighting.billboards_in_view(cow_road, camera).len() == 1
}

# The near plane is 0.4 m. The rider's place is worked out from the cow's, so
# the cow's distance carries a rounding, and the checks stand a little either
# side of the plane. At the lens's resting focal length the 1.4 m cow is 2
# pixels tall about 479.9 m off.
expect
	[
		(-5.0, False),
		(0.3, False),
		(0.39, False),
		(0.41, True),
		(0.5, True),
		(300.0, True),
		(479.0, True),
		(481.0, False),
		(600.0, False),
	].all(|(forward, want)| is_cow_seen_from(forward) == want)

# Wildlife: an animal and its baby at each of four bends, the first and third
# turning right and the second and fourth left.
billboards_at_four_bends : List(Geom.Placed(Billboard))
billboards_at_four_bends = [
	Wildlife.bend_billboards({
		animal: Elephant,
		bend: { segment_length: Distance.metres(100.0), turn: Angle.Turn.degrees(50.0) },
	}),
	Wildlife.bend_billboards({
		animal: Giraffe,
		bend: { segment_length: Distance.metres(50.0), turn: Angle.Turn.degrees(-70.0) },
	}),
	Wildlife.bend_billboards({
		animal: Zebra,
		bend: { segment_length: Distance.metres(10.0), turn: Angle.Turn.degrees(50.0) },
	}),
	Wildlife.bend_billboards({
		animal: Rhino,
		bend: { segment_length: Distance.metres(0.0), turn: Angle.Turn.degrees(-70.0) },
	}),
].join()

expect
	billboards_at_four_bends.map(|billboard| billboard.road_point.across.to_metres())
		== [-4.9, 0.0, 5.75, 0.0, -4.3, 0.0, 4.6, 0.0]

expect
	billboards_at_four_bends.map(|billboard| billboard.road_point.along.to_metres())
		== [100.0, 114.0, 50.0, 64.0, 10.0, 24.0, 0.0, 14.0]

expect
	billboards_at_four_bends.map(|billboard| billboard.kind.height.to_metres())
		== [2.8, 1.4, 4.5, 2.25, 1.6, 0.8, 2.2, 1.1]

expect
	billboards_at_four_bends.map(|billboard| billboard.kind.facing)
		== [
			FacesRight,
			FacesRight,
			FacesLeft,
			FacesLeft,
			FacesRight,
			FacesRight,
			FacesLeft,
			FacesLeft,
		]

# Tower: a tower that isn't turned stands on a square 12 m across, its corners
# 6 m to either side of its middle and 6 m before and past it. Each leg rises
# from its corner, from as high as the earth's curve hides it: 0.25 m for a
# tower 100 m straight ahead, 1/320 of the tower's 80 m. The legs taper, so
# each foot is drawn in toward the middle by 1/320 of 6 m.
shapes_of_tower_100_ahead : List(Shapes.Shape)
shapes_of_tower_100_ahead = {
	tower_road = crafted_road([segment_of([])])
	plain_tower : Tower
	plain_tower = { yaw: Angle.straight_ahead, beacon_brightness: Fraction.zero }
	sighted =
		Pipeline.sighting_of(
			{
				road_point: { along: Along.metres(100.0), across: Across.middle },
				lift: Distance.zero,
				kind: plain_tower,
			},
			{
				road: tower_road,
				vantage: origin,
				place: Ahead(SegmentPlace.Position.first),
			},
		)
			?? crash "CrossModuleExpects: a tower 100 m ahead is past the near plane"
	sighted.kind.scenery_picture({
		spot: sighted.spot,
		cam_focal: origin_camera.cam_focal,
		context: { road: tower_road, vantage: origin },
	}).to_shapes()
}

## How far right of the screen's middle the foot of leg `index` is: the middle
## of the rod's end at its corner.
leg_foot_x : U64 -> F64
leg_foot_x = |index| {
	coordinates = coordinates_of(
		shapes_of_tower_100_ahead.get(index) ?? crash "CrossModuleExpects: a tower has four legs",
	)
	match (coordinates.get(0), coordinates.get(6)) {
		(Ok(near_side), Ok(far_side)) => (near_side + far_side) / 2.0 - Screen.center_x.to_f64()
		_ => crash "CrossModuleExpects: a leg is a quad"
	}
}

## How far a leg's foot is to the side of the tower's middle, and before or
## past it.
foot_offset : F64
foot_offset = 6.0 * 319.0 / 320.0

# The legs go back left, back right, front right, front left.
expect
	[
		(leg_foot_x(0), -500.0 * foot_offset / (100.0 - foot_offset)),
		(leg_foot_x(1), 500.0 * foot_offset / (100.0 - foot_offset)),
		(leg_foot_x(2), 500.0 * foot_offset / (100.0 + foot_offset)),
		(leg_foot_x(3), -500.0 * foot_offset / (100.0 + foot_offset)),
	].all(|(got, want)| (got - want).abs() <= 0.000001)

# TowerSighting: a tower stands 160 m past the end of every segment, 20 m right
# and turned 30 degrees, and a segment longer than 1000 m has one more halfway
# along, 100 m left and not turned.
## A segment 1200 m long, holding nothing, which ends a route.
long_segment : Segment
long_segment = { ..segment_of([]), length: Distance.metres(1200.0) }

## The towers in view at `clock` from the origin of the segment at `rider_number` on a
## route of a 200 m segment going straight on into the long one.
towers_on_short_then_long : U32, Clock -> List(Pipeline.Sighted(Tower))
towers_on_short_then_long = |rider_number, clock|
	TowerSighting.towers_in_view(
		RoadAhead.RoadView.ahead_of(
			Route.from_segments([going_straight_on(segment_of([])), long_segment]),
			Route.SegmentIndex.number(rider_number),
		),
		{ camera: origin_camera, clock },
	)

## Where a tower stands on its segment, and how it is turned: along, across,
## and its turn in radians.
tower_numbers : Pipeline.Sighted(Tower) -> List(F64)
tower_numbers = |tower| [
	tower.spot.road_point().along.to_metres(),
	tower.spot.road_point().across.to_metres(),
	tower.kind.yaw.to_radians(),
]

expect {
	towers = towers_on_short_then_long(0, Clock.start)
	thirty = Angle.Turn.degrees(30.0).to_radians()
	got = towers.map(tower_numbers).join()
	want = [
		360.0,
		20.0,
		thirty,
		1360.0,
		20.0,
		thirty,
		600.0,
		-100.0,
		0.0,
	]
	towers.map(|tower| tower.spot.place())
		== [
			Ahead(SegmentPlace.Position.first),
			Ahead(second_position),
			Ahead(second_position),
		]
		and got.len() == want.len()
		and got.map2(want, |one, wanted| (one - wanted).abs() <= 0.000000001).all(|is_near| is_near)
}

# The end tower's beacon blinks on its segment's number, and the mid tower's
# the opposite way.
expect {
	got = towers_on_short_then_long(0, Clock.at_step(30)).map(|tower| tower.kind.beacon_brightness)
	clock = Clock.at_step(30)
	want = [
		Beacon.of_segment(Route.SegmentIndex.first).brightness_at(clock),
		Beacon.of_segment(Route.SegmentIndex.number(1)).brightness_at(clock),
		Beacon.of_segment(Route.SegmentIndex.number(1)).opposite().brightness_at(clock),
	]
	got == want and got.map(|brightness| brightness.to_f64()).sum() > 0.0
}

# The segment just behind shows its end tower, which stands past the bend, and
# a rider far past every tower sees none.
expect
	towers_on_short_then_long(1, Clock.start).map(|tower| tower.spot.place())
		== [Ahead(SegmentPlace.Position.first), Ahead(SegmentPlace.Position.first), JustBehind]
expect
	TowerSighting.towers_in_view(
		crafted_road([segment_of([])]),
		{ camera: { vantage: { ..origin, along: Along.metres(5000.0) } }, clock: Clock.start },
	).len()
		== 0

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
scene = Scene.scene_in_view(road, { camera: origin_camera, facts: scene_facts })

scene_renderings : List(Rendered)
scene_renderings = Scene.scene_renderings(scene)

## The route's start has no cat in view, so the cats come from the second
## segment's, seen as `seen` sees them.
cat_scene : Scene
cat_scene = Scene.scene_in_view(
	cat_road,
	{
		camera: { ..origin_camera, vantage: { ..origin, along: Along.metres(300.0) } },
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
expect depths_of(scene.trees) == sighted_depths(TreeSighting.trees_in_view(road, origin_camera))
expect
	depths_of(scene.birds)
		== sighted_depths(
			birds_seen_on(road, { camera: origin_camera, encounter_timing: Unplanned }),
		)
expect
	depths_of(scene.towers)
		== sighted_depths(
			TowerSighting.towers_in_view(road, { camera: origin_camera, clock: Clock.start }),
		)
expect
	depths_of(scene.billboards)
		== sighted_depths(BillboardSighting.billboards_in_view(road, origin_camera))
expect depths_of(cat_scene.cats) == sighted_depths(seen)
expect seen.len() > 0
expect scene.rails.len() == RailSighting.rail_quads_in_view(road, origin_camera).len()
expect
	depths_of(scene.trucks)
		== sighted_depths(
			TruckSighting.truck_in_view(
				road,
				{
					camera: origin_camera,
					route_position: scene_facts.truck.route_position,
					lit_truck: scene_facts.truck.lit_truck,
				},
			).map_ok(|truck| [truck]) ?? [],
		)
expect scene.trucks.len() == 1
expect scene.birds.len() > 0

# The renderings are every field's, the truck's among them.
expect
	scene_renderings.len()
		== [
			scene.trees.len(),
			scene.birds.len(),
			scene.towers.len(),
			scene.billboards.len(),
			scene.cats.len(),
			scene.trucks.len(),
			scene.rails.len(),
		].sum()

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
			road,
			vantage: origin,
			place: Ahead(SegmentPlace.Position.first),
		},
	)
		?? crash "CrossModuleExpects: a test's thing is past the near plane"

# A point on the rider's own segment, as a camera there sees it, turned as the
# camera faces: RoadAhead's turn from the road into the rider's view.
expect {
	seen_from = |road_point, yaw|
		RoadAhead.rider_point_at(
			road,
			{
				vantage: {
					along: Along.metres(5.0),
					across: Across.metres(0.5),
					yaw: Angle.Turn.radians(yaw),
				},
				place: Ahead(SegmentPlace.Position.first),
				road_point,
			},
		)
	[
		(
			seen_from({ along: Along.metres(0.0), across: Across.metres(-3.0) }, 0.0),
			{ right: Distance.metres(-3.5), forward: Distance.metres(-5.0) },
		),
		(
			seen_from({ along: Along.metres(12.0), across: Across.metres(0.0) }, 0.35),
			{
				right: Distance.metres(-2.869971008611849),
				forward: Distance.metres(6.404160086203927),
			},
		),
		(
			seen_from({ along: Along.metres(40.0), across: Across.metres(-5.0) }, -0.6),
			{
				right: Distance.metres(15.223140686823006),
				forward: Distance.metres(31.992280125511435),
			},
		),
		(
			seen_from({ along: Along.metres(7.5), across: Across.metres(3.25) }, 1.2),
			{
				right: Distance.metres(-1.333613890107213),
				forward: Distance.metres(3.4690018726015563),
			},
		),
	].all(
		|(got, want)| {
			right_miss = got.right.minus(want.right).to_metres().abs()
			forward_miss = got.forward.minus(want.forward).to_metres().abs()
			right_miss <= 0.000001 and forward_miss <= 0.000001
		},
	)
}

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
straight_road = crafted_road([segment_of([])])

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
			vantage: origin,
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
					camera: { vantage: origin, cam_focal: Pixels.of(128.0) },
					place: Ahead(SegmentPlace.Position.first),
				},
			).map_ok(|_| Seen)
				== outcome,
	)

# A rendering's depth is how far ahead its sighting stands.
expect
	[30.0, 64.0].all(
		|along| {
			sighting = post_sighting(along) ?? crash "CrossModuleExpects: a post 30 m or more ahead is in view"
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
	trees: Scene.tree_renderings([green_tree_ahead(forward)], origin_camera.cam_focal),
}

## A scene of a lone perched bird `forward` metres ahead.
lone_bird_scene : F64 -> Scene
lone_bird_scene = |forward| {
	..empty_scene,
	birds: [
		Pipeline.rendering_of(
			perched_bird_ahead(forward),
			{ cam_focal: origin_camera.cam_focal, context: {} },
		),
	],
}

## The shapes of a tree and a bird, these many metres ahead, in the order the
## frame draws them.
tree_and_bird_shapes : { tree_ahead : F64, bird_ahead : F64 } -> List(Shapes.Shape)
tree_and_bird_shapes = |{ tree_ahead, bird_ahead }|
	Scene.scene_shapes({ ..lone_tree_scene(tree_ahead), birds: lone_bird_scene(bird_ahead).birds })

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

## Five trees a metre apart, from 10 to 14 metres ahead, rendered together.
cluster_renderings : List(Rendered)
cluster_renderings = Scene.tree_renderings(
	[10.0, 11.0, 12.0, 13.0, 14.0].map(green_tree_ahead),
	origin_camera.cam_focal,
)

## The shapes of the cluster's tree at `index`, nearest first.
cluster_shapes : U64 -> List(Shapes.Shape)
cluster_shapes = |index|
	match cluster_renderings.get(index) {
		Ok(rendering) => rendering.picture().to_shapes()
		Err(OutOfBounds) => crash "CrossModuleExpects: the cluster has five trees"
	}

second_shape_points : List(Shapes.Shape) -> U64
second_shape_points = |shapes|
	match shapes {
		[_, Poly(polygon), ..] => polygon.coordinates.len()
		_ => crash "a tree in view draws a trunk and tiers"
	}

# A tree is drawn as the conifer told how many of the others are nearer, so the
# nearest tree's tiers are cones, in more detail than the farthest's triangles.
expect
	cluster_shapes(4)
		== Conifer.Green.scenery_picture({
			spot: green_tree_ahead(14.0).spot,
			cam_focal: origin_camera.cam_focal,
			context: { nearer_tree_count: 4 },
		}).to_shapes()
expect second_shape_points(cluster_shapes(0)) > second_shape_points(cluster_shapes(4))
expect second_shape_points(cluster_shapes(4)) >= 6

expect scene.trees.len() > 0
expect scene.towers.len() > 0
expect scene.billboards.len() > 0
expect scene.rails.len() > 0
expect scene_renderings.len() > 0

# A segment of the road ahead shows at most two towers, the one past its end and
# the one halfway along, and the segment just behind shows one.
expect scene.towers.len() <= 2 * road.segments_ahead().count.to_u64() + 1

# The scene's renderings come far to near: sorting them again changes nothing.
expect {
	parts_of = |renderings|
		renderings.map(|rendering| (rendering.depth(), rendering.picture().to_shapes()))
	parts_of(Rendered.depth_sorted_renderings(scene_renderings)) == parts_of(scene_renderings)
}

# GroundPatch's shapes. A ground patch's checks sit here because the corners
# need Distance and the fill needs Brush, and GroundPatch imports neither.
sample_patch_shape : List(Geom.RiderPoint) -> Try(Shapes.Shape, [PastHorizon, BehindCamera])
sample_patch_shape = |corners| GroundPatch.patch_shape(
	GroundPatch.of(corners, RgbColor.of(0x2F7E8C)),
	Pixels.of(685.5110432362151),
)

patch_corners_ahead : List(Geom.RiderPoint)
patch_corners_ahead = [
	{ right: Distance.metres(-5.0), forward: Distance.metres(10.0) },
	{ right: Distance.metres(5.0), forward: Distance.metres(10.0) },
	{ right: Distance.metres(5.0), forward: Distance.metres(20.0) },
	{ right: Distance.metres(-5.0), forward: Distance.metres(20.0) },
]

# A patch of `count` corners, all ahead of the camera.
corners_ahead : I64 -> List(Geom.RiderPoint)
corners_ahead = |count|
	List.from_iter(I64.until(0, count)).map(
		|k| {
			offset = (count - k).to_f64()
			{ right: Distance.metres(offset), forward: Distance.metres(10.0 + offset) }
		},
	)

## What became of a patch: drawn, or why not.
patch_outcome : Try(Shapes.Shape, [PastHorizon, BehindCamera]) -> [Drawn, PastHorizon, BehindCamera]
patch_outcome = |shape|
	match shape {
		Ok(_) => Drawn
		Err(PastHorizon) => PastHorizon
		Err(BehindCamera) => BehindCamera
	}

# A patch that straddles the horizon is kept, and one wholly past it is not.
expect
	sample_patch_shape([
		{ right: Distance.metres(-2.0), forward: Distance.metres(480.0) },
		{ right: Distance.metres(2.0), forward: Distance.metres(480.0) },
		{ right: Distance.metres(2.0), forward: Distance.metres(505.0) },
		{ right: Distance.metres(-2.0), forward: Distance.metres(505.0) },
	]).is_ok()
expect
	patch_outcome(
		sample_patch_shape([
			{ right: Distance.metres(-2.0), forward: Distance.metres(495.0) },
			{ right: Distance.metres(2.0), forward: Distance.metres(495.0) },
			{ right: Distance.metres(2.0), forward: Distance.metres(520.0) },
			{ right: Distance.metres(-2.0), forward: Distance.metres(520.0) },
		]),
	)
		== PastHorizon
expect
	patch_outcome(
		sample_patch_shape([
			{ right: Distance.metres(-5.0), forward: Distance.metres(-10.0) },
			{ right: Distance.metres(5.0), forward: Distance.metres(-10.0) },
			{ right: Distance.metres(5.0), forward: Distance.metres(-20.0) },
			{ right: Distance.metres(-5.0), forward: Distance.metres(-20.0) },
		]),
	)
		== BehindCamera

expect sample_patch_shape(patch_corners_ahead).is_ok()
expect sample_patch_shape(corners_ahead(8)).is_ok()
expect sample_patch_shape(corners_ahead(9)).is_ok()

expect {
	match sample_patch_shape(patch_corners_ahead) {
		Ok(Poly(polygon)) =>
			polygon.fill == Flat(Brush.opaque(RgbColor.of(0x2F7E8C)))
				and polygon.coordinates.len() == 8
		_ => False
	}
}

# GroundSighting's road along the first segment, 500 m long: one patch, its
# edges laid in 20 chunks of 25 m.
## A list of patches as a camera the drawing checks read paints them.
patch_shapes : List(GroundPatch) -> List(Shapes.Shape)
patch_shapes = |patches| patches.keep_oks(|patch| GroundPatch.patch_shape(patch, Pixels.of(500.0)))

## The ground in view from `rider_vantage` on the road ahead of the route's
## first segment. Its first patch is the road along that segment.
patches_seen_from : Geom.Vantage -> List(GroundPatch)
patches_seen_from = |rider_vantage| GroundSighting.patches_in_view(road, { vantage: rider_vantage })

first_road : GroundPatch
first_road = patches_seen_from(origin).first() ?? crash "CrossModuleExpects: the first segment lays road"

corner : List(Geom.RiderPoint), U64 -> Geom.RiderPoint
corner = |
	corners,
	i,
| corners.get(i) ?? crash "CrossModuleExpects: the road has a corner at each chunk's end on either edge"

## The road's corners where chunk `number` starts, on the right edge and the
## left: the start, then up the right edge, then back down the left.
chunk_start_corners : U64 -> (Geom.RiderPoint, Geom.RiderPoint)
chunk_start_corners = |number| {
	left_index = if number == 0 {
		0
	} else {
		42 - number
	}
	(corner(first_road.corners(), number + 1), corner(first_road.corners(), left_index))
}

expect first_road.corners().len() == 42
expect
	List.from_iter(U64.until(0, 21)).all(
		|number| {
			(right_corner, left_corner) = chunk_start_corners(number)
			want_forward = 25.0 * number.to_f64()
			(right_corner.right.to_metres() - 2.0).abs() <= 0.0001
				and (left_corner.right.to_metres() + 2.0).abs() <= 0.0001
				and (right_corner.forward.to_metres() - want_forward).abs() <= 0.0001
				and right_corner.forward == left_corner.forward
		},
	)

strip_shapes : List(Shapes.Shape)
strip_shapes = patch_shapes([first_road])

expect strip_shapes.len() == 1
expect {
	road_behind = patches_seen_from({ ..origin, along: Along.metres(5000.0) }).take_first(1)
	road_behind.len() == 1 and patch_shapes(road_behind).len() == 0
}
last_shape : Shapes.Shape
last_shape = strip_shapes.last() ?? crash "CrossModuleExpects: the road draws"

expect flat_color_of(last_shape) == RgbColor.of(0x34353C)

# Seen from its start, the road is cut at the near plane and at the horizon,
# 490 m out, so it keeps its corners from 25 m to 475 m on both edges, and
# gains two where each cut crosses its edges.
expect coordinates_of(last_shape).len() == 2 * (2 * 19 + 4)

# The paving of the first bend takes in 40 m of road on either side of it, so
# its corners reach back to 460 m along the first segment.
expect
	match GroundSighting.patches_in_view(road, origin_camera).get(1) {
		Ok(paving) => {
			paving_corners = paving.corners()
			paving_corners.len() == 8
				and paving_corners.any(|point| (point.forward.to_metres() - 460.0).abs() <= 0.0001)
		}
		Err(_) => False
	}

# A ride that has finished starts again.
done : RideInstant
done = {
	rider: {
		segment_index: Route.SegmentIndex.number(18),
		motorcycle: {
			along: Along.metres(400.0),
			across: Across.metres(0.0),
			yaw: Angle.Turn.radians(0.0),
			speed: Speed.at_rest,
			lean: Angle.Lean.radians(0.0),
		},
		eyes: { gaze_yaw: Angle.Turn.radians(0.0), look_depth: Fraction.of(0.9) },
	},
	truck: {
		route_position: Distance.metres(9000.0),
		speed: Speed.metres_a_step(2.0),
		pace: Slowing,
	},
	clock: Clock.at_step(12345),
	encounter_start: StartsAt(Clock.at_step(12300)),
}

## The world's ride a step on from `instant`, whether it went on or restarted.
instant_after : RideInstant -> RideInstant
instant_after = |instant|
	match RideInstant.next_or_restart(World.route, instant) {
		Continued(next) | Restarted(next) => next
	}

expect
	match RideInstant.next_or_restart(World.route, done) {
		Restarted(instant) =>
			instant.clock.to_f64() == 0.0
				and instant.rider.motorcycle.along.to_metres() == 0.0
				and instant.rider.motorcycle.speed.to_metres_a_step() == 0.3
				and instant.truck.route_position.to_metres() == 500.0
				and instant.rider.eyes.look_depth.to_f64() == 0.0
				and instant.encounter_start == Unplanned
		Continued(_) => False
	}

expect
	match RideInstant.next_or_restart(World.route, RideInstant.initial) {
		Continued(_) => True
		Restarted(_) => False
	}

# The gaze is home at each of the ride's crossings, and it did leave home. The
# bike doesn't turn at a seam, and `gaze_yaw` is measured from the bike, so a
# crossing carries the gaze over and it has no need to be reset.
expect {
	var $instant = RideInstant.initial
	var $crossings = 0
	var $is_home_at_each = True
	var $has_looked = False
	while !$instant.rider.is_finished(World.route) {
		next = instant_after($instant)
		if next.rider.segment_index != $instant.rider.segment_index {
			$crossings = $crossings + 1
			is_home = $instant.rider.eyes.gaze_yaw == Angle.straight_ahead
			$is_home_at_each = $is_home_at_each and is_home
		}
		$has_looked = $has_looked or next.rider.eyes.gaze_yaw != Angle.straight_ahead
		$instant = next
	}
	$crossings == 18 and $is_home_at_each and $has_looked
}

expect done.rider.is_finished(World.route)
expect instant_after(done).truck.pace == NotSlowing

# A ride that hasn't finished steps on: the clock by a step, the rider and the
# truck forward.
ride_at_step_one : RideInstant
ride_at_step_one = instant_after(RideInstant.initial)

ride_at_step_two : RideInstant
ride_at_step_two = instant_after(ride_at_step_one)

expect !RideInstant.initial.rider.is_finished(World.route)
expect ride_at_step_one.clock.to_f64() == 1.0
expect ride_at_step_two.clock.to_f64() == 2.0
expect ride_at_step_two.clock.steps_since(ride_at_step_one.clock) == Steps.one_step
expect ride_at_step_one.rider.motorcycle.along > RideInstant.initial.rider.motorcycle.along
expect ride_at_step_one.truck.route_position > RideInstant.initial.truck.route_position
expect ride_at_step_two.rider.motorcycle.along > ride_at_step_one.rider.motorcycle.along
expect ride_at_step_one.clock != Clock.start
expect !ride_at_step_one.rider.is_finished(World.route)

## A rider on the middle of the road at the starting speed, `along` metres down
## segment `index` of the route.
placed_rider : U32, F64 -> RiderState
placed_rider = |index, along| {
	..RiderState.initial,
	segment_index: Route.SegmentIndex.number(index),
	motorcycle: { ..Motorcycle.initial, along: Along.metres(along) },
}

## The route's last segment, which ends the route.
last_segment_index : U32
last_segment_index = 18

expect World.route.segment_at(Route.SegmentIndex.number(last_segment_index)).ending == RouteEnds

# The ride is finished once the rider reaches the end of the last segment, and
# not before, nor anywhere on a segment that bends into another.
expect placed_rider(last_segment_index, 300.0).is_finished(World.route)
expect !placed_rider(last_segment_index, 299.0).is_finished(World.route)
expect !placed_rider(0, 499.0).is_finished(World.route)

## That rider a step on.
rider_a_step_after : U32, F64 -> RiderState
rider_a_step_after = |index, along|
	placed_rider(index, along).next({ route: World.route, encounter_timing: Unplanned })

# A rider near the first bend crosses onto the next segment's road, and one well
# short of it, which the bend would carry far off that road, stays.
expect rider_a_step_after(0, 499.0).segment_index.to_i64() == 1
expect rider_a_step_after(0, 100.0).segment_index.to_i64() == 0

# The ride ends stopped dead at the route's end, and a step short of the end
# leaves the rider moving.
expect {
	stopped = ride_at_finish.rider.motorcycle
	stopped.along.to_metres() == 300.0 and stopped.speed == Speed.at_rest
}
expect {
	short = rider_a_step_after(last_segment_index, 290.0).motorcycle
	short.along.to_metres() < 300.0 and short.speed > Speed.at_rest
}

## A motorcycle just short of the first bend, a little off the middle and
## turned a little from the segment's axis.
motorcycle_at_first_seam : Motorcycle
motorcycle_at_first_seam = {
	along: Along.metres(499.0),
	across: Across.metres(0.5),
	yaw: Angle.Turn.radians(0.1),
	speed: Speed.metres_a_step(1.25),
	lean: Angle.Lean.radians(0.05),
}

# The crossing keeps the motorcycle's bearing in the world: the yaw turns back
# by the bend that turns the next segment's bearing. The two sums round apart,
# by no more than a float's last bits.
expect {
	first = Route.SegmentIndex.first
	at_seam = motorcycle_at_first_seam
	on_next = at_seam.motorcycle_past_bend(World.route.segment_at(first).bend_out_of())
	before = World.route.bearing_of(first).plus(at_seam.yaw)
	after = World.route.bearing_of(first.next()).plus(on_next.yaw)
	after.turn_from(before).abs() < Angle.Turn.radians(0.000000000001)
}

# The rider starts at the route's start and moves along it.
expect RideInstant.rider_distance(World.route, RideInstant.initial) == Distance.zero
expect
	RideInstant.rider_distance(World.route, ride_at_step_two)
		> RideInstant.rider_distance(World.route, ride_at_step_one)

# A tour can be ridden right up to the step the ride finishes at. A step past it
# crashes, since the ride starts again before reaching it.
expect {
	var $tour = Tour.initial
	while !$tour.instant.rider.is_finished($tour.route) {
		$tour = Tour.step_forward($tour)
	}
	finish = $tour.instant.clock
	Tour.at_step(finish.steps_since(Clock.start).to_u32()).instant.clock == finish
}

# The sun's disc is not yet wholly set a step before `fully_set_at`, and the sky
# is lighter than when it is.
expect {
	step_before_set = Sun.fully_set_at.minus(Steps.one_step)
	Sun.height_at(step_before_set) > Sun.height_when_set
		and Sky.darkness_at(step_before_set) < Sky.darkness_at(Sun.fully_set_at)
}

## The first step of the ride at which `holds` holds.
first_step_where : (Clock -> Bool) -> Clock
first_step_where = |holds| {
	var $clock = Clock.start
	while !holds($clock) {
		$clock = $clock.next()
	}
	$clock
}

## The climax of the sunset: the step the sun's lower edge meets the west range,
## where the sun starts to set on screen. The range stands above the horizon at
## the sun's bearing, so the sun's touching the horizon is never seen. The sun's
## top sinks behind the range at the first step the sun is behind it, which says
## how high the range stands there, and the lower edge meets it a diameter
## higher.
sunset_climax : Clock
sunset_climax = {
	hidden_at = first_step_where(Mountains.is_sun_behind_mountains)
	range_top = Sun.height_at(hidden_at).plus(Sun.radius_as_height)
	first_step_where(|clock| Sun.height_at(clock).minus(Sun.radius_as_height) < range_top)
}

## How many steps before and after the sunset's climax the rider must be on the
## long westward segment: 150, a few hundred metres of road, so the rider sees
## the sun come down onto the range from the straight and watches it start to
## sink.
sunset_margin : Steps
sunset_margin = Steps.of(150)

## The route's longest segment.
longest_segment_index : Route.SegmentIndex
longest_segment_index = {
	(_, longest_at) =
		World.route.route_segments()
			.map_with_index(|segment, at| (segment.length, at))
			.fold(
				(Distance.zero, 0),
				|(best_length, best_at), (length, at)|
					if length > best_length {
						(length, at)
					} else {
						(best_length, best_at)
					},
			)
	Route.SegmentIndex.number(longest_at.to_u32_wrap())
}

# The route's longest segment heads within 20° of the sun, as the rider enters it.
expect {
	bearing = World.route.bearing_of(longest_segment_index)
	Sun.bearing.turn_from(bearing).abs() < Angle.Turn.degrees(20.0)
}

# Steve's rule: the climax of the sunset happens on the really long road segment
# that heads west. The ride is ridden to `sunset_margin` steps past the climax,
# and the rider is on that segment from `sunset_margin` steps before it.
expect {
	from = sunset_climax.minus(sunset_margin)
	until = sunset_climax.plus(sunset_margin)
	var $instant = RideInstant.initial
	while $instant.clock != from {
		$instant = instant_after($instant)
	}
	var $is_on_long_segment = True
	while $instant.clock != until {
		is_on_it = $instant.rider.segment_index == longest_segment_index
		$is_on_long_segment = $is_on_long_segment and is_on_it
		$instant = instant_after($instant)
	}
	$is_on_long_segment and $instant.rider.segment_index == longest_segment_index
}

# Steve's rule: the ride reaches full night, past dusk, before it finishes. The
# rule is strict that night comes and loose about when, so it holds no step.
# The sky only darkens as the clock runs, so full darkness at the finish means it
# came at or before it.
expect Sky.darkness_at(ride_at_finish.clock) == Fraction.whole

## The ride at the step it finishes.
ride_at_finish : RideInstant
ride_at_finish = {
	var $instant = RideInstant.initial
	while !$instant.rider.is_finished(World.route) {
		$instant = instant_after($instant)
	}
	$instant
}

## What the encounters do over the whole ride: how many steps a bird is in
## flight and a cat crosses, whether every flying bird is ahead of the rider,
## how many cat segments the rider leaves, at a bend or the route's end, and
## whether each cat's hold on the eye has faded by then.
ride_encounters : {
	flying_step_count : U64,
	crossing_step_count : U64,
	is_bird_ahead_throughout : Bool,
	cat_exits : U64,
	is_faded_at_each_exit : Bool,
}
ride_encounters = {
	var $instant = RideInstant.initial
	var $flying_step_count = 0
	var $crossing_step_count = 0
	var $is_bird_ahead_throughout = True
	var $cat_exits = 0
	var $is_faded_at_each_exit = True
	while !$instant.rider.is_finished(World.route) {
		segment = World.route.segment_at($instant.rider.segment_index)
		timing = RideInstant.encounter_timing($instant)
		next = instant_after($instant)
		is_leaving =
			next.rider.segment_index != $instant.rider.segment_index
				or next.rider.is_finished(World.route)
		match segment.encounter {
			BirdHere(flight) => {
				stage = BirdFlight.flight_stage(timing)
				match stage {
					Playing(_) => {
						bird = BirdFlight.instant_at(flight, stage)
						$flying_step_count = $flying_step_count + 1
						$is_bird_ahead_throughout = $is_bird_ahead_throughout
							and bird.location.along > $instant.rider.motorcycle.along
					}
					Waiting | Past(_) => {}
				}
			}
			CatCrosses(_) => {
				if Cat.is_crossing(Cat.crossing_stage(timing)) {
					$crossing_step_count = $crossing_step_count + 1
				}
				if is_leaving {
					$cat_exits = $cat_exits + 1
					$is_faded_at_each_exit = $is_faded_at_each_exit
						and EncounterReaction.encounter_attention(segment, timing) == Attention.none
				}
			}
			QuietRoad => {}
		}
		$instant = next
	}
	{
		flying_step_count: $flying_step_count,
		crossing_step_count: $crossing_step_count,
		is_bird_ahead_throughout: $is_bird_ahead_throughout,
		cat_exits: $cat_exits,
		is_faded_at_each_exit: $is_faded_at_each_exit,
	}
}

# Steve's rule: the rider can't overtake a bird. Each of the route's birds flies
# its whole flight on the ride, and at every step of it the bird is ahead of the
# rider.
expect ride_encounters.flying_step_count == route_flights.len() * BirdFlight.flight_poses.len()
expect ride_encounters.is_bird_ahead_throughout

# Each of the three cats crosses on the ride. The reaction ends with its
# segment, so the cat's hold has to have faded by then or it would snap to
# nothing there.
expect ride_encounters.crossing_step_count == 3 * Cat.crossing_span.length.to_u32().to_u64()
expect ride_encounters.cat_exits == 3
expect ride_encounters.is_faded_at_each_exit

# A frame of the ride draws.
expect {
	frame = FrameView.frame_view_at(World.route, RideInstant.initial)
	first_shape = frame.ride_shapes.first() ?? crash "CrossModuleExpects: a frame draws"
	coordinates_of(first_shape).len() >= 6
}

# Cat: a crossing, frame by frame.
## A cat that crosses from beside a tree 100 m along and 3 m right of the
## middle of a road 2 m either side.
crossing_cat : CatCrossing
crossing_cat = CatCrossing.by_tree({
	road_half_width: Distance.metres(2.0),
	tree: { along: Along.metres(100.0), across: Across.metres(3.0) },
})

## The cat `steps_in` steps into its crossing.
crossing_frame_of : U32 -> Animation.Instant(PosedCat.CatPose)
crossing_frame_of = |steps_in| Cat.instant_at(crossing_cat, Playing(Steps.of(steps_in)))

## The frames of a crossing, one a step.
crossing_frames : List(Animation.Instant(PosedCat.CatPose))
crossing_frames =
	List.from_iter(U32.until(0, Cat.crossing_span.length.to_u32())).map(crossing_frame_of)

## The poses frames `from` to `to` of the crossing show.
crossing_poses : U64, U64 -> List(PosedCat.CatPose)
crossing_poses = |from, to| crossing_frames.sublist({
	start: from,
	len: to - from + 1,
}).map(|frame| frame.pose)

# Two strides as it walks out, frozen in the middle, then the leap.
expect
	crossing_poses(0, 9)
		== [
			Stride,
			Stride,
			Stride,
			Rest,
			Rest,
			Stride,
			Stride,
			Stride,
			Rest,
			Rest,
		]
expect crossing_poses(10, 33).all(|pose| pose == Frozen)
expect crossing_poses(34, 37) == [Coil, Flight, Flight, Land]
expect Cat.instant_at(crossing_cat, Waiting).pose == Rest
expect Cat.instant_at(crossing_cat, Past(Steps.zero)).pose == Collapse

## How far across the road the cat is `steps_in` steps into its crossing.
crossing_across_at : U32 -> F64
crossing_across_at = |steps_in| crossing_frame_of(steps_in).location.across.to_metres()

## How high the cat is `steps_in` steps into its crossing.
crossing_lift_at : U32 -> F64
crossing_lift_at = |steps_in| crossing_frame_of(steps_in).location.lift.to_metres()

# It walks the first ten frames in even steps, and then stands in the middle of
# the road, and every frame is on the ground until it leaves it.
expect
	[
		(0, 4.5),
		(1, 4.0925),
		(9, 0.8325),
		(10, 0.425),
		(33, 0.425),
		(34, 0.425),
	].all(|(steps_in, want)| (crossing_across_at(steps_in) - want).abs() <= 0.000000000001)
expect [0, 9, 10, 33, 34, 37].all(|steps_in| crossing_lift_at(steps_in) == 0.0)

# In the air, it is on its way and off the ground.
expect
	[(35, -1.141, 0.27), (36, -2.90275, 0.17)].all(
		|(steps_in, across, lift)|
			(crossing_across_at(steps_in) - across).abs() <= 0.000000000001
				and (crossing_lift_at(steps_in) - lift).abs() <= 0.000000000001,
	)

expect (crossing_across_at(37) - -3.49).abs() <= 0.000000000001
expect (
	Cat.instant_at(
		crossing_cat,
		Past(Steps.zero),
	).location.across.to_metres() - -3.49
).abs() <= 0.000000000001

# Every crossing is on its own road.
expect crossing_frames.all(|frame| frame.location.along == crossing_cat.along)

# BirdFlight: the tree a bird flies to, and its flight frame by frame.
## The tree a sample bird leaves.
flight_left_tree : Trees.RoadsideTree
flight_left_tree = tree_at(100.0, -6.0)

## A tree on the far side too near to fly to, and two far enough.
flight_sample_trees : List(Trees.RoadsideTree)
flight_sample_trees = [
	flight_left_tree,
	tree_at(100.0, 6.0),
	tree_at(140.0, -6.0),
	tree_at(140.0, 6.0),
	tree_at(180.0, 6.0),
]

## A flight from the left tree to a gold one 40 m on, across the road.
sample_flight : BirdFlight.Flight
sample_flight = { from: flight_left_tree, to: { ..tree_at(140.0, 6.0), kind: Conifer.Gold } }

## Where the tree a bird on the left tree flies to stands, among `choices`.
chosen_tree_numbers : List(Trees.RoadsideTree) -> List(F64)
chosen_tree_numbers = |choices|
	match BirdFlight.flight_from(choices, flight_left_tree) {
		Ok({ to, .. }) => [to.road_point.along.to_metres(), to.road_point.across.to_metres()]
		Err(NoTreeToFlyTo) => []
	}

expect chosen_tree_numbers(flight_sample_trees) == [140.0, 6.0]
expect chosen_tree_numbers([flight_left_tree, tree_at(124.0, 6.0)]) == []
expect chosen_tree_numbers([flight_left_tree, tree_at(125.0, 6.0)]) == [125.0, 6.0]
expect chosen_tree_numbers([flight_left_tree, tree_at(140.0, -6.0)]) == []
expect
	BirdFlight.flight_from(flight_sample_trees, flight_left_tree).map_ok(|flight| flight.from)
		== Ok(flight_left_tree)

## The sample bird `steps_in` steps into its flight.
flight_frame_of : U32 -> BirdFlight.BirdInstant
flight_frame_of = |steps_in| BirdFlight.instant_at(sample_flight, Playing(Steps.of(steps_in)))

expect {
	location = BirdFlight.instant_at(sample_flight, Waiting).location
	location.along.to_metres() == 100.0
		and location.across.to_metres() == -6.0
		and location.lift.to_metres() == left_top
}

expect {
	location = BirdFlight.instant_at(sample_flight, Past(Steps.zero)).location
	location.along.to_metres() == 140.0
		and location.across.to_metres() == 6.0
		and location.lift.to_metres() == far_top
}

expect BirdFlight.instant_at(sample_flight, Waiting).pose == Perched
expect BirdFlight.instant_at(sample_flight, Past(Steps.zero)).pose == Perched

# A flap side on, seven from behind, and one of diving, four steps to a flap.
expect
	[
		(0, Side(WingsUp)),
		(1, Side(WingsUp)),
		(2, Side(WingsDown)),
		(3, Side(WingsDown)),
		(4, Away(WingsUp)),
		(6, Away(WingsDown)),
		(29, Away(WingsUp)),
		(31, Away(WingsDown)),
		(32, Diving),
		(35, Diving),
	].all(|(steps_in, pose)| flight_frame_of(steps_in).pose == pose)

# The flight starts on the first tree's tip and ends on the second's, and its
# path rises over the straight line between them.
expect flight_frame_of(0).location == BirdFlight.instant_at(sample_flight, Waiting).location
expect {
	last = flight_frame_of(35).location
	[
		(last.along.to_metres(), 140.0),
		(last.across.to_metres(), 6.0),
		(last.lift.to_metres(), far_top),
	].all(|(got, want)| (got - want).abs() <= 0.000000001)
}
expect flight_frame_of(18).location.lift.to_metres() > (left_top + far_top) / 2.0 + 4.0

# PosedCat and PosedBird on screen.
## The spot `forward` ahead on the rider's own segment, `right` of the camera
## and `lift` off the ground.
posed_spot_at : {
	forward : Distance,
	right : Distance,
	lift : Distance,
} -> Spot
posed_spot_at = |{ forward, right, lift }| {
	foot =
		Geom.ahead_on_level({ right, forward })
			?? crash "CrossModuleExpects: a test's animal is past the near plane"
	Spot.at({
		place: Ahead(SegmentPlace.Position.first),
		road_point: {
			along: Along.metres(forward.to_metres()),
			across: Across.metres(right.to_metres()),
		},
		lift,
		foot,
	})
}

## `cat` 100 m straight ahead through a 500 px focal length, `lift` off the
## ground: on the ground its feet land at (480, 306), and it stands 8.5 px tall.
sample_cat_shapes : PosedCat, Distance -> List(Shapes.Shape)
sample_cat_shapes = |cat, lift|
	cat.scenery_picture({
		spot: posed_spot_at({
			forward: Distance.metres(100.0),
			right: Distance.zero,
			lift,
		}),
		cam_focal: Pixels.of(500.0),
		context: {},
	}).to_shapes()

## The first corner `cat` draws, `lift` off the ground: its still's first
## corner's coordinates, on screen.
first_cat_corner_coordinates : PosedCat, Distance -> List(F64)
first_cat_corner_coordinates = |cat, lift|
	match sample_cat_shapes(cat, lift) {
		[Poly(polygon), ..] => polygon.coordinates.take_first(2)
		_ => crash "CrossModuleExpects: a cat draws polygons"
	}

## Whether each of `got` is within a billionth of its `expected`.
is_near_each : List(F64), List(F64) -> Bool
is_near_each = |got, expected| {
	misses = got.map2(expected, |one, wanted| (one - wanted).abs())
	got.len() == expected.len() and misses.all(|miss| miss <= 0.000000001)
}

# The resting still's first corner is (0.0092, 0.4513), and 1 m of lift at 100 m
# raises it 5 px without moving it across.
expect
	[
		(Distance.zero, [480.0782, 302.16395]),
		(Distance.metres(1.0), [480.0782, 297.16395]),
	].all(|(lift, want)| is_near_each(first_cat_corner_coordinates({ pose: Rest }, lift), want))

# Each cat pose draws every polygon of its still.
expect
	[
		Rest,
		Stride,
		Frozen,
		Coil,
		Flight,
		Land,
		Collapse,
	].all(
		|pose| {
			shapes = sample_cat_shapes({ pose: pose }, Distance.zero)
			shapes.len() == PosedCat.pose_still(pose).polygons().len()
		},
	)

## `bird` 110 m ahead, `right` of the camera and `lift` off the ground, through
## a 500 px focal length. A lift of the camera's height puts its feet on the
## horizon.
bird_shapes_at : PosedBird, { right : Distance, lift : Distance } -> List(Shapes.Shape)
bird_shapes_at = |bird, { right, lift }| {
	spot = posed_spot_at({ forward: Distance.metres(110.0), right, lift })
	bird.scenery_picture({ spot, cam_focal: Pixels.of(500.0), context: {} }).to_shapes()
}

## How many pixels tall a perched bird `forward` ahead, on the ground, is
## through `cam_focal`.
bird_height_on_screen : Distance, Pixels -> F64
bird_height_on_screen = |forward, cam_focal| {
	spot = posed_spot_at({ forward, right: Distance.zero, lift: Distance.zero })
	bird : PosedBird
	bird = { pose: Perched }
	anchor = StillShapes.standing_anchor(
		{ spot, cam_focal, context: {} },
		{ height: bird.scenery_height(), flip: AsDrawn },
	)
	anchor.height_on_screen.to_f64()
}

expect
	[
		(bird_height_on_screen(Distance.metres(110.0), Pixels.of(500.0)), 10.0),
		(bird_height_on_screen(Distance.metres(220.0), Pixels.of(500.0)), 5.0),
		(bird_height_on_screen(Distance.metres(110.0), Pixels.of(1000.0)), 20.0),
	].all(|(got, want)| (got - want).abs() <= 0.000000001)

# The perched still's first corner is (-0.0344, 0.5715), at a height of 10 px
# from feet at (480, 300). 11 m to the right and 11 m above the camera, at
# 110 m, is 50 px each way.
expect {
	first_corner = |perch|
		match bird_shapes_at({ pose: Perched }, perch) {
			[Poly(polygon), ..] => polygon.coordinates.take_first(2)
			_ => crash "CrossModuleExpects: a bird draws polygons"
		}
	raised = { right: Distance.metres(11.0), lift: Camera.eye_height.plus(Distance.metres(11.0)) }
	[
		({ right: Distance.metres(0.0), lift: Camera.eye_height }, [479.656, 294.285]),
		(raised, [529.656, 244.285]),
	].all(|(perch, want)| is_near_each(first_corner(perch), want))
}

# Each still's polygons, in their colours, as a bird in each pose draws them.
expect {
	fill_of = |shape|
		match shape {
			Poly(polygon) => polygon.fill
			_ => crash "CrossModuleExpects: a bird's still is polygons"
		}
	level = { right: Distance.metres(0.0), lift: Camera.eye_height }
	drawn = [Side(WingsDown), Diving].join_map(
		|pose| bird_shapes_at({ pose: pose }, level).map(fill_of),
	)
	side_down = BirdStills.side_wings_down_still.polygons()
	stills = side_down.concat(BirdStills.diving_still.polygons())
	drawn
		== stills.map(
			|poly|
				match poly.fill {
					Flat(color) => Brush.flat(color)
					Shaded(_) => crash "CrossModuleExpects: a bird's still is flat"
				},
		)
}

# Every bird and emoji still draws all its polygons through StillShapes, so
# Polygon's own checks judge the data. The cat's poses are drawn above.
expect {
	anchor = {
		foot: Screen.point(100.0, 200.0),
		flip: AsDrawn,
		height_on_screen: Pixels.of(50.0),
	}
	bird_stills = [
		Perched,
		Side(WingsUp),
		Side(WingsDown),
		Away(WingsUp),
		Away(WingsDown),
		Diving,
	].map(PosedBird.pose_still)
	emoji_stills = [
		EmojiStills.duck,
		EmojiStills.elephant,
		EmojiStills.giraffe,
		EmojiStills.zebra,
		EmojiStills.rhino,
		EmojiStills.bull,
		EmojiStills.cow,
		EmojiStills.pig,
	].map(|emoji| emoji.still())
	bird_stills.concat(emoji_stills).all(
		|still| StillShapes.still_shapes(anchor, still).len() == still.polygons().len(),
	)
}

expect FrameView.frame_view_at(World.route, ride_at_step_one).ride_shapes.len() > 0

# The ride starts facing away from the sun.
expect FrameView.frame_view_at(World.route, RideInstant.initial).backdrop.sun_sighting == OutOfView

## A rider on the segment at `segment`, turned `yaw` from its axis, leaning
## `lean` and looking `gaze_yaw` from the way the motorcycle points.
rider_facing : {
	segment : U32,
	yaw : Angle.Turn,
	lean : Angle.Lean,
	gaze_yaw : Angle.Turn,
} -> RiderState
rider_facing = |{ segment, yaw, lean, gaze_yaw }| {
	..RiderState.initial,
	segment_index: Route.SegmentIndex.number(segment),
	motorcycle: { ..RiderState.initial.motorcycle, yaw, lean },
	eyes: { ..RiderState.initial.eyes, gaze_yaw },
}

# The camera's heading is the bearing the rider's segment sets off on, turned by
# the motorcycle's yaw, the gaze and the lean (0.15 of it). The first two are on
# the first segment, which sets off north: a rider looking straight ahead faces
# north, and one turned 0.375 by the yaw, 0.375 by the gaze and 0.01875 by the
# lean faces 0.76875. The third is the second segment's bearing alone, the first
# bend's 50 degrees. The fourth is the long westward segment's bearing, minus
# 120 degrees, turned 0.05 left. The fifth is the last segment's bearing, turned
# 0.0125 right by a gaze to the right against a lean to the left.
expect
	[
		(
			{
				segment: 0,
				yaw: Angle.Turn.radians(0.0),
				lean: Angle.Lean.radians(0.0),
				gaze_yaw: Angle.Turn.radians(0.0),
			},
			0.0,
		),
		(
			{
				segment: 0,
				yaw: Angle.Turn.radians(0.375),
				lean: Angle.Lean.radians(0.125),
				gaze_yaw: Angle.Turn.radians(0.375),
			},
			0.76875,
		),
		(
			{
				segment: 1,
				yaw: Angle.Turn.radians(0.0),
				lean: Angle.Lean.radians(0.0),
				gaze_yaw: Angle.Turn.radians(0.0),
			},
			0.8726646259971648,
		),
		(
			{
				segment: longest_segment_index.to_u32(),
				yaw: Angle.Turn.radians(-0.25),
				lean: Angle.Lean.radians(0.5),
				gaze_yaw: Angle.Turn.radians(0.125),
			},
			-2.144395102393195,
		),
		(
			{
				segment: 18,
				yaw: Angle.Turn.radians(0.0),
				lean: Angle.Lean.radians(-0.75),
				gaze_yaw: Angle.Turn.radians(0.125),
			},
			-1.4710298641951802,
		),
	].all(
		|(facing, heading)| {
			camera = RiderCamera.of(
				rider_facing(facing),
				{ route: World.route, encounter_timing: Unplanned },
			)
			camera.heading.to_radians() == heading
		},
	)

# The route sets off north, and each segment's bearing is the one before it
# turned by the bend between them.
expect World.route.bearing_of(Route.SegmentIndex.first) == Angle.north
expect {
	first_turn = World.route.segment_at(Route.SegmentIndex.first).bend_out_of().turn
	World.route.bearing_of(Route.SegmentIndex.number(1)) == Angle.north.plus(first_turn)
		and first_turn != Angle.straight_ahead
}

# The camera's focal length: the view widens as the rider leans, and as the
# rider's attention is caught, by the cat on the road or by a look to the side.
## The focal length of the camera for `rider` on the cat route, before any
## encounter is planned.
focal_of : RiderState -> Pixels
focal_of = |rider|
	RiderCamera.of(rider, { route: cat_route, encounter_timing: Unplanned }).cam_focal

## An encounter ten steps in.
ten_steps_in : EncounterPlan.Timing
ten_steps_in = EncounterPlan.timing_of(StartsAt(Clock.at_step(100)), Clock.at_step(110))

## The focal length of the camera for `rider` on the cat route, with the
## encounter on their segment ten steps in.
focal_ten_steps_in : RiderState -> Pixels
focal_ten_steps_in = |rider| RiderCamera.of(
	rider,
	{ route: cat_route, encounter_timing: ten_steps_in },
).cam_focal

## A rider at the start of the first segment, upright and looking ahead.
upright : RiderState
upright = RiderState.initial

## An upright rider on the segment at `number`.
rider_on : U32 -> RiderState
rider_on = |number| { ..upright, segment_index: Route.SegmentIndex.number(number) }

## The same rider leaning `lean`.
leaning = |rider, lean| { ..rider, motorcycle: { ..rider.motorcycle, lean } }

## The same rider as deep into a look as a rider goes.
looking_hard : RiderState -> RiderState
looking_hard = |rider| { ..rider, eyes: { ..rider.eyes, look_depth: Fraction.whole } }

## How strongly the encounter on this rider's segment, at `encounter_timing`, holds
## their attention.
encounter_attention_of : RiderState, EncounterPlan.Timing -> F64
encounter_attention_of = |rider, encounter_timing|
	EncounterReaction.encounter_attention(
		cat_route.segment_at(rider.segment_index),
		encounter_timing,
	).to_f64()

expect focal_of(upright).minus(Lens.resting_focal) == Pixels.zero
expect encounter_attention_of(upright, Unplanned) == 0.0
expect Gaze.gaze_attention(Fraction.zero).to_f64() == 0.0
expect Lens.focal_for({
	lean: upright.motorcycle.lean,
	attention: Attention.none,
}).minus(Lens.resting_focal) == Pixels.zero

focal_at_lean = |lean| focal_of(leaning(upright, lean))

no_lean = upright.motorcycle.lean

## The change from upright to the full lean.
full_change = Lens.full_lean.change_from(no_lean)

## The full lean, to the left.
full_left = no_lean.minus(full_change)

expect {
	half = no_lean.halfway_to(Lens.full_lean)
	focal_at_lean(half) < focal_at_lean(no_lean)
		and focal_at_lean(Lens.full_lean) < focal_at_lean(half)
		and focal_at_lean(full_left) < focal_at_lean(no_lean)
		and focal_at_lean(no_lean) <= Lens.resting_focal
}

# A lean past the greatest one widens the view no further.
expect focal_at_lean(Lens.full_lean) == focal_at_lean(full_left)

expect {
	twice = Lens.full_lean.plus(full_change)
	twice_change = twice.change_from(no_lean)
	ten_times = twice.plus(twice_change).plus(twice_change).plus(twice_change).plus(twice_change)
	focal_at_lean(twice).minus(focal_at_lean(Lens.full_lean)) == Pixels.zero
		and focal_at_lean(ten_times).minus(focal_at_lean(Lens.full_lean)) == Pixels.zero
}

expect encounter_attention_of(rider_on(1), ten_steps_in) > 0.0
expect !(encounter_attention_of(rider_on(1), Unplanned) > 0.0)
expect !(encounter_attention_of(rider_on(0), ten_steps_in) > 0.0)
expect focal_ten_steps_in(rider_on(1)) < focal_ten_steps_in(rider_on(0))

# While a cat crosses, the rider eases off: the throttle holds the acceleration
# at none. Before the crossing it opens.
## The change of speed Throttle makes for a rider at the start of the world's
## cat segment, going 0.3 m a step, with its crossing at `encounter_timing`.
cat_throttle_change : EncounterPlan.Timing -> F64
cat_throttle_change = |encounter_timing| {
	motorcycle = { ..Motorcycle.initial, speed: Speed.metres_a_step(0.3) }
	segment = World.route.segment_at(Route.SegmentIndex.number(3))
	Throttle.next_speed(motorcycle, { segment, encounter_timing })
		.change_from(motorcycle.speed)
		.to_metres_a_step_each_step()
}

expect cat_throttle_change(ten_steps_in) == 0.0
expect cat_throttle_change(Unplanned) > 0.0
expect {
	before_it = EncounterPlan.timing_of(StartsAt(Clock.at_step(100)), Clock.at_step(99))
	cat_throttle_change(before_it) > 0.0
}
expect focal_of(looking_hard(upright)) < focal_of(upright)
expect {
	half_look = { ..upright, eyes: { ..upright.eyes, look_depth: Fraction.of(0.5) } }
	focal_of(looking_hard(upright)) < focal_of(half_look)
}
expect Gaze.gaze_attention(Fraction.whole).to_f64() > Gaze.gaze_attention(Fraction.zero).to_f64()

both : Pixels
both = focal_of(looking_hard(leaning(upright, Lens.full_lean)))

lean_only : Pixels
lean_only = focal_of(leaning(upright, Lens.full_lean))

gaze_only : Pixels
gaze_only = focal_of(looking_hard(upright))

expect both <= lean_only
expect both <= gaze_only
expect
	both.to_f64().to_bits()
		== lean_only.to_f64().min(gaze_only.to_f64()).to_bits()
expect lean_only.plus(gaze_only) > both
expect both.to_f64() - lean_only.to_f64().min(gaze_only.to_f64()) == 0.0
expect Lens.focal_for({
	lean: Lens.full_lean,
	attention: Attention.none,
}).minus(lean_only) == Pixels.zero

## A pond's bend at the end of a segment 100 m long, turning 15° right.
right_pond_bend : Geom.Bend
right_pond_bend = { segment_length: Distance.metres(100.0), turn: Angle.Turn.degrees(15.0) }

## A pond's bend at the end of a segment 100 m long, turning 15° left.
left_pond_bend : Geom.Bend
left_pond_bend = { segment_length: Distance.metres(100.0), turn: Angle.Turn.degrees(-15.0) }

expect
	Pond.placed_ducks(right_pond_bend).map(|placed| placed.road_point.along.to_metres())
		== [111.0, 117.0, 121.0, 106.0, 107.0, 108.0]
expect Pond.placed_ducks(right_pond_bend).all(|placed| placed.kind.height.to_metres() == 0.9)

# A duck floats as far out from the road at a left turn as at a right one, on
# the other side.
expect
	Pond.placed_ducks(right_pond_bend).map(|placed| placed.road_point.across.to_metres())
		== [-10.0, -18.0, -11.0, -6.0, -14.0, -22.0]
		and Pond.placed_ducks(left_pond_bend).map(|placed| placed.road_point.across.to_metres())
			== [10.0, 18.0, 11.0, 6.0, 14.0, 22.0]

# Mirrored to the other side of the road at a left turn, each duck faces the
# other way.
expect
	Pond.placed_ducks(right_pond_bend).map(|placed| placed.kind.facing)
		== [FacesRight, FacesLeft, FacesRight, FacesRight, FacesLeft, FacesRight]
		and Pond.placed_ducks(left_pond_bend).map(|placed| placed.kind.facing)
			== [FacesLeft, FacesRight, FacesLeft, FacesLeft, FacesRight, FacesLeft]

# The pond's water and bank lie off the road on the outside of the bend,
# whichever way the road turns.
expect {
	pond_acrosses = |bend|
		Pond.pond_outlines(bend).join_map(|outline| outline.corners.map(|point| point.across))
	pond_acrosses(right_pond_bend).all(|across| across < Geom.left_edge)
		and pond_acrosses(left_pond_bend).all(|across| across > Geom.right_edge)
}
# Coast's projections. Coast imports neither Angle nor Speed, which these need.

## The coast of a motorcycle at the start of the segment, going the base speed.
coast_of : F64, F64 -> Coast.Outcome
coast_of = |across, lean_radians|
	Coast.project({
		..Motorcycle.initial,
		across: Across.metres(across),
		lean: Angle.Lean.radians(lean_radians),
	})

expect coast_of(0.0, 0.0) == EndsAt(Across.metres(0.0))
expect coast_of(3.0, 0.0) == EndsAt(Across.metres(3.0))
expect Coast.project({ ..Motorcycle.initial, speed: Speed.at_rest }) == EndsAt(Across.metres(0.0))

# A rider this slow and this far over circles on the road, and the coast still ends.
expect {
	circling = Coast.project({
		..Motorcycle.initial,
		speed: Speed.metres_a_step(0.01),
		lean: Angle.Lean.radians(0.5),
	})
	match circling {
		EndsAt(_) => True
		Leaves(_) => False
	}
}

# A coast's path has a motorcycle for each step it ran and ends where its
# outcome says, clear of the start when it stays on the road, and `project`
# gives the same outcome without the path.
expect {
	state = {
		..Motorcycle.initial,
		yaw: Angle.Turn.radians(-1.5),
		speed: Speed.metres_a_step(0.7),
	}
	coast = Coast.coast_path(state)
	match coast.outcome {
		Leaves({ side: Left, after }) =>
			coast.path_motorcycles.len() == after.to_u32().to_u64()
				and coast.outcome == Coast.project(state)
		Leaves({ side: Right, .. }) | EndsAt(_) => False
	}
}
expect {
	state = { ..Motorcycle.initial, across: Across.metres(1.0) }
	coast = Coast.coast_path(state)
	match (coast.outcome, coast.path_motorcycles.last()) {
		(EndsAt(end_across), Ok(last)) =>
			last.across == end_across
				and last.along.distance_from(state.along) >= Coast.clear_distance
				and coast.outcome == Coast.project(state)
		(Leaves(_), _) | (EndsAt(_), Err(_)) => False
	}
}

## How many steps a coast runs before it leaves the road.
steps_off_road : Coast.Outcome -> Steps
steps_off_road = |coast|
	match coast {
		Leaves({ after, .. }) => after
		EndsAt(_) => crash "CrossModuleExpects: this coast stays on the road"
	}

# A lean to the right coasts off the right shoulder, and the same lean to the
# left coasts off the left one in as many steps.
expect {
	right_lean = coast_of(0.0, 0.2)
	left_lean = coast_of(0.0, -0.2)
	right_lean == Leaves({ side: Right, after: steps_off_road(right_lean) })
		and left_lean == Leaves({ side: Left, after: steps_off_road(left_lean) })
		and steps_off_road(right_lean) == steps_off_road(left_lean)
}

## The change of speed Throttle makes for a motorcycle on the first segment far
## off to the right, leaning `lean`.
wide_of_road : F64 -> F64
wide_of_road = |lean| {
	motorcycle = {
		..Motorcycle.initial,
		across: Across.metres(100.0),
		lean: Angle.Lean.radians(lean),
	}
	first_segment = World.route.segment_at(Route.SegmentIndex.number(0))
	Throttle.next_speed(motorcycle, { segment: first_segment, encounter_timing: Unplanned })
		.change_from(motorcycle.speed)
		.to_metres_a_step_each_step()
}

# A rider far off to the right, whose coast crosses no shoulder, opens the
# throttle however far they lean. Each is within 1e-12 of its want.
expect [-0.001, -0.035, -0.535].all(|lean| (wide_of_road(lean) - 0.01).abs() <= 0.000000000001)

## A segment with no pigs.
pigless_segment : Segment
pigless_segment = segment_of([])

## The route's first segment with a herd the rider finds distracting.
distracting_segment : Segment
distracting_segment = World.first_distracting_segment

expect Gawking.eye_catching_pig(pigless_segment) == NoPigCatchesEye

## A segment of the route whose herd the rider passes by.
passed_by_segment : Segment
passed_by_segment = World.route.segment_at(Route.SegmentIndex.number(11))

expect Gawking.eye_catching_pig(passed_by_segment) == NoPigCatchesEye

## The pig that catches the eye on the distracting segment.
watched_pig : Geom.Placed(Billboard)
watched_pig =
	match Gawking.eye_catching_pig(distracting_segment) {
		CatchesEye(pig) => pig
		NoPigCatchesEye => crash "CrossModuleExpects: this segment's pigs catch the eye"
	}

# The rider watches a pig of the herd.
expect distracting_segment.segment_pigs().count_if(|pig| pig == watched_pig) == 1

## A motorcycle `along` metres into its segment, at rest in every other way.
motorcycle_at : F64 -> Motorcycle
motorcycle_at = |along| {
	..Motorcycle.initial,
	along: Motorcycle.initial.along.plus(Distance.metres(along)),
}

## A motorcycle on the distracting segment, `metres` short of the pig.
short_of_pig : F64 -> Motorcycle
short_of_pig = |metres| {
	..Motorcycle.initial,
	along: watched_pig.road_point.along.minus(Distance.metres(metres)),
}

expect !Gawking.is_gawking(motorcycle_at(200.0), pigless_segment)
expect !Gawking.is_gawking(motorcycle_at(100.0), distracting_segment)
expect Gawking.is_gawking(motorcycle_at(200.0), distracting_segment)
expect Gawking.is_gawking(motorcycle_at(341.0), distracting_segment)

# The gawking starts where the pig is noticed, and not a centimetre sooner.
expect Gawking.is_gawking(short_of_pig(Gawking.notice_distance.to_metres()), distracting_segment)
expect !Gawking.is_gawking(short_of_pig(150.01), distracting_segment)

expect Gawking.gawk_brake(motorcycle_at(200.0), pigless_segment) == NoLimit
expect Gawking.gawk_brake(motorcycle_at(100.0), distracting_segment) == NoLimit

## The brake for a motorcycle `metres` short of the pig, going `speed` metres a
## step.
brake_short_of_pig : F64, F64 -> F64
brake_short_of_pig = |metres, speed| {
	motorcycle = { ..short_of_pig(metres), speed: Speed.metres_a_step(speed) }
	match Gawking.gawk_brake(motorcycle, distracting_segment) {
		AtMost(brake) => brake.to_metres_a_step_each_step()
		NoLimit => crash "CrossModuleExpects: this rider is gawking"
	}
}

# Each is within 1e-12 of its want. The brake works out the road left to the
# settle distance, until there's less than the least distance left.
expect
	[
		((125.0, 0.3), -0.00025),
		((75.0, 0.3), -0.0005),
		((27.0, 0.3), -0.0125),
		((26.0, 0.3), -0.025),
		((25.5, 0.3), -0.025),
		((0.0, 0.3), -0.025),
		((-10.0, 0.3), -0.025),
		((125.0, 0.2), 0.0),
		((125.0, 0.1), 0.00015),
	].all(
		|
			((metres, speed), want),
		| (brake_short_of_pig(metres, speed) - want).abs() <= 0.000000000001,
	)

## How far this motorcycle on the distracting segment wants to turn to the pig.
turn_to_pig : Motorcycle -> F64
turn_to_pig = |motorcycle|
	match Gaze.desired_gaze(motorcycle, distracting_segment) {
		OnPig(turn) => turn.to_radians()
		OnRoad => crash "CrossModuleExpects: no pig in sight"
	}

expect {
	far = turn_to_pig(motorcycle_at(200.0))
	near = turn_to_pig(motorcycle_at(320.0))
	far > 0.0 and near > far
}

expect Gaze.desired_gaze(motorcycle_at(200.0), pigless_segment) == OnRoad
expect Gaze.desired_gaze(motorcycle_at(100.0), distracting_segment) == OnRoad

# The gawking outlasts the look: at 341 m the rider still gawks, but no longer
# looks.
expect Gaze.desired_gaze(motorcycle_at(341.0), distracting_segment) == OnRoad

## A motorcycle 100 m short of the pig, turned so the pig is `degrees` off.
motorcycle_with_pig_off : F64 -> Motorcycle
motorcycle_with_pig_off = |degrees| {
	straight = short_of_pig(100.0)
	turn_to_watched_pig = Angle.Turn.radians(
		F64.atan2({
			x: watched_pig.road_point.along.distance_from(straight.along).to_metres(),
			y: watched_pig.road_point.across.distance_from(straight.across).to_metres(),
		}),
	).minus(straight.yaw)
	{ ..straight, yaw: turn_to_watched_pig.minus(Angle.Turn.degrees(degrees)) }
}

## Whether this motorcycle's rider on the distracting segment wants to look at
## the pig.
is_looking : Motorcycle -> Bool
is_looking = |motorcycle|
	match Gaze.desired_gaze(motorcycle, distracting_segment) {
		OnPig(_) => True
		OnRoad => False
	}

# The pig stays in sight up to the release angle, on either side of the
# motorcycle.
expect
	[
		(34.99, True),
		(-34.99, True),
		(35.01, False),
		(-35.01, False),
	].all(|(degrees, is_in_sight)| is_looking(motorcycle_with_pig_off(degrees)) == is_in_sight)

# A coast off the left shoulder means lean more right, and off the right more
# left.
expect LeanSearch.lean_correction(Leaves({ side: Left, after: Steps.one_step })) == MoreRight
expect LeanSearch.lean_correction(Leaves({ side: Right, after: Steps.one_step })) == MoreLeft

## A straight road of three segments, 500 m, 320 m and 400 m long, and the
## road ahead of a rider on the first of them.
truck_road : RoadAhead.RoadView
truck_road = crafted_road([
	{ ..going_straight_on(segment_of([])), length: Distance.metres(500.0) },
	{ ..going_straight_on(segment_of([])), length: Distance.metres(320.0) },
	{ ..segment_of([]), length: Distance.metres(400.0) },
])

## What becomes of a truck `lead` metres ahead of a rider on the truck road's
## first segment, seen from `vantage`, with its lights off. On the first
## segment the rider's distance along the route is the vantage's `along`.
truck_seen_from : Geom.Vantage, F64 -> TruckSighting.TruckFate
truck_seen_from = |vantage, lead|
	TruckSighting.truck_in_view(
		truck_road,
		{
			camera: { vantage: vantage },
			route_position: Distance.metres(vantage.along.to_metres() + lead),
			lit_truck: { headlights: Off, brake_lights: Off },
		},
	)

## What becomes of a truck `lead` metres ahead of a rider at `origin`.
truck_lead_of : F64 -> TruckSighting.TruckFate
truck_lead_of = |lead| truck_seen_from(origin, lead)

## Where the truck is, for a lead that puts it in view.
lit_truck_of : F64 -> Pipeline.Sighted(LitTruck)
lit_truck_of = |lead| truck_lead_of(lead) ?? crash "CrossModuleExpects: this lead puts the truck in view"

# The truck is in view on the road ahead, and not past its end or behind the
# rider.
expect
	[
		(100.0, True),
		(499.0, True),
		(600.0, True),
		(900.0, True),
		(2000.0, False),
		(0.0, False),
		(-50.0, False),
	].all(|(lead, want)| truck_lead_of(lead).is_ok() == want)

# A truck past a segment's end stands on a later segment, measured from its
# start, in the middle of the road.
expect
	[
		(100.0, SegmentPlace.Position.first),
		(499.0, SegmentPlace.Position.first),
		(600.0, second_position),
		(900.0, second_position.next()),
	].all(|(lead, want)| lit_truck_of(lead).spot.place() == Ahead(want))

expect
	[
		(100.0, 100.0),
		(499.0, 499.0),
		(600.0, 100.0),
		(900.0, 80.0),
	].all(|(lead, want)| lit_truck_of(lead).spot.road_point().along.to_metres() == want)

expect
	[
		(100.0, 0.0),
		(499.0, 0.0),
		(600.0, 0.0),
		(900.0, 0.0),
	].all(|(lead, want)| lit_truck_of(lead).spot.road_point().across.to_metres() == want)

## The lights a truck in view shows, when it has `lights` on.
lights_shown : LitTruck -> LitTruck
lights_shown = |lights| {
	truck = TruckSighting.truck_in_view(
		truck_road,
		{
			camera: { vantage: origin },
			route_position: Distance.metres(100.0),
			lit_truck: lights,
		},
	) ?? crash "CrossModuleExpects: this lead puts the truck in view"
	truck.kind
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
		(lit_truck_of(100.0).spot.foot().forward().to_metres(), 100.0),
		(lit_truck_of(499.0).spot.foot().forward().to_metres(), 499.0),
		(lit_truck_of(100.0).spot.foot().right().to_metres(), 0.0),
	].all(|(got, want)| (got - want).abs() <= 0.0001)

# A truck in view must be past the near plane.
expect truck_seen_from({ ..origin, along: Along.metres(100.0) }, 0.25).is_err()
expect truck_seen_from({ ..origin, along: Along.metres(100.0) }, 1.0).is_ok()

## A still 50 pixels tall, standing as drawn on a foot at (100, 200).
upright_still_anchor : StillShapes.Anchor
upright_still_anchor = {
	foot: Screen.point(100.0, 200.0),
	flip: AsDrawn,
	height_on_screen: Pixels.of(50.0),
}

# A still of one flat polygon of colour 7, its three points all at the foot, is
# drawn as one opaque polygon there.
expect
	StillShapes.still_shapes(
		upright_still_anchor,
		Still.of([{ fill: Flat(RgbColor.of(7)), points: List.repeat({ x: 0.0, y: 0.0 }, 3) }]),
	)
		== [
			Poly({
				coordinates: [100.0, 200.0, 100.0, 200.0, 100.0, 200.0],
				fill: Flat(Brush.opaque(RgbColor.of(7))),
			}),
		]
