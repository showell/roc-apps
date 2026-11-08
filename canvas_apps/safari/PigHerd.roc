## A herd of pigs grazes on the right of the road about a place along it, in a
## big herd or in two short rows. One pig of each herd stands out from the rest.
import Across
import Along
import Billboard
import Distance
import EmojiStills
import Geom
import Scatter

PigHerd := [BigHerd(PigHerd.BigPigHerd), TwoRows(PigHerd.TwoRowPigHerd)].{

	## A big herd: rows of columns, each pig strayed a little from its place.
	## The front row is nearest the road, and each row behind it stands
	## `row_depth` farther from the road and as far again along it. The front
	## row always has its standout pig: the columns are counted either side of
	## it.
	BigPigHerd := {
		## How many columns stand before the standout pig's, and after it.
		columns_before_standout : U64,
		columns_after_standout : U64,

		## How many rows stand behind the front row.
		rows_behind_front : U64,

		## Where the first column is along the road, from the herd's place.
		first_column : Distance,

		## The distance between columns, along the road.
		column_spacing : Distance,
		row_depth : Distance,

		## How far a pig strays from its place, along the road and across it.
		jitter_along : Distance,
		jitter_across : Distance,
	}.{

		## The herd's pig that stands out, about `herd_along`.
		standout_pig : PigHerd.BigPigHerd, Along -> Geom.Placed(Billboard)
		standout_pig = |herd, herd_along| {
			column = herd.columns_before_standout
			herd_pig(herd, { herd_along, row: 0, column })
		}

		is_eq : _
	}

	## Two short rows of pigs, the back row farther from the road. The front row
	## always has its standout pig.
	TwoRowPigHerd := {
		## Where the pigs of the front row are along the road, from the herd's
		## place: the pigs before the standout pig, the standout pig, and the
		## pigs after it.
		front_row : {
			offsets_before : List(Distance),
			standout_offset : Distance,
			offsets_after : List(Distance),
		},

		## Where the pigs of the back row are along the road, from the herd's
		## place.
		back_offsets : List(Distance),

		## How much farther from the road the back row stands than the front.
		back_row_offset : Distance,
	}.{

		## The herd's pig that stands out, about `herd_along`.
		standout_pig : PigHerd.TwoRowPigHerd, Along -> Geom.Placed(Billboard)
		standout_pig = |herd, herd_along| {
			along = herd_along.plus(herd.front_row.standout_offset)
			placed_pig({ along, across: front_row_across })
		}

		is_eq : _
	}

	## The herd's pigs about `herd_along`.
	herd_pigs : PigHerd, Along -> List(Geom.Placed(Billboard))
	herd_pigs = |herd, herd_along|
		match herd {
			BigHerd(big_herd) => big_herd_pigs(big_herd, herd_along)
			TwoRows(two_rows) => two_row_pigs(two_rows, herd_along)
		}

	## The herd's pig that stands out, about `herd_along`.
	standout_pig : PigHerd, Along -> Geom.Placed(Billboard)
	standout_pig = |herd, herd_along|
		match herd {
			BigHerd(big_herd) => big_herd.standout_pig(herd_along)
			TwoRows(two_rows) => two_rows.standout_pig(herd_along)
		}

	is_eq : _
}

## How far from the middle of the road the row of pigs nearest it stands, 10
## metres off the road's edge. Each herd sets its own.
front_row_distance : Distance
front_row_distance = Geom.road_half_width.plus(Distance.metres(10.0))

## Where the row of pigs nearest the road stands across it.
front_row_across : Across
front_row_across = Across.right_of_middle(front_row_distance)

## How every pig looks: the pig emoji, a little over a metre tall.
pig_species : Billboard.Species
pig_species = { emoji: EmojiStills.pig, adult_height: Distance.metres(1.1) }

placed_pig : { along : Along, across : Across } -> Geom.Placed(Billboard)
placed_pig = |{ along, across }| {
	road_point: { along, across },
	lift: Distance.zero,
	kind: Billboard.adult_billboard(pig_species, FacesLeft),
}

## The big herd's pigs about `herd_along`, row by row from the road.
big_herd_pigs : PigHerd.BigPigHerd, Along -> List(Geom.Placed(Billboard))
big_herd_pigs = |herd, herd_along| {
	columns = List.from_iter(U64.until(0, column_count(herd)))
	List.from_iter(U64.until(0, herd.rows_behind_front + 1))
		.join_map(|row| columns.map(|column| herd_pig(herd, { herd_along, row, column })))
}

## How many columns the big herd has: those either side of the standout pig's,
## and its own.
column_count : PigHerd.BigPigHerd -> U64
column_count = |herd| herd.columns_before_standout + 1 + herd.columns_after_standout

## Where the two-row herd's front row pigs are along the road, from the herd's
## place, in the order they stand.
front_offsets : PigHerd.TwoRowPigHerd -> List(Distance)
front_offsets = |herd| {
	row = herd.front_row
	row.offsets_before.append(row.standout_offset).concat(row.offsets_after)
}

## The two-row herd's pigs about `herd_along`, front row first.
two_row_pigs : PigHerd.TwoRowPigHerd, Along -> List(Geom.Placed(Billboard))
two_row_pigs = |herd, herd_along| {
	back_across = front_row_across.plus(herd.back_row_offset)
	row_pigs(herd_along, { across: front_row_across, offsets: front_offsets(herd) })
		.concat(row_pigs(herd_along, { across: back_across, offsets: herd.back_offsets }))
}

