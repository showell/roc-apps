## The ride's world is its route, planned as a list of segments. Each plan says
## how long its segment is, what grows and grazes along it, what crosses it, and
## how it turns into the next. The route makes some choices across its segments,
## such as which herds are big and which the rider finds distracting, and this
## module resolves them before each segment is built.
import Along
import Angle
import Cat
import CowHerd
import Distance
import PigHerd
import Scenery
import Segment
import lib.Trig

World :: [].{

	## A segment's place in the route, counted from 0. It says where a segment
	## is in the route, where a SegmentPlace.Position says how far ahead of the
	## rider it is.
	SegmentIndex :: U32.{

		number : U32 -> World.SegmentIndex
		number = |n| World.SegmentIndex.(n)

		to_u32 : World.SegmentIndex -> U32
		to_u32 = |World.SegmentIndex.(n)| n

		to_i64 : World.SegmentIndex -> I64
		to_i64 = |World.SegmentIndex.(n)| n.to_i64()

		## The route's first segment.
		first : World.SegmentIndex
		first = World.SegmentIndex.(0)

		next : World.SegmentIndex -> World.SegmentIndex
		next = |World.SegmentIndex.(n)| World.SegmentIndex.(n + 1)

		## The segment before this one, unless this is the first.
		previous : World.SegmentIndex -> [Previous(World.SegmentIndex), AtRouteStart]
		previous = |World.SegmentIndex.(n)|
			if n == 0 {
				AtRouteStart
			} else {
				Previous(World.SegmentIndex.(n - 1))
			}

		## How many segments come before this one.
		count_before : World.SegmentIndex -> U64
		count_before = |World.SegmentIndex.(n)| n.to_u64()

		## The segment of `route_segments` at this index.
		segment_in : World.SegmentIndex, List(Segment) -> Segment
		segment_in = |index, route_segments|
			route_segments.get(index.count_before())
				?? crash "World.SegmentIndex.segment_in: the route has no segment there"

		is_eq : _
	}

	## Whether the route plans pigs along a segment.
	PigPresence : [WithPigs, NoPigs]

	## One segment of the route as planned: its length and scenery, its turn
	## into the next (right is positive), what lives along it, and
	## what lives at its end.
	SegmentPlan : {
		length : Distance,
		scheme : Scenery.Scheme,
		turn : Angle.Turn,
		crossing : [CatCrosses, BirdHere, QuietRoad],
		pigs : World.PigPresence,
		bull : [WithBull, NoBull],
		ending : [Continues, Terminates],
		bend_life : Scenery.BendLife,
	}

	plans : List(World.SegmentPlan)
	plans = [
		{
			length: Distance.metres(500.0),
			scheme: AllGreen,
			turn: Angle.Turn.degrees(50.0),
			crossing: BirdHere,
			pigs: NoPigs,
			bull: NoBull,
			ending: Continues,
			bend_life: Animal(Elephant),
		},
		{
			length: Distance.metres(320.0),
			scheme: AllGreen,
			turn: Angle.Turn.degrees(-70.0),
			crossing: QuietRoad,
			pigs: NoPigs,
			bull: NoBull,
			ending: Continues,
			bend_life: Animal(Elephant),
		},
		{
			length: Distance.metres(400.0),
			scheme: AllGreen,
			turn: Angle.Turn.degrees(20.0),
			crossing: QuietRoad,
			pigs: WithPigs,
			bull: NoBull,
			ending: Continues,
			bend_life: Animal(Elephant),
		},
		{
			length: Distance.metres(300.0),
			scheme: GoldGreen,
			turn: Angle.Turn.degrees(20.0),
			crossing: CatCrosses,
			pigs: NoPigs,
			bull: NoBull,
			ending: Continues,
			bend_life: Animal(Elephant),
		},
		{
			length: Distance.metres(300.0),
			scheme: AllGreen,
			turn: Angle.Turn.degrees(-70.0),
			crossing: QuietRoad,
			pigs: NoPigs,
			bull: WithBull,
			ending: Continues,
			bend_life: Animal(Giraffe),
		},
		{
			length: Distance.metres(300.0),
			scheme: AllGreen,
			turn: Angle.Turn.degrees(-70.0),
			crossing: BirdHere,
			pigs: NoPigs,
			bull: WithBull,
			ending: Continues,
			bend_life: Animal(Elephant),
		},
		{
			length: Distance.metres(1200.0),
			scheme: RedGreen,
			turn: Angle.Turn.degrees(80.0),
			crossing: QuietRoad,
			pigs: NoPigs,
			bull: WithBull,
			ending: Continues,
			bend_life: Animal(Rhino),
		},
		{
			length: Distance.metres(300.0),
			scheme: AllGreen,
			turn: Angle.Turn.degrees(15.0),
			crossing: QuietRoad,
			pigs: NoPigs,
			bull: WithBull,
			ending: Continues,
			bend_life: Animal(Elephant),
		},
		{
			length: Distance.metres(300.0),
			scheme: AllGreen,
			turn: Angle.Turn.degrees(-70.0),
			crossing: QuietRoad,
			pigs: NoPigs,
			bull: WithBull,
			ending: Continues,
			bend_life: Animal(Elephant),
		},
		{
			length: Distance.metres(800.0),
			scheme: AllGreen,
			turn: Angle.Turn.degrees(15.0),
			crossing: CatCrosses,
			pigs: NoPigs,
			bull: WithBull,
			ending: Continues,
			bend_life: Animal(Elephant),
		},
		{
			length: Distance.metres(300.0),
			scheme: AllGreen,
			turn: Angle.Turn.degrees(15.0),
			crossing: QuietRoad,
			pigs: WithPigs,
			bull: WithBull,
			ending: Continues,
			bend_life: Animal(Elephant),
		},
		{
			length: Distance.metres(300.0),
			scheme: AllGreen,
			turn: Angle.Turn.degrees(15.0),
			crossing: QuietRoad,
			pigs: WithPigs,
			bull: WithBull,
			ending: Continues,
			bend_life: Animal(Elephant),
		},
		{
			length: Distance.metres(300.0),
			scheme: RedGreen,
			turn: Angle.Turn.degrees(15.0),
			crossing: QuietRoad,
			pigs: WithPigs,
			bull: WithBull,
			ending: Continues,
			bend_life: DuckPond,
		},
		{
			length: Distance.metres(400.0),
			scheme: AllGreen,
			turn: Angle.Turn.degrees(-50.0),
			crossing: QuietRoad,
			pigs: WithPigs,
			bull: WithBull,
			ending: Continues,
			bend_life: Animal(Elephant),
		},
		{
			length: Distance.metres(300.0),
			scheme: AllGreen,
			turn: Angle.Turn.degrees(50.0),
			crossing: BirdHere,
			pigs: WithPigs,
			bull: WithBull,
			ending: Continues,
			bend_life: Animal(Elephant),
		},
		{
			length: Distance.metres(300.0),
			scheme: RedGreen,
			turn: Angle.Turn.degrees(-50.0),
			crossing: QuietRoad,
			pigs: NoPigs,
			bull: WithBull,
			ending: Continues,
			bend_life: Animal(Zebra),
		},
		{
			length: Distance.metres(300.0),
			scheme: AllGreen,
			turn: Angle.Turn.degrees(50.0),
			crossing: QuietRoad,
			pigs: WithPigs,
			bull: WithBull,
			ending: Continues,
			bend_life: Animal(Elephant),
		},
		{
			length: Distance.metres(300.0),
			scheme: AllGreen,
			turn: Angle.Turn.degrees(-50.0),
			crossing: QuietRoad,
			pigs: WithPigs,
			bull: WithBull,
			ending: Continues,
			bend_life: Animal(Elephant),
		},
		{
			length: Distance.metres(300.0),
			scheme: RedGreen,
			turn: Angle.Turn.degrees(0.0),
			crossing: CatCrosses,
			pigs: WithPigs,
			bull: WithBull,
			ending: Terminates,
			bend_life: Quiet,
		},
	]

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
	herd_count_before : World.SegmentIndex -> U32
	herd_count_before = |index|
		plans
			.take_first(index.count_before())
			.count_if(|plan| plan.pigs == WithPigs)
			.to_u32_wrap()

	## Segment `number` of the route, counting from 0.
	route_segment : U32 -> Segment
	route_segment = |number| {
		index = World.SegmentIndex.number(number)
		plan = plans.get(index.count_before())
			?? crash "World.route_segment: the route has no segment there"
		built_segment(plan, index)
	}

	## Every segment of the route, in order.
	segments : List(Segment)
	segments = plans.map_with_index(
		|plan, at| built_segment(plan, World.SegmentIndex.number(at.to_u32_wrap())),
	)

	## The segments' length, end to end. It is summed from the last segment to
	## the first: a float sum's rounding depends on its order, and another
	## order can move a pixel.
	route_length : List(Segment) -> Distance
	route_length = |route_segments| route_segments.fold_rev(
		Distance.zero,
		|segment, sum| segment.length.plus(sum),
	)

	## How far along the route the point at `along` on the segment at `index`
	## is.
	distance_along_route : List(Segment), { index : World.SegmentIndex, along : Along } -> Distance
	distance_along_route = |route_segments, { index, along }|
		route_length(route_segments.take_first(index.count_before())).plus(along.from_start())
}

