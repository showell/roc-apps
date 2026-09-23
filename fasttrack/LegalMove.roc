# LegalMove -- every move a card allows, from LegalMove.elm.
#
# A move is a walk from a square: Routes holds every walk of every length,
# as a piece sees the board from its own zone, and the board says which are
# open -- a piece may not pass or land on its own color. A card says whether
# a walk may leave the pen (an A, joker or 6) or the bullseye (a J, Q or K),
# and a walk starting on a fast-track square may take the fast track.
#
# `movers` are the colors whose pieces the player may move (Player.movers):
# one in a game for one, two in a partnership. Each piece walks its own
# color's way home; the fast track's obligation and the split seven's second
# piece are the movers' together.
#
# The order moves are listed in is Elm's where it decides anything: a split
# seven's partial moves before its full ones, a jack's step before its
# trades (Player.get_player_move_type takes the first of two).
import Board
import Config
import Piece
import Routes
import Type

LegalMove :: [].{
	## Where the piece of color `c` on `start` lands after `n` steps: once
	## for every open walk, in Routes' order.
	ends : Type.Board, U64, U64, I64, Bool, Bool, Bool -> List(U64)
	ends = |board, c, start, n, reverse, leave_pen, leave_bulls|
		if n <= 0 or n > 10 {
			[]
		} else if !reverse and ((Board.is_pen(start) and !leave_pen) or (start == Board.bullseye and !leave_bulls)) {
			[]
		} else {
			r = Board.relative(c, start)
			walks = if reverse { Routes.backward_walks(r, I64.to_u64_wrap(n)) } else { Routes.forward_walks(r, I64.to_u64_wrap(n)) }
			List.join_map(
				walks,
				|walk|
					if List.any(walk, |x| Piece.holds(board, Board.absolute(c, x), c)) {
						[]
					} else {
						[Board.absolute(c, List.last(walk) ?? crash("LegalMove: an empty walk"))]
					},
			)
		}

	## Whether the piece on `s` can go `n` more squares, for the second part
	## of a split seven: no leaving the pen or the bullseye.
	get_can_go_n_spaces : Type.Board, U64, List(Str), I64, List(Str) -> Bool
	get_can_go_n_spaces = |board, s, zone_colors, n, movers| can_go(board, s, n, List.map(movers, |m| Board.color_index(zone_colors, m)))

	can_go : Type.Board, U64, I64, List(U64) -> Bool
	can_go = |board, s, n, movers|
		match Piece.at(board, s) {
			Err(_) => Bool.False
			Ok(c) =>
				if Board.is_ft(s) or !Piece.any_on_fast_track(board, movers) {
					!List.is_empty(ends(board, c, s, n, Bool.False, Bool.False, Bool.False))
				} else {
					Bool.False
				}
		}

	## Every forward move the hand allows; when there is none, every move
	## backwards instead.
	get_moves_for_cards : List(Str), Type.Board, List(Str), List(Str) -> List(Type.Move)
	get_moves_for_cards = |cards, board, zone_colors, movers| {
		m = List.map(movers, |c| Board.color_index(zone_colors, c))
		moves_for = |make_move_type| List.join_map(cards, |card| moves_for_type(make_move_type(card), board, m))
		forward_moves = moves_for(|card| if card == "4" { Reverse(card) } else { WithCard(card) })
		if List.is_empty(forward_moves) {
			moves_for(|card| Reverse(card))
		} else {
			forward_moves
		}
	}

	get_moves_for_move_type : Type.MoveType, Type.Board, List(Str), List(Str) -> List(Type.Move)
	get_moves_for_move_type = |move_type, board, zone_colors, movers| moves_for_type(move_type, board, List.map(movers, |c| Board.color_index(zone_colors, c)))

	moves_for_type : Type.MoveType, Type.Board, List(U64) -> List(Type.Move)
	moves_for_type = |move_type, board, movers| {
		starts = match move_type {
			FinishSplit(_, exclude) => Piece.team_other_non_pen_pieces(board, movers, exclude)
			_ => Piece.team_movable_pieces(board, movers)
		}
		List.join_map(starts, |start| moves_from(move_type, board, start, movers))
	}

	get_moves_from_location : Type.MoveType, Type.Board, List(Str), U64, List(Str) -> List(Type.Move)
	get_moves_from_location = |move_type, board, zone_colors, start, movers| moves_from(move_type, board, start, List.map(movers, |c| Board.color_index(zone_colors, c)))

	moves_from : Type.MoveType, Type.Board, U64, List(U64) -> List(Type.Move)
	moves_from = |move_type, board, start, movers|
		match Piece.at(board, start) {
			Err(_) => []
			Ok(c) =>
				if Board.is_ft(start) or !Piece.any_on_fast_track(board, movers) {
					card = get_card_for_move_type(move_type)
					reverse = match move_type {
						Reverse(_) => Bool.True
						_ => card == "4"
					}
					leave_pen = List.contains(["A", "joker", "6"], card)
					leave_bulls = List.contains(["J", "Q", "K"], card) and start == Board.bullseye
					n = move_count_for_move_type(move_type, Board.is_pen(start))
					if move_type == WithCard("7") {
						moves_for_seven(board, c, start, movers)
					} else if move_type == WithCard("J") {
						steps = List.map(ends(board, c, start, 1, reverse, leave_pen, leave_bulls), |end| { kind: WithCard("J"), start, end })
						trades = if Board.is_track(start) { List.map(Piece.swappable_locs(board, c), |end| { kind: JackTrade, start, end }) } else { [] }
						List.concat(steps, trades)
					} else {
						List.map(ends(board, c, start, n, reverse, leave_pen, leave_bulls), |end| { kind: move_type, start, end })
					}
				} else {
					[]
				}
		}

	## A seven moves one piece seven, or splits between two: the first part
	## is offered only if some other piece can then finish the split, and
	## never onto the bullseye.
	moves_for_seven : Type.Board, U64, U64, List(U64) -> List(Type.Move)
	moves_for_seven = |board, c, start, movers| {
		full = List.map(ends(board, c, start, 7, Bool.False, Bool.False, Bool.False), |end| { kind: WithCard("7"), start, end })
		others = Piece.team_other_non_pen_pieces(board, movers, start)
		if List.is_empty(others) {
			full
		} else {
			partial = List.join_map(
				[1, 2, 3, 4, 5, 6],
				|count| {
					candidates = List.map(List.drop_if(ends(board, c, start, count, Bool.False, Bool.False, Bool.False), |end| end == Board.bullseye), |end| { kind: StartSplit(count), start, end })
					List.keep_if(candidates, |move| can_finish_split(board, others, 7 - count, move, movers))
				},
			)
			List.concat(partial, full)
		}
	}

	can_finish_split : Type.Board, List(U64), I64, Type.Move, List(U64) -> Bool
	can_finish_split = |board, others, count, move, movers| {
		moved = Piece.move_piece(move, board)
		List.any(others, |other| can_go(moved, other, count, movers))
	}

	get_card_for_play_type : Type.PlayType -> Str
	get_card_for_play_type = |play_type|
		match play_type {
			PlayCard(card) => card
			FinishSeven(_) => "7"
		}

	get_card_for_move_type : Type.MoveType -> Str
	get_card_for_move_type = |move_type|
		match move_type {
			WithCard(card) => card
			Reverse(card) => card
			StartSplit(_) => "7"
			FinishSplit(_, _) => "7"
			JackTrade => "J"
		}

	move_count_for_move_type : Type.MoveType, Bool -> I64
	move_count_for_move_type = |move_type, in_pen|
		match move_type {
			WithCard(card) => Config.move_count_for_card(card, in_pen)
			Reverse(card) => Config.move_count_for_card(card, in_pen)
			StartSplit(count) => count
			FinishSplit(count, _) => count
			# never asked of a trade
			JackTrade => 0
		}

}
