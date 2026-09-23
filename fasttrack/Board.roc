# Board -- every square as a number: zone by zone in the game's own color
# order, each zone's squares in Config.config_locations order, then the
# bullseye. `relative_index` counts zones from a piece's own instead, which is
# how SquareValues is laid out: every color sees the same board from home.
import Config
import Type

Board :: [].{
	## A square no piece of this color can reach.
	far : I64
	far = 1000

	per_zone : U64
	per_zone = List.len(Config.config_locations)

	all_locs : List(Str) -> List(Type.PieceLocation)
	all_locs = |zone_colors|
		List.append(
			List.join_map(zone_colors, |color| List.map(Config.config_locations, |l| { zone: NormalColor(color), id: l.id })),
			{ zone: BullsEyeZone, id: "bullseye" },
		)

	square_of : Str -> U64
	square_of = |id| List.find_first_index(Config.config_locations, |l| l.id == id) ?? crash("Board: no square ${id}")

	zone_of : List(Str), Str -> U64
	zone_of = |zone_colors, color| List.find_first_index(zone_colors, |c| c == color) ?? crash("Board: no zone ${color}")

	index_of : List(Str), Type.PieceLocation -> U64
	index_of = |zone_colors, loc|
		match loc.zone {
			BullsEyeZone => List.len(zone_colors) * per_zone
			NormalColor(color) => zone_of(zone_colors, color) * per_zone + square_of(loc.id)
		}

	## The square as a piece of `color` sees it: its own zone first.
	relative_index : List(Str), Str, Type.PieceLocation -> U64
	relative_index = |zone_colors, color, loc| {
		n = List.len(zone_colors)
		match loc.zone {
			BullsEyeZone => n * per_zone
			NormalColor(zone) => U64.rem_by(zone_of(zone_colors, zone) + n - zone_of(zone_colors, color), n) * per_zone + square_of(loc.id)
		}
	}

	## A piece of `color` moving with every freedom a card can give.
	free_params : List(Str), Str, Bool -> Type.FindLocParams
	free_params = |zone_colors, color, on_fast_track| {
		reverse_mode: Bool.False,
		can_fast_track: on_fast_track,
		can_leave_pen: Bool.True,
		can_leave_bulls_eye: Bool.True,
		piece_color: color,
		piece_map: [],
		zone_colors,
	}
}

expect {
	colors = ["red", "blue", "green", "purple"]
	Board.relative_index(colors, "blue", { zone: NormalColor("blue"), id: "HP1" }) == 0
	and Board.relative_index(colors, "blue", { zone: NormalColor("red"), id: "HP1" }) == 3 * Board.per_zone
	and Board.relative_index(colors, "red", { zone: NormalColor("green"), id: "L0" }) == Board.index_of(colors, { zone: NormalColor("green"), id: "L0" })
}