## The segment at `index` of the route, built from its plan once the route's
## choices for it are made: the shape of its herd and whether the rider finds it
## distracting, both from how many herds come before it.
built_segment : World.SegmentPlan, World.SegmentIndex -> Segment
built_segment = |plan, index| {
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
		crossing: plan.crossing,
		ending: match plan.ending {
			Continues => Bends({ turn: plan.turn, bend_life: plan.bend_life })
			Terminates => RouteEnds
		},
	})
}

expect World.plans.len() == 19

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
			index = World.SegmentIndex.number(number)
			World.herd_count_before(index).to_i64() == want
		},
	)

expect World.big_herd_count.to_i64() == 2
expect World.pig_novelty_count.to_i64() == 2

seg : U32 -> Segment
seg = |i| World.route_segment(i)

expect seg(0).length.to_metres() == 500.0
expect seg(1).length.to_metres() == 320.0
expect seg(6).length.to_metres() == 1200.0
expect seg(9).length.to_metres() == 800.0
expect seg(18).length.to_metres() == 300.0
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
		(exit_turn_of(seg(0)).abs().to_radians() / Trig.deg, 50.0),
		(exit_turn_of(seg(1)).abs().to_radians() / Trig.deg, 70.0),
		(exit_turn_of(seg(6)).abs().to_radians() / Trig.deg, 80.0),
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

