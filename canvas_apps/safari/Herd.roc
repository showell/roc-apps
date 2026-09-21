# Herd -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Scenery
import Trees
import lib.Trig

Herd :: [].{

	bull_cp : I64
	bull_cp = 128002

	cow_cp : I64
	cow_cp = 128004

	cow_height : F64
	cow_height = 1.4

	calf_height : F64
	calf_height = (cow_height / 2.0)

	bull_height : F64
	bull_height = (cow_height * 1.15)

	bull_dist : F64
	bull_dist = 24.0

	bull_tree_gap : F64
	bull_tree_gap = 0.5

	herd_gap_behind_bull : F64
	herd_gap_behind_bull = 6.0

	herd_col_spacing : F64
	herd_col_spacing = 6.0

	herd_row_stagger : F64
	herd_row_stagger = 2.0

	herd_row_depth : F64
	herd_row_depth = 5.0

	herd_jitter_along : F64
	herd_jitter_along = 1.5

	herd_jitter_across : F64
	herd_jitter_across = 1.2

	bull_of : Bool -> List(Scenery.Critter)
	bull_of = |bull| (if bull { [{ along: bull_dist, across: (0.0 - ((((Scenery.lane_width / 2.0) + Trees.tree_road_offset) + (bull_height / 2.0)) + bull_tree_gap)), codepoint: bull_cp, height: bull_height, face_right: False }] } else { [] })

	# cows_from builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	cows_from : I64 -> List(Scenery.Critter)
	cows_from = |i| cows_from_acc(i, [])

	cows_from_acc : I64, List(Scenery.Critter) -> List(Scenery.Critter)
	cows_from_acc = |i, acc| (if (i >= 14) { acc } else { cows_from_acc((i + 1), List.append(acc, cow_at(i))) })

	cow_at : I64 -> Scenery.Critter
	cow_at = |i| ({
		fi = I64.to_f64(i)
		col = I64.to_f64(I64.div_trunc_by(i, 3))
		row = I64.to_f64((i - (I64.div_trunc_by(i, 3) * 3)))
		along = ((((bull_dist + herd_gap_behind_bull) + (col * herd_col_spacing)) + ((row - 1.0) * herd_row_stagger)) + (herd_jitter_along * Trig.r_sin((fi * 2.7))))
		across = (0.0 - ((((Scenery.lane_width / 2.0) + Scenery.herd_road_offset) + (row * herd_row_depth)) + (herd_jitter_across * Trig.r_cos((fi * 1.9)))))
		{ along: along, across: across, codepoint: cow_cp, height: (if ((i - (I64.div_trunc_by(i, 4) * 4)) == 1) { calf_height } else { cow_height }), face_right: True }
	})

	fill_cows : Bool -> List(Scenery.Critter)
	fill_cows = |bull| List.concat(bull_of(bull), cows_from(0))
}
