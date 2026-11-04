## Pigs graze on the right of the road near the end of a segment. On the
## first few segments with pigs they are a big herd, and one of them catches
## the rider's eye; after that, they stand in two short rows.
import Scenery
import lib.Trig

Pigs :: [].{

	pig_codepoint : I64
	pig_codepoint = 128022

	pig_height : F64
	pig_height = 1.1

	## How many segments with pigs have the big herd.
	pig_novelty_count : I64
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
	pig_row_front = [(0.0 - 6.0), (0.0 - 2.0), 2.0, 6.0]

	pig_row_back : List(F64)
	pig_row_back = [(0.0 - 10.0), (0.0 - 6.0), (0.0 - 2.0), 2.0, 6.0, 10.0]

	## The pig that catches the rider's eye, on a segment `length` metres
	## long.
	gaze_pig : F64 -> Scenery.Critter
	gaze_pig = |length| pig({ along: ((length - pig_dist_before_end) + gaze_pig_along_offset), across: (road_edge + Scenery.herd_road_offset) })

	## The big herd on a segment `length` metres long, row by row from the
	## road.
	fill_pig_herd : F64 -> List(Scenery.Critter)
	fill_pig_herd = |length| {
		herd_along = (length - pig_dist_before_end)
		List.from_iter(I64.until(0, big_herd_rows))
			.join_map(|row| List.from_iter(I64.until(0, big_herd_cols)).map(|column| herd_pig(herd_along, { row, column })))
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
pig = |{ along, across }| { along, across, codepoint: Pigs.pig_codepoint, height: Pigs.pig_height, face_right: False }

herd_pig : F64, { row : I64, column : I64 } -> Scenery.Critter
herd_pig = |herd_along, { row, column }| {
	i = ((row * Pigs.big_herd_cols) + column).to_f64()
	fr = row.to_f64()
	fc = column.to_f64()
	in_line = (((herd_along + Pigs.pig_herd_first_col) + (fc * Pigs.pig_col_spacing)) + (fr * Pigs.pig_row_depth))
	in_row = ((road_edge + Scenery.herd_road_offset) + (fr * Pigs.pig_row_depth))
	pig({
		along: (in_line + (Pigs.pig_jitter_along * Trig.r_sin((i * 2.3)))),
		across: (in_row + (Pigs.pig_jitter_across * Trig.r_cos((i * 1.7)))),
	})
}

pig_row : F64, { across : F64, offsets : List(F64) } -> List(Scenery.Critter)
pig_row = |herd_along, { across, offsets }| offsets.map(|offset| pig({ along: (herd_along + offset), across }))
