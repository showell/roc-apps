## A herd of cows grazes on the left of the road, in columns that run back
## from it, each cow a little out of line. A bull may stand in front of the
## herd, by the trees.
import Across
import Along
import Billboard
import Distance
import EmojiStills
import Geom
import Scatter
import Trees

CowHerd :: { cow_count : U64, rows_behind_front : U64 }.{

	## Whether a bull leads the herd.
	Bull : [WithBull, NoBull]

	## A herd of `cow_count` cows. `rows_behind_front` is how many rows stand
	## behind the front row, nearest the road. Each column has one cow in each
	## row, so a column holds one more cow than this.
	herd : { cow_count : U64, rows_behind_front : U64 } -> CowHerd
	herd = |shape| CowHerd.(shape)

	## The herd's cows behind `herd_along`, column by column from the front,
	## led by the bull at `herd_along` if the herd has one.
	herd_cows : CowHerd, { herd_along : Along, bull : CowHerd.Bull } -> List(Geom.Placed(Billboard))
	herd_cows = |CowHerd.({ cow_count, rows_behind_front }), { herd_along, bull }| {
		cows =
			List.from_iter(U64.until(0, cow_count))
				.map(|cow_number| herd_cow({ herd_along, cow_number, rows_behind_front }))
		match bull {
			WithBull => [herd_bull(herd_along)].concat(cows)
			NoBull => cows
		}
	}

	is_eq : _
}

cow : Billboard.Species
cow = { emoji: EmojiStills.cow, adult_height: Distance.metres(1.4) }

bull : Billboard.Species
bull = { emoji: EmojiStills.bull, adult_height: cow.adult_height.times(1.15) }

## The gap between the bull's side and the trees.
bull_tree_gap : Distance
bull_tree_gap = Distance.metres(0.5)

## The bull at `herd_along`, by the trees.
herd_bull : Along -> Geom.Placed(Billboard)
herd_bull = |herd_along| {
	bull_billboard = Billboard.adult_billboard(bull, FacesLeft)
	bull_middle = Trees.near_tree_line.plus(bull_billboard.half_width())
	{
		road_point: {
			along: herd_along,
			across: Across.left_of_middle(bull_middle.plus(bull_tree_gap)),
		},
		lift: Distance.zero,
		kind: bull_billboard,
	}
}

## How far from the middle of the road the herd's front row stands, 10 metres
## off the road's edge. Each herd sets its own.
front_row_distance : Distance
front_row_distance = Geom.road_half_width.plus(Distance.metres(10.0))

## How far along the road behind the bull's place the first column's place is,
## chosen by eye.
gap_behind_bull : Distance
gap_behind_bull = Distance.metres(4.0)

## The distance between the herd's columns, along the road, chosen by eye.
column_spacing : Distance
column_spacing = Distance.metres(6.0)

## How far along the road each row back is moved from the one in front, chosen
## by eye. A column's place is where its front row stands.
row_stagger : Distance
row_stagger = Distance.metres(2.0)

## The distance between the herd's rows, away from the road, chosen by eye.
row_depth : Distance
row_depth = Distance.metres(5.0)

## How far a cow strays from its place along the road, chosen by eye.
jitter_along : Distance
jitter_along = Distance.metres(1.5)

## How far a cow strays from its place across the road, chosen by eye.
jitter_across : Distance
jitter_across = Distance.metres(1.2)

## Every fourth cow, starting with cow 1, is a calf.
is_calf : U64 -> Bool
is_calf = |cow_number| cow_number.rem_by(4) == 1

## The herd's cow at `cow_number`, counting from 0. The scatter's phases, 2.7
## along the road and 1.9 across it, are chosen by eye.
herd_cow : {
	herd_along : Along,
	cow_number : U64,
	rows_behind_front : U64,
} -> Geom.Placed(Billboard)
herd_cow = |{ herd_along, cow_number, rows_behind_front }| {
	cows_per_column = rows_behind_front + 1
	column = cow_number.div_trunc_by(cows_per_column).to_f64()
	row = cow_number.rem_by(cows_per_column).to_f64()
	herd_front = herd_along.plus(gap_behind_bull)
	column_place = herd_front.plus(column_spacing.times(column))
	in_line = column_place.plus(row_stagger.times(row))
	row_place = front_row_distance.plus(row_depth.times(row))
	stray = Scatter.stray_of(
		cow_number,
		{
			along_phase: 2.7,
			across_phase: 1.9,
			jitter_along,
			jitter_across,
		},
	)
	out_from_road = row_place.plus(stray.across)
	{
		road_point: {
			along: in_line.plus(stray.along),
			across: Across.left_of_middle(out_from_road),
		},
		lift: Distance.zero,
		kind: cow_billboard(cow_number),
	}
}

## The billboard for the herd's cow at `cow_number`: young for a calf, grown
## for the rest.
cow_billboard : U64 -> Billboard
cow_billboard = |cow_number|
	if is_calf(cow_number) {
		Billboard.young_billboard(cow, FacesRight)
	} else {
		Billboard.adult_billboard(cow, FacesRight)
	}

expect {
	bull_height = herd_bull(Along.metres(24.0)).kind.scenery_height()
	(bull_height.to_metres() - 1.61).abs() <= 0.000000000001
}

expect
	[
		(0, False),
		(1, True),
		(2, False),
		(4, False),
		(5, True),
		(13, True),
	].all(|(cow_number, want)| is_calf(cow_number) == want)

## A herd of five cows in columns of two, its last column one cow short.
five_cows : CowHerd
five_cows = CowHerd.herd({ cow_count: 5, rows_behind_front: 1 })

cows_with_bull : List(Geom.Placed(Billboard))
cows_with_bull = five_cows.herd_cows({ herd_along: Along.metres(24.0), bull: WithBull })

cows_without_bull : List(Geom.Placed(Billboard))
cows_without_bull = five_cows.herd_cows({ herd_along: Along.metres(24.0), bull: NoBull })

expect cows_with_bull.len() == 6
expect cows_without_bull.len() == 5

# The bull leads, facing left, and the cows follow him in their own order, facing
# right.
expect cows_with_bull.take_first(1).map(|leader| leader.road_point.along) == [Along.metres(24.0)]
expect
	cows_with_bull.take_first(1).map(|leader| leader.kind)
		== [Billboard.adult_billboard(bull, FacesLeft)]
expect cows_with_bull.drop_first(1) == cows_without_bull
expect cows_with_bull.take_first(2).map(|critter| critter.kind.facing()) == [FacesLeft, FacesRight]
expect cows_without_bull.all(|member| member.kind.facing() == FacesRight)
expect {
	calf_or_cow = [
		Billboard.young_billboard(cow, FacesRight),
		Billboard.adult_billboard(cow, FacesRight),
	]
	cows_without_bull.all(|member| calf_or_cow.contains(member.kind))
}

# Column by column from the front, each cow strays from its place by no more
# than the jitter: along the road and across it.
expect {
	places = [
		(28.0, -12.0),
		(30.0, -17.0),
		(34.0, -12.0),
		(36.0, -17.0),
		(40.0, -12.0),
	]
	misses = cows_without_bull.map2(
		places,
		|one, (along, across)| (
			(one.road_point.along.to_metres() - along).abs(),
			(one.road_point.across.to_metres() - across).abs(),
		),
	)
	within_jitter = misses.all(|(along_miss, across_miss)| along_miss <= 1.5 and across_miss <= 1.2)
	misses.len() == 5 and within_jitter
}
