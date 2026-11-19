# Motion -- what moved in one update, square by square, for the page to
# animate: the moving piece along the walk it took, then any piece it sent
# back to the pen (`sent_home`: it stays put until the mover lands on it,
# then goes home at once), or the piece a jack traded with. A piece brought
# out of the pen by discard credits steps from the pen to L0.
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
	Motion : {
		color : Str,
		path : List(U64),
		sent_home : Bool,
	}

	## The motions of `msg`, which took `before` to `after`.
	motions_of : Type.Game, Type.GameMsg, Type.Game -> List(Motion.Motion)
	motions_of = |before, msg, after| {
		name = |c| before.zone_colors.get(c) ?? crash "Motion.motions_of: a piece of a color the game has"
		match msg {
			# Only a discard can bring a piece out; an undo moves nothing on
			# the page, it just shows the earlier board.
			DiscardCard(_) => brought_out_motions(before, after, name)
			_ => Move.moves_made(before, msg).join_map(|m| motions_of_move(before.board, m, name))
		}
	}

	motions_of_move : Type.Board, Type.Move, (U64 -> Str) -> List(Motion.Motion)
	motions_of_move = |board, m, name|
		match Piece.color_at(board, m.start) {
			Err(_) => []
			Ok(c) => {
				hit = Piece.color_at(board, m.end)
				match m.kind {
					JackTrade =>
						match hit {
							Ok(other) => [
								{
									color: name(c),
									path: [m.start, m.end],
									sent_home: Bool.False,
								},
								{
									color: name(other),
									path: [m.end, m.start],
									sent_home: Bool.False,
								},
							]
							Err(_) => [
								{
									color: name(c),
									path: [m.start, m.end],
									sent_home: Bool.False,
								},
							]
						}
					_ => {
						(n, direction) = match m.kind {
							WithCard(card) => (
								Config.move_count_for_card(card, Board.is_pen(m.start)),
								if card == "4" {
									Backward
								} else {
									Forward
								},
							)
							Reverse(card) => (
								Config.move_count_for_card(card, Board.is_pen(m.start)),
								Backward,
							)
							StartSplit(k) => (k, Forward)
							FinishSplit(k, _) => (k, Forward)
							JackTrade => (1, Forward)
						}
						walked = {
							color: name(c),
							path: LegalMove.squares_between(
								board,
								c,
								m.start,
								m.end,
								n,
								direction,
							),
							sent_home: Bool.False,
						}
						List.concat([walked], sent_home_motions(board, m.end, name))
					}
				}
			}
		}

	## A piece on `s` sent back to the first open square of its pen.
	sent_home_motions : Type.Board, U64, (U64 -> Str) -> List(Motion.Motion)
	sent_home_motions = |board, s, name|
		match Piece.color_at(board, s) {
			Ok(victim) => [
				{
					color: name(victim),
					path: [s, Piece.open_holding_pen_location(board, victim)],
					sent_home: Bool.True,
				},
			]
			Err(_) => []
		}

	## Discard credits bring the active player's last pen piece out to L0.
	brought_out_motions : Type.Game, Type.Game, (U64 -> Str) -> List(Motion.Motion)
	brought_out_motions = |before, after, name|
		if before.board == after.board {
			[]
		} else {
			c = before.active_player_idx
			l0 = Board.square_at(c, Board.l0)
			match Piece.piece_to_move_out_of_pen(before.board, c) {
				Ok(pen) => List.concat(
					[
						{
							color: name(c),
							path: [pen, l0],
							sent_home: Bool.False,
						},
					],
					sent_home_motions(before.board, l0, name),
				)
				Err(_) => []
			}
		}
}

## A game for one with only these pieces, red to play these cards, the
## first of them already chosen.
test_game : List((Str, Str, Str)), List(Str) -> Type.Game
test_game = |pieces, hand| {
	start = Game.begin_game(0, Normal, Solo)
	players = Player.update_player(
		start.players,
		0,
		|p| { ..p, hand, turn: TurnBegin },
	)
	ready = Player.set_turn_to_need_card({
		..start,
		board: Piece.board_of(start.zone_colors, pieces),
		players,
	})
	Game.update_game(ActivateCard(0), History.init({}), ready).1
}

## What a click at `s` moves.
click_motions : Type.Game, U64 -> List(Motion.Motion)
click_motions = |g, s| Motion.motions_of(
	g,
	SetStartLocation(s),
	Game.update_game(SetStartLocation(s), History.init({}), g).1,
)

# A 3 walks red's piece from L0 up to L3, square by square.
expect {
	g = test_game([("red", "L0", "red")], ["3"])
	click_motions(g, Board.square_at(0, Board.l0)) == [{ color: "red", path: [11, 12, 13, 14], sent_home: Bool.False }]
}

# Landing on blue sends blue back to its pen's first open square.
expect {
	g = test_game([("red", "L0", "red"), ("red", "L2", "blue")], ["2"])
	click_motions(g, Board.square_at(0, Board.l0)) == [{ color: "red", path: [11, 12, 13], sent_home: Bool.False }, { color: "blue", path: [13, Board.square_at(1, 0)], sent_home: Bool.True }]
}

# A jack trades: each piece goes to the other's square.
expect {
	g = test_game([("red", "L0", "red"), ("red", "L3", "blue")], ["J"])
	end_click = Game.update_game(
		SetStartLocation(Board.square_at(0, Board.l0)),
		History.init({}),
		g,
	).1
	Motion.motions_of(
		end_click,
		SetEndLocation(Board.square_at(0, 14)),
		Game.update_game(
			SetEndLocation(Board.square_at(0, 14)),
			History.init({}),
			end_click,
		).1,
	)
		== [{ color: "red", path: [11, 14], sent_home: Bool.False }, { color: "blue", path: [14, 11], sent_home: Bool.False }]
}

# An undo moves nothing on the page, even when the board it restores differs.
expect {
	g = test_game([("red", "L0", "red"), ("red", "HP1", "red")], ["3"])
	moved = Game.update_game(
		SetStartLocation(Board.square_at(0, Board.l0)),
		History.init({}),
		g,
	).1
	Motion.motions_of(moved, UndoAction, g) == []
}
