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
import game.Attention
import game.BendInView
import game.Billboard
import game.BirdFlight
import game.Cat
import game.CatCrossing
import game.Clock
import game.Coast
import game.Conifer
import game.EncounterSighting
import game.BillboardSighting
import game.DepthSort
import game.Distance
import game.EmojiStills
import game.EncounterReaction
import game.Fraction
import game.FrameView
import game.Gaze
import game.RoadAhead
import game.Route
import game.Segment
import game.SegmentPlace
import game.Geom
import game.Motorcycle
import game.Mountains
import game.Lens
import game.Ground
import game.GroundSighting
import game.Pipeline
import game.Pond
import game.PosedBird
import game.PosedCat
import game.RailSighting
import game.Rendered
import game.Scene
import game.RideInstant
import game.Rider
import game.RiderCamera
import game.RiderState
import game.Screen
import game.Sky
import game.Speed
import game.Spot
import game.Steps
import game.StillShapes
import game.Sun
import game.Throttle
import game.TowerSighting
import game.TreeSighting
import game.TruckSighting
import game.Trees
import game.VehicleLimits
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
road_from : U32 -> RoadAhead.RoadView
road_from = |number| RoadAhead.RoadView.ahead_of(World.route, Route.SegmentIndex.number(number))

## The road ahead of a rider on the route's first segment.
road : RoadAhead.RoadView
road = road_from(0)

## The world's first `count` segments, a route of their own.
route_of_first : U64 -> Route
route_of_first = |count|
	Route.from_segments(
		World.route.route_segments().take_first(count).map_with_index(
			|segment, at|
				if at + 1 == count {
					{ ..segment, ending: RouteEnds }
				} else {
					segment
				},
		),
	)

# Positions count along the road ahead from the rider's segment, not along the
# route from its start.
expect {
	from_third = road_from(2)
	length_at = |position| RoadAhead.segment_at(from_third, position).length
	length_of = |number| World.route.segment_at(Route.SegmentIndex.number(number)).length
	length_of(2) != length_of(0)
		and length_of(3) != length_of(1)
		and length_at(SegmentPlace.Position.first) == length_of(2)
		and length_at(SegmentPlace.Position.first.next()) == length_of(3)
}

# The road ahead holds as many segments as the rider can see, or the rest of
# the route.
expect World.route.segment_count() == 19
expect
	[
		(0, 7),
		(12, 7),
		(13, 6),
		(15, 4),
		(18, 1),
	].all(|(number, want)| road_from(number).segments_ahead().count == want)

expect [
	(0, 0),
	(3, 3),
].all(|(first, want)| RoadAhead.rider_segment(road_from(first)).to_i64() == want)

