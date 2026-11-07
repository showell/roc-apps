## Pigs graze on the right of the road near the end of a segment, in a big
## herd or in two short rows. One pig of each herd stands out from the rest.
import Across
import Along
import Billboard
import Distance
import Geom
import Scenery

Pigs :: [].{

	## Whether the route plans pigs along a segment.
	PigPresence : [WithPigs, NoPigs]

	## How a segment's pigs stand.
	PigHerd : [NoPigs, BigHerd(Pigs.BigPigHerd), TwoRows(Pigs.TwoRowPigHerd)]

	## How the rider takes a herd, whatever its shape.
	PigInterest : [Unnoticed, Distracting]

	## A big herd: rows of columns, each pig strayed a little from its place.
	## The first row is nearest the road, and each row behind it stands
	## `row_depth` farther from the road and as far again along it.
	BigPigHerd := {
		columns : U64,
		rows : U64,

		## Where the first column is along the road, from the pigs' place.
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

		## The herd's pigs about `place`, row by row from the road.
		big_herd_pigs : Pigs.BigPigHerd, Along -> List(Geom.Placed(Billboard))
		big_herd_pigs = |herd, place| {
			columns = List.from_iter(U64.until(0, herd.columns))
			List.from_iter(U64.until(0, herd.rows))
				.join_map(|row| columns.map(|column| herd_pig(herd, { place, row, column })))
		}

		## The herd's pig that stands out, about `place`.
		standout_pig : Pigs.BigPigHerd, Along -> Geom.Placed(Billboard)
		standout_pig = |herd, place| {
			standout_spot = { place, row: 0, column: herd.standout_column }
			herd_pig(herd, standout_spot)
		}

		is_eq : _
	}

	## Two short rows of pigs, the back row farther from the road.
	TwoRowPigHerd := {
		## Where the pigs of each row are along the road, from the pigs' place.
		front_offsets : List(Distance),
		back_offsets : List(Distance),

		## How much farther from the road the back row stands than the front.
		back_row_offset : Distance,
	}.{

		## The herd's pigs about `place`, front row first.
		two_row_pigs : Pigs.TwoRowPigHerd, Along -> List(Geom.Placed(Billboard))
		two_row_pigs = |herd, place| {
			back_across = front_row_across.plus(herd.back_row_offset)
			row_pigs(place, { across: front_row_across, offsets: herd.front_offsets })
				.concat(row_pigs(place, { across: back_across, offsets: herd.back_offsets }))
		}

		## The herd's pig that stands out, about `place`: the middle pig of the
		## front row, the later of the two middle ones when the row is even.
		standout_pig : Pigs.TwoRowPigHerd, Along -> Geom.Placed(Billboard)
		standout_pig = |herd, place| {
			offset = herd.front_offsets.get(herd.front_offsets.len() // 2)
				?? crash "Pigs.TwoRowPigHerd.standout_pig: a two-row herd has a pig in its front row"
			pig({ along: place.plus(offset), across: front_row_across })
		}

		is_eq : _
	}

	pig_codepoint : U32
	pig_codepoint = 128022

	pig_height : Distance
	pig_height = Distance.metres(1.1)

	## How far before the end of its segment the pigs are.
	pig_distance_before_end : Distance
	pig_distance_before_end = Distance.metres(60.0)

	## The route's big herd, seven rows of seven.
	big_pig_herd : Pigs.BigPigHerd
	big_pig_herd = {
		columns: 7,
		rows: 7,
		first_column: Distance.metres(-6.0),
		column_spacing: Distance.metres(4.0),
		row_depth: Distance.metres(6.0),
		jitter_along: Distance.metres(1.2),
		jitter_across: Distance.metres(1.0),
		standout_column: 2,
	}

	## The route's two-row herd, four pigs in front and six behind.
	two_row_pig_herd : Pigs.TwoRowPigHerd
	two_row_pig_herd = {
		front_offsets: [-6.0, -2.0, 2.0, 6.0].map(Distance.metres),
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

	## The pigs of `herd` on a segment `length` long.
	herd_pigs : Pigs.PigHerd, Distance -> List(Geom.Placed(Billboard))
	herd_pigs = |herd, length|
		match herd {
			BigHerd(big_herd) => big_herd.big_herd_pigs(pigs_place(length))
			TwoRows(two_rows) => two_rows.two_row_pigs(pigs_place(length))
			NoPigs => []
		}

	## The pig of `herd` that stands out on a segment `length` long.
	standout_pig : Pigs.PigHerd, Distance -> [Standout(Geom.Placed(Billboard)), NoPigs]
	standout_pig = |herd, length|
		match herd {
			BigHerd(big_herd) => Standout(big_herd.standout_pig(pigs_place(length)))
			TwoRows(two_rows) => Standout(two_rows.standout_pig(pigs_place(length)))
			NoPigs => NoPigs
		}
}

## Where the pigs are on a segment `length` long.
pigs_place : Distance -> Along
pigs_place = |length| Along.at(length.minus(Pigs.pig_distance_before_end))

## Where the row of pigs nearest the road stands across it.
front_row_across : Across
front_row_across = Across.right_of_middle(Geom.road_half_width.plus(Scenery.herd_road_offset))

pig : { along : Along, across : Across } -> Geom.Placed(Billboard)
pig = |{ along, across }| {
	along,
	across,
	kind: {
		codepoint: Pigs.pig_codepoint,
		height: Pigs.pig_height,
		facing: FacesLeft,
	},
}

herd_pig : Pigs.BigPigHerd,
{
	place : Along,
	row : U64,
	column : U64,
} -> Geom.Placed(Billboard)
herd_pig = |herd, { place, row, column }| {
	i = (row * herd.columns + column).to_f64()
	fr = row.to_f64()
	fc = column.to_f64()
	first_column = place.plus(herd.first_column)
	in_column = first_column.plus(herd.column_spacing.times(fc))
	in_line = in_column.plus(herd.row_depth.times(fr))
	in_row = front_row_across.plus(herd.row_depth.times(fr))
	pig({
		along: in_line.plus(herd.jitter_along.times((i * 2.3).sin())),
		across: in_row.plus(herd.jitter_across.times((i * 1.7).cos())),
	})
}

row_pigs : Along, { across : Across, offsets : List(Distance) } -> List(Geom.Placed(Billboard))
row_pigs = |place, { across, offsets }|
	offsets.map(|offset| pig({ along: place.plus(offset), across }))

long_segment : Distance
long_segment = Distance.metres(1000.0)

## The standout pig of a herd on a 1000 m segment.
standout_on_long_segment : Pigs.PigHerd -> Geom.Placed(Billboard)
standout_on_long_segment = |herd|
	match Pigs.standout_pig(herd, long_segment) {
		Standout(standout) => standout
		NoPigs => crash "Pigs' expects: a herd has a standout pig"
	}

eye_catcher : Geom.Placed(Billboard)
eye_catcher = standout_on_long_segment(BigHerd(Pigs.big_pig_herd))

expect Pigs.standout_pig(NoPigs, long_segment) == NoPigs

expect
	[
		(NoPigs, 0),
		(TwoRows(Pigs.two_row_pig_herd), 10),
		(BigHerd(Pigs.big_pig_herd), 49),
	].all(|(herd, count)| Pigs.herd_pigs(herd, long_segment).len() == count)

# The third pig of the row nearest the road, strayed from its place.
expect (eye_catcher.along.to_metres() - 940.80757).abs() <= 0.00001
expect (eye_catcher.across.to_metres() - 11.0332).abs() <= 0.00001
expect eye_catcher.kind.height.to_metres() == 1.1
expect Pigs.pig_height.to_metres() == 1.1
expect Pigs.pig_distance_before_end.to_metres() == 60.0
expect eye_catcher.kind.codepoint == 128022
expect Pigs.pig_codepoint == 128022
expect Pigs.big_pig_herd.columns == 7
expect Pigs.big_pig_herd.rows == 7
expect Pigs.big_pig_herd.standout_column == 2
expect eye_catcher.kind.facing == FacesLeft

all_pigs : List(Geom.Placed(Billboard))
all_pigs = Pigs.herd_pigs(BigHerd(Pigs.big_pig_herd), long_segment)

herd_pig_at : U64 -> Geom.Placed(Billboard)
herd_pig_at = |i| all_pigs.get(i) ?? crash "Pigs: the big herd has 49 pigs"

expect all_pigs.len() == 49
expect herd_pig_at(2) == eye_catcher
expect all_pigs.count_if(|herd_member| herd_member == eye_catcher) == 1
expect Pigs.herd_pigs(BigHerd(Pigs.big_pig_herd), Distance.metres(500.0)).len() == 49
expect herd_pig_at(0).kind.codepoint == 128022
expect herd_pig_at(48).kind.codepoint == 128022

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
	].all(|(i, along)| (herd_pig_at(i).along.to_metres() - along).abs() <= 1.2)

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
	].all(|(i, across)| (herd_pig_at(i).across.to_metres() - across).abs() <= 1.0)

