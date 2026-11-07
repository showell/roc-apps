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
import game.BendView
import game.Billboard
import game.BirdFlight
import game.Cat
import game.CatCrossing
import game.Clock
import game.Conifer
import game.EncounterSighting
import game.BillboardSighting
import game.DepthSort
import game.Distance
import game.EmojiStills
import game.Fraction
import game.FrameView
import game.RoadAhead
import game.Route
import game.Segment
import game.SegmentPlace
import game.Geom
import game.Mountains
import game.Ground
import game.GroundSighting
import game.Pipeline
import game.PosedBird
import game.PosedCat
import game.RailSighting
import game.Rendered
import game.Scene
import game.SceneShapes
import game.RideInstant
import game.Rider
import game.RiderCamera
import game.RiderState
import game.Screen
import game.Sky
import game.Speed
import game.Steps
import game.StillShapes
import game.Sun
import game.TreeSighting
import game.Trees
import game.Truck
import game.TruckSighting
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
				JustBehind(_) => True
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

## The point 50 m along and 1 m right on the segment at `place` on the road
## ahead of a rider on the route's first segment, as `turned_vantage` sees it.
turned_point_at : SegmentPlace -> Geom.RiderPoint
turned_point_at = |place|
	RoadAhead.rider_point_at(
		road,
		{
			vantage: turned_vantage,
			place,
			road_point: { along: Along.metres(50.0), across: Across.metres(1.0) },
		},
	)

expect {
	at_d0 = turned_point_at(Ahead(SegmentPlace.Position.first))
	second_segment_point = turned_point_at(Ahead(SegmentPlace.Position.number(1)))
	[
		(at_d0.right.to_metres(), 9.933466539753061),
		(at_d0.forward.to_metres(), -49.00332889206208),
		(second_segment_point.right.to_metres(), -48.11621135085446),
		(second_segment_point.forward.to_metres(), 431.95658232777186),
	].all(|(got, want)| (got - want).abs() <= 0.00000005 * want.abs().max(1.0))
}

m_prev_left : SegmentPlace
m_prev_left = JustBehind({
	segment_length: Distance.metres(300.0),
	turn: Angle.Turn.radians(-1.2217304763960306),
})

m_prev_right : SegmentPlace
m_prev_right = JustBehind({
	segment_length: Distance.metres(300.0),
	turn: Angle.Turn.radians(0.8726646259971648),
})

expect
	[
		(turned_point_at(m_prev_left).right.to_metres(), -194.76069932822074),
		(turned_point_at(m_prev_left).forward.to_metres(), -231.63435691739767),
		(turned_point_at(m_prev_right).right.to_metres(), 239.9883995667414),
		(turned_point_at(m_prev_right).forward.to_metres(), -218.13274420105967),
	].all(|(got, want)| (got - want).abs() <= 0.0000001 * want.abs().max(1.0))

## The apex of a bend from a segment 300 m long, just behind the rider's.
apex_after_turn : Angle.Turn -> Geom.RiderPoint
apex_after_turn = |turn|
	BendView.apex(
		road,
		{
			vantage: turned_vantage,
			bend_view: {
				before: JustBehind({ segment_length: Distance.metres(300.0), turn }),
				bend: { segment_length: Distance.metres(300.0), turn },
			},
		},
	)

# Each is within 1e-7 of its want, scaled up by a want past 1.
expect
	[
		(
			apex_after_turn(Angle.Turn.radians(0.8726646259971648)).right.to_metres(),
			17.297297467543466,
		),
		(
			apex_after_turn(Angle.Turn.radians(0.8726646259971648)).forward.to_metres(),
			-100.43071597950589,
		),
		(
			apex_after_turn(Angle.Turn.radians(-1.2217304763960306)).right.to_metres(),
			21.403438709482494,
		),
		(
			apex_after_turn(Angle.Turn.radians(-1.2217304763960306)).forward.to_metres(),
			-100.55298847633645,
		),
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
	segment_behind_rider = {
		..segment_of([tree_at(195.0, 0.0)]),
		ending: Bends({ turn: Angle.Turn.degrees(degrees), bend_life: Animal(Elephant) }),
		encounter: QuietRoad,
	}
	rider_segment = { ..segment_of([]), encounter: QuietRoad }
	TreeSighting.trees_in_view(
		RoadAhead.RoadView.ahead_of(
			Route.from_segments([segment_behind_rider, rider_segment]),
			Route.SegmentIndex.number(1),
		),
		origin_camera,
	)
}

