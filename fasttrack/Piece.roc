# Piece -- the pieces on the board: finding them and moving them, from
# Piece.elm, over square numbers (Board.roc). A color is its place in the
# game's color order (Board.color_index).
import Board
import Setup
import Type

Piece :: [].{
	empty : Type.Board
	empty = List.repeat(0, Board.count)

	## Who stands on `s`.
	at : Type.Board, U64 -> Try(U64, [NotFound])
	at = |board, s|
		match List.get(board, s) {
			Ok(v) if v > 0 => Ok(U8.to_u64(v) - 1)
			_ => Err(NotFound)
		}

	is_open : Type.Board, U64 -> Bool
	is_open = |board, s| (List.get(board, s) ?? 0) == 0

	holds : Type.Board, U64, U64 -> Bool
	holds = |board, s, c| (List.get(board, s) ?? 0) == U64.to_u8_wrap(c + 1)

	place : Type.Board, U64, U64 -> Type.Board
	place = |board, s, c| List.set(board, s, U64.to_u8_wrap(c + 1)) ?? board

	clear : Type.Board, U64 -> Type.Board
	clear = |board, s| List.set(board, s, 0) ?? board

	## The color on `s`, by name, for the page.
	get_piece : Type.Board, List(Str), U64 -> Try(Str, [NotFound])
	get_piece = |board, zone_colors, s|
		match at(board, s) {
			Ok(c) => Ok(List.get(zone_colors, c) ?? "bogus")
			Err(_) => Err(NotFound)
		}

	## The LAST occupied pen square: the one a piece leaves the pen from.
	piece_to_move_out_of_pen : Type.Board, U64 -> Try(U64, [NotFound])
	piece_to_move_out_of_pen = |board, c|
		match List.find_last(Board.pen_of(c), |s| !is_open(board, s)) {
			Ok(s) => Ok(s)
			Err(_) => Err(NotFound)
		}

	## Only when a piece is being sent home, so there is always a square.
	open_holding_pen_location : Type.Board, U64 -> U64
	open_holding_pen_location = |board, c| List.find_first(Board.pen_of(c), |s| is_open(board, s)) ?? crash("Piece: no open pen square")

	## Every piece of another color on the open track (the bullseye too): the
	## squares a jack may trade with.
	swappable_locs : Type.Board, U64 -> List(U64)
	swappable_locs = |board, c| List.keep_if(Board.squares, |s| Board.is_track(s) and !is_open(board, s) and !holds(board, s, c))

	my_pieces : Type.Board, U64 -> List(U64)
	my_pieces = |board, c| List.keep_if(Board.squares, |s| holds(board, s, c))

	## Every piece of this color that can move, counting the pen once.
	movable_pieces : Type.Board, U64 -> List(U64)
	movable_pieces = |board, c| {
		pieces = non_pen_pieces(board, c)
		match piece_to_move_out_of_pen(board, c) {
			Ok(pen) => List.prepend(pieces, pen)
			Err(_) => pieces
		}
	}

	non_pen_pieces : Type.Board, U64 -> List(U64)
	non_pen_pieces = |board, c| List.drop_if(my_pieces(board, c), Board.is_pen)

	other_non_pen_pieces : Type.Board, U64, U64 -> List(U64)
	other_non_pen_pieces = |board, c, s| List.drop_if(non_pen_pieces(board, c), |x| x == s)

	fast_track_squares : List(U64)
	fast_track_squares = [Board.at(0, Board.ft), Board.at(1, Board.ft), Board.at(2, Board.ft), Board.at(3, Board.ft)]

	## A piece on the fast track must be moved before any other: across every
	## color the player moves, which in a partnership is the team.
	any_on_fast_track : Type.Board, List(U64) -> Bool
	any_on_fast_track = |board, movers| List.any(fast_track_squares, |s| List.any(movers, |c| holds(board, s, c)))

	has_piece_on_fast_track : Type.Board, U64 -> Bool
	has_piece_on_fast_track = |board, c| any_on_fast_track(board, [c])

	team_movable_pieces : Type.Board, List(U64) -> List(U64)
	team_movable_pieces = |board, movers| List.join_map(movers, |c| movable_pieces(board, c))

	team_other_non_pen_pieces : Type.Board, List(U64), U64 -> List(U64)
	team_other_non_pen_pieces = |board, movers, s| List.join_map(movers, |c| other_non_pen_pieces(board, c, s))

	## Every base square of `c` holds a piece of its own.
	all_home : Type.Board, U64 -> Bool
	all_home = |board, c| List.all(Board.base_of(c), |s| holds(board, s, c))

	## A color's pieces in its own base.
	in_base : Type.Board, U64 -> U64
	in_base = |board, c| List.count_if(Board.base_of(c), |s| holds(board, s, c))

	## A color's pieces in its pen.
	in_pen : Type.Board, U64 -> U64
	in_pen = |board, c| List.count_if(Board.pen_of(c), |s| holds(board, s, c))

	config_pieces : Setup.InitSetup, List(Str) -> Type.Board
	config_pieces = |init_setup, zone_colors|
		List.fold(
			List.map_with_index(zone_colors, |_, c| c),
			empty,
			|board, c| List.fold(Setup.starting_locations(init_setup), board, |b, id| place(b, Board.at(c, Board.square_of(id)), c)),
		)

	bring_player_out : U64, Type.Board -> Type.Board
	bring_player_out = |c, board|
		match piece_to_move_out_of_pen(board, c) {
			# probably a bug
			Err(_) => board
			Ok(start) => execute_move(RegularMove, start, Board.at(c, Board.l0), board)
		}

	move_piece : Type.Move, Type.Board -> Type.Board
	move_piece = |move, board| {
		flavor = match move.kind {
			JackTrade => TradePieces
			_ => RegularMove
		}
		execute_move(flavor, move.start, move.end, board)
	}

	## A piece landing on another either trades places with it (a jack's
	## trade) or sends it back to its own pen.
	execute_move : Type.MoveFlavor, U64, U64, Type.Board -> Type.Board
	execute_move = |flavor, start, end, board| {
		start_c = at(board, start) ?? crash("Piece.execute_move: no piece to move")
		match at(board, end) {
			Ok(end_c) =>
				if flavor == TradePieces {
					place(place(board, start, end_c), end, start_c)
				} else {
					pen = open_holding_pen_location(board, end_c)
					sent_home = place(board, pen, end_c)
					place(clear(sent_home, start), end, start_c)
				}
			Err(_) => place(clear(board, start), end, start_c)
		}
	}

	## A board with these pieces, each `(zone, id, color)` by name: for the
	## tests.
	board_of : List(Str), List((Str, Str, Str)) -> Type.Board
	board_of = |zone_colors, pieces|
		List.fold(
			pieces,
			empty,
			|b, (zone, id, color)| {
				s = if zone == "BE" { Board.bullseye } else { Board.at(Board.color_index(zone_colors, zone), Board.square_of(id)) }
				place(b, s, Board.color_index(zone_colors, color))
			},
		)
}
