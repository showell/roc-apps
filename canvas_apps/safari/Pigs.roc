## Pigs graze on the right of the road near the end of a segment. On the
## first few segments with pigs they are a big herd, and one of them catches
## the rider's eye; after that, they stand in two short rows.
import Scenery
import lib.Trig

Pigs :: [].{

	## Whether the route plans pigs along a segment.
	PigPresence : [WithPigs, NoPigs]

	## Whether a segment's pigs catch the rider's eye.
	PigAttention : [Distracting, Unnoticed]

	pig_codepoint : I64
	pig_codepoint = 128022

	pig_height : F64
	pig_height = 1.1

	## How many segments with pigs have the big herd.
	pig_novelty_count : U32
	pig_novelty_count = 2

	## How far before the end of its segment the pigs are.
	pig_dist_before_end : F64
	pig_dist_before_end = 60.0

	## How far past that the pig that catches the rider's eye stands.
	gaze_pig_along_offset : F64
	gaze_pig_along_offset = 2.0

	big_herd_cols : I64
	big_herd_cols = 7

	big_herd_rows : I64
	big_herd_rows = 7

	## The distance between the big herd's columns, along the road.
	pig_col_spacing : F64
	pig_col_spacing = 4.0

	## The distance between rows of pigs, away from the road. Each row of the
	## big herd is also moved this far along the road.
	pig_row_depth : F64
	pig_row_depth = 6.0

	## How far a pig of the big herd strays from its place, along the road
	## and across it.
	pig_jitter_along : F64
	pig_jitter_along = 1.2

	pig_jitter_across : F64
	pig_jitter_across = 1.0

	## Where the big herd's first column is, along the road, from the pigs'
	## place.
	pig_herd_first_col : F64
	pig_herd_first_col = (0.0 - 6.0)

	## How much farther from the road the back row stands than the front.
	pig_back_row_offset : F64
	pig_back_row_offset = 6.0

	## Where the pigs of the front and back rows are along the road, from the
	## pigs' place.
	pig_row_front : List(F64)
	pig_row_front = [
		(0.0 - 6.0),
		(0.0 - 2.0),
		2.0,
		6.0,
	]

	pig_row_back : List(F64)
	pig_row_back = [
		(0.0 - 10.0),
		(0.0 - 6.0),
		(0.0 - 2.0),
		2.0,
		6.0,
		10.0,
	]

	has_pigs : Pigs.PigPresence -> Bool
	has_pigs = |presence|
		match presence {
			WithPigs => True
			NoPigs => False
		}

	## How a segment's pigs strike the rider, when `pig_segments_so_far` of
	## the route's segments, this one included, have pigs.
	attention_of : { presence : Pigs.PigPresence, pig_segments_so_far : U32 } -> Pigs.PigAttention
	attention_of = |{ presence, pig_segments_so_far }|
		if has_pigs(presence) and pig_segments_so_far <= pig_novelty_count {
			Distracting
		} else {
			Unnoticed
		}

	## The pigs on a segment `length` metres long: a big herd where they catch
	## the rider's eye, and two rows elsewhere.
	pigs_along : {
		presence : Pigs.PigPresence,
		attention : Pigs.PigAttention,
		length : F64,
	} -> List(Scenery.Critter)
	pigs_along = |
		{
			presence,
			attention,
			length,
		},
	|
		match (presence, attention) {
			(WithPigs, Distracting) => fill_pig_herd(length)
			(WithPigs, Unnoticed) => fill_pig_row(length)
			(NoPigs, Distracting) | (NoPigs, Unnoticed) => []
		}

	## The pig that catches the rider's eye, on a segment `length` metres
	## long.
	gaze_pig : F64 -> Scenery.Critter
	gaze_pig = |length|
		pig({
			along: ((length - pig_dist_before_end) + gaze_pig_along_offset),
			across: (road_edge + Scenery.herd_road_offset),
		})

	## The big herd on a segment `length` metres long, row by row from the
	## road.
	fill_pig_herd : F64 -> List(Scenery.Critter)
	fill_pig_herd = |length| {
		herd_along = (length - pig_dist_before_end)
		columns = List.from_iter(I64.until(0, big_herd_cols))
		List.from_iter(I64.until(0, big_herd_rows))
			.join_map(|row| columns.map(|column| herd_pig(herd_along, { row, column })))
	}

	## The two rows of pigs on a segment `length` metres long, front row first.
	fill_pig_row : F64 -> List(Scenery.Critter)
	fill_pig_row = |length| {
		herd_along = (length - pig_dist_before_end)
		edge = (road_edge + Scenery.herd_road_offset)
		List.concat(
			pig_row(herd_along, { across: edge, offsets: pig_row_front }),
			pig_row(herd_along, { across: (edge + pig_back_row_offset), offsets: pig_row_back }),
		)
	}
}

