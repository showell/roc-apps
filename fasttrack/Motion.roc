# Motion -- what moved in one update, square by square, for the page to
# animate: the moving piece along the walk it took, then any piece it sent
# back to the pen, or the piece a jack traded with. A piece brought out of
# the pen by discard credits steps from the pen to L0.
import Board
import Config
import Game
import History
import LegalMove
import Move
import Piece
import Player
import Type

Motion :: [].{
	Motion : { color : Str, path : List(U64) }

	## The motions of `msg`, which took `before` to `after`.
	of : Type.Game, Type.GameMsg, Type.Game -> List(Motion.Motion)
	of = |before, msg, after| {
		name = |c| List.get(before.zone_colors, c) ?? "black"
		moves = Move.made(before, msg)
		if List.is_empty(moves) {
			brought_out(before, after, name)
		} else {
			List.join_map(moves, |m| of_move(before.board, m, name))
		}
	}

	of_move : Type.Board, Type.Move, (U64 -> Str) -> List(Motion.Motion)
	of_move = |board, m, name|
		match Piece.at(board, m.start) {
			Err(_) => []
			Ok(c) => {
				hit = Piece.at(board, m.end)
				match m.kind {
					JackTrade =>
						match hit {
							Ok(other) => [{ color: name(c), path: [m.start, m.end] }, { color: name(other), path: [m.end, m.start] }]
							Err(_) => [{ color: name(c), path: [m.start, m.end] }]
						}
					_ => {
						(n, reverse) = match m.kind {
							WithCard(card) => (Config.move_count_for_card(card, Board.is_pen(m.start)), card == "4")
							Reverse(card) => (Config.move_count_for_card(card, Board.is_pen(m.start)), Bool.True)
							StartSplit(k) => (k, Bool.False)
							FinishSplit(k, _) => (k, Bool.False)
							JackTrade => (1, Bool.False)
						}
						walked = { color: name(c), path: LegalMove.walk_between(board, c, m.start, m.end, n, reverse) }
						List.concat([walked], sent_home(board, m.end, name))
					}
				}
			}
		}

	## A piece on `s` sent back to the first open square of its pen.
	sent_home : Type.Board, U64, (U64 -> Str) -> List(Motion.Motion)
	sent_home = |board, s, name|
		match Piece.at(board, s) {
			Ok(victim) => [{ color: name(victim), path: [s, Piece.open_holding_pen_location(board, victim)] }]
			Err(_) => []
		}

	## Discard credits bring the active player's last pen piece out to L0.
	brought_out : Type.Game, Type.Game, (U64 -> Str) -> List(Motion.Motion)
	brought_out = |before, after, name|
		if before.board == after.board {
			[]
		} else {
			c = before.active_player_idx
			l0 = Board.at(c, Board.l0)
			match Piece.piece_to_move_out_of_pen(before.board, c) {
				Ok(pen) => List.concat([{ color: name(c), path: [pen, l0] }], sent_home(before.board, l0, name))
				Err(_) => []
			}
		}
}

## A game for one with only these pieces, red to play these cards, the
## first of them already chosen.
test_game : List((Str, Str, Str)), List(Str) -> Type.Game
test_game = |pieces, hand| {
	start = Game.begin_game(0, Normal, Solo)
	players = Player.update_player(start.players, 0, |p| { ..p, hand, turn: TurnBegin })
	ready = Player.set_turn_to_need_card({ ..start, board: Piece.board_of(start.zone_colors, pieces), players })
	Game.update_game(ActivateCard(0), History.init, ready).1
}

## What a click at `s` moves.
motions_at : Type.Game, U64 -> List(Motion.Motion)
motions_at = |g, s| Motion.of(g, SetStartLocation(s), Game.update_game(SetStartLocation(s), History.init, g).1)

# A 3 walks red's piece from L0 up to L3, square by square.
expect {
	g = test_game([("red", "L0", "red")], ["3"])
	motions_at(g, Board.at(0, Board.l0)) == [{ color: "red", path: [11, 12, 13, 14] }]
}

# Landing on blue sends blue back to its pen's first open square.
expect {
	g = test_game([("red", "L0", "red"), ("red", "L2", "blue")], ["2"])
	motions_at(g, Board.at(0, Board.l0)) == [{ color: "red", path: [11, 12, 13] }, { color: "blue", path: [13, Board.at(1, 0)] }]
}

# A jack trades: each piece goes to the other's square.
expect {
	g = test_game([("red", "L0", "red"), ("red", "L3", "blue")], ["J"])
	end_click = Game.update_game(SetStartLocation(Board.at(0, Board.l0)), History.init, g).1
	Motion.of(end_click, SetEndLocation(Board.at(0, 14)), Game.update_game(SetEndLocation(Board.at(0, 14)), History.init, end_click).1)
	== [{ color: "red", path: [11, 14] }, { color: "blue", path: [14, 11] }]
}
