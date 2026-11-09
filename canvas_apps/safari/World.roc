## The ride's world is its route, planned as a list of segments. Each plan says
## how long its segment is, what grows and grazes along it, what the rider meets
## on it, and how it turns into the next. The route makes some choices across
## its segments, such as which herds are big and which the rider finds
## distracting, and this module resolves them before each segment is built.
##
## The world is built once and never changes during the ride. It holds these.
## The route is a list of segments, each known by its place in the list, a
## `Route.SegmentIndex` counted from 0; `World.route` builds it from
## `World.segment_plans`, and `Route.from_segments` checks that every segment
## but the last bends.
## A segment's trees are a list, each tree known by where it stands on its
## segment, along and across the road; `Trees.roadside_trees` plants them from
## the segment's scheme and length.
## A segment has at most one herd of pigs, whose shape and whether it distracts
## the rider `built_segment` chooses here, and one herd of cows, led by a bull or
## not; each animal's place is worked out from its herd when it is asked for
## (`Segment.segment_pigs`, `Segment.segment_cows`), not kept.
## A segment has one encounter, a cat crossing, a bird's flight or a quiet road,
## and `Segment.from_choices` places the cat by one of its trees and the bird on
## another.
## A segment ends by bending into the next, with its turn and what lives at the
## bend (an animal and its baby, a pond with its ducks, or nothing), or by ending
## the route; a pond is known by the segment whose bend it lies at, and its
## ducks, like the animal, are placed from that bend.
## Towers aren't kept at all: each follows from its segment, one past the end of
## every segment and one halfway along a segment longer than a kilometre, so a
## tower is known by its segment and its place on it, a `Beacon.TowerKey`.
import Angle
import BirdFlight
import CatCrossing
import CowHerd
import Distance
import PigHerd
import RoadAhead
import Route
import Segment
import Trees

