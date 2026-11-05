## A herd of cows grazes on the left of the road, in columns of three that
## run back from it, each cow a little out of line. A bull may stand in
## front of the herd, by the trees.
import Across
import Along
import Distance
import Scenery
import Trees
import lib.Trig

Herd :: [].{

	bull_codepoint : I64
	bull_codepoint = 128002

	cow_codepoint : I64
	cow_codepoint = 128004

	cow_height : Distance
	cow_height = Distance.metres(1.4)

	calf_height : Distance
	calf_height = cow_height.divided_by(2.0)

	bull_height : Distance
	bull_height = cow_height.times(1.15)

	## How far along its segment the bull stands.
	bull_dist : Along
	bull_dist = Along.metres(24.0)

	## The gap between the bull's side and the trees.
	bull_tree_gap : Distance
	bull_tree_gap = Distance.metres(0.5)

	herd_gap_behind_bull : Distance
	herd_gap_behind_bull = Distance.metres(6.0)

	## How many cows the herd has.
	herd_size : I64
	herd_size = 14

	## The distance between the herd's columns, along the road.
	herd_col_spacing : Distance
	herd_col_spacing = Distance.metres(6.0)

	## How far along the road each row back is moved from the one in front.
	herd_row_stagger : Distance
	herd_row_stagger = Distance.metres(2.0)

	## The distance between the herd's rows, away from the road.
	herd_row_depth : Distance
	herd_row_depth = Distance.metres(5.0)

	## How far a cow strays from its place, along the road and across it.
	herd_jitter_along : Distance
	herd_jitter_along = Distance.metres(1.5)

	herd_jitter_across : Distance
	herd_jitter_across = Distance.metres(1.2)

	## The bull, when the herd has one.
	bull_of : [WithBull, NoBull] -> List(Scenery.Critter)
	bull_of = |bull|
		match bull {
			WithBull => {
				tree_line = Scenery.lane_half_width.plus(Trees.tree_road_offset)
				bull_middle = tree_line.plus(bull_height.divided_by(2.0))
				[
					{
						along: bull_dist,
						across: Across.left_of_middle(bull_middle.plus(bull_tree_gap)),
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
	herd_front = Herd.bull_dist.plus(Herd.herd_gap_behind_bull)
	column_place = herd_front.plus(Herd.herd_col_spacing.times(column))
	in_line = column_place.plus(Herd.herd_row_stagger.times(row - 1.0))
	road_edge = Scenery.lane_half_width.plus(Scenery.herd_road_offset)
	row_place = road_edge.plus(Herd.herd_row_depth.times(row))
	out_from_road = row_place.plus(Herd.herd_jitter_across.times(Trig.r_cos((fi * 1.9))))
	{
		along: in_line.plus(Herd.herd_jitter_along.times(Trig.r_sin((fi * 2.7)))),
		across: Across.left_of_middle(out_from_road),
		codepoint: Herd.cow_codepoint,
		height: if i.rem_by(4) == 1 {
			Herd.calf_height
		} else {
			Herd.cow_height
		},
		face_right: True,
	}
}

expect Herd.bull_codepoint == 128002
expect Herd.cow_codepoint == 128004

expect Herd.bull_of(WithBull).map(|bull| bull.codepoint) == [128002]
expect Herd.bull_of(NoBull).len() == 0
expect Herd.fill_cows(WithBull).len() == 15
expect Herd.fill_cows(NoBull).len() == 14

# The bull faces left and the cows right.
expect Herd.fill_cows(WithBull).take_first(2).map(|critter| critter.face_right) == [False, True]

expect Herd.bull_of(WithBull).map(|bull| bull.along) == [Along.metres(24.0)]
expect Herd.bull_of(WithBull).map(|bull| bull.across) == [Across.metres(-4.805)]
expect Herd.bull_dist == Along.metres(24.0)
expect Herd.bull_tree_gap == Distance.metres(0.5)

expect Herd.cow_height == Distance.metres(1.4)
expect Herd.calf_height == Distance.metres(0.7)

expect (Herd.bull_height.to_metres() - 1.61).abs() <= 0.000000000001
expect Herd.bull_of(WithBull).all(|bull| (bull.height.to_metres() - 1.61).abs() <= 0.000000000001)

expect
	Herd.cows.map(|cow| cow.height.to_metres())
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

expect Herd.cows.len() == 14
expect Herd.cows.all(|cow| cow.codepoint == 128004)

# The bull leads, and the cows follow him in their own order.
expect Herd.fill_cows(WithBull).take_first(1).map(|bull| bull.along) == [Along.metres(24.0)]
expect Herd.fill_cows(WithBull).drop_first(1) == Herd.cows

expect Herd.herd_gap_behind_bull == Distance.metres(6.0)
expect Herd.herd_col_spacing == Distance.metres(6.0)
expect Herd.herd_row_stagger == Distance.metres(2.0)
expect Herd.herd_row_depth == Distance.metres(5.0)
expect Herd.herd_jitter_along == Distance.metres(1.5)
expect Herd.herd_jitter_across == Distance.metres(1.2)

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
	misses = Herd.cows.map2(places, |cow, place| (cow.along.to_metres() - place).abs())
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
	misses = Herd.cows.map2(places, |cow, place| (cow.across.to_metres() - place).abs())
	misses.all(|miss| miss <= 1.2)
}
