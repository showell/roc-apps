# Pigs -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Scenery
import lib.Trig

Pigs :: [].{

	pig_cp : I64
	pig_cp = 128022

	pig_height : F64
	pig_height = 1.1

	pig_novelty_count : I64
	pig_novelty_count = 2

	pig_dist_before_end : F64
	pig_dist_before_end = 60.0

	gaze_pig_along_offset : F64
	gaze_pig_along_offset = 2.0

	big_herd_cols : I64
	big_herd_cols = 7

	big_herd_rows : I64
	big_herd_rows = 7

	pig_col_spacing : F64
	pig_col_spacing = 4.0

	pig_row_depth : F64
	pig_row_depth = 6.0

	pig_jitter_along : F64
	pig_jitter_along = 1.2

	pig_jitter_across : F64
	pig_jitter_across = 1.0

	pig_herd_first_col : F64
	pig_herd_first_col = (0.0 - 6.0)

	pig_back_row_offset : F64
	pig_back_row_offset = 6.0

	gaze_pig : F64, F64 -> Scenery.Critter
	gaze_pig = |length, lane_half| { along: ((length - pig_dist_before_end) + gaze_pig_along_offset), across: (lane_half + Scenery.herd_road_offset), codepoint: pig_cp, height: pig_height, face_right: False }

	herd_pig_at : F64, I64, I64 -> Scenery.Critter
	herd_pig_at = |base, r, c| ({
		i = I64.to_f64(((r * big_herd_cols) + c))
		fr = I64.to_f64(r)
		fc = I64.to_f64(c)
		along = ((((base + pig_herd_first_col) + (fc * pig_col_spacing)) + (fr * pig_row_depth)) + (pig_jitter_along * Trig.r_sin((i * 2.3))))
		across = ((((Scenery.lane_width / 2.0) + Scenery.herd_road_offset) + (fr * pig_row_depth)) + (pig_jitter_across * Trig.r_cos((i * 1.7))))
		{ along: along, across: across, codepoint: pig_cp, height: pig_height, face_right: False }
	})

	# herd_cols_from builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	herd_cols_from : F64, I64, I64 -> List(Scenery.Critter)
	herd_cols_from = |base, r, c| herd_cols_from_acc(base, r, c, [])

	herd_cols_from_acc : F64, I64, I64, List(Scenery.Critter) -> List(Scenery.Critter)
	herd_cols_from_acc = |base, r, c, acc| (if (c >= big_herd_cols) { acc } else { herd_cols_from_acc(base, r, (c + 1), List.append(acc, herd_pig_at(base, r, c))) })

	# herd_rows_from builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	herd_rows_from : F64, I64 -> List(Scenery.Critter)
	herd_rows_from = |base, r| herd_rows_from_acc(base, r, [])

	herd_rows_from_acc : F64, I64, List(Scenery.Critter) -> List(Scenery.Critter)
	herd_rows_from_acc = |base, r, acc| (if (r >= big_herd_rows) { acc } else { herd_rows_from_acc(base, (r + 1), List.concat(acc, herd_cols_from(base, r, 0))) })

	fill_pig_herd : F64 -> List(Scenery.Critter)
	fill_pig_herd = |length| herd_rows_from((length - pig_dist_before_end), 0)

	pig_row_front : List(F64)
	pig_row_front = [(0.0 - 6.0), (0.0 - 2.0), 2.0, 6.0]

	pig_row_back : List(F64)
	pig_row_back = [(0.0 - 10.0), (0.0 - 6.0), (0.0 - 2.0), 2.0, 6.0, 10.0]

	# row_pigs_at builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	row_pigs_at : F64, F64, List(F64), I64 -> List(Scenery.Critter)
	row_pigs_at = |base, across, ds, i| row_pigs_at_acc(base, across, ds, i, [])

	row_pigs_at_acc : F64, F64, List(F64), I64, List(Scenery.Critter) -> List(Scenery.Critter)
	row_pigs_at_acc = |base, across, ds, i, acc| (if (i >= U64.to_i64_wrap(List.len(ds))) { acc } else { row_pigs_at_acc(base, across, ds, (i + 1), List.append(acc, { along: (base + (List.get(ds, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))), across: across, codepoint: pig_cp, height: pig_height, face_right: False })) })

	fill_pig_row : F64 -> List(Scenery.Critter)
	fill_pig_row = |length| ({
		base = (length - pig_dist_before_end)
		edge = ((Scenery.lane_width / 2.0) + Scenery.herd_road_offset)
		List.concat(row_pigs_at(base, edge, pig_row_front, 0), row_pigs_at(base, (edge + pig_back_row_offset), pig_row_back, 0))
	})
}
