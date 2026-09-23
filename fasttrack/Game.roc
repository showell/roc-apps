# Game -- beginning a game and answering a message, from Game.elm.
#
# Undo: history is reset AFTER the board rotates to the next player; a card
# played saves the state from BEFORE it; moving pieces saves nothing in
# between. So "oops" takes back the last card and everything it caused.
#
# Elm's `beginActiveTurn` also ran WhatIf.debugWhatIf, which only logged; the
# computer player is Agent.roc. Elm never said who won; `winner` does.
import Color
import Config
import History
import Move
import Piece
import Player
import Setup
import Type

Game :: [].{
	num_players : U64
	num_players = 4

	begin_game : U64, Setup.InitSetup, Type.Teams -> Type.Game
	begin_game = |millis, init_setup, teams| {
		zone_colors = Color.get_zone_colors(num_players)
		begin_active_turn(
			{
				zone_colors,
				piece_map: Piece.config_pieces(init_setup, zone_colors),
				players: Player.config_players(init_setup, zone_colors, teams, millis),
				active_player_idx: 0,
				num_players,
			},
		)
	}

	update_game : Type.GameMsg, History.History(Type.Game), Type.Game -> (History.History(Type.Game), Type.Game)
	update_game = |msg, history, game| {
		save_prior = |new_game| (History.update(history, game), new_game)
		match msg {
			UndoAction => History.undo(history, game)
			ActivateCard(idx) => save_prior(Player.update_active_player(|p| Player.activate_card(idx, p), game))
			DiscardCard(idx) => {
				discarded = Player.update_active_player(|p| Player.discard_card(idx, p), game)
				save_prior(Player.ensure_hand_not_empty(Move.maybe_get_out_via_discard(discarded)))
			}
			CoverCard(idx) => save_prior(Player.ensure_hand_not_empty(Player.update_active_player(|p| Player.cover_card(idx, p), game)))
			RotateBoard => {
				rotated = rotate_board(game)
				(History.reset(rotated), rotated)
			}
			SetStartLocation(loc) => (history, handle_start_loc_click(loc, game))
			SetEndLocation(loc) => (history, handle_end_loc_click(loc, game))
		}
	}

	rotate_board : Type.Game -> Type.Game
	rotate_board = |game| {
		old_idx = game.active_player_idx
		new_idx = U64.rem_by(old_idx + 1, game.num_players)
		players = Player.set_turn(new_idx, TurnBegin, Player.set_turn(old_idx, TurnIdle, game.players))
		begin_active_turn({ ..game, players, active_player_idx: new_idx })
	}

	## The first color with every base square its own -- and in a
	## partnership, its partner's too; the team is named "red and green".
	winner : Type.Game -> Try(Str, [NoWinner])
	winner = |game| {
		# One arm per partnership style: an or-pattern that binds `partner`
		# crashes the compiler (nightly 09-07; see Agent.partners).
		both_home = |color, partner| Piece.all_home(game.piece_map, color) and Piece.all_home(game.piece_map, partner)
		done = |player|
			match player.team {
				Solo => if Piece.all_home(game.piece_map, player.color) { Ok(player.color) } else { Err(NoWinner) }
				Partner(partner) => if both_home(player.color, partner) { Ok(Str.concat(player.color, Str.concat(" and ", partner))) } else { Err(NoWinner) }
				PartnerOnceHome(partner) => if both_home(player.color, partner) { Ok(Str.concat(player.color, Str.concat(" and ", partner))) } else { Err(NoWinner) }
			}
		match List.find_first(game.players, |p| Try.is_ok(done(p))) {
			Ok(p) => done(p)
			Err(_) => Err(NoWinner)
		}
	}

	begin_active_turn : Type.Game -> Type.Game
	begin_active_turn = |game| Player.set_turn_to_need_card(Player.replenish_hand(game))

	handle_start_loc_click : Type.PieceLocation, Type.Game -> Type.Game
	handle_start_loc_click = |location, game|
		match Player.get_active_player(game).turn {
			TurnNeedStartLoc(_) => Move.maybe_auto_move(location, Player.update_active_player(|p| Player.set_start_location(location, p), game))
			# the click handlers are wrong
			_ => game
		}

	handle_end_loc_click : Type.PieceLocation, Type.Game -> Type.Game
	handle_end_loc_click = |end_loc, game| {
		active_player = Player.get_active_player(game)
		match active_player.turn {
			TurnNeedEndLoc(info) => Move.move_to_end_loc(active_player, info.start_location, end_loc, game)
			_ => game
		}
	}
}

# Seed 0 deals red, the first player, the first five draws from the full deck
# at the positions web/elm_random_oracle.mjs prints: 7, 8, 14, 39, 19.
expect {
	game = Game.begin_game(0, Normal, Solo)
	red = Player.get_player(game.players, 0)
	red.hand == ["9", "J", "5", "5", "J"] and List.len(red.deck) == 49
}
