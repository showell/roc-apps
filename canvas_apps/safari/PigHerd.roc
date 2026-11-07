## A herd of pigs grazes on the right of the road about a place along it, in a
## big herd or in two short rows, or a segment has none. One pig of each herd
## stands out from the rest.
import Across
import Along
import Billboard
import Distance
import Geom
import Pig
import Scenery

PigHerd := [NoPigs, BigHerd(PigHerd.BigPigHerd), TwoRows(PigHerd.TwoRowPigHerd)].{

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
			NoPigs => []
		}

	## The herd's pig that stands out, about `herd_along`.
	standout_pig : PigHerd, Along -> [Standout(Geom.Placed(Billboard)), NoPigs]
	standout_pig = |herd, herd_along|
		match herd {
			BigHerd(big_herd) => Standout(big_herd.standout_pig(herd_along))
			TwoRows(two_rows) => Standout(two_rows.standout_pig(herd_along))
			NoPigs => NoPigs
		}

	is_eq : _
}

## Where the row of pigs nearest the road stands across it.
front_row_across : Across
front_row_across = Across.right_of_middle(Scenery.herd_front_distance)

pig : { along : Along, across : Across } -> Geom.Placed(Billboard)
pig = |{ along, across }| {
	along,
	across,
	kind: Billboard.adult_billboard(Pig.pig, FacesLeft),
}

herd_pig : PigHerd.BigPigHerd,
{
	herd_along : Along,
	row : U64,
	column : U64,
} -> Geom.Placed(Billboard)
herd_pig = |herd, { herd_along, row, column }| {
	i = (row * herd.columns + column).to_f64()
	fr = row.to_f64()
	fc = column.to_f64()
	first_column = herd_along.plus(herd.first_column)
	in_column = first_column.plus(herd.column_spacing.times(fc))
	in_line = in_column.plus(herd.row_depth.times(fr))
	in_row = front_row_across.plus(herd.row_depth.times(fr))
	pig({
		along: in_line.plus(herd.jitter_along.times((i * 2.3).sin())),
		across: in_row.plus(herd.jitter_across.times((i * 1.7).cos())),
	})
}

row_pigs : Along, { across : Across, offsets : List(Distance) } -> List(Geom.Placed(Billboard))
row_pigs = |herd_along, { across, offsets }|
	offsets.map(|offset| pig({ along: herd_along.plus(offset), across }))

expect PigHerd.NoPigs.herd_pigs(Along.metres(940.0)) == []
expect PigHerd.NoPigs.standout_pig(Along.metres(940.0)) == NoPigs