## The route's number of the segment in view just behind a rider on the
## world's segment `first`, or -1 at the route's start.
number_behind : U32 -> I64
number_behind = |first| {
	behind = RoadAhead.segments_in_view(road_from(first)).find_last(
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
	second_segment_point = turned_point_at(road, Ahead(SegmentPlace.Position.number(1)))
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
			place: bend_in_view.before,
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

# Segment's fifth left tree, which a bird starts on: only trees on the left count.
## A left and a right tree at each of `alongs`.
pairs_at : List(F64) -> List(Trees.RoadsideTree)
pairs_at = |alongs| alongs.join_map(|along| [tree_at(along, -6.0), tree_at(along, 6.0)])

## How far along the fifth left tree of `choices` is, if there is one.
fifth_along : List(Trees.RoadsideTree) -> Try(F64, [NoTree])
fifth_along = |choices|
	match Segment.fifth_left_tree(choices) {
		Found(tree) => Ok(tree.road_point.along.to_metres())
		NoTree => Err(NoTree)
	}

expect fifth_along([]) == Err(NoTree)
expect fifth_along(pairs_at([10.0, 20.0, 30.0, 40.0])) == Err(NoTree)
expect fifth_along(pairs_at([10.0, 20.0, 30.0, 40.0, 50.0])) == Ok(50.0)
expect fifth_along(pairs_at([10.0, 20.0, 30.0, 40.0, 50.0, 60.0])) == Ok(50.0)
expect fifth_along([50.0, 60.0, 70.0, 80.0, 90.0].map(|along| tree_at(along, 6.0))) == Err(NoTree)

## Whether the trees planted for `plan` have a fifth on the left.
has_fifth_left_tree : World.SegmentPlan -> Bool
has_fifth_left_tree = |plan| {
	planted = Trees.roadside_trees({ scheme: plan.scheme, length: plan.length })
	match Segment.fifth_left_tree(planted) {
		Found(_) => True
		NoTree => False
	}
}

# Every segment the route plans with a bird has a tree for it to start on, or
# building the segment crashes. A segment too short for five trees on the left
# has none.
expect {
	bird_plans = World.segment_plans.keep_if(|plan| plan.encounter == BirdHere)
	bird_plans.len() > 0 and bird_plans.all(has_fifth_left_tree)
}
expect {
	short_plan = {
		..World.last_plan,
		length: Distance.metres(50.0),
		encounter: BirdHere,
	}
	!has_fifth_left_tree(short_plan)
}

## A segment 200 m long holding only `trees`, which ends a route.
segment_of : List(Trees.RoadsideTree) -> Segment
segment_of = |trees| {
	..World.route.segment_at(Route.SegmentIndex.first),
	length: Distance.metres(200.0),
	trees,
	ending: RouteEnds,
	encounter: match Segment.fifth_left_tree(trees) {
		Found(perch) => BirdHere(BirdFlight.habit_from(trees, perch))
		NoTree => QuietRoad
	},
}

## `segment`, bending straight on into another.
going_straight_on : Segment -> Segment
going_straight_on = |segment| {
	..segment,
	ending: Bends({ turn: Angle.straight_ahead, bend_life: Animal(Elephant) }),
}

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

## The birds on one segment of `trees`, for a rider `rider_along` metres into
## it, seen through a focal length of `cam_focal`.
birds_on : List(Trees.RoadsideTree),
{
	rider_along : F64,
	cam_focal : Pixels,
} -> List(Pipeline.Sighted(PosedBird))
birds_on = |trees, seen_from| birds_on_segment(segment_of(trees), seen_from)

## The birds on `segment_index`, for a rider `rider_along` metres into it.
birds_on_segment : Segment,
{
	rider_along : F64,
	cam_focal : Pixels,
} -> List(Pipeline.Sighted(PosedBird))
birds_on_segment = |segment, { rider_along, cam_focal }|
	EncounterSighting.birds_in_view(
		RoadAhead.RoadView.ahead_of(Route.from_segments([segment]), Route.SegmentIndex.first),
		{ vantage: { ..origin, along: Along.metres(rider_along) }, cam_focal },
	)

## The one bird that a rider `rider_along` metres in sees on the segment with
## a far tree.
bird_at : F64 -> Pipeline.Sighted(PosedBird)
bird_at = |rider_along|
	birds_on(left_trees.append(far_tree), { rider_along, cam_focal: Pixels.of(500.0) }).first()
		?? crash "CrossModuleExpects: this rider sees a bird"

## How far off a bird is, across the road and up.
place_numbers : Pipeline.Sighted(PosedBird) -> List(F64)
place_numbers = |bird| [
	bird.spot.foot().right().to_metres(),
	bird.spot.foot().forward().to_metres(),
	bird.spot.lift().to_metres(),
]

expect place_numbers(bird_at(0.0)) == [-6.0, 100.0, left_top]
expect place_numbers(bird_at(40.0)) == [-6.0, 60.0, left_top]

# Halfway through its flight, with the rider 37.5 m from the tree it left.
expect {
	bird = bird_at(62.5)
	[
		(bird.spot.foot().right().to_metres(), 0.0),
		(bird.spot.foot().forward().to_metres(), 52.5),
		(
			bird.spot.lift().to_metres(),
			(left_top + far_top) / 2.0 + BirdFlight.flight_arc.to_metres(),
		),
	].all(|(got, want)| (got - want).abs() <= 0.000000001)
}

expect place_numbers(bird_at(85.0)) == [6.0, 45.0, far_top]
expect bird_at(40.0).kind.pose == Perched
expect bird_at(62.5).kind.pose != Perched
expect bird_at(85.0).kind.pose == Perched

# With no tree far enough to fly to, the bird stays on its own however near
# the rider is.
expect {
	stays = birds_on(left_trees, { rider_along: 62.5, cam_focal: Pixels.of(500.0) })
	stays.join_map(place_numbers) == [-6.0, 37.5, left_top]
}

## How many birds there are on `trees` for each rider and focal length.
bird_count : List(Trees.RoadsideTree), { rider_along : F64, cam_focal : Pixels } -> I64
bird_count = |trees, seen_from| birds_on(trees, seen_from).len().to_i64_wrap()

## A segment where a cat crosses, with the same trees: it has no bird.
segment_with_cat : Segment
segment_with_cat = {
	..segment_of(left_trees),
	encounter: World.route.segment_at(Route.SegmentIndex.number(3)).encounter,
}

expect bird_count(left_trees, { rider_along: 0.0, cam_focal: Pixels.of(500.0) }) == 1
expect bird_count(left_trees.drop_last(1), { rider_along: 0.0, cam_focal: Pixels.of(500.0) }) == 0
expect bird_count(left_trees, { rider_along: 99.5, cam_focal: Pixels.of(500.0) }) == 1
expect bird_count(left_trees, { rider_along: 99.7, cam_focal: Pixels.of(500.0) }) == 0
expect bird_count(left_trees, { rider_along: 120.0, cam_focal: Pixels.of(500.0) }) == 0
expect bird_count(left_trees, { rider_along: 0.0, cam_focal: Pixels.of(91.0) }) == 1
expect bird_count(left_trees, { rider_along: 0.0, cam_focal: Pixels.of(90.0) }) == 0
expect
	birds_on_segment(segment_with_cat, { rider_along: 0.0, cam_focal: Pixels.of(500.0) }).len()
		== 0

## Two segments on the road ahead, the rider at the start of the first.
two_segments : List(Pipeline.Sighted(PosedBird))
two_segments = EncounterSighting.birds_in_view(
	RoadAhead.RoadView.ahead_of(
		Route.from_segments([going_straight_on(segment_of(left_trees)), segment_of(left_trees)]),
		Route.SegmentIndex.first,
	),
	origin_camera,
)

expect
	match two_segments.map(|bird| bird.spot.foot().forward()) {
		[near, far] => near == Distance.metres(100.0) and near < far
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

metre_a_step : Speed
metre_a_step = Speed.metres_a_step(1.0)

## The cat on the segment at `number` on the road ahead, if it is in view from
## the origin at 1 m a step.
cat_at : U32 -> Try(Pipeline.Sighted(PosedCat), [NoCat, BehindCamera, TooSmall])
cat_at = |number| EncounterSighting.segment_cat(
	cat_road,
	{
		camera: origin_camera,
		in_view: numbered_segment(cat_road, number),
		speed: metre_a_step,
	},
)

expect cat_route.route_segments().map(World.has_cat) == [False, True, False]

expect
	[
		(0.0, 0, 0.0),
		(0.0, 1, 500.0),
		(0.0, 2, 820.0),
		(120.0, 0, -120.0),
		(120.0, 1, 380.0),
		(120.0, 2, 700.0),
	].all(
		|
			(along, number, want),
		| {
			vantage = { ..origin, along: Along.metres(along) }
			gap = RoadAhead.gap_to_segment(
				cat_road,
				{ vantage, in_view: numbered_segment(cat_road, number) },
			)
			gap.to_metres() == want
		},
	)

## The cats in view for a rider `along` metres into the first segment.
ride_sightings : F64 -> List(Pipeline.Sighted(PosedCat))
ride_sightings = |along| EncounterSighting.cats_in_view(
	cat_road,
	{
		camera: { ..origin_camera, vantage: { ..origin, along: Along.metres(along) } },
		speed: metre_a_step,
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
expect cat_at(0).is_err()
expect cat_at(2).is_err()
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

# The sighting looks along the whole road ahead, and the reaction only at the
# rider's own segment. They agree because a crossing starts on its own segment: even at
# top speed it starts closer to the cat than the cat is to the segment's start,
# and a rider comes onto a segment no further along than that.
## The cats of the route, each with its segment.
route_cats : List({ segment : Segment, crossing : CatCrossing })
route_cats = World.route.route_segments().join_map(
	|segment|
		match segment.encounter {
			CatCrosses(crossing) => [{ segment, crossing }]
			BirdHere(_) | QuietRoad => []
		},
)

## How far short of a cat a crossing starts, at the fastest a rider goes.
farthest_start : Distance
farthest_start = Cat.clear_gap.plus(VehicleLimits.top_speed.distance_in(Cat.crossing_steps))

expect route_cats.len() == 3
expect farthest_start.to_metres() == 98.0
expect farthest_start < Segment.cat_along.plus(CatCrossing.cat_beyond_tree).from_start()
expect route_cats.all(|{ crossing, .. }| farthest_start < crossing.along.from_start())

# The reaction ends with its segment, so the cat's hold has to have faded by then
# or it would snap to nothing there. Braking for the bend only hurries the fade.
expect
	route_cats.all(
		|{ segment, crossing }| {
			gap = crossing.along.distance_from(Along.at(segment.length))
			Cat.attention({ gap, speed: Throttle.exit_speed(segment) }).to_f64() == 0.0
		},
	)

# BillboardSighting: how far along the road ahead each kind of critter is sighted.
## The road ahead of a rider on the first of a route of the world's first six
## segments.
six_segments : RoadAhead.RoadView
six_segments = RoadAhead.RoadView.ahead_of(route_of_first(6), Route.SegmentIndex.first)

## The road ahead of a rider on a route of the world's first segment alone.
first_alone : RoadAhead.RoadView
first_alone = RoadAhead.RoadView.ahead_of(route_of_first(1), Route.SegmentIndex.first)

## The critters of the segment at `in_view` on `road_view`, seen from the origin.
segment_billboards_on : RoadAhead.RoadView, RoadAhead.SegmentInView -> List(BillboardSighting.Fate)
segment_billboards_on = |road_view, in_view|
	BillboardSighting.segment_billboards(road_view, { vantage: origin, in_view })

## The farm animals of the segment at `in_view` on `road_view`, seen from the
## origin.
farm_sightings_on : RoadAhead.RoadView, RoadAhead.SegmentInView -> List(BillboardSighting.Fate)
farm_sightings_on = |road_view, in_view|
	BillboardSighting.farm_sightings(road_view, { vantage: origin, in_view })

## What lives at the end of the segment at `in_view` on `road_view`, seen from
## the origin.
bend_sightings_on : RoadAhead.RoadView, RoadAhead.SegmentInView -> List(BillboardSighting.Fate)
bend_sightings_on = |road_view, in_view|
	BillboardSighting.bend_sightings(road_view, { vantage: origin, in_view })

## The segment `number` places along the road ahead of `road_view`.
numbered_segment : RoadAhead.RoadView, U32 -> RoadAhead.SegmentInView
numbered_segment = |road_view, number|
	RoadAhead.segment_in_view_at(road_view, SegmentPlace.Position.number(number))

## The road ahead of a rider on the segment after the world's segment `number`,
## and `number` in view just behind that rider.
road_past_segment : U32 -> { road_view : RoadAhead.RoadView, in_view : RoadAhead.SegmentInView }
road_past_segment = |number| {
	road_view = road_from(number + 1)
	{ road_view, in_view: segment_in_view_behind(road_view) }
}

farm_at : U32 -> I64
farm_at = |number|
	farm_sightings_on(six_segments, numbered_segment(six_segments, number))
		.len()
		.to_i64_wrap()

bend_at : U32 -> I64
bend_at = |number|
	bend_sightings_on(six_segments, numbered_segment(six_segments, number))
		.len()
		.to_i64_wrap()

expect farm_at(0) > 0
expect farm_at(2) > 0
expect farm_at(3) == 0
expect farm_at(4) == 0
expect farm_at(5) == 0
expect bend_at(3) > 0
expect bend_at(4) > 0
expect bend_at(5) == 0

## How many critters live at the end of the world's segment `index`, seen alone.
lone_bend_count : U32 -> I64
lone_bend_count = |index|
	bend_sightings_on(road_from(index), numbered_segment(road_from(index), 0))
		.len()
		.to_i64_wrap()

# Segment 12 ends at the duck pond, 0 and 4 at an animal and its baby, and 18,
# the road's last, quietly.
expect lone_bend_count(12) == 6
expect lone_bend_count(0) == 2
expect lone_bend_count(4) == 2
expect lone_bend_count(18) == 0
expect {
	first = numbered_segment(six_segments, 0)
	whole = segment_billboards_on(six_segments, first).len().to_i64_wrap()
	whole == farm_at(0) + bend_at(0)
}

## How many critters the segments from `position` to the road's end hold.
count_from : U32 -> I64
count_from = |position|
	List.from_iter(U32.until(position, 6))
		.map(
			|number| {
				in_view = numbered_segment(six_segments, number)
				segment_billboards_on(six_segments, in_view).len().to_i64_wrap()
			},
		)
		.sum()

expect
	BillboardSighting.billboard_fates(first_alone, origin_camera).len()
		== segment_billboards_on(first_alone, numbered_segment(first_alone, 0)).len()
expect BillboardSighting.billboard_fates(
	six_segments,
	origin_camera,
).len().to_i64_wrap() == count_from(0)
expect count_from(0) >= count_from(1)
expect count_from(1) >= count_from(2)
expect {
	{ road_view, in_view } = road_past_segment(4)
	segment_billboards_on(road_view, in_view).len() > 0
}
expect {
	{ road_view, in_view } = road_past_segment(12)
	bend_sightings_on(road_view, in_view).len() == 6
}
expect {
	{ road_view, in_view } = road_past_segment(0)
	fates = farm_sightings_on(road_view, in_view)
	fates.len() > 0 and fates.all(|fate| how_it_went(fate) == BehindCamera)
}
expect {
	{ road_view, in_view } = road_past_segment(0)
	bend_sightings_on(road_view, in_view).len() == 2
}

## A billboard standing on the ground of the first segment, as the rider at its
## start sees it.
critter_fate : {
	along : Along,
	across : Across,
	kind : Billboard,
} -> BillboardSighting.Fate
critter_fate = |{ along, across, kind }| {
	critter = {
		road_point: { along, across },
		lift: Distance.zero,
		kind,
	}
	BillboardSighting.sight_critter(
		road,
		{
			vantage: origin,
			place: Ahead(SegmentPlace.Position.first),
			critter,
		},
	)
}

## A cow 2.5 m to the right of the rider, `forward` metres ahead.
cow_fate : { forward : Distance, height : Distance } -> BillboardSighting.Fate
cow_fate = |{ forward, height }|
	critter_fate({
		along: Along.at(forward),
		across: Across.metres(2.5),
		kind: { emoji: EmojiStills.cow, height, facing: FacesRight },
	})

## Which way a sighting went, whatever it carries.
how_it_went : BillboardSighting.Fate -> [Seen, BehindCamera, TooSmall]
how_it_went = |fate|
	match fate {
		Ok(_) => Seen
		Err(BehindCamera) => BehindCamera
		Err(TooSmall) => TooSmall
	}

# The near plane is 0.4 m, and a cow on it is in view. At the lens's resting
# focal length a 1 m cow is 2 pixels tall about 342.8 m off.
expect
	[
		(-5.0, 1.0, BehindCamera),
		(0.3, 1.0, BehindCamera),
		(0.39, 1.0, BehindCamera),
		(0.4, 1.0, Seen),
		(0.5, 1.0, Seen),
		(300.0, 1.0, Seen),
		(342.0, 1.0, Seen),
		(343.0, 1.0, TooSmall),
		(400.0, 1.0, TooSmall),
		(10.0, 0.0, TooSmall),
		(50.0, 0.9, Seen),
	].all(
		|(forward, height, want)| {
			fate = cow_fate({ forward: Distance.metres(forward), height: Distance.metres(height) })
			how_it_went(fate) == want
		},
	)

near_cow : Pipeline.Sighted(Billboard)
near_cow =
	cow_fate({ forward: Distance.metres(0.5), height: Distance.metres(1.0) })
		?? crash "CrossModuleExpects: a cow 0.5 m ahead is in view"

left_bull : Pipeline.Sighted(Billboard)
left_bull =
	critter_fate({
		along: Along.metres(50.0),
		across: Across.metres(-1.5),
		kind: {
			emoji: EmojiStills.bull,
			height: Distance.metres(1.6),
			facing: FacesLeft,
		},
	})
		?? crash "CrossModuleExpects: a bull 50 m ahead is in view"

expect near_cow.spot.foot().right().to_metres() == 2.5
expect near_cow.spot.foot().forward().to_metres() == 0.5
expect near_cow.kind.height.to_metres() == 1.0
expect left_bull.spot.foot().right().to_metres() == -1.5
expect left_bull.spot.foot().forward().to_metres() == 50.0
expect left_bull.kind.height.to_metres() == 1.6

expect near_cow.kind.emoji == EmojiStills.cow
expect left_bull.kind.emoji == EmojiStills.bull
expect near_cow.kind.facing == FacesRight
expect left_bull.kind.facing == FacesLeft

# RailSighting's run up to a bend and out of it.
rail_point_at : List(Geom.RiderPoint), U64 -> Geom.RiderPoint
rail_point_at = |points, i|
	points.get(i) ?? crash "CrossModuleExpects: an index past the rail's end"

runup_points_to_bend : List(Geom.RiderPoint)
runup_points_to_bend = RailSighting.runup_points(
	road,
	{
		vantage: origin,
		place: Ahead(SegmentPlace.Position.first),
		length: Distance.metres(500.0),
		across: Across.metres(2.0),
	},
)

expect RailSighting.runout_points(
	road,
	{
		vantage: origin,
		place: Ahead(SegmentPlace.Position.first),
		across: Across.metres(2.0),
	},
).len() == 10
expect runup_points_to_bend.len() == 11
expect
	[
		(rail_point_at(runup_points_to_bend, 0).forward.to_metres(), 490.0),
		(rail_point_at(runup_points_to_bend, 10).forward.to_metres(), 500.0),
	].all(|(got, want)| (got - want).abs() <= 0.0001)

# Scene, on the scene from the start of the route.
scene_facts : Scene.RideFacts
scene_facts = {
	speed: VehicleLimits.starting_speed,
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
		facts: { ..scene_facts, speed: metre_a_step },
	},
)

## The depths of `renderings`, in their order.
depths_of : List(Rendered) -> List(Distance)
depths_of = |renderings| renderings.map(|rendering| rendering.depth)

## How far ahead each of `sightings` stands, in their order.
sighted_depths : List(Pipeline.Sighted(kind)) -> List(Distance)
sighted_depths = |sightings| sightings.map(|sighting| sighting.spot.foot().forward())

# Each field holds what its own sighting found, in the sighting's order, each
# thing at its own depth.
expect depths_of(scene.trees) == sighted_depths(TreeSighting.trees_in_view(road, origin_camera))
expect
	depths_of(scene.birds)
		== sighted_depths(EncounterSighting.birds_in_view(road, origin_camera))
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
	scene.truck.map_ok(|truck| truck.depth)
		== TruckSighting.truck_in_view(
			road,
			{
				camera: origin_camera,
				route_position: scene_facts.truck.route_position,
				lit_truck: scene_facts.truck.lit_truck,
			},
		).map_ok(|truck| truck.spot.foot().forward())
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
			1,
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
	truck: Err(NoTruck),
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
		Ok(rendering) => rendering.picture.to_shapes()
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
expect scene.towers.len() <= 2 * RoadAhead.most_segments_ahead.to_u64() + 1

## Whether no rendering in `renderings` is farther than the one before it.
is_far_to_near : List(Rendered) -> Bool
is_far_to_near = |renderings|
	renderings.map2(
		renderings.drop_first(1),
		|before, after| DepthSort.is_farther({ this: after.depth, that: before.depth }),
	)
		.all(|is_out_of_order| !is_out_of_order)

expect is_far_to_near(scene_renderings)
expect is_far_to_near([])

# GroundSighting's road along the first segment, 500 m long: one patch, its
# edges laid in 20 chunks of 25 m.
## A list of patches as a camera the drawing checks read paints them.
patch_shapes : List(Ground.Patch) -> List(Shapes.Shape)
patch_shapes = |patches| patches.keep_oks(|patch| Ground.patch_shape(patch, Pixels.of(500.0)))

## The ground in view from `rider_vantage` on the road ahead of the route's
## first segment. Its first patch is the road along that segment.
patches_seen_from : Geom.Vantage -> List(Ground.Patch)
patches_seen_from = |rider_vantage| GroundSighting.patches_in_view(road, { vantage: rider_vantage })

first_road : Ground.Patch
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
	(corner(first_road.corners, number + 1), corner(first_road.corners, left_index))
}

expect first_road.corners.len() == 42
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
		Ok(paving) =>
			paving.corners.len() == 8
				and paving.corners.any(|point| (point.forward.to_metres() - 460.0).abs() <= 0.0001)
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
}

expect {
	instant = RideInstant.next_or_restart(World.route, done)
	instant.clock.to_f64() == 0.0
		and instant.rider.motorcycle.along.to_metres() == 0.0
		and instant.rider.motorcycle.speed.to_metres_a_step() == 0.3
		and instant.truck.route_position.to_metres() == 500.0
		and instant.rider.eyes.look_depth.to_f64() == 0.0
}

# The gaze is home at each of the ride's crossings, and it did leave home. The
# bike doesn't turn at a seam, and `gaze_yaw` is measured from the bike, so a
# crossing carries the gaze over and it has no need to be reset.
expect {
	var $rider = RiderState.initial
	var $crossings = 0
	var $is_home_at_each = True
	var $has_looked = False
	while !Rider.is_finished($rider, World.route) {
		next = Rider.rider_state_at_next_step($rider, World.route)
		if next.segment_index != $rider.segment_index {
			$crossings = $crossings + 1
			$is_home_at_each = $is_home_at_each and $rider.eyes.gaze_yaw == Angle.straight_ahead
		}
		$has_looked = $has_looked or next.eyes.gaze_yaw != Angle.straight_ahead
		$rider = next
	}
	$crossings == 18 and $is_home_at_each and $has_looked
}

expect Rider.is_finished(done.rider, World.route)
expect RideInstant.next_or_restart(World.route, done).truck.pace == NotSlowing

# A ride that hasn't finished steps on: the clock by a step, the rider and the
# truck forward.
ride_at_step_one : RideInstant
ride_at_step_one = RideInstant.next_or_restart(World.route, RideInstant.initial)

ride_at_step_two : RideInstant
ride_at_step_two = RideInstant.next_or_restart(World.route, ride_at_step_one)

expect !Rider.is_finished(RideInstant.initial.rider, World.route)
expect ride_at_step_one.clock.to_f64() == 1.0
expect ride_at_step_two.clock.to_f64() == 2.0
expect ride_at_step_two.clock.steps_since(ride_at_step_one.clock) == Steps.one_step
expect ride_at_step_one.rider.motorcycle.along > RideInstant.initial.rider.motorcycle.along
expect ride_at_step_one.truck.route_position > RideInstant.initial.truck.route_position
expect ride_at_step_two.rider.motorcycle.along > ride_at_step_one.rider.motorcycle.along
expect ride_at_step_one.clock != Clock.start
expect !Rider.is_finished(ride_at_step_one.rider, World.route)

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
	range_top = Sun.height(hidden_at).plus(Sun.radius)
	first_step_where(|clock| Sun.height(clock).minus(Sun.radius) < range_top)
}

## How many steps before and after the sunset's climax the rider must be on the
## long westward segment: 150, a few hundred metres of road, so the rider sees
## the sun come down onto the range from the straight and watches it start to
## sink. The climax falls 230 steps after the rider turns onto the segment and
## 451 before the next bend, so a change in the ride's timing has room to move
## it before the rule breaks.
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
	var $rider = RiderState.initial
	var $clock = Clock.start
	while $clock != from {
		$rider = Rider.rider_state_at_next_step($rider, World.route)
		$clock = $clock.next()
	}
	var $is_on_long_segment = True
	while $clock != until {
		$is_on_long_segment = $is_on_long_segment and $rider.segment_index == longest_segment_index
		$rider = Rider.rider_state_at_next_step($rider, World.route)
		$clock = $clock.next()
	}
	$is_on_long_segment and $rider.segment_index == longest_segment_index
}

