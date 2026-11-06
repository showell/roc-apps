## Pigs graze on the right of the road near the end of a segment. On the
## first few segments with pigs they are a big herd, and one pig of that herd
## catches the rider's eye. After that, they stand in two short rows.
import Across
import Along
import Distance
import Scenery

Pigs :: [].{

	## Whether the route plans pigs along a segment.
	PigPresence : [WithPigs, NoPigs]

	## What a built segment's pigs are to the rider: there are none, the rider
	## passes them by, or this one of them catches the eye.
	PigInterest : [NoPigs, Unnoticed, Distracting(Scenery.Critter)]

	pig_codepoint : I64
	pig_codepoint = 128022

	pig_height : Distance
	pig_height = Distance.metres(1.1)

	## How many segments with pigs have the big herd.
	pig_novelty_count : U32
	pig_novelty_count = 2

	## How far before the end of its segment the pigs are.
	pig_distance_before_end : Distance
	pig_distance_before_end = Distance.metres(60.0)

	big_herd_columns : I64
	big_herd_columns = 7

	big_herd_rows : I64
	big_herd_rows = 7

	## The distance between the big herd's columns, along the road.
	pig_column_spacing : Distance
	pig_column_spacing = Distance.metres(4.0)

	## The distance between rows of pigs, away from the road. Each row of the
	## big herd is also moved this far along the road.
	pig_row_depth : Distance
	pig_row_depth = Distance.metres(6.0)

	## How far a pig of the big herd strays from its place, along the road
	## and across it.
	pig_jitter_along : Distance
	pig_jitter_along = Distance.metres(1.2)

	pig_jitter_across : Distance
	pig_jitter_across = Distance.metres(1.0)

	## Where the big herd's first column is, along the road, from the pigs'
	## place.
	pig_herd_first_column : Distance
	pig_herd_first_column = Distance.metres(-6.0)

	## How much farther from the road the back row stands than the front.
	pig_back_row_offset : Distance
	pig_back_row_offset = Distance.metres(6.0)

	## Where the pigs of the front and back rows are along the road, from the
	## pigs' place.
	pig_row_front : List(Distance)
	pig_row_front = [-6.0, -2.0, 2.0, 6.0].map(Distance.metres)

	pig_row_back : List(Distance)
	pig_row_back = [
		-10.0,
		-6.0,
		-2.0,
		2.0,
		6.0,
		10.0,
	].map(Distance.metres)

	has_pigs : Pigs.PigPresence -> Bool
	has_pigs = |presence|
		match presence {
			WithPigs => True
			NoPigs => False
		}

	## How the pigs of a segment `length` long strike the rider, when
	## `pig_segments_so_far` of the route's segments, this one included, have pigs.
	## The pig that catches the eye is the third in the row nearest the road.
	interest_of : {
		presence : Pigs.PigPresence,
		pig_segments_so_far : U32,
		length : Distance,
	} -> Pigs.PigInterest
	interest_of = |{ presence, pig_segments_so_far, length }|
		match presence {
			NoPigs => NoPigs
			WithPigs if pig_segments_so_far <= pig_novelty_count =>
				Distracting(herd_pig(pigs_place(length), { row: 0, column: 2 }))
			WithPigs => Unnoticed
		}

	## The pigs on a segment `length` long: a big herd where they catch the
	## rider's eye, and two rows where they don't.
	pigs_along : { interest : Pigs.PigInterest, length : Distance } -> List(Scenery.Critter)
	pigs_along = |{ interest, length }|
		match interest {
			Distracting(_) => big_herd(length)
			Unnoticed => two_rows(length)
			NoPigs => []
		}

	## The big herd on a segment `length` long, row by row from the road.
	big_herd : Distance -> List(Scenery.Critter)
	big_herd = |length| {
		herd_along = pigs_place(length)
		columns = List.from_iter(I64.until(0, big_herd_columns))
		List.from_iter(I64.until(0, big_herd_rows))
			.join_map(|row| columns.map(|column| herd_pig(herd_along, { row, column })))
	}

	## The two rows of pigs on a segment `length` long, front row first.
	two_rows : Distance -> List(Scenery.Critter)
	two_rows = |length| {
		herd_along = pigs_place(length)
		edge = Scenery.road_half_width.plus(Scenery.herd_road_offset)
		front_across = Across.right_of_middle(edge)
		back_across = Across.right_of_middle(edge.plus(pig_back_row_offset))
		pig_row(herd_along, { across: front_across, offsets: pig_row_front })
			.concat(pig_row(herd_along, { across: back_across, offsets: pig_row_back }))
	}
}

## Where the pigs are on a segment `length` long.
pigs_place : Distance -> Along
pigs_place = |length| Along.at(length.minus(Pigs.pig_distance_before_end))

