## Pigs graze on the right of the road near the end of a segment. On the
## first few segments with pigs they are a big herd, and one of them catches
## the rider's eye; after that, they stand in two short rows.
import Across
import Along
import Distance
import Scenery
import lib.Trig

Pigs :: [].{

	## Whether the route plans pigs along a segment.
	PigPresence : [WithPigs, NoPigs]

	## Whether a segment's pigs catch the rider's eye.
	PigAttention : [Distracting, Unnoticed]

	pig_codepoint : I64
	pig_codepoint = 128022

	pig_height : Distance
	pig_height = Distance.metres(1.1)

	## How many segments with pigs have the big herd.
	pig_novelty_count : U32
	pig_novelty_count = 2

	## How far before the end of its segment the pigs are.
	pig_dist_before_end : Distance
	pig_dist_before_end = Distance.metres(60.0)

	## How far past that the pig that catches the rider's eye stands.
	gaze_pig_along_offset : Distance
	gaze_pig_along_offset = Distance.metres(2.0)

	big_herd_cols : I64
	big_herd_cols = 7

	big_herd_rows : I64
	big_herd_rows = 7

	## The distance between the big herd's columns, along the road.
	pig_col_spacing : Distance
	pig_col_spacing = Distance.metres(4.0)

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
	pig_herd_first_col : Distance
	pig_herd_first_col = Distance.metres(-6.0)

	## How much farther from the road the back row stands than the front.
	pig_back_row_offset : Distance
	pig_back_row_offset = Distance.metres(6.0)

	## Where the pigs of the front and back rows are along the road, from the
	## pigs' place.
	pig_row_front : List(Distance)
	pig_row_front = [
		-6.0,
		-2.0,
		2.0,
		6.0,
	].map(Distance.metres)

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

	## How a segment's pigs strike the rider, when `pig_segments_so_far` of
	## the route's segments, this one included, have pigs.
	attention_of : { presence : Pigs.PigPresence, pig_segments_so_far : U32 } -> Pigs.PigAttention
	attention_of = |{ presence, pig_segments_so_far }|
		if has_pigs(presence) and pig_segments_so_far <= pig_novelty_count {
			Distracting
		} else {
			Unnoticed
		}

	## The pigs on a segment `length` long: a big herd where they catch the
	## rider's eye, and two rows elsewhere.
	pigs_along : {
		presence : Pigs.PigPresence,
		attention : Pigs.PigAttention,
		length : Distance,
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

	## The pig that catches the rider's eye, on a segment `length` long.
	gaze_pig : Distance -> Scenery.Critter
	gaze_pig = |length|
		pig({
			along: pigs_place(length).plus(gaze_pig_along_offset),
			across: Across.right_of_middle(road_edge.plus(Scenery.herd_road_offset)),
		})

	## The big herd on a segment `length` long, row by row from the road.
	fill_pig_herd : Distance -> List(Scenery.Critter)
	fill_pig_herd = |length| {
		herd_along = pigs_place(length)
		columns = List.from_iter(I64.until(0, big_herd_cols))
		List.from_iter(I64.until(0, big_herd_rows))
			.join_map(|row| columns.map(|column| herd_pig(herd_along, { row, column })))
	}

	## The two rows of pigs on a segment `length` long, front row first.
	fill_pig_row : Distance -> List(Scenery.Critter)
	fill_pig_row = |length| {
		herd_along = pigs_place(length)
		edge = road_edge.plus(Scenery.herd_road_offset)
		front_across = Across.right_of_middle(edge)
		back_across = Across.right_of_middle(edge.plus(pig_back_row_offset))
		List.concat(
			pig_row(herd_along, { across: front_across, offsets: pig_row_front }),
			pig_row(herd_along, { across: back_across, offsets: pig_row_back }),
		)
	}
}

road_edge : Distance
road_edge = Scenery.lane_half_width

## Where the pigs are on a segment `length` long.
pigs_place : Distance -> Along
pigs_place = |length| Along.at(length.minus(Pigs.pig_dist_before_end))

pig : { along : Along, across : Across } -> Scenery.Critter
pig = |{ along, across }| {
	along,
	across,
	codepoint: Pigs.pig_codepoint,
	height: Pigs.pig_height,
	face_right: False,
}

herd_pig : Along, { row : I64, column : I64 } -> Scenery.Critter
herd_pig = |herd_along, { row, column }| {
	i = ((row * Pigs.big_herd_cols) + column).to_f64()
	fr = row.to_f64()
	fc = column.to_f64()
	first_column = herd_along.plus(Pigs.pig_herd_first_col)
	in_line = first_column.plus(Pigs.pig_col_spacing.times(fc)).plus(Pigs.pig_row_depth.times(fr))
	in_row = road_edge.plus(Scenery.herd_road_offset).plus(Pigs.pig_row_depth.times(fr))
	out_from_middle = in_row.plus(Pigs.pig_jitter_across.times(Trig.r_cos((i * 1.7))))
	pig({
		along: in_line.plus(Pigs.pig_jitter_along.times(Trig.r_sin((i * 2.3)))),
		across: Across.right_of_middle(out_from_middle),
	})
}

pig_row : Along, { across : Across, offsets : List(Distance) } -> List(Scenery.Critter)
pig_row = |herd_along, { across, offsets }|
	offsets.map(|offset| pig({ along: herd_along.plus(offset), across }))
