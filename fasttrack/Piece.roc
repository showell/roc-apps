# Piece -- the pieces on the board: finding them and moving them, from
# Piece.elm.
import Assoc
import Config
import Setup
import Type

Piece :: [].{
	fake_location : Type.PieceLocation
	fake_location = { zone: NormalColor("bogus"), id: "bogus" }

	get_piece : Type.PieceMap, Type.PieceLocation -> Try(Str, [NotFound])
	get_piece = |piece_map, piece_loc| Assoc.dict_get(piece_map, piece_loc)

	## Only for a location known to hold a piece: a move already validated.
	get_the_piece : Type.PieceMap, Type.PieceLocation -> Str
	get_the_piece = |piece_map, piece_loc| Assoc.dict_get(piece_map, piece_loc) ?? "bogus"

	is_open_location : Type.PieceMap, Type.PieceLocation -> Bool
	is_open_location = |piece_map, piece_loc| Try.is_err(get_piece(piece_map, piece_loc))

	## The LAST occupied pen square: the one a piece leaves the pen from.
	piece_to_move_out_of_pen : Type.PieceMap, Str -> Try(Type.PieceLocation, [NotFound])
	piece_to_move_out_of_pen = |piece_map, color|
		match List.find_last(Config.holding_pen_locations, |id| Try.is_ok(get_piece(piece_map, { zone: NormalColor(color), id }))) {
			Ok(id) => Ok({ zone: NormalColor(color), id })
			Err(_) => Err(NotFound)
		}

	## Only when a piece is being sent home, so there is always a square.
	open_holding_pen_location : Type.PieceMap, Str -> Type.PieceLocation
	open_holding_pen_location = |piece_map, color|
		match List.find_first(Config.holding_pen_locations, |id| is_open_location(piece_map, { zone: NormalColor(color), id })) {
			Ok(id) => { zone: NormalColor(color), id }
			Err(_) => fake_location
		}

	is_color : Type.PieceMap, Str, Type.PieceLocation -> Bool
	is_color = |piece_map, color, loc| Assoc.dict_get(piece_map, loc) == Ok(color)

	is_normal_loc : Type.PieceLocation -> Bool
	is_normal_loc = |loc| !Config.is_holding_pen_id(loc.id) and !Config.is_base_id(loc.id)

	swappable_locs : Type.PieceMap, Str -> Assoc.AssocSet(Type.PieceLocation)
	swappable_locs = |piece_map, active_color|
		Assoc.set_from_list(
			Assoc.dict_keys(piece_map)
			.keep_if(|loc| !is_color(piece_map, active_color, loc))
			.keep_if(is_normal_loc),
		)

	my_pieces : Type.PieceMap, Str -> Assoc.AssocSet(Type.PieceLocation)
	my_pieces = |piece_map, active_color|
		Assoc.set_from_list(List.keep_if(Assoc.dict_keys(piece_map), |loc| is_color(piece_map, active_color, loc)))

	## Every piece of this color that can move, counting the pen once.
	movable_pieces : Type.PieceMap, Str -> Assoc.AssocSet(Type.PieceLocation)
	movable_pieces = |piece_map, color| {
		pieces = non_pen_pieces(piece_map, color)
		match piece_to_move_out_of_pen(piece_map, color) {
			Ok(pen_loc) => Assoc.set_insert(pieces, pen_loc)
			Err(_) => pieces
		}
	}

	non_pen_pieces : Type.PieceMap, Str -> Assoc.AssocSet(Type.PieceLocation)
	non_pen_pieces = |piece_map, active_color|
		List.keep_if(my_pieces(piece_map, active_color), |loc| !Config.is_holding_pen_id(loc.id))

	other_non_pen_pieces : Type.PieceMap, Str, Type.PieceLocation -> Assoc.AssocSet(Type.PieceLocation)
	other_non_pen_pieces = |piece_map, active_color, loc|
		Assoc.set_remove(non_pen_pieces(piece_map, active_color), loc)

	## A piece on the fast track must be moved before any other: across every
	## color the player moves, which in a partnership is the team.
	any_on_fast_track : Type.PieceMap, List(Str) -> Bool
	any_on_fast_track = |piece_map, movers| List.any(movers, |color| has_piece_on_fast_track(piece_map, color))

	team_movable_pieces : Type.PieceMap, List(Str) -> Assoc.AssocSet(Type.PieceLocation)
	team_movable_pieces = |piece_map, movers| List.join_map(movers, |color| movable_pieces(piece_map, color))

	team_other_non_pen_pieces : Type.PieceMap, List(Str), Type.PieceLocation -> Assoc.AssocSet(Type.PieceLocation)
	team_other_non_pen_pieces = |piece_map, movers, loc| List.join_map(movers, |color| other_non_pen_pieces(piece_map, color, loc))

	## Every base square of `color` holds a piece of its own.
	all_home : Type.PieceMap, Str -> Bool
	all_home = |piece_map, color| List.all(Config.base_locations, |id| get_piece(piece_map, { zone: NormalColor(color), id }) == Ok(color))

	has_piece_on_fast_track : Type.PieceMap, Str -> Bool
	has_piece_on_fast_track = |piece_map, active_color|
		List.any(my_pieces(piece_map, active_color), |loc| loc.id == "FT")

	config_pieces : Setup.InitSetup, List(Str) -> Type.PieceMap
	config_pieces = |init_setup, zone_colors|
		List.fold(
			zone_colors,
			[],
			|piece_map, color|
				List.fold(Setup.starting_locations(init_setup, color), piece_map, |pm, loc| Assoc.dict_insert(pm, loc, color)),
		)

	bring_player_out : Str, Type.PieceMap -> Type.PieceMap
	bring_player_out = |color, piece_map|
		match piece_to_move_out_of_pen(piece_map, color) {
			# probably a bug
			Err(_) => piece_map
			Ok(start_loc) => execute_move(RegularMove, start_loc, { zone: NormalColor(color), id: "L0" }, piece_map)
		}

	move_piece : Type.Move, Type.PieceMap -> Type.PieceMap
	move_piece = |move, piece_map| {
		flavor = match move.kind {
			JackTrade => TradePieces
			_ => RegularMove
		}
		execute_move(flavor, move.start, move.end, piece_map)
	}

	## A piece landing on another either trades places with it (a jack's
	## trade) or sends it back to its own pen.
	execute_move : Type.MoveFlavor, Type.PieceLocation, Type.PieceLocation, Type.PieceMap -> Type.PieceMap
	execute_move = |flavor, start_loc, end_loc, piece_map| {
		start_color = get_the_piece(piece_map, start_loc)
		match get_piece(piece_map, end_loc) {
			Ok(end_color) =>
				if flavor == TradePieces {
					Assoc.dict_insert(Assoc.dict_insert(piece_map, start_loc, end_color), end_loc, start_color)
				} else {
					pen_loc = open_holding_pen_location(piece_map, end_color)
					sent_home = Assoc.dict_insert(piece_map, pen_loc, end_color)
					Assoc.dict_insert(Assoc.dict_remove(sent_home, start_loc), end_loc, start_color)
				}
			Err(_) =>
				Assoc.dict_insert(Assoc.dict_remove(piece_map, start_loc), end_loc, start_color)
		}
	}
}