## The big herd's pig in `row` and `column`. The scatter's phases, 2.3 along
## the road and 1.7 across it, are chosen by eye.
herd_pig : PigHerd.BigPigHerd,
{
	herd_along : Along,
	row : U64,
	column : U64,
} -> Geom.Placed(Billboard)
herd_pig = |herd, { herd_along, row, column }| {
	rows_back = row.to_f64()
	columns_along = column.to_f64()
	first_column = herd_along.plus(herd.first_column)
	in_column = first_column.plus(herd.column_spacing.times(columns_along))
	in_line = in_column.plus(herd.row_depth.times(rows_back))
	in_row = front_row_across.plus(herd.row_depth.times(rows_back))
	stray = Scatter.stray_of(
		row * column_count(herd) + column,
		{
			along_phase: 2.3,
			across_phase: 1.7,
			jitter_along: herd.jitter_along,
			jitter_across: herd.jitter_across,
		},
	)
	placed_pig({ along: in_line.plus(stray.along), across: in_row.plus(stray.across) })
}

row_pigs : Along, { across : Across, offsets : List(Distance) } -> List(Geom.Placed(Billboard))
row_pigs = |herd_along, { across, offsets }|
	offsets.map(|offset| placed_pig({ along: herd_along.plus(offset), across }))

## A big herd of three rows of four, the second pig of the front row standing
## out. It has more columns after the standout than before it, and more columns
## than rows, so a swap of either pair shows.
three_rows_of_four : PigHerd.BigPigHerd
three_rows_of_four = {
	columns_before_standout: 1,
	columns_after_standout: 2,
	rows_behind_front: 2,
	first_column: Distance.metres(-4.0),
	column_spacing: Distance.metres(4.0),
	row_depth: Distance.metres(6.0),
	jitter_along: Distance.metres(1.2),
	jitter_across: Distance.metres(1.0),
}

## A two-row herd, three pigs in front and two behind. The second pig of the
## front row stands out.
three_in_front_two_behind : PigHerd.TwoRowPigHerd
three_in_front_two_behind = {
	front_row: {
		offsets_before: [Distance.metres(-3.0)],
		standout_offset: Distance.metres(1.0),
		offsets_after: [Distance.metres(5.0)],
	},
	back_offsets: [-1.0, 3.0].map(Distance.metres),
	back_row_offset: Distance.metres(6.0),
}

## Where these herds stand along the road.
fixture_herd_along : Along
fixture_herd_along = Along.metres(940.0)

# A big herd has a pig for each row and column, and a two-row herd one for each
# offset, wherever the herd stands.
expect
	[
		(PigHerd.TwoRows(three_in_front_two_behind), 5),
		(PigHerd.BigHerd(three_rows_of_four), 12),
	].all(|(herd, count)| herd.herd_pigs(fixture_herd_along).len() == count)
expect PigHerd.BigHerd(three_rows_of_four).herd_pigs(Along.metres(440.0)).len() == 12

eye_catcher : Geom.Placed(Billboard)
eye_catcher = PigHerd.BigHerd(three_rows_of_four).standout_pig(fixture_herd_along)

all_pigs : List(Geom.Placed(Billboard))
all_pigs = PigHerd.BigHerd(three_rows_of_four).herd_pigs(fixture_herd_along)

herd_pig_at : U64 -> Geom.Placed(Billboard)
herd_pig_at = |i| all_pigs.get(i) ?? crash "PigHerd's expects: the big herd has 12 pigs"

# The big herd's standout is the pig of the front row after the columns before
# it, and it is one pig of the herd.
expect herd_pig_at(1) == eye_catcher
expect all_pigs.count_if(|herd_member| herd_member == eye_catcher) == 1

# Row by row from the road, each pig within the jitter of its place: along the
# road and across it.
expect
	[
		(0, 936.0, 12.0),
		(1, 940.0, 12.0),
		(2, 944.0, 12.0),
		(3, 948.0, 12.0),
		(4, 942.0, 18.0),
		(5, 946.0, 18.0),
		(6, 950.0, 18.0),
		(7, 954.0, 18.0),
		(8, 948.0, 24.0),
		(9, 952.0, 24.0),
		(10, 956.0, 24.0),
		(11, 960.0, 24.0),
	].all(
		|(i, along, across)| {
			place = herd_pig_at(i).road_point
			along_miss = (place.along.to_metres() - along).abs()
			across_miss = (place.across.to_metres() - across).abs()
			along_miss <= 1.2 and across_miss <= 1.0
		},
	)

both_rows : List(Geom.Placed(Billboard))
both_rows = PigHerd.TwoRows(three_in_front_two_behind).herd_pigs(fixture_herd_along)

# The front row's pigs, in the order they stand, then the back row's.
expect
	both_rows.map(|critter| critter.road_point.along.to_metres())
		== [937.0, 941.0, 945.0, 939.0, 943.0]
expect
	both_rows.map(|critter| critter.road_point.across.to_metres())
		== [12.0, 12.0, 12.0, 18.0, 18.0]

# The two-row herd's standout is the front row's pig after those before it, one
# of the herd.
two_row_standout : Geom.Placed(Billboard)
two_row_standout = PigHerd.TwoRows(three_in_front_two_behind).standout_pig(fixture_herd_along)

expect two_row_standout.road_point.along.to_metres() == 941.0
expect two_row_standout.road_point.across.to_metres() == 12.0
expect both_rows.get(1) == Ok(two_row_standout)
expect both_rows.count_if(|row_member| row_member == two_row_standout) == 1
