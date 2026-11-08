## EncounterExpects holds the expects of the encounters: the cats and birds,
## their plans and their stills.

import Fixtures
import game.Across
import game.Along
import game.Animation
import game.BirdFlight
import game.BirdStills
import game.Camera
import game.Cat
import game.CatCrossing
import game.Clock
import game.Conifer
import game.Distance
import game.EmojiStills
import game.EncounterPlan
import game.EncounterPoses
import game.EncounterReaction
import game.EncounterSighting
import game.Fraction
import game.RiderView
import game.Pipeline
import game.Pixels
import game.PosedBird
import game.PosedCat
import game.RoadAhead
import game.Route
import game.Screen
import game.Segment
import game.SegmentPlace
import game.Speed
import game.Spot
import game.Steps
import game.Still
import game.StillShapes
import game.Trees
import game.VehicleLimits
import game.World
import lib.ArgbColor
import lib.Brush
import lib.RgbColor
import lib.Shapes

EncounterExpects :: [].{}

## The birds the camera sees on `road_view`, with the encounter on the
## rider's segment at `encounter_timing`.
birds_seen_on : RoadAhead.RoadView,
{
	camera : Pipeline.SightingCamera,
	encounter_timing : EncounterPlan.Timing,
} -> List(Pipeline.Sighted(PosedBird))
birds_seen_on = |road_view, { camera, encounter_timing }|
	EncounterSighting.animals_in_view(
		road_view,
		{ camera, animals: EncounterPoses.bird_poses(road_view, encounter_timing) },
	)

## The cats in view on the cat route, before its encounter is planned, for a
## rider `along` metres into its first segment.
ride_sightings : F64 -> List(Pipeline.Sighted(PosedCat))
ride_sightings = |along| {
	road_view = Fixtures.cat_road
	EncounterSighting.animals_in_view(
		road_view,
		{
			camera: {
				..Fixtures.origin_camera,
				vantage: { ..Fixtures.origin, along: Along.metres(along) },
			},
			animals: EncounterPoses.cat_poses(road_view, Unplanned),
		},
	)
}

# EncounterSighting's birds, on a straight segment with its fifth left tree 100 m along: a bird
# sits, flies and lands as the rider comes, stays where no tree is far enough to
# fly to, and is left out with no tree for it, behind the near plane or too small
# to draw.

left_trees : List(Trees.RoadsideTree)
left_trees = [20.0, 40.0, 60.0, 80.0, 100.0].map(|along| Fixtures.tree_at(along, -6.0))

far_tree : Trees.RoadsideTree
far_tree = { ..Fixtures.tree_at(130.0, 6.0), kind: Conifer.Gold }

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

## The trees of a segment with a bird: five on the left, and one on the far
## side to fly to.
bird_trees : List(Trees.RoadsideTree)
bird_trees = left_trees.append(far_tree)

## The flight of a bird on `bird_trees`, from the fifth left tree to the far
## one.
bird_flight : BirdFlight.Flight
bird_flight = { from: Fixtures.tree_at(100.0, -6.0), to: far_tree }

## A segment of `bird_trees` with its bird.
bird_segment : Segment
bird_segment = { ..Fixtures.segment_of(bird_trees), encounter: BirdHere(bird_flight) }

## A flight that started at step 100, at step `now`.
flight_at_step : U32 -> EncounterPlan.Timing
flight_at_step = |now| EncounterPlan.timing_of(StartsAt(Clock.at_step(100)), Clock.at_step(now))

## The birds on `segment`, alone on its route, for a rider `rider_along` metres
## into it, seen through a focal length of `focal_length`, with the bird's flight
## at `encounter_timing`.
birds_on : Segment,
{
	rider_along : F64,
	focal_length : Pixels,
	encounter_timing : EncounterPlan.Timing,
} -> List(Pipeline.Sighted(PosedBird))
birds_on = |segment, { rider_along, focal_length, encounter_timing }|
	birds_seen_on(
		Fixtures.crafted_road([segment]),
		{
			camera: {
				vantage: { ..Fixtures.origin, along: Along.metres(rider_along) },
				focal_length,
			},
			encounter_timing,
		},
	)

