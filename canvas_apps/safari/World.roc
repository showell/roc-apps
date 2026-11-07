## The ride's world: the route, a line of road segments, each built once from
## its entry in `route_segments`. A segment holds its scenery (trees, cows, pigs, a cat
## by a tree), how it turns into the next, where the rider commits to that
## turn, and what lives at its end.
import Across
import Along
import Angle
import Billboard
import BirdFlight
import Cat
import CowHerd
import Distance
import Geom
import PigHerd
import Scenery
import Trees
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
		segment_in : World.SegmentIndex, List(World.Segment) -> World.Segment
		segment_in = |index, route_segments|
			route_segments.get(index.count_before())
				?? crash "World.SegmentIndex.segment_in: the route has no segment there"

		is_eq : _
	}

	## Whether the route plans pigs along a segment.
	PigPresence : [WithPigs, NoPigs]

	## How the rider takes a herd, whatever its shape.
	PigInterest : [Unnoticed, Distracting]

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

	## One segment of road, built from its plan.
	Segment : {
		length : Distance,
		trees : List(Trees.RoadsideTree),
		pig_herd : PigHerd,
		bull : [WithBull, NoBull],

		## How the rider takes the segment's herd. A segment with no pigs has
		## nothing to notice, so its pigs are `Unnoticed`.
		pig_interest : World.PigInterest,

		## The turn into the next segment: positive to the right, negative to
		## the left.
		exit_turn : Angle.Turn,
		commit_along : Along,
		mid_tower : [MidTower, NoMidTower],

		## What crosses the road here, at most one thing, so that the rider has
		## one experience at a time. Most of the road is quiet, so that a crossing
		## stands out.
		crossing : [CatCrosses(Cat.Crossing), BirdHere(BirdFlight.Habit), QuietRoad],
		ending : [Continues({ next : World.SegmentIndex }), Terminates],
		bend_life : Scenery.BendLife,
	}

	## A segment longer than this has a tower halfway along.
	mid_tower_min_length : Distance
	mid_tower_min_length = Distance.metres(1000.0)

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

	## How far before the end of its segment a herd stands.
	pig_distance_before_end : Distance
	pig_distance_before_end = Distance.metres(60.0)

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

	## Where the cow herd stands along its segment: the bull's place, with the
	## cows behind him.
	cow_herd_along : Along
	cow_herd_along = Along.metres(24.0)

	## The pigs of `segment`'s herd.
	segment_pigs : World.Segment -> List(Geom.Placed(Billboard))
	segment_pigs = |segment| segment.pig_herd.herd_pigs(pig_herd_along(segment.length))

	## The cows of `segment`'s herd, led by its bull if it has one.
	segment_cows : World.Segment -> List(Geom.Placed(Billboard))
	segment_cows = |segment| route_cows(segment.bull)

	## The pig of `segment`'s herd that stands out.
	standout_pig : World.Segment -> [Standout(Geom.Placed(Billboard)), NoPigs]
	standout_pig = |segment| segment.pig_herd.standout_pig(pig_herd_along(segment.length))

	## How many of the segments before `index` have pigs.
	herd_count_before : World.SegmentIndex -> U32
	herd_count_before = |index|
		plans
			.take_first(index.count_before())
			.count_if(|plan| plan.pigs == WithPigs)
			.to_u32_wrap()

	## Segment `number` of the route, counting from 0.
	route_segment : U32 -> World.Segment
	route_segment = |number| {
		index = World.SegmentIndex.number(number)
		plan = plans.get(index.count_before())
			?? crash "World.route_segment: the route has no segment there"
		built_segment(plan, index)
	}

	## Every segment of the route, in order.
	segments : List(World.Segment)
	segments = plans.map_with_index(
		|plan, at| built_segment(plan, World.SegmentIndex.number(at.to_u32_wrap())),
	)

	## The segments' length, end to end. It is summed from the last segment to
	## the first: a float sum's rounding depends on its order, and another
	## order can move a pixel.
	route_length : List(World.Segment) -> Distance
	route_length = |route_segments| route_segments.fold_rev(
		Distance.zero,
		|segment, sum| segment.length.plus(sum),
	)

	## How far along the route the point at `along` on the segment at `index`
	## is.
	distance_along_route : List(World.Segment),
	{
		index : World.SegmentIndex,
		along : Along,
	} -> Distance
	distance_along_route = |route_segments, { index, along }|
		route_length(route_segments.take_first(index.count_before())).plus(along.from_start())

	## The bend at the end of `segment`.
	bend_out_of : World.Segment -> Geom.Bend
	bend_out_of = |segment| { segment_length: segment.length, turn: segment.exit_turn }
}