## Whether `trees` is one tree, sighted on the segment just behind the rider.
is_one_tree_behind : List(Pipeline.Sighted(Conifer)) -> Bool
is_one_tree_behind = |trees|
	match trees.map(|tree| tree.spot.place()) {
		[JustBehind(_)] => True
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

expect cat_route.route_segments().map(has_cat) == [False, True, False]

## Whether a segment has a cat waiting by the road.
has_cat : Segment -> Bool
has_cat = |seg|
	match seg.encounter {
		CatCrosses(_) => True
		BirdHere(_) | QuietRoad => False
	}

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

## The speed a rider leaves `segment` at: the bend's, or none at the route's end.
leaving_speed : Segment -> Speed
leaving_speed = |segment|
	match segment.ending {
		Bends({ turn, .. }) => VehicleLimits.turn_speed(turn.abs())
		RouteEnds => Speed.at_rest
	}

# The reaction ends with its segment, so the cat's hold has to have faded by then
# or it would snap to nothing there. Braking for the bend only hurries the fade.
expect
	route_cats.all(
		|{ segment, crossing }| {
			gap = crossing.along.distance_from(Along.at(segment.length))
			Cat.attention({ gap, speed: leaving_speed(segment) }).to_f64() == 0.0
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
segment_sightings_on : RoadAhead.RoadView, RoadAhead.SegmentInView -> List(BillboardSighting.Fate)
segment_sightings_on = |road_view, in_view|
	BillboardSighting.segment_sightings(road_view, { vantage: origin, in_view })

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

## The world's segment `number`, as the segment just behind the rider.
segment_behind : U32 -> RoadAhead.SegmentInView
segment_behind = |number| {
	segment = World.route.segment_at(Route.SegmentIndex.number(number))
	{
		index: Route.SegmentIndex.number(number),
		segment,
		place: RoadAhead.place_behind(segment),
	}
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
	whole = segment_sightings_on(six_segments, first).len().to_i64_wrap()
	whole == farm_at(0) + bend_at(0)
}

## How many critters the segments from `position` to the road's end hold.
count_from : U32 -> I64
count_from = |position|
	List.from_iter(U32.until(position, 6))
		.map(
			|number| {
				in_view = numbered_segment(six_segments, number)
				segment_sightings_on(six_segments, in_view).len().to_i64_wrap()
			},
		)
		.sum()

expect
	BillboardSighting.billboard_fates(first_alone, origin_camera).len()
		== segment_sightings_on(first_alone, numbered_segment(first_alone, 0)).len()
expect BillboardSighting.billboard_fates(
	six_segments,
	origin_camera,
).len().to_i64_wrap() == count_from(0)
expect count_from(0) >= count_from(1)
expect count_from(1) >= count_from(2)
expect segment_sightings_on(six_segments, segment_behind(4)).len() > 0
expect bend_sightings_on(six_segments, segment_behind(12)).len() == 6
expect {
	fates = farm_sightings_on(six_segments, segment_behind(0))
	fates.len() > 0 and fates.all(|fate| how_it_went(fate) == BehindCamera)
}
expect bend_sightings_on(six_segments, segment_behind(0)).len() == 2

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
		kind: { still: EmojiStills.cow, height, facing: FacesRight },
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
			still: EmojiStills.bull,
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

expect near_cow.kind.still == EmojiStills.cow
expect left_bull.kind.still == EmojiStills.bull
expect near_cow.kind.facing == FacesRight
expect left_bull.kind.facing == FacesLeft

expect BillboardSighting.min_critter_px.to_f64() == 2.0

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

expect RailSighting.run_out_points(
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
scene_view : { road : RoadAhead.RoadView, camera : { vantage : Geom.Vantage, cam_focal : Pixels } }
scene_view = { road, camera: origin_camera }

scene : Scene
scene = Scene.scene_in_view(
	road,
	{
		camera: origin_camera,
		facts: {
			speed: VehicleLimits.starting_speed,
			truck: {
				route_position: Distance.metres(500.0),
				lit_truck: { headlights: Off, brake_lights: Off },
			},
			clock: Clock.start,
		},
	},
)

scene_renderings : List(Rendered)
scene_renderings = SceneShapes.scene_renderings(scene, scene_view)

## A scene with nothing in view.
empty_scene : Scene
empty_scene = {
	trees: [],
	towers: [],
	billboards: [],
	cats: [],
	rails: [],
	truck: Err(NoTruck),
	birds: [],
}

## How many renderings `only` has, seen as `scene` is.
rendering_count : Scene -> U64
rendering_count = |only| SceneShapes.scene_renderings(only, scene_view).len()

# Each kind of thing in view has its rendering, one kind at a time, and a scene
# with nothing in view has none. The route's start has no cat in view, so the
# cats come from the second segment's.
expect rendering_count({ ..empty_scene, trees: scene.trees }) == scene.trees.len()
expect rendering_count({ ..empty_scene, towers: scene.towers }) == scene.towers.len()
expect rendering_count({ ..empty_scene, billboards: scene.billboards }) == scene.billboards.len()
expect rendering_count({ ..empty_scene, cats: seen }) == seen.len()
expect rendering_count({ ..empty_scene, rails: scene.rails }) == scene.rails.len()
expect rendering_count({ ..empty_scene, birds: scene.birds }) == scene.birds.len()
expect rendering_count({ ..empty_scene, truck: scene.truck }) == 1
expect rendering_count(empty_scene) == 0

# A truck in view stands at its own depth, and one that isn't in view isn't drawn.
expect {
	truck_only = { ..empty_scene, truck: scene.truck }
	truck_renderings = SceneShapes.scene_renderings(truck_only, scene_view)
	truck_depths = truck_renderings.map(|rendering| rendering.depth)
	scene.truck.map_ok(|truck| [truck.spot.foot().forward()]) == Ok(truck_depths)
}
expect scene.birds.len() > 0
expect rendering_count({ ..empty_scene, truck: Err(BehindCamera) }) == 0

expect
	scene_renderings.len()
		== [
			scene.trees.len(),
			scene.towers.len(),
			scene.billboards.len(),
			scene.cats.len(),
			1,
			scene.rails.len(),
			scene.birds.len(),
		].sum()

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

first_road : Ground.Patch
first_road = GroundSighting.road_along(
	road,
	{ vantage: origin, in_view: numbered_segment(road, 0) },
)

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
expect patch_shapes([
	GroundSighting.road_along(
		road,
		{ vantage: { ..origin, along: Along.metres(5000.0) }, in_view: numbered_segment(road, 0) },
	),
]).len() == 0
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
			heading: Angle.Bearing.radians(0.0),
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
	turns_before =
		World.route.route_segments()
			.take_first(longest_segment_index.count_before())
			.map(|segment| segment.bend_out_of().turn)
	bearing = turns_before.fold(Angle.north, |so_far, turn| so_far.plus(turn))
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
	].map(PosedBird.pose_polygons)
	emoji_stills = [
		EmojiStills.duck,
		EmojiStills.elephant,
		EmojiStills.giraffe,
		EmojiStills.zebra,
		EmojiStills.rhino,
		EmojiStills.bull,
		EmojiStills.cow,
		EmojiStills.pig,
	].map(|emoji| emoji.polygons())
	bird_stills.concat(emoji_stills).all(
		|still| StillShapes.still_shapes(anchor, still).len() == still.polygons().len(),
	)
}

expect FrameView.frame_view_at(World.route, ride_at_step_one).shapes.len() > 0

# The ride starts facing away from the sun.
expect FrameView.frame_view_at(World.route, RideInstant.initial).sun_sighting == OutOfView

## A rider on `heading`, leaning `lean` and looking `gaze_yaw` from the way the
## motorcycle points.
rider_facing : {
	heading : Angle.Bearing,
	lean : Angle.Lean,
	gaze_yaw : Angle.Turn,
} -> RiderState
rider_facing = |{ heading, lean, gaze_yaw }| {
	..RiderState.initial,
	motorcycle: { ..RiderState.initial.motorcycle, heading, lean },
	eyes: { ..RiderState.initial.eyes, gaze_yaw },
}

# The camera's heading is the motorcycle's, turned by the gaze and the lean.
expect
	[
		(
			{
				heading: Angle.Bearing.radians(0.0),
				lean: Angle.Lean.radians(0.0),
				gaze_yaw: Angle.Turn.radians(0.0),
			},
			0.0,
		),
		(
			{
				heading: Angle.Bearing.radians(4.5),
				lean: Angle.Lean.radians(0.125),
				gaze_yaw: Angle.Turn.radians(0.375),
			},
			4.89375,
		),
		(
			{
				heading: Angle.Bearing.radians(1.0),
				lean: Angle.Lean.radians(0.5),
				gaze_yaw: Angle.Turn.radians(-0.25),
			},
			0.825,
		),
		(
			{
				heading: Angle.Bearing.radians(-2.0),
				lean: Angle.Lean.radians(-0.75),
				gaze_yaw: Angle.Turn.radians(0.125),
			},
			-1.9875,
		),
		(
			{
				heading: Angle.Bearing.radians(0.5),
				lean: Angle.Lean.radians(1.25),
				gaze_yaw: Angle.Turn.radians(0.0),
			},
			0.6875,
		),
	].all(
		|(facing, heading)| {
			camera = RiderCamera.of(rider_facing(facing), World.route)
			camera.heading.to_radians() == heading
		},
	)

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
