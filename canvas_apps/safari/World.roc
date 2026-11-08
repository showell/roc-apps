## The ride's world is its route, planned as a list of segments. Each plan says
## how long its segment is, what grows and grazes along it, what the rider meets
## on it, and how it turns into the next. The route makes some choices across
## its segments, such as which herds are big and which the rider finds
## distracting, and this module resolves them before each segment is built.
import Angle
import BirdFlight
import CatCrossing
import CowHerd
import Distance
import PigHerd
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

	## The route's last segment, which ends it.
	last_plan : World.SegmentPlan
	last_plan = {
		length: Distance.metres(300.0),
		scheme: RedGreen,
		encounter: CatCrosses,
		pigs: WithPigs,
		bull: WithBull,
	}

	## Every segment's plan, in order.
	segment_plans : List(World.SegmentPlan)
	segment_plans = bending_plans.map(|bending| bending.segment_plan).append(last_plan)

	## The route, built from its plans. Each segment but the last bends as its
	## plan says, and the last ends the route.
	route : Route
	route = {
		bending_segments = bending_plans.map_with_index(
			|{ segment_plan, turn, bend_life }, at| {
				index = Route.SegmentIndex.number(at.to_u32_wrap())
				built_segment(segment_plan, { index, ending: Bends({ turn, bend_life }) })
			},
		)
		last_index = Route.SegmentIndex.number(bending_plans.len().to_u32_wrap())
		last_segment = built_segment(last_plan, { index: last_index, ending: RouteEnds })
		Route.from_segments(bending_segments.append(last_segment))
	}

	## The route's first segment with a cat.
	first_cat_segment : Segment
	first_cat_segment =
		World.route.route_segments().find_first(Segment.has_cat)
			?? crash "World.first_cat_segment: the route has a cat"

	## The cat crossing on the route's first segment with a cat.
	first_cat_crossing : CatCrossing
	first_cat_crossing =
		match World.first_cat_segment.encounter {
			CatCrosses(crossing) => crossing
			BirdHere(_) | QuietRoad => crash "World.first_cat_crossing: the first cat segment has a cat"
		}

	## The bird's flight on the route's first segment with a bird.
	first_bird_flight : BirdFlight.Flight
	first_bird_flight =
		match first_bird_segment.encounter {
			BirdHere(flight) => flight
			CatCrosses(_) | QuietRoad => crash "World.first_bird_flight: the first bird segment has a bird"
		}

	## The route's first segment whose pigs draw the rider's eye.
	first_distracting_segment : Segment
	first_distracting_segment =
		World.route.route_segments().find_first(Segment.is_distracting)
			?? crash "World.first_distracting_segment: the route has a distracting herd"
}

## The route's first segment with a bird.
first_bird_segment : Segment
first_bird_segment =
	World.route.route_segments().find_first(Segment.has_bird)
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
						PigHerd.TwoRows(two_row_pig_herd)
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
big_herd_count : U32
big_herd_count = 2

## How many of the route's herds, from its first, the rider finds distracting.
## The rider passes the rest by.
pig_novelty_count : U32
pig_novelty_count = 2

## The route's big herd, seven rows of seven. The third pig of the front row
## stands out.
big_pig_herd : PigHerd.BigPigHerd
big_pig_herd = {
	columns_before_standout: 2,
	columns_after_standout: 4,
	rows_behind_front: 6,
	first_column: Distance.metres(-6.0),
	column_spacing: Distance.metres(4.0),
	row_depth: Distance.metres(6.0),
	jitter_along: Distance.metres(1.2),
	jitter_across: Distance.metres(1.0),
}

## The route's two-row herd, four pigs in front and six behind. The third pig
## of the front row stands out.
two_row_pig_herd : PigHerd.TwoRowPigHerd
two_row_pig_herd = {
	front_row: {
		offsets_before: [-6.0, -2.0].map(Distance.metres),
		standout_offset: Distance.metres(2.0),
		offsets_after: [6.0].map(Distance.metres),
	},
	back_offsets: [
		-10.0,
		-6.0,
		-2.0,
		2.0,
		6.0,
		10.0,
	].map(Distance.metres),
	back_row_offset: Distance.metres(6.0),
}

## The route's cow herd, fourteen cows in columns of three.
cow_herd : CowHerd
cow_herd = {
	cow_count: 14,
	rows_behind_front: 2,
	gap_behind_bull: Distance.metres(6.0),
	column_spacing: Distance.metres(6.0),
	row_stagger: Distance.metres(2.0),
	row_depth: Distance.metres(5.0),
	jitter_along: Distance.metres(1.5),
	jitter_across: Distance.metres(1.2),
}

## How many of the segments before `index` have pigs.
herd_count_before : Route.SegmentIndex -> U32
herd_count_before = |index|
	World.segment_plans
		.take_first(index.count_before())
		.count_if(|plan| plan.pigs == WithPigs)
		.to_u32_wrap()

route_segment_at : U32 -> Segment
route_segment_at = |i| World.route.segment_at(Route.SegmentIndex.number(i))

expect
	[
		(0, False),
		(17, False),
		(18, True),
	].all(|(index, want)| is_route_end(route_segment_at(index)) == want)

expect
	[
		(0, False),
		(6, True),
		(9, False),
	].all(|(index, want)| route_segment_at(index).has_mid_tower() == want)

# The rider commits to the route's end at the end of its last segment.
expect route_segment_at(18).commit_along().to_metres() == 300.0

expect
	[
		(route_segment_at(0).commit_along().to_metres(), 498.32180073764545),
		(route_segment_at(1).commit_along().to_metres(), 319.2720595314676),
		(route_segment_at(6).commit_along().to_metres(), 1199.647346038583),
	].all(|(got, want)| (got - want).abs() <= 0.00000001)

# Each cat starts behind a tree that is really there, and just past it.
expect
	[3, 9, 18].all(
		|index| {
			crossing = crossing_at(index)
			beyond = CatCrossing.cat_beyond_tree
			behind = CatCrossing.cat_behind_tree
			route_segment_at(index).trees.any(
				|{ road_point, .. }|
					road_point.along.plus(beyond) == crossing.along()
						and road_point.across.plus(behind) == crossing.start_across(),
			)
		},
	)

## Whether the route ends with a segment.
is_route_end : Segment -> Bool
is_route_end = |segment|
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
