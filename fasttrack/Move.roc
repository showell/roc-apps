# Move -- carrying out a move and what follows it, from Move.elm.
import Config
import Piece
import Player
import Type

Move :: [].{
	perform_move : Type.Move, Type.Game -> Type.Game
	perform_move = |move, game|
		match Piece.get_piece(game.piece_map, move.start) {
			Err(_) => game
			Ok(_) => {
				new_piece_map = Piece.move_piece(move, game.piece_map)
				moved = Player.ensure_hand_not_empty({ ..game, piece_map: new_piece_map })
				Player.update_active_player(|p| Player.finish_move(new_piece_map, game.zone_colors, move, p), moved)
			}
		}

	## A piece with exactly one place to go goes there; with several, the
	## player picks.
	maybe_auto_move : Type.PieceLocation, Type.Game -> Type.Game
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
			Player.update_active_player(Player.clear_credits, { ..game, piece_map: Piece.bring_player_out(player.color, game.piece_map) })
		}
	}

	move_to_end_loc : Type.Player, Type.PieceLocation, Type.PieceLocation, Type.Game -> Type.Game
	move_to_end_loc = |active_player, start_loc, end_loc, game|
		match Player.get_player_move_type(active_player, end_loc) {
			Ok(kind) => perform_move({ kind, start: start_loc, end: end_loc }, game)
			# a programming error
			Err(_) => game
		}
}