## The segment at `index` of the route, built from its plan.
built_segment : World.SegmentPlan, World.SegmentIndex -> World.Segment
built_segment = |plan, index| {
	trees = Trees.roadside_trees({ scheme: plan.scheme, length: plan.length })
	earlier_herd_count = World.herd_count_before(index)
	pig_herd =
		match plan.pigs {
			WithPigs if earlier_herd_count < World.big_herd_count =>
				PigHerd.BigHerd(World.big_pig_herd)
			WithPigs => PigHerd.TwoRows(World.two_row_pig_herd)
			NoPigs => PigHerd.NoPigs
		}
	pig_interest =
		match plan.pigs {
			WithPigs if earlier_herd_count < World.pig_novelty_count => Distracting
			WithPigs | NoPigs => Unnoticed
		}
	{
		length: plan.length,
		trees,
		pig_herd,
		bull: plan.bull,
		pig_interest,
		exit_turn: plan.turn,
		commit_along: match plan.ending {
			Continues =>
				Geom.commit_along({ segment_length: plan.length, turn: plan.turn })
			Terminates => Along.at(plan.length)
		},
		mid_tower: if plan.length > World.mid_tower_min_length {
			MidTower
		} else {
			NoMidTower
		},
		crossing: match plan.crossing {
			CatCrosses => CatCrosses(
				Cat.crossing({
					road_half_width: Geom.road_half_width,
					tree: nearest_tree_ahead(trees, Cat.cat_along),
				}),
			)
			BirdHere => BirdFlight.crossing_among(trees)
			QuietRoad => QuietRoad
		},
		ending: match plan.ending {
			Continues => Continues({ next: index.next() })
			Terminates => Terminates
		},
		bend_life: match plan.ending {
			Continues => plan.bend_life
			Terminates => Quiet
		},
	}
}

## The nearest tree on the right at or past `along`, which a segment's cat waits
## by. A segment's trees are planted in order along the road, so the first found
## is the nearest.
nearest_tree_ahead : List(Trees.RoadsideTree), Along -> Trees.RoadsideTree
nearest_tree_ahead = |trees, along|
	trees.find_first(|tree| tree.across > Across.middle and tree.along >= along)
		?? crash "World.nearest_tree_ahead: a segment with a cat is long enough to have its tree"

## Where a herd stands on a segment `length` long.
pig_herd_along : Distance -> Along
pig_herd_along = |length| Along.at(length.minus(World.pig_distance_before_end))

## The route's cow herd at its place, led by a bull or not.
route_cows : [WithBull, NoBull] -> List(Geom.Placed(Billboard))
route_cows = |bull| World.cow_herd.herd_cows({ herd_along: World.cow_herd_along, bull })

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

seg : U32 -> World.Segment
seg = |i| World.route_segment(i)

expect seg(0).length.to_metres() == 500.0
expect seg(1).length.to_metres() == 320.0
expect seg(6).length.to_metres() == 1200.0
expect seg(9).length.to_metres() == 800.0
expect seg(18).length.to_metres() == 300.0
expect
	[
		(0, 1),
		(1, 2),
		(17, 18),
	].all(|(index, want)| next_of(seg(index)) == want)

expect [(0, False), (18, True)].all(|(index, want)| is_route_end(seg(index)) == want)

expect
	[
		(0, True),
		(1, False),
		(6, True),
		(18, True),
	].all(|(index, want)| turns_right(seg(index)) == want)

expect
	[
		(0, False),
		(6, True),
		(9, False),
	].all(|(index, want)| has_mid_tower(seg(index)) == want)

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
		(seg(0).exit_turn.abs().to_radians() / Trig.deg, 50.0),
		(seg(1).exit_turn.abs().to_radians() / Trig.deg, 70.0),
		(seg(6).exit_turn.abs().to_radians() / Trig.deg, 80.0),
		(seg(18).exit_turn.abs().to_radians() / Trig.deg, 0.0),
		(seg(18).commit_along.to_metres(), 300.0),
	].all(|(got, want)| (got - want).abs() <= 0.000000000001)

expect
	[
		(seg(0).commit_along.to_metres(), 498.32180073764545),
		(seg(1).commit_along.to_metres(), 319.2720595314676),
		(seg(6).commit_along.to_metres(), 1199.647346038583),
	].all(|(got, want)| (got - want).abs() <= 0.00000001)

expect World.segment_pigs(seg(0)).len() == 0
expect World.segment_pigs(seg(2)).len() == 49
expect World.segment_pigs(seg(10)).len() == 49
expect World.segment_pigs(seg(11)).len() == 10
expect World.segment_pigs(seg(13)).len() == 10
expect World.segment_pigs(seg(18)).len() == 10
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
		(0, PigHerd.NoPigs),
		(2, PigHerd.BigHerd(World.big_pig_herd)),
		(10, PigHerd.BigHerd(World.big_pig_herd)),
		(11, PigHerd.TwoRows(World.two_row_pig_herd)),
		(18, PigHerd.TwoRows(World.two_row_pig_herd)),
	].all(|(index, want)| seg(index).pig_herd == want)