pig : { along : Along, across : Across } -> Scenery.Critter
pig = |{ along, across }| {
	along,
	across,
	codepoint: Pigs.pig_codepoint,
	height: Pigs.pig_height,
	facing: FacesLeft,
}

herd_pig : Along, { row : I64, column : I64 } -> Scenery.Critter
herd_pig = |herd_along, { row, column }| {
	i = (row * Pigs.big_herd_columns + column).to_f64()
	fr = row.to_f64()
	fc = column.to_f64()
	first_column = herd_along.plus(Pigs.pig_herd_first_column)
	in_column = first_column.plus(Pigs.pig_column_spacing.times(fc))
	in_line = in_column.plus(Pigs.pig_row_depth.times(fr))
	edge = Scenery.road_half_width.plus(Scenery.herd_road_offset)
	in_row = edge.plus(Pigs.pig_row_depth.times(fr))
	out_from_middle = in_row.plus(Pigs.pig_jitter_across.times((i * 1.7).cos()))
	pig({
		along: in_line.plus(Pigs.pig_jitter_along.times((i * 2.3).sin())),
		across: Across.right_of_middle(out_from_middle),
	})
}

pig_row : Along, { across : Across, offsets : List(Distance) } -> List(Scenery.Critter)
pig_row = |herd_along, { across, offsets }|
	offsets.map(|offset| pig({ along: herd_along.plus(offset), across }))

## How a 1000 m segment's pigs strike the rider.
interest_on_long_segment : Pigs.PigPresence, U32 -> Pigs.PigInterest
interest_on_long_segment = |presence, pig_segments_so_far|
	Pigs.interest_of({ presence, pig_segments_so_far, length: Distance.metres(1000.0) })

eye_catcher : Scenery.Critter
eye_catcher =
	match interest_on_long_segment(WithPigs, 1) {
		Distracting(eye_catching_pig) => eye_catching_pig
		NoPigs | Unnoticed => crash "Pigs' expects: the first pigs catch the eye"
	}

expect interest_on_long_segment(NoPigs, 1) == NoPigs
expect interest_on_long_segment(WithPigs, 2) == Distracting(eye_catcher)
expect interest_on_long_segment(WithPigs, 3) == Unnoticed

expect
	[
		(NoPigs, 0),
		(Unnoticed, 10),
		(Distracting(eye_catcher), 49),
	].all(
		|(interest, count)| Pigs.pigs_along({
			interest,
			length: Distance.metres(1000.0),
		}).len() == count,
	)

# The third pig of the row nearest the road, strayed from its place.
expect (eye_catcher.along.to_metres() - 940.80757).abs() <= 0.00001
expect (eye_catcher.across.to_metres() - 11.0332).abs() <= 0.00001
expect eye_catcher.height.to_metres() == 1.1
expect Pigs.pig_height.to_metres() == 1.1
expect Pigs.pig_distance_before_end.to_metres() == 60.0
expect eye_catcher.codepoint == 128022
expect Pigs.pig_codepoint == 128022
expect Pigs.pig_novelty_count.to_i64() == 2
expect Pigs.big_herd_columns == 7
expect Pigs.big_herd_rows == 7
expect eye_catcher.facing == FacesLeft

whole_herd : List(Scenery.Critter)
whole_herd = Pigs.big_herd(Distance.metres(1000.0))

herd_pig_at : U64 -> Scenery.Critter
herd_pig_at = |i| whole_herd.get(i) ?? crash "Pigs: the big herd has 49 pigs"

expect whole_herd.len() == 49
expect herd_pig_at(2) == eye_catcher
expect whole_herd.count_if(|herd_member| herd_member == eye_catcher) == 1
expect Pigs.big_herd(Distance.metres(500.0)).len() == 49
expect herd_pig_at(0).codepoint == 128022
expect herd_pig_at(48).codepoint == 128022

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

both_rows : List(Scenery.Critter)
both_rows = Pigs.two_rows(Distance.metres(1000.0))

expect both_rows.len() == 10
expect Pigs.pig_row_front.len() == 4
expect Pigs.pig_row_back.len() == 6

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

expect Pigs.pig_row_front.map(Distance.to_metres) == [-6.0, -2.0, 2.0, 6.0]
expect Pigs.pig_row_back.map(Distance.to_metres) == [-10.0, -6.0, -2.0, 2.0, 6.0, 10.0]
expect Pigs.pig_back_row_offset.to_metres() == 6.0
expect Pigs.pig_herd_first_column.to_metres() == -6.0
expect Pigs.pig_column_spacing.to_metres() == 4.0
expect Pigs.pig_row_depth.to_metres() == 6.0
expect Pigs.pig_jitter_along.to_metres() == 1.2
expect Pigs.pig_jitter_across.to_metres() == 1.0