road_edge : F64
road_edge = (Scenery.lane_width / 2.0)

pig : { along : F64, across : F64 } -> Scenery.Critter
pig = |{ along, across }| {
	along,
	across,
	codepoint: Pigs.pig_codepoint,
	height: Pigs.pig_height,
	face_right: False,
}

herd_pig : F64, { row : I64, column : I64 } -> Scenery.Critter
herd_pig = |herd_along, { row, column }| {
	i = ((row * Pigs.big_herd_cols) + column).to_f64()
	fr = row.to_f64()
	fc = column.to_f64()
	first_column = (herd_along + Pigs.pig_herd_first_col)
	in_line = ((first_column + (fc * Pigs.pig_col_spacing)) + (fr * Pigs.pig_row_depth))
	in_row = ((road_edge + Scenery.herd_road_offset) + (fr * Pigs.pig_row_depth))
	pig({
		along: (in_line + (Pigs.pig_jitter_along * Trig.r_sin((i * 2.3)))),
		across: (in_row + (Pigs.pig_jitter_across * Trig.r_cos((i * 1.7)))),
	})
}

pig_row : F64, { across : F64, offsets : List(F64) } -> List(Scenery.Critter)
pig_row = |herd_along, { across, offsets }|
	offsets.map(|offset| pig({ along: (herd_along + offset), across }))

eye_catcher : Scenery.Critter
eye_catcher = Pigs.gaze_pig(1000.0)

expect eye_catcher.along == 942.0
expect eye_catcher.across == 12.0
expect eye_catcher.height == 1.1
expect Pigs.pig_height == 1.1
expect Pigs.pig_dist_before_end == 60.0
expect Pigs.gaze_pig_along_offset == 2.0
expect eye_catcher.codepoint == 128022
expect Pigs.pig_codepoint == 128022
expect Pigs.pig_novelty_count.to_i64() == 2
expect Pigs.big_herd_cols == 7
expect Pigs.big_herd_rows == 7
expect !eye_catcher.face_right

big_herd : List(Scenery.Critter)
big_herd = Pigs.fill_pig_herd(1000.0)

herd_pig_at : U64 -> Scenery.Critter
herd_pig_at = |i| big_herd.get(i) ?? crash "Pigs: the big herd has 49 pigs"

expect big_herd.len() == 49
expect Pigs.fill_pig_herd(500.0).len() == 49
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
	].all(|(i, along)| (herd_pig_at(i).along - along).abs() <= 1.2)

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
	].all(|(i, across)| (herd_pig_at(i).across - across).abs() <= 1.0)

two_rows : List(Scenery.Critter)
two_rows = Pigs.fill_pig_row(1000.0)

expect two_rows.len() == 10
expect Pigs.pig_row_front.len() == 4
expect Pigs.pig_row_back.len() == 6

expect
	two_rows.map(|critter| critter.along)
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
	two_rows.map(|critter| critter.across)
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

expect Pigs.pig_row_front == [-6.0, -2.0, 2.0, 6.0]
expect Pigs.pig_row_back == [-10.0, -6.0, -2.0, 2.0, 6.0, 10.0]
expect Pigs.pig_back_row_offset == 6.0
expect Pigs.pig_herd_first_col == -6.0
expect Pigs.pig_col_spacing == 4.0
expect Pigs.pig_row_depth == 6.0
expect Pigs.pig_jitter_along == 1.2
expect Pigs.pig_jitter_across == 1.0
