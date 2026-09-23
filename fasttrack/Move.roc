# Move -- carrying out a move and what follows it, from Move.elm.
import Board
import Config
import Piece
import Player
import Type

Move :: [].{
	perform_move : Type.Move, Type.Game -> Type.Game
	perform_move = |move, game|
		if Piece.is_open(game.board, move.start) {
			game
		} else {
			board = Piece.move_piece(move, game.board)
			moved = Player.ensure_hand_not_empty({ ..game, board })
			Player.update_active_player(|p| Player.finish_move(board, game.zone_colors, move, p), moved)
		}

	## A piece with exactly one place to go goes there; with several, the
	## player picks.
	maybe_auto_move : U64, Type.Game -> Type.Game
	maybe_auto_move = |start_loc, game| {
		active_player = Player.get_active_player(game)
		match Player.end_locs_for_player(active_player) {
			[end_loc] => move_to_end_loc(active_player, start_loc, end_loc, game)
			_ => game
		}
	}

	maybe_get_out_via_discard : Type.Game -> Type.Game
	maybe_get_out_via_discard = |game| {
		player = Player.get_active_player(game)
		if player.get_out_credits < Config.num_credits_to_get_out {
			game
		} else {
			Player.update_active_player(Player.clear_credits, { ..game, board: Piece.bring_player_out(Board.color_index(game.zone_colors, player.color), game.board) })
		}
	}

	move_to_end_loc : Type.Player, U64, U64, Type.Game -> Type.Game
	move_to_end_loc = |active_player, start_loc, end_loc, game|
		match Player.get_player_move_type(active_player, end_loc) {
			Ok(kind) => perform_move({ kind, start: start_loc, end: end_loc }, game)
			# a programming error
			Err(_) => game
		}

	## The moves one message makes: an end click's, or a start click's when
	## that piece has only one place to go (maybe_auto_move).
	made : Type.Game, Type.GameMsg -> List(Type.Move)
	made = |game, msg|
		match (Player.get_active_player(game).turn, msg) {
			(TurnNeedStartLoc(info), SetStartLocation(start)) => {
				from = List.keep_if(info.moves, |m| m.start == start)
				match from {
					[first, ..] if List.all(from, |m| m.end == first.end) => [first]
					_ => []
				}
			}
			(TurnNeedEndLoc(info), SetEndLocation(end)) => {
				match List.find_first(info.moves, |m| m.start == info.start_location and m.end == end) {
					Ok(m) => [m]
					Err(_) => []
				}
			}
			_ => []
		}
}