# Steve's rule: the ride reaches full night, past dusk, before it finishes. The
# rule is strict that night comes and loose about when, so it holds no step.
# The sky only darkens as the clock runs, so full dusk at the finish means it
# came at or before it.
expect {
	var $rider = RiderState.initial
	var $clock = Clock.start
	while !Rider.is_finished($rider, World.route) {
		$rider = Rider.rider_state_at_next_step($rider, World.route)
		$clock = $clock.next()
	}
	Sky.dusk_at($clock) == Fraction.whole
}

# A frame of the ride draws.
expect {
	frame = FrameView.frame_view_at(World.route, RideInstant.initial)
	first_shape = frame.shapes.first() ?? crash "CrossModuleExpects: a frame draws"
	coordinates_of(first_shape).len() >= 6
}

# Every bird and emoji still draws all its polygons through StillShapes, so
# Polygon's own checks judge the data. PosedCat's tests draw every cat pose.
expect {
	anchor = {
		feet: Screen.point(100.0, 200.0),
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

expect FrameView.frame_view_at(World.route, ride_at_step_one).shapes.len() > 0

# The ride starts facing away from the sun.
expect FrameView.frame_view_at(World.route, RideInstant.initial).sun_sighting == OutOfView

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
			camera = RiderCamera.of(rider_facing(facing), World.route)
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
## The focal length of the camera for `rider` on the cat route.
focal_of : RiderState -> Pixels
focal_of = |rider| RiderCamera.of(rider, cat_route).cam_focal

## A rider at the start of the first segment, upright and looking ahead.
upright : RiderState
upright = RiderState.initial

## A rider 120 m along a segment: near enough to its cat, if it has one, to
## notice it.
rider_near_cat_on : U32 -> RiderState
rider_near_cat_on = |number| {
	segment_index: Route.SegmentIndex.number(number),
	motorcycle: { ..upright.motorcycle, along: Along.metres(120.0) },
	eyes: upright.eyes,
}

## The same rider leaning `lean`.
leaning = |rider, lean| { ..rider, motorcycle: { ..rider.motorcycle, lean } }

## The same rider as deep into a look as a rider goes.
looking_hard : RiderState -> RiderState
looking_hard = |rider| { ..rider, eyes: { ..rider.eyes, look_depth: Fraction.whole } }

## How strongly the encounter on this rider's segment holds their attention.
encounter_attention_of : RiderState -> F64
encounter_attention_of = |rider|
	EncounterReaction.encounter_attention(
		cat_route.segment_at(rider.segment_index),
		rider.motorcycle,
	).to_f64()

expect focal_of(upright).minus(Lens.resting_focal) == Pixels.zero
expect encounter_attention_of(upright) == 0.0
expect Gaze.gaze_attention(Fraction.zero).to_f64() == 0.0
expect Lens.cam_focal({
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

expect encounter_attention_of(rider_near_cat_on(1)) > 0.0
expect !(encounter_attention_of({ ..upright, segment_index: Route.SegmentIndex.number(1) }) > 0.0)
expect !(encounter_attention_of(rider_near_cat_on(0)) > 0.0)
expect focal_of(rider_near_cat_on(1)) < focal_of(rider_near_cat_on(0))
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
expect Lens.cam_focal({
	lean: Lens.full_lean,
	attention: Attention.none,
}).minus(lean_only) == Pixels.zero

## A clock with the sun behind the mountains.
after_sunset : Clock
after_sunset = Clock.at_step(5700)

## The truck's lights at `clock`, with the truck's pace as given.
lights_at : { clock : Clock, pace : [Slowing, NotSlowing] } -> _
lights_at = |{ clock, pace }|
	FrameView.lit_truck({
		..RideInstant.initial,
		truck: { ..RideInstant.initial.truck, pace },
		clock,
	})

expect lights_at({ clock: Clock.start, pace: NotSlowing }) == { headlights: Off, brake_lights: Off }
expect lights_at({ clock: Clock.start, pace: Slowing }) == { headlights: Off, brake_lights: On }
expect lights_at({ clock: after_sunset, pace: NotSlowing }) == { headlights: On, brake_lights: Off }
expect lights_at({ clock: after_sunset, pace: Slowing }) == { headlights: On, brake_lights: On }

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
	Throttle.next_speed(motorcycle, first_segment)
		.change_from(motorcycle.speed)
		.to_metres_a_step_each_step()
}

# A rider far off to the right, whose coast crosses no shoulder, opens the
# throttle however far they lean. Each is within 1e-12 of its want.
expect [-0.001, -0.035, -0.535].all(|lean| (wide_of_road(lean) - 0.01).abs() <= 0.000000000001)

## The spot on a straight road of a thing 3 m left of the middle and 2 m up,
## `forward` ahead of the camera.
straight_ahead_spot : F64 -> Try(Spot, [BehindCamera])
straight_ahead_spot = |forward|
	Spot.straight_ahead({
		road_point: { along: Along.metres(50.0), across: Across.metres(-3.0) },
		lift: Distance.metres(2.0),
		forward: Distance.metres(forward),
	})

# A spot ahead keeps its road point and lift, sits on the first segment ahead,
# and has its foot as far left of the camera as the thing is of the middle.
expect
	match straight_ahead_spot(20.0) {
		Ok(spot) => {
			foot = spot.foot().at_height(Distance.zero)
			spot.place() == Ahead(SegmentPlace.Position.first)
				and spot.road_point() == { along: Along.metres(50.0), across: Across.metres(-3.0) }
				and spot.lift() == Distance.metres(2.0)
				and foot.right() == Distance.metres(-3.0)
				and foot.forward() == Distance.metres(20.0)
		}
		Err(BehindCamera) => False
	}

# A spot short of the near plane is behind the camera.
expect
	match straight_ahead_spot(0.1) {
		Ok(_) => False
		Err(BehindCamera) => True
	}
