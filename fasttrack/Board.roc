# Board -- every square as a number, from red's side of the board: zone by
# zone in the game's color order (red, blue, green, purple), each zone's 22
# squares in Config.config_locations order, then the bullseye, 88.
#
# A zone's squares: 0-3 the pen (HP1-HP4), 4-7 the base (B1-B4), 8 HH, 9 DS,
# 10 BR, 11-15 L0-L4, 16 FT, 17-21 R0-R4.
#
# Every color sees the same board from its own zone, so the rules and the
# square values are written once, as red sees them; `relative` and
# `absolute` translate a square for any color (the translation table).
import Config
import Type

Board :: [].{
	## A square no piece of this color can reach.
	far : I64
	far = 1000

	per_zone : U64
	per_zone = 22

	zones : U64
	zones = 4

	bullseye : U64
	bullseye = 88

	## The squares, 0 through 88.
	count : U64
	count = 89

	## Local squares within a zone.
	hh : U64
	hh = 8

	ds : U64
	ds = 9

	l0 : U64
	l0 = 11

	ft : U64
	ft = 16

	r4 : U64
	r4 = 21

	zone : U64 -> U64
	zone = |s| s // per_zone

	local : U64 -> U64
	local = |s| s % per_zone

	at : U64, U64 -> U64
	at = |z, l| z * per_zone + l

	is_pen : U64 -> Bool
	is_pen = |s| s < bullseye and local(s) < 4

	is_base : U64 -> Bool
	is_base = |s| s < bullseye and local(s) >= 4 and local(s) < 8

	is_ft : U64 -> Bool
	is_ft = |s| s < bullseye and local(s) == ft

	## Neither a pen nor a base square: the open track, and the bullseye.
	is_track : U64 -> Bool
	is_track = |s| !is_pen(s) and !is_base(s)

	## A color's pen squares, HP1 to HP4, and its base squares, B1 to B4.
	pen_of : U64 -> List(U64)
	pen_of = |c| [at(c, 0), at(c, 1), at(c, 2), at(c, 3)]

	base_of : U64 -> List(U64)
	base_of = |c| [at(c, 4), at(c, 5), at(c, 6), at(c, 7)]

	## The translation table: `relative_table` holds, for each color, every
	## square as that color sees it (its own zone first), and
	## `absolute_table` the way back. Red's rows are the identity.
	relative_table : List(List(U64))
	relative_table = List.map([0, 1, 2, 3], |c| List.map(squares, |s| turn(s, zones - c)))

	absolute_table : List(List(U64))
	absolute_table = List.map([0, 1, 2, 3], |c| List.map(squares, |r| turn(r, c)))

	## 0 through 88.
	squares : List(U64)
	squares = List.map_with_index(List.repeat(0, count), |_, i| i)

	## A square moved round by `k` zones; the bullseye stays put.
	turn : U64, U64 -> U64
	turn = |s, k| if s == bullseye { s } else { at((zone(s) + k) % zones, local(s)) }

	## Square `s` as color `c` sees it.
	relative : U64, U64 -> U64
	relative = |c, s| List.get(List.get(relative_table, c) ?? [], s) ?? crash("Board.relative: no such square")

	## The square color `c` calls `r`.
	absolute : U64, U64 -> U64
	absolute = |c, r| List.get(List.get(absolute_table, c) ?? [], r) ?? crash("Board.absolute: no such square")

	## A color's place in the game's color order.
	color_index : List(Str), Str -> U64
	color_index = |zone_colors, color| List.find_first_index(zone_colors, |c| c == color) ?? crash("Board: no zone ${color}")

	## The squares by name, for the page, the click codes and the tests.
	square_of : Str -> U64
	square_of = |id| List.find_first_index(Config.config_locations, |l| l.id == id) ?? crash("Board: no square ${id}")

	index_of : List(Str), Type.PieceLocation -> U64
	index_of = |zone_colors, loc|
		match loc.zone {
			BullsEyeZone => bullseye
			NormalColor(color) => at(color_index(zone_colors, color), square_of(loc.id))
		}

	loc_of : List(Str), U64 -> Type.PieceLocation
	loc_of = |zone_colors, s|
		if s == bullseye {
			{ zone: BullsEyeZone, id: "bullseye" }
		} else {
			{ zone: NormalColor(List.get(zone_colors, zone(s)) ?? "bogus"), id: (List.get(Config.config_locations, local(s)) ?? { x: 0.0, y: 0.0, id: "bogus" }).id }
		}

	## Every square in order, by name.
	all_locs : List(Str) -> List(Type.PieceLocation)
	all_locs = |zone_colors| List.map(squares, |s| loc_of(zone_colors, s))
}

expect Board.relative(1, Board.at(1, 0)) == 0 and Board.relative(1, Board.at(0, 0)) == 3 * Board.per_zone and Board.relative(0, 57) == 57
expect Board.absolute(2, Board.relative(2, 40)) == 40 and Board.relative(3, Board.bullseye) == Board.bullseye
expect {
	colors = ["red", "blue", "green", "purple"]
	Board.index_of(colors, { zone: NormalColor("green"), id: "L0" }) == Board.at(2, Board.l0)
	and Board.loc_of(colors, Board.at(3, Board.ft)) == { zone: NormalColor("purple"), id: "FT" }
	and List.len(Board.all_locs(colors)) == Board.count
}