expect World.segment_cows(seg(0)).len() == 14
expect World.segment_cows(seg(3)).len() == 14
expect World.segment_cows(seg(4)).len() == 15
expect World.segment_cows(seg(18)).len() == 15
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

# On a gold segment the pairs differ. The tree found is whichever comes next, near
# the road or far from it, and never one on the left.
expect nearest_tree_ahead(seg(3).trees, Cat.cat_along).across == Across.metres(3.5)
expect nearest_tree_ahead(seg(3).trees, Along.metres(90.0)).across == Across.metres(8.0)
expect nearest_tree_ahead(seg(3).trees, Along.metres(90.0)).along == Along.metres(96.0)
expect nearest_tree_ahead(seg(3).trees, Along.metres(96.0)).along == Along.metres(96.0)
expect nearest_tree_ahead(seg(3).trees, Along.metres(96.5)).along == Along.metres(126.0)

## Whether the route ends with a segment.
is_route_end : World.Segment -> Bool
is_route_end = |segment|
	match segment.ending {
		Continues(_) => False
		Terminates => True
	}

## The segment after one that continues.
next_of : World.Segment -> I64
next_of = |segment|
	match segment.ending {
		Continues({ next }) => next.to_i64()
		Terminates => crash "World.next_of: segments 0, 1 and 17 continue"
	}

## Whether a segment ends by turning right.
turns_right : World.Segment -> Bool
turns_right = |segment| segment.exit_turn.is_right()

## Whether a segment has a tower halfway along.
has_mid_tower : World.Segment -> Bool
has_mid_tower = |segment|
	match segment.mid_tower {
		MidTower => True
		NoMidTower => False
	}

## Whether a segment has a cat waiting by the road.
has_cat : World.Segment -> Bool
has_cat = |segment|
	match segment.crossing {
		CatCrosses(_) => True
		BirdHere(_) | QuietRoad => False
	}

## Whether a segment's pigs draw the rider's eye.
is_distracting : World.Segment -> Bool
is_distracting = |segment|
	match segment.pig_interest {
		Distracting => True
		Unnoticed => False
	}

## The cat crossing at a segment that has one.
crossing_at : U32 -> Cat.Crossing
crossing_at = |index|
	match seg(index).crossing {
		CatCrosses(crossing) => crossing
		BirdHere(_) | QuietRoad => crash "World.crossing_at: segments 3, 9 and 18 have a cat"
	}

## Where a herd stands on a 1000 m segment.
long_segment_herd_along : Along
long_segment_herd_along = pig_herd_along(Distance.metres(1000.0))

## The standout pig of a herd on a 1000 m segment.
standout_on_long_segment : PigHerd -> Geom.Placed(Billboard)
standout_on_long_segment = |herd|
	match herd.standout_pig(long_segment_herd_along) {
		Standout(standout) => standout
		NoPigs => crash "World's expects: a herd has a standout pig"
	}

eye_catcher : Geom.Placed(Billboard)
eye_catcher = standout_on_long_segment(PigHerd.BigHerd(World.big_pig_herd))

expect World.standout_pig(seg(0)) == NoPigs
expect long_segment_herd_along.to_metres() == 940.0

expect
	[
		(PigHerd.NoPigs, 0),
		(PigHerd.TwoRows(World.two_row_pig_herd), 10),
		(PigHerd.BigHerd(World.big_pig_herd), 49),
	].all(|(herd, count)| herd.herd_pigs(long_segment_herd_along).len() == count)

# The third pig of the row nearest the road, strayed from its place.
expect (eye_catcher.along.to_metres() - 940.80757).abs() <= 0.00001
expect (eye_catcher.across.to_metres() - 11.0332).abs() <= 0.00001
expect eye_catcher.kind.height.to_metres() == 1.1
expect World.pig_distance_before_end.to_metres() == 60.0
expect eye_catcher.kind.codepoint == 128022
expect World.big_pig_herd.columns == 7
expect World.big_pig_herd.rows == 7
expect World.big_pig_herd.standout_column == 2
expect eye_catcher.kind.facing == FacesLeft

all_pigs : List(Geom.Placed(Billboard))
all_pigs = PigHerd.BigHerd(World.big_pig_herd).herd_pigs(long_segment_herd_along)

herd_pig_at : U64 -> Geom.Placed(Billboard)
herd_pig_at = |i| all_pigs.get(i) ?? crash "World's expects: the big herd has 49 pigs"

expect all_pigs.len() == 49
expect herd_pig_at(2) == eye_catcher
expect all_pigs.count_if(|herd_member| herd_member == eye_catcher) == 1
expect {
	herd_along = pig_herd_along(Distance.metres(500.0))
	PigHerd.BigHerd(World.big_pig_herd).herd_pigs(herd_along).len() == 49
}
expect herd_pig_at(0).kind.codepoint == 128022
expect herd_pig_at(48).kind.codepoint == 128022