## The one bird that a rider `rider_along` metres in sees, with its flight at
## `encounter_timing`.
bird_at : F64, EncounterPlan.Timing -> Pipeline.Sighted(PosedBird)
bird_at = |rider_along, encounter_timing|
	birds_on(
		bird_segment,
		{ rider_along, focal_length: Pixels.of(500.0), encounter_timing },
	).first()
		?? crash "EncounterExpects: this rider sees a bird"

## How far off a bird is: right of the camera, forward of it, and its lift.
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
bird_count : { rider_along : F64, focal_length : Pixels } -> I64
bird_count = |{ rider_along, focal_length }| {
	birds = birds_on(bird_segment, { rider_along, focal_length, encounter_timing: Unplanned })
	birds.len().to_i64_wrap()
}

## A segment where a cat crosses, with the same trees: it has no bird.
segment_with_cat : Segment
segment_with_cat = {
	..Fixtures.segment_of(bird_trees),
	encounter: World.route.segment_at(Route.SegmentIndex.number(3)).encounter,
}

expect bird_count({ rider_along: 0.0, focal_length: Pixels.of(500.0) }) == 1
expect bird_count({ rider_along: 99.5, focal_length: Pixels.of(500.0) }) == 1
expect bird_count({ rider_along: 99.7, focal_length: Pixels.of(500.0) }) == 0
expect bird_count({ rider_along: 120.0, focal_length: Pixels.of(500.0) }) == 0
expect bird_count({ rider_along: 0.0, focal_length: Pixels.of(91.0) }) == 1
expect bird_count({ rider_along: 0.0, focal_length: Pixels.of(90.0) }) == 0
expect
	birds_seen_on(
		Fixtures.crafted_road([segment_with_cat]),
		{ camera: Fixtures.origin_camera, encounter_timing: Unplanned },
	).len()
		== 0

## The birds on two segments on the road ahead, the rider at the start of the
## first, whose bird is in flight.
birds_on_two_segments : List(Pipeline.Sighted(PosedBird))
birds_on_two_segments = birds_seen_on(
	Fixtures.crafted_road([Fixtures.going_straight_on(bird_segment), bird_segment]),
	{ camera: Fixtures.origin_camera, encounter_timing: flight_at_step(118) },
)

# Only the rider's own segment plays its encounter: the bird ahead still sits.
expect
	match birds_on_two_segments.map(|bird| bird.kind.pose) {
		[near, far] => near != Perched and far == Perched
		_ => crash "EncounterExpects: each of two segments has a bird in view"
	}

# EncounterSighting's cats: which cats are in view as the rider comes on them.

## The first cat in view for a rider `along` metres in.
first_cat : F64 -> Pipeline.Sighted(PosedCat)
first_cat = |along|
	ride_sightings(along).first() ?? crash "EncounterExpects: the second segment's cat is in view"

## How far ahead the first cat in view is for a rider `along` metres in.
cat_forward : F64 -> Distance
cat_forward = |along| first_cat(along).spot.foot().forward()

## How far right of the camera the first cat in view is for a rider `along`
## metres in.
cat_right : F64 -> Distance
cat_right = |along| first_cat(along).spot.foot().right()

# The cat route's one cat is on its second segment.
expect
	EncounterPoses.cat_poses(Fixtures.cat_road, Unplanned).map(|cat| cat.place)
		== [Ahead(Fixtures.second_position)]
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

## How far short of a cat its crossing is planned for the fastest rider.
cat_planning_gap : Distance
cat_planning_gap = EncounterPlan.planning_gap(Cat.crossing_span, VehicleLimits.top_speed)

## How far short of a bird's perch its flight is planned for the fastest rider.
bird_planning_gap : Distance
bird_planning_gap = EncounterPlan.planning_gap(BirdFlight.flight_span, VehicleLimits.top_speed)

expect route_cats.len() == 3
expect route_cats.all(|{ crossing, .. }| cat_planning_gap < crossing.along().from_start())
expect Fixtures.route_flights.len() == 4
expect Fixtures.route_flights.all(
	|{ from, .. }| bird_planning_gap < from.road_point.along.from_start(),
)

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

# Cat: a crossing, frame by frame.
## A cat that crosses from beside a tree 100 m along and 3 m right of the
## middle of a road 2 m either side.
crossing_cat : CatCrossing
crossing_cat = CatCrossing.by_tree({
	tree: { along: Along.metres(100.0), across: Across.metres(3.0) },
})