World :: [].{

	## Whether the route plans pigs along a segment.
	PigPresence : [WithPigs, NoPigs]

	## One segment of the route as planned: its length and scenery, and what
	## lives along it.
	SegmentPlan : {
		length : Distance,
		scheme : Trees.Scheme,
		encounter : Segment.PlannedEncounter,
		pigs : World.PigPresence,
		bull : CowHerd.Bull,
	}

	## A segment the route plans to bend into the next: the segment's own plan,
	## its turn into the next (right is positive), and what lives at the bend.
	BendingPlan : {
		segment_plan : World.SegmentPlan,
		turn : Angle.Turn,
		bend_life : Segment.BendLife,
	}

	## Every segment of the route but the last, in order, each with its bend.
	bending_plans : List(World.BendingPlan)
	bending_plans = [
		{
			segment_plan: {
				length: Distance.metres(500.0),
				scheme: AllGreen,
				encounter: BirdHere,
				pigs: NoPigs,
				bull: NoBull,
			},
			turn: Angle.Turn.degrees(50.0),
			bend_life: Animal(Elephant),
		},
		{
			segment_plan: {
				length: Distance.metres(320.0),
				scheme: AllGreen,
				encounter: QuietRoad,
				pigs: NoPigs,
				bull: NoBull,
			},
			turn: Angle.Turn.degrees(-70.0),
			bend_life: Animal(Elephant),
		},
		{
			segment_plan: {
				length: Distance.metres(400.0),
				scheme: AllGreen,
				encounter: BirdHere,
				pigs: WithPigs,
				bull: NoBull,
			},
			turn: Angle.Turn.degrees(20.0),
			bend_life: Animal(Elephant),
		},
		{
			segment_plan: {
				length: Distance.metres(300.0),
				scheme: GoldGreen,
				encounter: CatCrosses,
				pigs: NoPigs,
				bull: NoBull,
			},
			turn: Angle.Turn.degrees(20.0),
			bend_life: Animal(Elephant),
		},
		{
			segment_plan: {
				length: Distance.metres(300.0),
				scheme: AllGreen,
				encounter: QuietRoad,
				pigs: NoPigs,
				bull: WithBull,
			},
			turn: Angle.Turn.degrees(-70.0),
			bend_life: Animal(Giraffe),
		},
		{
			segment_plan: {
				length: Distance.metres(300.0),
				scheme: AllGreen,
				encounter: BirdHere,
				pigs: NoPigs,
				bull: WithBull,
			},
			turn: Angle.Turn.degrees(-70.0),
			bend_life: Animal(Elephant),
		},
		{
			segment_plan: {
				length: Distance.metres(1200.0),
				scheme: RedGreen,
				encounter: QuietRoad,
				pigs: NoPigs,
				bull: WithBull,
			},
			turn: Angle.Turn.degrees(80.0),
			bend_life: Animal(Rhino),
		},
		{
			segment_plan: {
				length: Distance.metres(300.0),
				scheme: AllGreen,
				encounter: QuietRoad,
				pigs: NoPigs,
				bull: WithBull,
			},
			turn: Angle.Turn.degrees(15.0),
			bend_life: Animal(Elephant),
		},
		{
			segment_plan: {
				length: Distance.metres(300.0),
				scheme: AllGreen,
				encounter: QuietRoad,
				pigs: NoPigs,
				bull: WithBull,
			},
			turn: Angle.Turn.degrees(-70.0),
			bend_life: Animal(Elephant),
		},
		{
			segment_plan: {
				length: Distance.metres(800.0),
				scheme: AllGreen,
				encounter: CatCrosses,
				pigs: NoPigs,
				bull: WithBull,
			},
			turn: Angle.Turn.degrees(15.0),
			bend_life: Animal(Elephant),
		},
		{
			segment_plan: {
				length: Distance.metres(300.0),
				scheme: AllGreen,
				encounter: QuietRoad,
				pigs: WithPigs,
				bull: WithBull,
			},
			turn: Angle.Turn.degrees(15.0),
			bend_life: Animal(Elephant),
		},
		{
			segment_plan: {
				length: Distance.metres(300.0),
				scheme: AllGreen,
				encounter: QuietRoad,
				pigs: WithPigs,
				bull: WithBull,
			},
			turn: Angle.Turn.degrees(15.0),
			bend_life: Animal(Elephant),
		},
		{
			segment_plan: {
				length: Distance.metres(300.0),
				scheme: RedGreen,
				encounter: QuietRoad,
				pigs: WithPigs,
				bull: WithBull,
			},
			turn: Angle.Turn.degrees(15.0),
			bend_life: DuckPond,
		},
		{
			segment_plan: {
				length: Distance.metres(400.0),
				scheme: AllGreen,
				encounter: QuietRoad,
				pigs: WithPigs,
				bull: WithBull,
			},
			turn: Angle.Turn.degrees(-50.0),
			bend_life: Animal(Elephant),
		},
		{
			segment_plan: {
				length: Distance.metres(300.0),
				scheme: AllGreen,
				encounter: BirdHere,
				pigs: WithPigs,
				bull: WithBull,
			},
			turn: Angle.Turn.degrees(50.0),
			bend_life: Animal(Elephant),
		},
		{
			segment_plan: {
				length: Distance.metres(300.0),
				scheme: RedGreen,
				encounter: QuietRoad,
				pigs: NoPigs,
				bull: WithBull,
			},
			turn: Angle.Turn.degrees(-50.0),
			bend_life: Animal(Zebra),
		},
		{
			segment_plan: {
				length: Distance.metres(300.0),
				scheme: AllGreen,
				encounter: QuietRoad,
				pigs: WithPigs,
				bull: WithBull,
			},
			turn: Angle.Turn.degrees(50.0),
			bend_life: Animal(Elephant),
		},
		{
			segment_plan: {
				length: Distance.metres(300.0),
				scheme: AllGreen,
				encounter: QuietRoad,
				pigs: WithPigs,
				bull: WithBull,
			},
			turn: Angle.Turn.degrees(-50.0),
			bend_life: Animal(Elephant),
		},
	]

	## Every segment's plan, in order.
	segment_plans : List(World.SegmentPlan)
	segment_plans = bending_plans.map(|bending| bending.segment_plan).append(last_plan)

	## The route, built from its plans. Each segment but the last bends as its
	## plan says, and the last ends the route.
	route : Route
	route = {
		bending_segments = bending_plans.map_with_index(
			|{ segment_plan, turn, bend_life }, at| {
				index = Route.SegmentIndex.from_count_before(at)
				built_segment(segment_plan, { index, ending: Bends({ turn, bend_life }) })
			},
		)
		last_index = Route.SegmentIndex.from_count_before(bending_plans.len())
		last_segment = built_segment(last_plan, { index: last_index, ending: RouteEnds })
		Route.from_segments(bending_segments.append(last_segment))
	}

	## The road ahead of a rider on the route's first segment. What stands on
	## that segment has no bend between it and the rider.
	road_at_start : RoadAhead.RoadView
	road_at_start = RoadAhead.RoadView.ahead_of(World.route, Route.SegmentIndex.first)

	## The route's first segment with a cat.
	first_cat_segment : Segment
	first_cat_segment =
		World.route.route_segments().find_first(
			|segment|
				match segment.encounter {
					CatCrosses(_) => True
					BirdHere(_) | QuietRoad => False
				},
		)
			?? crash "World.first_cat_segment: the route has a cat"

	## The cat crossing on the route's first segment with a cat.
	first_cat_crossing : CatCrossing
	first_cat_crossing =
		match World.first_cat_segment.encounter {
			CatCrosses(crossing) => crossing
			BirdHere(_) | QuietRoad => crash "World.first_cat_crossing: the first cat segment has a cat"
		}

	## The bird's flight on the route's first segment with a bird.
	first_bird_flight : BirdFlight
	first_bird_flight =
		match first_bird_segment.encounter {
			BirdHere(flight) => flight
			CatCrosses(_) | QuietRoad => crash "World.first_bird_flight: the first bird segment has a bird"
		}

	## The route's first segment whose pigs draw the rider's eye.
	first_distracting_segment : Segment
	first_distracting_segment =
		World.route.route_segments().find_first(Segment.has_distracting_pigs)
			?? crash "World.first_distracting_segment: the route has a distracting herd"
}