both_rows : List(Geom.Placed(Billboard))
both_rows = Pigs.herd_pigs(TwoRows(Pigs.two_row_pig_herd), long_segment)

expect both_rows.len() == 10
expect Pigs.two_row_pig_herd.front_offsets.len() == 4
expect Pigs.two_row_pig_herd.back_offsets.len() == 6

expect
	both_rows.map(|critter| critter.along.to_metres())
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
	both_rows.map(|critter| critter.across.to_metres())
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
two_row_standout = standout_on_long_segment(TwoRows(Pigs.two_row_pig_herd))

expect two_row_standout.along.to_metres() == 942.0
expect two_row_standout.across.to_metres() == 12.0
expect both_rows.get(2) == Ok(two_row_standout)
expect both_rows.count_if(|row_member| row_member == two_row_standout) == 1

expect Pigs.two_row_pig_herd.front_offsets.map(Distance.to_metres) == [-6.0, -2.0, 2.0, 6.0]
expect
	Pigs.two_row_pig_herd.back_offsets.map(Distance.to_metres)
		== [
			-10.0,
			-6.0,
			-2.0,
			2.0,
			6.0,
			10.0,
		]
expect Pigs.two_row_pig_herd.back_row_offset.to_metres() == 6.0
expect Pigs.big_pig_herd.first_column.to_metres() == -6.0
expect Pigs.big_pig_herd.column_spacing.to_metres() == 4.0
expect Pigs.big_pig_herd.row_depth.to_metres() == 6.0
expect Pigs.big_pig_herd.jitter_along.to_metres() == 1.2
expect Pigs.big_pig_herd.jitter_across.to_metres() == 1.0