expect seg(0).standout_pig() == NoPigs
expect seg(0).segment_cows().len() == 14
expect seg(3).segment_cows().len() == 14
expect seg(4).segment_cows().len() == 15
expect seg(18).segment_cows().len() == 15
expect seg(0).trees.len() == 28
expect seg(1).trees.len() == 16
expect seg(6).trees.len() == 74
expect seg(18).trees.len() == 14
expect crossing_at(3).mid_across.to_metres() == 0.425
expect crossing_at(18).mid_across.to_metres() == 0.425
# Each cat starts behind a tree that is really there, and just past it.
expect
	[3, 9, 18].all(
		|index| {
			crossing = crossing_at(index)
			seg(index).trees.any(
				|tree|
					tree.along.plus(Cat.cat_beyond_tree) == crossing.along
						and tree.across.plus(Cat.cat_behind_tree) == crossing.start_across,
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
	match segment.crossing {
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
crossing_at : U32 -> Cat.Crossing
crossing_at = |index|
	match seg(index).crossing {
		CatCrosses(crossing) => crossing
		BirdHere(_) | QuietRoad => crash "World.crossing_at: segments 3, 9 and 18 have a cat"
	}

expect Segment.pig_distance_before_end.to_metres() == 60.0
expect World.big_pig_herd.columns == 7
expect World.big_pig_herd.rows == 7
expect World.big_pig_herd.standout_column == 2
expect World.two_row_pig_herd.back_offsets.len() == 6
expect
	World.two_row_pig_herd.back_offsets.map(Distance.to_metres)
		== [
			-10.0,
			-6.0,
			-2.0,
			2.0,
			6.0,
			10.0,
		]
expect World.two_row_pig_herd.back_row_offset.to_metres() == 6.0
expect World.big_pig_herd.first_column.to_metres() == -6.0
expect World.big_pig_herd.column_spacing.to_metres() == 4.0
expect World.big_pig_herd.row_depth.to_metres() == 6.0
expect World.big_pig_herd.jitter_along.to_metres() == 1.2
expect World.big_pig_herd.jitter_across.to_metres() == 1.0
