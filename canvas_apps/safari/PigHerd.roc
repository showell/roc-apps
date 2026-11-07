## A herd of pigs grazes on the right of the road about a place along it, in a
## big herd or in two short rows. One pig of each herd stands out from the rest.
import Across
import Along
import Billboard
import Distance
import Geom
import Pig
import Scatter
import Scenery

PigHerd := [BigHerd(PigHerd.BigPigHerd), TwoRows(PigHerd.TwoRowPigHerd)].{

	## A big herd: rows of columns, each pig strayed a little from its place.
	## The first row is nearest the road, and each row behind it stands
	## `row_depth` farther from the road and as far again along it.
	BigPigHerd := {
		columns : U64,
		rows : U64,

		## Where the first column is along the road, from the herd's place.
		first_column : Distance,

		## The distance between columns, along the road.
		column_spacing : Distance,
		row_depth : Distance,

		## How far a pig strays from its place, along the road and across it.
		jitter_along : Distance,
		jitter_across : Distance,

		## Which pig of the row nearest the road stands out, counting from 0.
		standout_column : U64,
	}.{

		## The herd's pigs about `herd_along`, row by row from the road.
		big_herd_pigs : PigHerd.BigPigHerd, Along -> List(Geom.Placed(Billboard))
		big_herd_pigs = |herd, herd_along| {
			columns = List.from_iter(U64.until(0, herd.columns))
			List.from_iter(U64.until(0, herd.rows))
				.join_map(|row| columns.map(|column| herd_pig(herd, { herd_along, row, column })))
		}

		## The herd's pig that stands out, about `herd_along`.
		standout_pig : PigHerd.BigPigHerd, Along -> Geom.Placed(Billboard)
		standout_pig = |herd, herd_along| {
			column = herd.standout_column
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

		## Where the front row's pigs are along the road, from the herd's place,
		## in the order they stand.
		front_offsets : PigHerd.TwoRowPigHerd -> List(Distance)
		front_offsets = |herd| {
			row = herd.front_row
			row.offsets_before.append(row.standout_offset).concat(row.offsets_after)
		}

		## The herd's pigs about `herd_along`, front row first.
		two_row_pigs : PigHerd.TwoRowPigHerd, Along -> List(Geom.Placed(Billboard))
		two_row_pigs = |herd, herd_along| {
			back_across = front_row_across.plus(herd.back_row_offset)
			row_pigs(herd_along, { across: front_row_across, offsets: herd.front_offsets() })
				.concat(row_pigs(herd_along, { across: back_across, offsets: herd.back_offsets }))
		}

		## The herd's pig that stands out, about `herd_along`.
		standout_pig : PigHerd.TwoRowPigHerd, Along -> Geom.Placed(Billboard)
		standout_pig = |herd, herd_along| {
			along = herd_along.plus(herd.front_row.standout_offset)
			pig({ along, across: front_row_across })
		}

		is_eq : _
	}

	## The herd's pigs about `herd_along`.
	herd_pigs : PigHerd, Along -> List(Geom.Placed(Billboard))
	herd_pigs = |herd, herd_along|
		match herd {
			BigHerd(big_herd) => big_herd.big_herd_pigs(herd_along)
			TwoRows(two_rows) => two_rows.two_row_pigs(herd_along)
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

## Where the row of pigs nearest the road stands across it.
front_row_across : Across
front_row_across = Across.right_of_middle(Scenery.herd_front_distance)

pig : { along : Along, across : Across } -> Geom.Placed(Billboard)
pig = |{ along, across }| {
	road_point: { along, across },
	lift: Distance.zero,
	kind: Billboard.adult_billboard(Pig.pig, FacesLeft),
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
	fr = row.to_f64()
	fc = column.to_f64()
	first_column = herd_along.plus(herd.first_column)
	in_column = first_column.plus(herd.column_spacing.times(fc))
	in_line = in_column.plus(herd.row_depth.times(fr))
	in_row = front_row_across.plus(herd.row_depth.times(fr))
	stray = Scatter.offset(
		row * herd.columns + column,
		{
			along_phase: 2.3,
			across_phase: 1.7,
			jitter_along: herd.jitter_along,
			jitter_across: herd.jitter_across,
		},
	)
	pig({ along: in_line.plus(stray.along), across: in_row.plus(stray.across) })
}

row_pigs : Along, { across : Across, offsets : List(Distance) } -> List(Geom.Placed(Billboard))
row_pigs = |herd_along, { across, offsets }|
	offsets.map(|offset| pig({ along: herd_along.plus(offset), across }))

## A big herd of seven rows of seven. The third pig of the row nearest the road
## stands out.
seven_by_seven : PigHerd.BigPigHerd
seven_by_seven = {
	columns: 7,
	rows: 7,
	first_column: Distance.metres(-6.0),
	column_spacing: Distance.metres(4.0),
	row_depth: Distance.metres(6.0),
	jitter_along: Distance.metres(1.2),
	jitter_across: Distance.metres(1.0),
	standout_column: 2,
}

## A two-row herd, four pigs in front and six behind. The third pig of the front
## row stands out.
four_and_six : PigHerd.TwoRowPigHerd
four_and_six = {
	front_row: {
		offsets_before: [-6.0, -2.0].map(Distance.metres),
		standout_offset: Distance.metres(2.0),
		offsets_after: [6.0].map(Distance.metres),
	},
	back_offsets: [
		-10.0,
		-6.0,
		-2.0,
		2.0,
		6.0,
		10.0,
	].map(Distance.metres),
	back_row_offset: Distance.metres(6.0),
}

## Where these herds stand along the road.
fixture_herd_along : Along
fixture_herd_along = Along.metres(940.0)

eye_catcher : Geom.Placed(Billboard)
eye_catcher = PigHerd.BigHerd(seven_by_seven).standout_pig(fixture_herd_along)

expect
	[
		(PigHerd.TwoRows(four_and_six), 10),
		(PigHerd.BigHerd(seven_by_seven), 49),
	].all(|(herd, count)| herd.herd_pigs(fixture_herd_along).len() == count)

# The third pig of the row nearest the road, strayed from its place.
expect (eye_catcher.road_point.along.to_metres() - 940.80757).abs() <= 0.00001
expect (eye_catcher.road_point.across.to_metres() - 11.0332).abs() <= 0.00001
expect eye_catcher.kind.height.to_metres() == 1.1
expect eye_catcher.kind.still.codepoint() == 128022
expect eye_catcher.kind.facing == FacesLeft

all_pigs : List(Geom.Placed(Billboard))
all_pigs = PigHerd.BigHerd(seven_by_seven).herd_pigs(fixture_herd_along)

herd_pig_at : U64 -> Geom.Placed(Billboard)
herd_pig_at = |i| all_pigs.get(i) ?? crash "PigHerd's expects: the big herd has 49 pigs"

expect all_pigs.len() == 49
expect herd_pig_at(2) == eye_catcher
expect all_pigs.count_if(|herd_member| herd_member == eye_catcher) == 1
expect PigHerd.BigHerd(seven_by_seven).herd_pigs(Along.metres(440.0)).len() == 49
expect herd_pig_at(0).kind.still.codepoint() == 128022
expect herd_pig_at(48).kind.still.codepoint() == 128022

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
	].all(|(i, along)| (herd_pig_at(i).road_point.along.to_metres() - along).abs() <= 1.2)

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
	].all(|(i, across)| (herd_pig_at(i).road_point.across.to_metres() - across).abs() <= 1.0)

both_rows : List(Geom.Placed(Billboard))
both_rows = PigHerd.TwoRows(four_and_six).herd_pigs(fixture_herd_along)

expect both_rows.len() == 10
expect four_and_six.front_offsets().len() == 4

expect
	both_rows.map(|critter| critter.road_point.along.to_metres())
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
	both_rows.map(|critter| critter.road_point.across.to_metres())
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

# The two-row herd's standout is the third pig of its front row, one of the herd.
two_row_standout : Geom.Placed(Billboard)
two_row_standout = PigHerd.TwoRows(four_and_six).standout_pig(fixture_herd_along)

expect two_row_standout.road_point.along.to_metres() == 942.0
expect two_row_standout.road_point.across.to_metres() == 12.0
expect both_rows.get(2) == Ok(two_row_standout)
expect both_rows.count_if(|row_member| row_member == two_row_standout) == 1

expect four_and_six.front_offsets().map(Distance.to_metres) == [-6.0, -2.0, 2.0, 6.0]