## The route's last segment, which ends it.
last_plan : World.SegmentPlan
last_plan = {
	length: Distance.metres(300.0),
	scheme: RedGreen,
	encounter: CatCrosses,
	pigs: WithPigs,
	bull: WithBull,
}

## The route's first segment with a bird.
first_bird_segment : Segment
first_bird_segment =
	World.route.route_segments().find_first(
		|segment|
			match segment.encounter {
				BirdHere(_) => True
				CatCrosses(_) | QuietRoad => False
			},
	)
		?? crash "World.first_bird_segment: the route has a bird"

## The segment at `index` of the route, built from its plan once the route's
## choices for it are made: the shape of its herd and whether the rider finds it
## distracting, both from how many herds come before it, and how it ends, from
## its place in the route.
built_segment : World.SegmentPlan,
{
	index : Route.SegmentIndex,
	ending : Segment.Ending,
} -> Segment
built_segment = |plan, { index, ending }| {
	earlier_herd_count = herd_count_before(index)
	pigs =
		match plan.pigs {
			WithPigs => {
				herd =
					if earlier_herd_count < big_herd_count {
						PigHerd.BigHerd(big_pig_herd)
					} else {
						PigHerd.TwoRows
					}
				interest =
					if earlier_herd_count < pig_novelty_count {
						Distracting
					} else {
						Unnoticed
					}
				Herd({ herd, interest })
			}
			NoPigs => NoPigs
		}
	Segment.from_choices({
		length: plan.length,
		scheme: plan.scheme,
		pigs,
		cows: { herd: cow_herd, bull: plan.bull },
		encounter: plan.encounter,
		ending,
	})
}

