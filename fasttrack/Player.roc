# Player -- a player's hand, deck and turn, from Player.elm.
#
# A turn is a small state machine (Type.Turn): pick a card, pick a piece,
# pick where it goes, and either the turn is done or the card lets the player
# go again. With nothing playable, the player discards (at the start of a
# turn, earning a credit towards leaving the pen) or covers a card.
import Assoc
import Config
import ElmRandom
import LegalMove
import Piece
import Setup
import Type

Player :: [].{
	get_playable_cards : Type.Player -> Assoc.AssocSet(Str)
	get_playable_cards = |player|
		match player.turn {
			TurnNeedCard(info) => Assoc.set_from_list(List.map(info.moves, |m| LegalMove.get_card_for_move_type(m.kind)))
			_ => []
		}

	## Two moves can join the same two squares only by a jack, moving one or
	## trading. Elm takes the first, the forward move, and so does this.
	get_player_move_type : Type.Player, Type.PieceLocation -> Try(Type.MoveType, [NotFound])
	get_player_move_type = |player, end_loc|
		match player.turn {
			TurnNeedEndLoc(info) => {
				move_types = List.map(List.keep_if(info.moves, |m| m.end == end_loc), |m| m.kind)
				n = List.len(move_types)
				if n == 1 or n == 2 {
					match List.first(move_types) {
						Ok(t) => Ok(t)
						Err(_) => Err(NotFound)
					}
				} else {
					Err(NotFound)
				}
			}
			_ => Err(NotFound)
		}

	## `hand` is empty unless a setup other than Normal deals one.
	config_player : Setup.InitSetup, Str, Type.Team -> Type.Player
	config_player = |init_setup, color, team| {
		deck: Config.full_deck,
		hand: Setup.starting_hand(init_setup, color),
		get_out_credits: 0,
		turn: TurnBegin,
		color,
		team,
	}

	## In a partnership, partners sit opposite: red and green, blue and
	## purple.
	config_players : Setup.InitSetup, List(Str), Type.Teams -> List(Type.Player)
	config_players = |init_setup, zone_colors, teams| {
		n = List.len(zone_colors)
		List.map_with_index(
			zone_colors,
			|color, i| {
				partner = List.get(zone_colors, U64.rem_by(i + n // 2, n)) ?? color
				team = match teams {
					Solo => Solo
					Anytime => Partner(partner)
					OnceHome => PartnerOnceHome(partner)
				}
				config_player(init_setup, color, team)
			},
		)
	}

	get_player : List(Type.Player), U64 -> Type.Player
	get_player = |players, idx| List.get(players, idx) ?? config_player(Normal, "bogus", Solo)

	## The colors whose pieces this player may move: its own, and its
	## partner's when its team's rules allow.
	movers : Type.Player, Type.PieceMap -> List(Str)
	movers = |player, piece_map|
		match player.team {
			Solo => [player.color]
			Partner(partner) => [player.color, partner]
			PartnerOnceHome(partner) => if Piece.all_home(piece_map, player.color) { [player.color, partner] } else { [player.color] }
		}

	get_active_player : Type.Game -> Type.Player
	get_active_player = |game| get_player(game.players, game.active_player_idx)

	get_moves_for_player : Type.Player, Type.PieceMap, List(Str) -> List(Type.Move)
	get_moves_for_player = |player, piece_map, zone_colors|
		LegalMove.get_moves_for_cards(Assoc.set_from_list(player.hand), piece_map, zone_colors, movers(player, piece_map))

	turn_need_card : Type.PieceMap, List(Str), Type.Player -> Type.Player
	turn_need_card = |piece_map, zone_colors, player| {
		moves = get_moves_for_player(player, piece_map, zone_colors)
		if List.is_empty(moves) {
			turn = match player.turn {
				TurnBegin => TurnNeedDiscard
				_ => TurnNeedCover
			}
			{ ..player, turn }
		} else {
			{ ..player, turn: TurnNeedCard({ moves: moves }), get_out_credits: 0 }
		}
	}

	maybe_finish_turn : Str, Type.PieceMap, List(Str), Type.Player -> Type.Player
	maybe_finish_turn = |card, piece_map, zone_colors, player|
		if Config.is_move_again_card(card) {
			turn_need_card(piece_map, zone_colors, player)
		} else {
			{ ..player, turn: TurnDone }
		}

	ensure_hand_not_empty : Type.Game -> Type.Game
	ensure_hand_not_empty = |game|
		if List.is_empty(get_player(game.players, game.active_player_idx).hand) {
			replenish_hand(game)
		} else {
			game
		}

	set_turn_to_need_card : Type.Game -> Type.Game
	set_turn_to_need_card = |game|
		update_active_player(|player| turn_need_card(game.piece_map, game.zone_colors, player), game)

	## The second half of a split seven: any OTHER piece, the rest of the way.
	finish_seven_split : Type.PieceMap, List(Str), List(Str), I64, Type.PieceLocation -> Type.Turn
	finish_seven_split = |piece_map, zone_colors, move_colors, distance, end_loc| {
		move_count = 7 - distance
		moves = LegalMove.get_moves_for_move_type(FinishSplit(move_count, end_loc), piece_map, zone_colors, move_colors)
		TurnNeedStartLoc(
			{
				play_type: FinishSeven(move_count),
				moves,
				start_locs: Assoc.set_from_list(List.map(moves, |m| m.start)),
			},
		)
	}

	clear_credits : Type.Player -> Type.Player
	clear_credits = |player| {
		turn = match player.turn {
			TurnNeedDiscard => TurnNeedCover
			other => other
		}
		{ ..player, get_out_credits: 0, turn }
	}

	finish_move : Type.PieceMap, List(Str), Type.Move, Type.Player -> Type.Player
	finish_move = |piece_map, zone_colors, move, player|
		match move.kind {
			StartSplit(distance) => { ..player, turn: finish_seven_split(piece_map, zone_colors, movers(player, piece_map), distance, move.end) }
			_ => maybe_finish_turn(LegalMove.get_card_for_move_type(move.kind), piece_map, zone_colors, player)
		}

	set_start_location : Type.PieceLocation, Type.Player -> Type.Player
	set_start_location = |start_loc, player|
		match player.turn {
			TurnNeedStartLoc(info) => {
				moves = List.keep_if(info.moves, |m| m.start == start_loc)
				turn = TurnNeedEndLoc(
					{
						play_type: info.play_type,
						moves,
						start_location: start_loc,
						end_locs: Assoc.set_from_list(List.map(moves, |m| m.end)),
					},
				)
				{ ..player, turn }
			}
			_ => player
		}

	get_start_location : Type.Player -> Try(Type.PieceLocation, [NotFound])
	get_start_location = |player|
		match player.turn {
			TurnNeedEndLoc(info) => Ok(info.start_location)
			_ => Err(NotFound)
		}

	update_active_player : (Type.Player -> Type.Player), Type.Game -> Type.Game
	update_active_player = |f, game| { ..game, players: update_player(game.players, game.active_player_idx, f) }

	update_player : List(Type.Player), U64, (Type.Player -> Type.Player) -> List(Type.Player)
	update_player = |players, idx, f| List.set(players, idx, f(get_player(players, idx))) ?? crash("update_player: no player at that index")

	set_turn : U64, Type.Turn, List(Type.Player) -> List(Type.Player)
	set_turn = |idx, turn, players| update_player(players, idx, |player| { ..player, turn })

	discard_card : U64, Type.Player -> Type.Player
	discard_card = |idx, player|
		match (List.get(player.hand, idx), player.turn) {
			(Ok(card), TurnNeedDiscard) => {
				# A move-again card keeps the player discarding; the caller
				# moves to covering once there are credits enough to get out.
				turn = if Config.is_move_again_card(card) { TurnNeedDiscard } else { TurnDone }
				{ ..player, hand: List.drop_at(player.hand, idx), turn, get_out_credits: player.get_out_credits + 1 }
			}
			_ => player
		}

	cover_card : U64, Type.Player -> Type.Player
	cover_card = |idx, player|
		match (List.get(player.hand, idx), player.turn) {
			(Ok(card), TurnNeedCover) => {
				turn = if Config.is_move_again_card(card) { TurnNeedCover } else { TurnDone }
				{ ..player, hand: List.drop_at(player.hand, idx), turn }
			}
			_ => player
		}

	activate_card : U64, Type.Player -> Type.Player
	activate_card = |idx, player|
		match (List.get(player.hand, idx), player.turn) {
			(Ok(active_card), TurnNeedCard(info)) => {
				moves = List.keep_if(info.moves, |m| LegalMove.get_card_for_move_type(m.kind) == active_card)
				turn = TurnNeedStartLoc(
					{
						play_type: PlayCard(active_card),
						moves,
						start_locs: Assoc.set_from_list(List.map(moves, |m| m.start)),
					},
				)
				{ ..player, hand: List.drop_at(player.hand, idx), turn }
			}
			_ => player
		}

	maybe_replenish_deck : List(Str) -> List(Str)
	maybe_replenish_deck = |deck| if List.is_empty(deck) { Config.full_deck } else { deck }

	## Draw until the hand holds five.
	replenish_hand : Type.Game -> Type.Game
	replenish_hand = |game| {
		var $game = game
		var $player = get_player(game.players, game.active_player_idx)
		while List.len($player.hand) < 5 {
			draw = ElmRandom.int(0, U64.to_i64_wrap(List.len($player.deck)) - 1, $game.seed)
			$game = { ..$game, players: update_player($game.players, $game.active_player_idx, |p| draw_card(I64.to_u64_wrap(draw.value), p)), seed: draw.seed }
			$player = get_player($game.players, $game.active_player_idx)
		}
		$game
	}

	draw_card : U64, Type.Player -> Type.Player
	draw_card = |idx, player|
		match List.get(player.deck, idx) {
			Ok(card) => { ..player, deck: maybe_replenish_deck(List.drop_at(player.deck, idx)), hand: List.append(player.hand, card) }
			Err(_) => player
		}

	start_locs_for_player : Type.Player -> Assoc.AssocSet(Type.PieceLocation)
	start_locs_for_player = |player|
		match player.turn {
			TurnNeedStartLoc(info) => info.start_locs
			_ => []
		}

	end_locs_for_player : Type.Player -> Assoc.AssocSet(Type.PieceLocation)
	end_locs_for_player = |player|
		match player.turn {
			TurnNeedEndLoc(info) => info.end_locs
			_ => []
		}
}