## The cat `steps_in` steps into its crossing.
crossing_frame_of : U32 -> Animation.Instant(PosedCat.CatPose)
crossing_frame_of = |steps_in| Cat.instant_at(crossing_cat, Playing(Steps.of(steps_in)))

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

## Whether `segment`'s encounter holds back the throttle at step `now`, its
## animation having started at step 100.
is_throttle_held : Segment, U32 -> Bool
is_throttle_held = |segment, now|
	match EncounterReaction.encounter_throttle(segment, flight_at_step(now)) {
		AtMost(_) => True
		NoLimit => False
	}

# The rider eases off for a cat for exactly the steps it crosses, and never for a
# bird.
expect
	[
		(99, False),
		(100, True),
		(137, True),
		(138, False),
	].all(|(now, want)| is_throttle_held(World.first_cat_segment, now) == want)
expect [99, 100, 137, 138].all(|now| !is_throttle_held(bird_segment, now))

# BirdFlight: the tree a bird flies to, and its flight frame by frame.
## The tree a sample bird leaves.
flight_left_tree : Trees.RoadsideTree
flight_left_tree = Fixtures.tree_at(100.0, -6.0)

## A tree on the far side too near to fly to, and two far enough.
flight_sample_trees : List(Trees.RoadsideTree)
flight_sample_trees = [
	flight_left_tree,
	Fixtures.tree_at(100.0, 6.0),
	Fixtures.tree_at(140.0, -6.0),
	Fixtures.tree_at(140.0, 6.0),
	Fixtures.tree_at(180.0, 6.0),
]

## A flight from the left tree to a gold one 40 m on, across the road.
sample_flight : BirdFlight.Flight
sample_flight = {
	from: flight_left_tree,
	to: { ..Fixtures.tree_at(140.0, 6.0), kind: Conifer.Gold },
}

## Where the tree a bird on the left tree flies to stands, among `choices`.
chosen_tree_numbers : List(Trees.RoadsideTree) -> List(F64)
chosen_tree_numbers = |choices|
	match BirdFlight.flight_from(choices, flight_left_tree) {
		Ok({ to, .. }) => [to.road_point.along.to_metres(), to.road_point.across.to_metres()]
		Err(NoTreeToFlyTo) => []
	}

expect chosen_tree_numbers(flight_sample_trees) == [140.0, 6.0]
expect chosen_tree_numbers([flight_left_tree, Fixtures.tree_at(124.0, 6.0)]) == []
expect chosen_tree_numbers([flight_left_tree, Fixtures.tree_at(125.0, 6.0)]) == [125.0, 6.0]
expect chosen_tree_numbers([flight_left_tree, Fixtures.tree_at(140.0, -6.0)]) == []

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
		RiderView.rider_point_ahead({ right, forward })
			?? crash "EncounterExpects: a test's animal is past the near plane"
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
		focal_length: Pixels.of(500.0),
		context: {},
	}).to_shapes()

## The first corner `cat` draws, `lift` off the ground: its still's first
## corner's coordinates, on screen.
first_cat_corner_coordinates : PosedCat, Distance -> List(F64)
first_cat_corner_coordinates = |cat, lift|
	match sample_cat_shapes(cat, lift) {
		[Poly(polygon), ..] => polygon.coordinates.take_first(2)
		_ => crash "EncounterExpects: a cat draws polygons"
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
	bird.scenery_picture({ spot, focal_length: Pixels.of(500.0), context: {} }).to_shapes()
}

## How many pixels tall a perched bird `forward` ahead, on the ground, is
## through `focal_length`.
bird_height_on_screen : Distance, Pixels -> F64
bird_height_on_screen = |forward, focal_length| {
	spot = posed_spot_at({ forward, right: Distance.zero, lift: Distance.zero })
	bird : PosedBird
	bird = { pose: Perched }
	anchor = StillShapes.standing_anchor(
		{ spot, focal_length, context: {} },
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
			_ => crash "EncounterExpects: a bird draws polygons"
		}
	raised = { right: Distance.metres(11.0), lift: Camera.eye_height.plus(Distance.metres(11.0)) }
	[
		({ right: Distance.metres(0.0), lift: Camera.eye_height }, [479.656, 294.285]),
		(raised, [529.656, 244.285]),
	].all(|(perch, want)| is_near_each(first_corner(perch), want))
}