## How many of the route's herds, from its first, are big. The rest stand in
## two rows.
big_herd_count : U64
big_herd_count = 2

## How many of the route's herds, from its first, the rider finds distracting.
## The rider passes the rest by.
pig_novelty_count : U64
pig_novelty_count = 2

## The route's big herd, seven rows of seven. The third pig of the front row
## stands out.
big_pig_herd : PigHerd.BigPigHerd
big_pig_herd = {
	columns_before_standout: 2,
	columns_after_standout: 4,
	rows_behind_front: 6,
}

## The route's cow herd, fourteen cows in columns of three.
cow_herd : CowHerd
cow_herd = CowHerd.herd({ cow_count: 14, rows_behind_front: 2 })

## How many of the segments before `index` have pigs.
herd_count_before : Route.SegmentIndex -> U64
herd_count_before = |index|
	World.segment_plans
		.take_first(index.count_before())
		.count_if(|plan| plan.pigs == WithPigs)

route_segment_at : U32 -> Segment
route_segment_at = |i| World.route.segment_at(Route.SegmentIndex.number(i))

expect
	[
		(0, False),
		(17, False),
		(18, True),
	].all(|(index, want)| is_last_segment(route_segment_at(index)) == want)

# The rider commits to the route's end at the end of its last segment.
expect route_segment_at(18).commit_along().to_metres() == 300.0

expect
	[
		(route_segment_at(0).commit_along().to_metres(), 498.32180073764545),
		(route_segment_at(1).commit_along().to_metres(), 319.2720595314676),
		(route_segment_at(6).commit_along().to_metres(), 1199.647346038583),
	].all(|(got, want)| (got - want).abs() <= 0.00000001)

# Each cat crosses by a tree that is really there.
expect
	[3, 9, 18].all(
		|index| {
			cat_tree = crossing_at(index).tree()
			route_segment_at(index).trees.any(|tree| tree.road_point == cat_tree)
		},
	)

# Every segment is longer than zero. Route.segments_with_ends and each bend's geometry
# measure from it.
expect World.segment_plans.all(|plan| plan.length > Distance.zero)

# Every bend really turns the road off its line. BendInView.outer_corner crashes on
# a bend that turns 0 or 180 degrees.
expect World.bending_plans.all(|{ turn, .. }| !turn.is_straight_or_back())

# Each encounter's animal waits before its segment's commit_along, because
# EncounterPlan.plan_at_next_step forgets the plan once the rider leaves the segment.
expect
	World.route.route_segments().all(
		|segment|
			match segment.encounter.encounter_span() {
				Ok({ planned_along, .. }) => planned_along < segment.commit_along()
				Err(QuietRoad) => True
			},
	)

# Every pig and cow stands on its own segment, between its start and its length, where
# Segment's pig_distance_before_end and cow_herd_along mean to place the herds.
expect
	World.route.route_segments().all(
		|segment| {
			is_on_segment = |placed| {
				along = placed.road_point.along.from_start()
				along >= Distance.zero and along <= segment.length
			}
			segment.segment_pigs().all(is_on_segment) and segment.segment_cows().all(is_on_segment)
		},
	)

## Whether `segment` ends the route.
is_last_segment : Segment -> Bool
is_last_segment = |segment|
	match segment.ending {
		Bends(_) => False
		RouteEnds => True
	}

## The cat crossing at a segment that has one.
crossing_at : U32 -> CatCrossing
crossing_at = |index|
	match route_segment_at(index).encounter {
		CatCrosses(crossing) => crossing
		BirdHere(_) | QuietRoad => crash "World.crossing_at: the segment has a cat"
	}