# Rows 0, 3 and 6 along the road, each pig within the jitter of its place.
expect
	[
		(0, 934.0),
		(1, 938.0),
		(2, 942.0),
		(3, 946.0),
		(4, 950.0),
		(5, 954.0),
		(6, 958.0),
		(21, 952.0),
		(22, 956.0),
		(23, 960.0),
		(24, 964.0),
		(25, 968.0),
		(26, 972.0),
		(27, 976.0),
		(42, 970.0),
		(43, 974.0),
		(44, 978.0),
		(45, 982.0),
		(46, 986.0),
		(47, 990.0),
		(48, 994.0),
	].all(|(i, along)| (herd_pig_at(i).along.to_metres() - along).abs() <= 1.2)

expect
	[
		(0, 12.0),
		(6, 12.0),
		(7, 18.0),
		(13, 18.0),
		(14, 24.0),
		(21, 30.0),
		(28, 36.0),
		(35, 42.0),
		(42, 48.0),
		(48, 48.0),
	].all(|(i, across)| (herd_pig_at(i).across.to_metres() - across).abs() <= 1.0)

both_rows : List(Geom.Placed(Billboard))
both_rows = PigHerd.TwoRows(World.two_row_pig_herd).herd_pigs(long_segment_herd_along)

expect both_rows.len() == 10
expect World.two_row_pig_herd.front_offsets().len() == 4
expect World.two_row_pig_herd.back_offsets.len() == 6

expect
	both_rows.map(|critter| critter.along.to_metres())
		== [
			934.0,
			938.0,
			942.0,
			946.0,
			930.0,
			934.0,
			938.0,
			942.0,
			946.0,
			950.0,
		]

expect
	both_rows.map(|critter| critter.across.to_metres())
		== [
			12.0,
			12.0,
			12.0,
			12.0,
			18.0,
			18.0,
			18.0,
			18.0,
			18.0,
			18.0,
		]

# The two-row herd's standout is the third pig of its front row, one of the herd.
two_row_standout : Geom.Placed(Billboard)
two_row_standout = standout_on_long_segment(PigHerd.TwoRows(World.two_row_pig_herd))

expect two_row_standout.along.to_metres() == 942.0
expect two_row_standout.across.to_metres() == 12.0
expect both_rows.get(2) == Ok(two_row_standout)
expect both_rows.count_if(|row_member| row_member == two_row_standout) == 1

expect World.two_row_pig_herd.front_offsets().map(Distance.to_metres) == [-6.0, -2.0, 2.0, 6.0]
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

cows_with_bull : List(Geom.Placed(Billboard))
cows_with_bull = route_cows(WithBull)

cows_without_bull : List(Geom.Placed(Billboard))
cows_without_bull = route_cows(NoBull)

expect cows_with_bull.len() == 15
expect cows_without_bull.len() == 14

# The bull leads, facing left, and the cows follow him in their own order, facing
# right.
expect cows_with_bull.take_first(1).map(|bull| bull.along) == [Along.metres(24.0)]
expect cows_with_bull.take_first(1).map(|bull| bull.kind.codepoint) == [128002]
expect cows_with_bull.drop_first(1) == cows_without_bull
expect cows_with_bull.take_first(2).map(|critter| critter.kind.facing) == [FacesLeft, FacesRight]
expect cows_without_bull.all(|cow| cow.kind.facing == FacesRight)
expect cows_without_bull.all(|cow| cow.kind.codepoint == 128004)

expect
	cows_without_bull.map(|cow| cow.kind.height.to_metres())
		== [
			1.4,
			0.7,
			1.4,
			1.4,
			1.4,
			0.7,
			1.4,
			1.4,
			1.4,
			0.7,
			1.4,
			1.4,
			1.4,
			0.7,
		]

# Each cow strays from its place by no more than the jitter.
expect {
	places = [
		28.0,
		30.0,
		32.0,
		34.0,
		36.0,
		38.0,
		40.0,
		42.0,
		44.0,
		46.0,
		48.0,
		50.0,
		52.0,
		54.0,
	]
	misses = cows_without_bull.map2(places, |cow, place| (cow.along.to_metres() - place).abs())
	misses.all(|miss| miss <= 1.5)
}

expect {
	places = [
		-12.0,
		-17.0,
		-22.0,
		-12.0,
		-17.0,
		-22.0,
		-12.0,
		-17.0,
		-22.0,
		-12.0,
		-17.0,
		-22.0,
		-12.0,
		-17.0,
	]
	misses = cows_without_bull.map2(places, |cow, place| (cow.across.to_metres() - place).abs())
	misses.all(|miss| miss <= 1.2)
}
