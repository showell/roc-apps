## A herd of cows grazes on the left of the road, in columns of three that
## run back from it, each cow a little out of line. A bull may stand in
## front of the herd, by the trees.
import Scenery
import Trees
import lib.Trig

Herd :: [].{

	bull_codepoint : I64
	bull_codepoint = 128002

	cow_codepoint : I64
	cow_codepoint = 128004

	cow_height : F64
	cow_height = 1.4

	calf_height : F64
	calf_height = (cow_height / 2.0)

	bull_height : F64
	bull_height = (cow_height * 1.15)

	## How far along its segment the bull stands.
	bull_dist : F64
	bull_dist = 24.0

	## The gap between the bull's side and the trees.
	bull_tree_gap : F64
	bull_tree_gap = 0.5

	herd_gap_behind_bull : F64
	herd_gap_behind_bull = 6.0

	## How many cows the herd has.
	herd_size : I64
	herd_size = 14

	## The distance between the herd's columns, along the road.
	herd_col_spacing : F64
	herd_col_spacing = 6.0

	## How far along the road each row back is moved from the one in front.
	herd_row_stagger : F64
	herd_row_stagger = 2.0

	## The distance between the herd's rows, away from the road.
	herd_row_depth : F64
	herd_row_depth = 5.0

	## How far a cow strays from its place, along the road and across it.
	herd_jitter_along : F64
	herd_jitter_along = 1.5

	herd_jitter_across : F64
	herd_jitter_across = 1.2

	## The bull, when the herd has one.
	bull_of : [WithBull, NoBull] -> List(Scenery.Critter)
	bull_of = |bull|
		match bull {
			WithBull => {
				tree_line = ((Scenery.lane_width / 2.0) + Trees.tree_road_offset)
				[
					{
						along: bull_dist,
						across: (0.0 - ((tree_line + (bull_height / 2.0)) + bull_tree_gap)),
						codepoint: bull_codepoint,
						height: bull_height,
						face_right: False,
					},
				]
			}
			NoBull => []
		}

	## The herd's cows, column by column from the front. Every fourth cow,
	## from the second, is a calf.
	cows : List(Scenery.Critter)
	cows = List.from_iter(I64.until(0, herd_size)).map(cow_at)

	## The bull, if there is one, then the cows.
	fill_cows : [WithBull, NoBull] -> List(Scenery.Critter)
	fill_cows = |bull| List.concat(Herd.bull_of(bull), Herd.cows)
}

cow_at : I64 -> Scenery.Critter
cow_at = |i| {
	fi = i.to_f64()
	column = i.div_trunc_by(3).to_f64()
	row = i.rem_by(3).to_f64()
	herd_front = (Herd.bull_dist + Herd.herd_gap_behind_bull)
	column_place = (herd_front + (column * Herd.herd_col_spacing))
	in_line = (column_place + ((row - 1.0) * Herd.herd_row_stagger))
	road_edge = ((Scenery.lane_width / 2.0) + Scenery.herd_road_offset)
	row_place = (road_edge + (row * Herd.herd_row_depth))
	out_from_road = (row_place + (Herd.herd_jitter_across * Trig.r_cos((fi * 1.9))))
	{
		along: (in_line + (Herd.herd_jitter_along * Trig.r_sin((fi * 2.7)))),
		across: (0.0 - out_from_road),
		codepoint: Herd.cow_codepoint,
		height: if (i.rem_by(4) == 1) Herd.calf_height else Herd.cow_height,
		face_right: True,
	}
}
