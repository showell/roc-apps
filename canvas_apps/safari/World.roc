## The ride's world is its route, planned as a list of segments. Each plan says
## how long its segment is, what grows and grazes along it, what the rider meets
## on it, and how it turns into the next. The route makes some choices across
## its segments, such as which herds are big and which the rider finds
## distracting, and this module resolves them before each segment is built.
import Angle
import CatCrossing
import CowHerd
import Distance
import PigHerd
import Route
import Segment
import Trees
import lib.Trig

World :: [].{

	## Whether the route plans pigs along a segment.
	PigPresence : [WithPigs, NoPigs]

	## One segment of the route as planned: its length and scenery, and what
	## lives along it.
	SegmentPlan : {
		length : Distance,
		scheme : Trees.Scheme,
		encounter : [CatCrosses, BirdHere, QuietRoad],
		pigs : World.PigPresence,
		bull : [WithBull, NoBull],
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
				encounter: QuietRoad,
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

	## How many of the route's herds, from its first, are big. The rest stand
	## in two rows.
	big_herd_count : U32
	big_herd_count = 2

	## How many of the route's herds, from its first, the rider finds
	## distracting. The rider passes the rest by.
	pig_novelty_count : U32
	pig_novelty_count = 2

	## The route's big herd, seven rows of seven.
	big_pig_herd : PigHerd.BigPigHerd
	big_pig_herd = {
		columns: 7,
		rows: 7,
		first_column: Distance.metres(-6.0),
		column_spacing: Distance.metres(4.0),
		row_depth: Distance.metres(6.0),
		jitter_along: Distance.metres(1.2),
		jitter_across: Distance.metres(1.0),
		standout_column: 2,
	}

	## The route's two-row herd, four pigs in front and six behind. The third
	## pig of the front row stands out.
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
		rows: 3,
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
		segment_plans
			.take_first(index.count_before())
			.count_if(|plan| plan.pigs == WithPigs)
			.to_u32_wrap()

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
}

## The segment at `index` of the route, built from its plan once the route's
## choices for it are made: the shape of its herd and whether the rider finds it
## distracting, both from how many herds come before it, and how it ends, from
## its place in the route.
built_segment : World.SegmentPlan,
{
	index : Route.SegmentIndex,
	ending : [Bends({ turn : Angle.Turn, bend_life : Segment.BendLife }), RouteEnds],
} -> Segment
built_segment = |plan, { index, ending }| {
	earlier_herd_count = World.herd_count_before(index)
	pigs =
		match plan.pigs {
			WithPigs => {
				herd =
					if earlier_herd_count < World.big_herd_count {
						PigHerd.BigHerd(World.big_pig_herd)
					} else {
						PigHerd.TwoRows(World.two_row_pig_herd)
					}
				interest =
					if earlier_herd_count < World.pig_novelty_count {
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
		cows: { herd: World.cow_herd, bull: plan.bull },
		encounter: plan.encounter,
		ending,
	})
}

expect
	[
		(0, 0),
		(2, 0),
		(3, 1),
		(10, 1),
		(11, 2),
		(12, 3),
		(18, 8),
	].all(
		|(number, want)| {
			index = Route.SegmentIndex.number(number)
			World.herd_count_before(index).to_i64() == want
		},
	)

seg : U32 -> Segment
seg = |i| World.route.segment_at(Route.SegmentIndex.number(i))

expect
	[
		(0, False),
		(17, False),
		(18, True),
	].all(|(index, want)| is_route_end(seg(index)) == want)

expect
	[
		(0, True),
		(1, False),
		(6, True),
	].all(|(index, want)| turns_right(seg(index)) == want)

expect
	[
		(0, False),
		(6, True),
		(9, False),
	].all(|(index, want)| seg(index).has_mid_tower() == want)

expect
	[
		(0, False),
		(3, True),
		(9, True),
		(12, False),
		(18, True),
	].all(|(index, want)| has_cat(seg(index)) == want)

expect
	[
		(exit_turn_of(seg(0)).abs().to_radians() / Trig.degree, 50.0),
		(exit_turn_of(seg(1)).abs().to_radians() / Trig.degree, 70.0),
		(exit_turn_of(seg(6)).abs().to_radians() / Trig.degree, 80.0),
		(seg(18).commit_along().to_metres(), 300.0),
	].all(|(got, want)| (got - want).abs() <= 0.000000000001)

expect
	[
		(seg(0).commit_along().to_metres(), 498.32180073764545),
		(seg(1).commit_along().to_metres(), 319.2720595314676),
		(seg(6).commit_along().to_metres(), 1199.647346038583),
	].all(|(got, want)| (got - want).abs() <= 0.00000001)

expect seg(0).segment_pigs().len() == 0
expect seg(2).segment_pigs().len() == 49
expect seg(10).segment_pigs().len() == 49
expect seg(11).segment_pigs().len() == 10
expect seg(13).segment_pigs().len() == 10
expect seg(18).segment_pigs().len() == 10
expect
	[
		(0, False),
		(2, True),
		(10, True),
		(11, False),
		(18, False),
	].all(|(index, want)| is_distracting(seg(index)) == want)

expect
	[
		(0, NoPigs),
		(2, Herd({ herd: PigHerd.BigHerd(World.big_pig_herd), interest: Distracting })),
		(10, Herd({ herd: PigHerd.BigHerd(World.big_pig_herd), interest: Distracting })),
		(11, Herd({ herd: PigHerd.TwoRows(World.two_row_pig_herd), interest: Unnoticed })),
		(18, Herd({ herd: PigHerd.TwoRows(World.two_row_pig_herd), interest: Unnoticed })),
	].all(|(index, want)| seg(index).pigs == want)

expect seg(0).segment_standout_pig() == NoPigs
expect seg(0).segment_cows().len() == 14
expect seg(3).segment_cows().len() == 14
expect seg(4).segment_cows().len() == 15
expect seg(18).segment_cows().len() == 15
expect seg(0).trees.len() == 28
expect seg(1).trees.len() == 16
expect seg(6).trees.len() == 74
expect seg(18).trees.len() == 14
# Each cat starts behind a tree that is really there, and just past it.
expect
	[3, 9, 18].all(
		|index| {
			crossing = crossing_at(index)
			beyond = CatCrossing.cat_beyond_tree
			behind = CatCrossing.cat_behind_tree
			seg(index).trees.any(
				|{ road_point, .. }|
					road_point.along.plus(beyond) == crossing.along
						and road_point.across.plus(behind) == crossing.start_across,
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

## The turn out of a segment that bends.
exit_turn_of : Segment -> Angle.Turn
exit_turn_of = |segment| segment.bend_out_of().turn

## Whether a segment ends by turning right.
turns_right : Segment -> Bool
turns_right = |segment| exit_turn_of(segment).is_right()

## Whether a segment has a cat waiting by the road.
has_cat : Segment -> Bool
has_cat = |segment|
	match segment.encounter {
		CatCrosses(_) => True
		BirdHere(_) | QuietRoad => False
	}

## Whether a segment's pigs draw the rider's eye.
is_distracting : Segment -> Bool
is_distracting = |segment|
	match segment.pigs {
		Herd({ interest: Distracting, .. }) => True
		Herd({ interest: Unnoticed, .. }) | NoPigs => False
	}

## The cat crossing at a segment that has one.
crossing_at : U32 -> CatCrossing
crossing_at = |index|
	match seg(index).encounter {
		CatCrosses(crossing) => crossing
		BirdHere(_) | QuietRoad => crash "World.crossing_at: segments 3, 9 and 18 have a cat"
	}