# Each still's polygons, in their colors, as a bird in each pose draws them.
expect {
	fill_of = |shape|
		match shape {
			Poly(polygon) => polygon.fill
			_ => crash "EncounterExpects: a bird's still is polygons"
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
					Shaded(_) => crash "EncounterExpects: a bird's still is flat"
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

## A still 50 pixels tall, standing as drawn on a foot at (100, 200).
upright_still_anchor : StillShapes.Anchor
upright_still_anchor = {
	foot: Screen.point(100.0, 200.0),
	flip: AsDrawn,
	height_on_screen: Pixels.of(50.0),
}

# A still of one flat polygon of color 7, a corner at the foot, is drawn as one
# opaque polygon there.
expect {
	corners = [{ x: 0.0, y: 0.0 }, { x: 1.0, y: 0.0 }, { x: 0.0, y: 1.0 }]
	still = Still.of([{ fill: Flat(RgbColor.of(7)), points: corners }])
	StillShapes.still_shapes(upright_still_anchor, still)
		== [
			Poly({
				coordinates: [100.0, 200.0, 150.0, 200.0, 100.0, 150.0],
				fill: Flat(Brush.opaque_rgba(RgbColor.of(7))),
			}),
		]
}

## Color stops with an alpha byte and offsets inside 0 to 1, as a still holds
## them.
still_stops : Still.ColorStops
still_stops = {
	start_color: ArgbColor.of(0x80FFE9A8),
	end_color: ArgbColor.of(0xFF000000),
	start_offset: Fraction.of(0.25),
	end_offset: Fraction.of(0.75),
}

## The same stops as a brush takes them.
brush_stops : Brush.TwoStops
brush_stops = {
	start_color: Brush.translucent(ArgbColor.of(0x80FFE9A8)),
	end_color: Brush.translucent(ArgbColor.of(0xFF000000)),
	start_offset: 0.25,
	end_offset: 0.75,
}

# A radial gradient whose axes span Still's least area, in a still drawn at
# Pipeline's smallest height, is one Brush can just invert, and one a little
# thinner is not.
expect {
	height = Pipeline.smallest_height_on_screen.to_f64()
	ellipse_spanning = |area|
		Brush.ellipse({
			stops: brush_stops,
			center: { x: 0.0, y: 0.0 },
			axis_u: { x: area * height, y: 0.0 },
			axis_v: { x: 0.0, y: height },
		})
	least = Still.min_axes_area
	ellipse_spanning(least).is_ok() and ellipse_spanning(least * 0.99).is_err()
}

## Three corners of a still, at the foot and up the still's middle.
still_corners : List(Still.FramePoint)
still_corners = [{ x: 0.0, y: 0.0 }, { x: 0.5, y: 0.0 }, { x: 0.0, y: 1.0 }]

## The shapes of a still of one polygon, on `still_corners`, filled by
## `gradient`.
shaded_still_shapes : Still.Gradient -> List(Shapes.Shape)
shaded_still_shapes = |gradient|
	StillShapes.still_shapes(
		upright_still_anchor,
		Still.of([{ fill: Shaded(gradient), points: still_corners }]),
	)

## Where `still_corners` land on screen.
still_corner_coordinates : List(F64)
still_corner_coordinates = [100.0, 200.0, 125.0, 200.0, 100.0, 150.0]

# A linear gradient keeps its stops' alphas and offsets, and runs between its
# two points on screen.
expect {
	gradient = Linear({
		stops: still_stops,
		start: { x: 0.0, y: 0.0 },
		end: { x: 0.0, y: 1.0 },
	})
	fill = Linear({
		stops: brush_stops,
		start_point: { x: 100.0, y: 200.0 },
		end_point: { x: 100.0, y: 150.0 },
	})
	shaded_still_shapes(gradient) == [Poly({ coordinates: still_corner_coordinates, fill })]
}

# A radial gradient keeps its stops the same way, its axes as steps on screen.
expect {
	gradient = Radial({
		stops: still_stops,
		center: { x: 0.0, y: 0.5 },
		axis_u: { x: 0.5, y: 0.0 },
		axis_v: { x: 0.0, y: 0.5 },
	})
	fill = Ellipse({
		stops: brush_stops,
		center: { x: 100.0, y: 175.0 },
		axis_u: { x: 25.0, y: 0.0 },
		axis_v: { x: 0.0, y: -25.0 },
	})
	shaded_still_shapes(gradient) == [Poly({ coordinates: still_corner_coordinates, fill })]
}
