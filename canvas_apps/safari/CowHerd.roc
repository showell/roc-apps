## A herd of cows grazes on the left of the road, in columns that run back
## from it, each cow a little out of line. A bull may stand in front of the
## herd, by the trees.
import Across
import Along
import Billboard
import Conifer
import Distance
import EmojiStills
import Geom
import Scatter
import Scenery
import Trees

CowHerd := {
	cow_count : U64,

	## How many cows stand in each column, one to a row.
	rows : U64,

	## How far along the road behind the bull's place the first column stands.
	gap_behind_bull : Distance,

	## The distance between the herd's columns, along the road.
	column_spacing : Distance,

	## How far along the road each row back is moved from the one in front.
	row_stagger : Distance,

	## The distance between the herd's rows, away from the road.
	row_depth : Distance,

	## How far a cow strays from its place, along the road and across it.
	jitter_along : Distance,
	jitter_across : Distance,
}.{

	## The herd's cows behind `herd_along`, column by column from the front,
	## led by the bull at `herd_along` if the herd has one.
	herd_cows : CowHerd,
	{
		herd_along : Along,
		bull : [WithBull, NoBull],
	} -> List(Geom.Placed(Billboard))
	herd_cows = |herd, { herd_along, bull: with_bull }| {
		cows =
			List.from_iter(U64.until(0, herd.cow_count))
				.map(|cow_number| herd_cow(herd, { herd_along, cow_number }))
		match with_bull {
			WithBull => [herd_bull(herd_along)].concat(cows)
			NoBull => cows
		}
	}

	is_eq : _
}

cow : Billboard.Species
cow = { still: EmojiStills.cow, adult_height: Distance.metres(1.4) }

bull : Billboard.Species
bull = { still: EmojiStills.bull, adult_height: cow.adult_height.times(1.15) }

## The gap between the bull's side and the trees.
bull_tree_gap : Distance
bull_tree_gap = Distance.metres(0.5)

## The bull at `herd_along`, by the trees.
herd_bull : Along -> Geom.Placed(Billboard)
herd_bull = |herd_along| {
	tree_line = Trees.tree_line_distance(Conifer.Green)
	bull_middle = tree_line.plus(bull.adult_height.divided_by(2.0))
	{
		along: herd_along,
		across: Across.left_of_middle(bull_middle.plus(bull_tree_gap)),
		lift: Distance.zero,
		kind: Billboard.adult_billboard(bull, FacesLeft),
	}
}

## Every fourth cow, from the second, is a calf.
is_calf : U64 -> Bool
is_calf = |cow_number| cow_number.rem_by(4) == 1

## The herd's cow at `cow_number`, counting from 0. The scatter's phases, 2.7
## along the road and 1.9 across it, are chosen by eye.
herd_cow : CowHerd, { herd_along : Along, cow_number : U64 } -> Geom.Placed(Billboard)
herd_cow = |herd, { herd_along, cow_number }| {
	column = cow_number.div_trunc_by(herd.rows).to_f64()
	row = cow_number.rem_by(herd.rows).to_f64()
	herd_front = herd_along.plus(herd.gap_behind_bull)
	column_place = herd_front.plus(herd.column_spacing.times(column))
	in_line = column_place.plus(herd.row_stagger.times(row - 1.0))
	row_place = Scenery.herd_front_distance.plus(herd.row_depth.times(row))
	stray = Scatter.offset(
		cow_number,
		{
			along_phase: 2.7,
			across_phase: 1.9,
			jitter_along: herd.jitter_along,
			jitter_across: herd.jitter_across,
		},
	)
	out_from_road = row_place.plus(stray.across)
	{
		along: in_line.plus(stray.along),
		across: Across.left_of_middle(out_from_road),
		lift: Distance.zero,
		kind: if is_calf(cow_number) {
			Billboard.young_billboard(cow, FacesRight)
		} else {
			Billboard.adult_billboard(cow, FacesRight)
		},
	}
}

expect herd_bull(Along.metres(24.0)).along == Along.metres(24.0)
expect herd_bull(Along.metres(24.0)).across == Across.metres(-4.805)
expect herd_bull(Along.metres(24.0)).kind.still == EmojiStills.bull
expect herd_bull(Along.metres(24.0)).kind.facing == FacesLeft
expect (herd_bull(Along.metres(24.0)).kind.height.to_metres() - 1.61).abs() <= 0.000000000001

expect
	[
		(0, False),
		(1, True),
		(2, False),
		(4, False),
		(5, True),
		(13, True),
	].all(|(cow_number, want)| is_calf(cow_number) == want)

## A herd of fourteen cows in columns of three.
fourteen_cows : CowHerd
fourteen_cows = {
	cow_count: 14,
	rows: 3,
	gap_behind_bull: Distance.metres(6.0),
	column_spacing: Distance.metres(6.0),
	row_stagger: Distance.metres(2.0),
	row_depth: Distance.metres(5.0),
	jitter_along: Distance.metres(1.5),
	jitter_across: Distance.metres(1.2),
}

cows_with_bull : List(Geom.Placed(Billboard))
cows_with_bull = fourteen_cows.herd_cows({ herd_along: Along.metres(24.0), bull: WithBull })

cows_without_bull : List(Geom.Placed(Billboard))
cows_without_bull = fourteen_cows.herd_cows({ herd_along: Along.metres(24.0), bull: NoBull })

expect cows_with_bull.len() == 15
expect cows_without_bull.len() == 14

# The bull leads, facing left, and the cows follow him in their own order, facing
# right.
expect cows_with_bull.take_first(1).map(|leader| leader.along) == [Along.metres(24.0)]
expect cows_with_bull.take_first(1).map(|leader| leader.kind.still.codepoint()) == [128002]
expect cows_with_bull.drop_first(1) == cows_without_bull
expect cows_with_bull.take_first(2).map(|critter| critter.kind.facing) == [FacesLeft, FacesRight]
expect cows_without_bull.all(|member| member.kind.facing == FacesRight)
expect cows_without_bull.all(|member| member.kind.still.codepoint() == 128004)

expect
	cows_without_bull.map(|member| member.kind.height.to_metres())
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
	misses = cows_without_bull.map2(places, |one, place| (one.along.to_metres() - place).abs())
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
	misses = cows_without_bull.map2(places, |one, place| (one.across.to_metres() - place).abs())
	misses.all(|miss| miss <= 1.2)
}
