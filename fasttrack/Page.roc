# Page -- the page as data, from View.elm and Polygon.elm.
#
# Elm built Html and Svg and let its virtual DOM find the differences. Here
# the page is a flat list of Wire.Node, which a page replaces wholesale on
# every click -- it is a handful of buttons and lines -- and the board is a
# fixed list of Wire.Slot, which a page draws once and then patches, because
# the board never changes shape: rotating it recolors the squares, and never
# moves one.
#
# **THE GEOMETRY IS Polygon.elm's.** Each zone is a panel drawn upright,
# pushed out by the incircle radius, rotated a side's angle about the centre,
# and the whole board nudged a square in. With four sides every angle is a
# multiple of 90 degrees, so a square stays a square and a slot needs only a
# centre.
import pf.Wire
import Agent
import Assoc
import Codes
import Color
import Config
import LegalMove
import Piece
import Player
import Reach
import Type

Page :: [].{
	## A subtree of nodes, flattened: its root first, `parent` counted from
	## the subtree's own start.
	Tree : List(Wire.Node)

	el : Str, Str, U32, Bool, List(Page.Tree) -> Page.Tree
	el = |tag, style, click, disabled, children| {
		root = { parent: 0, tag, text: "", style, click, disabled }
		List.fold(
			children,
			[root],
			|acc, child| {
				offset = U64.to_u32_wrap(List.len(acc))
				List.concat(acc, List.map(child, |n| if n.parent == 0 { { ..n, parent: 1 } } else { { ..n, parent: n.parent + offset } }))
			},
		)
	}

	div : List(Page.Tree) -> Page.Tree
	div = |children| el("div", "", 0, Bool.False, children)

	span : List(Page.Tree) -> Page.Tree
	span = |children| el("span", "", 0, Bool.False, children)

	text : Str -> Page.Tree
	text = |s| [{ parent: 0, tag: "", text: s, style: "", click: 0, disabled: Bool.False }]

	bold : Str, List(Page.Tree) -> Page.Tree
	bold = |style, children| el("b", style, 0, Bool.False, children)

	button : Str, U32, List(Page.Tree) -> Page.Tree
	button = |style, click, children| el("button", style, click, Bool.False, children)

	panel_width : F64
	panel_width = 4.0 * Config.square_size

	panel_height : F64
	panel_height = 5.0 * Config.square_size

	## `incircleRadius`: from the centre to the middle of a side.
	incircle_radius : U64 -> F64
	incircle_radius = |side_count| (panel_width / 2.0) / F64.tan(F64.pi / U64.to_f64(side_count))

	center_offset : U64 -> F64
	center_offset = |side_count| panel_height + incircle_radius(side_count)

	## What the page may offer: `interactive` is false in the computer's seat
	## and once someone has won, and then nothing takes a click.
	## `reach` is the fewest cards home for the player to move, square by
	## square (Reach.fewest_cards), or [] to show none.
	## `reach_title` is what the button that cycles it says, and
	## `reach_showing` what the board shows now ("" for nothing).
	Flags : { interactive : Bool, show_undo : Bool, tick : U32, winner : Str, reach : List(Reach.Best), reach_title : Str, reach_showing : Str }

	view : Type.Game, Page.Flags -> Wire.View
	view = |game, flags| {
		active_player = Player.get_active_player(game)
		active_color = active_player.color
		zone_colors = Color.rotate_list(game.active_player_idx, game.zone_colors)
		undo_button = if flags.show_undo { [button("", Codes.undo, [text("oops")])] } else { [] }
		side_count = List.len(zone_colors)
		console =
			if flags.winner != "" {
				winner_view(flags.winner)
			} else if flags.interactive {
				player_view(active_player, active_color, undo_button)
			} else {
				computer_view(active_player, active_color)
			}
		{
			board_size: 2.0 * center_offset(side_count) + 3.0 * Config.square_size,
			slots: board_view(game, zone_colors, active_player, flags.interactive, flags.reach),
			nodes: el(
				"div",
				"display: flex; flex-direction: row",
				0,
				Bool.False,
				[
					div([div([div([el("board", "", 0, Bool.False, [])]), el("hr", "", 0, Bool.False, []), console])]),
					div([reach_button(flags.reach_title, flags.reach_showing), cheat_sheet_view(active_player)]),
				],
			),
			tick: flags.tick,
			winner: flags.winner,
		}
	}

	## "red wins!", or for a partnership "red and green win!", in the first
	## color named.
	winner_view : Str -> Page.Tree
	winner_view = |winner| {
		(color, verb) = match Str.split_first(winner, " and ") {
			Ok(parts) => (parts.before, "win")
			Err(_) => (winner, "wins")
		}
		div([bold("color: ${color}; font-size: 150%", [text("${winner} ${verb}!")])])
	}

	## Who plays with whom, in a partnership.
	team_line : Type.Player -> List(Page.Tree)
	team_line = |player|
		match player.team {
			Solo => []
			Partner(partner) => [div([text("${player.color} plays with ${partner}, and may move either's pieces")])]
			PartnerOnceHome(partner) => [div([text("${player.color} plays with ${partner}, and may move ${partner}'s pieces once its own are home")])]
		}

	## Cycles the fewest cards home on every square -- off, plain, with a free
	## face card -- for the player to move, whose zone is at the bottom.
	reach_button : Str, Str -> Page.Tree
	reach_button = |title, showing|
		div(
			List.concat(
				[button("", Codes.toggle_reach, [text(title)])],
				if showing == "" { [] } else { [div([text("the board shows: ${showing}")])] },
			),
		)

	## The computer's hand, face up, and nothing to press.
	computer_view : Type.Player, Str -> Page.Tree
	computer_view = |player, color|
		div(
			[
				span(List.map(player.hand, |card| el("button", card_css(color, color), 0, Bool.True, [text(card)]))),
				div([text("the computer is playing ${color}")]),
			]
			.concat(team_line(player)),
		)

	board_view : Type.Game, List(Str), Type.Player, Bool, List(Reach.Best) -> List(Wire.Slot)
	board_view = |game, zone_colors, active_player, interactive, reach| {
		side_count = List.len(zone_colors)
		angle = 2.0 * F64.pi / U64.to_f64(side_count)
		center = center_offset(side_count)
		radius = incircle_radius(side_count)
		zones = List.join(
			List.map_with_index(
				zone_colors,
				|zone_color, i| {
					theta = angle * U64.to_f64(i)
					List.map(
						Config.config_locations,
						|loc| {
							# Upright in the panel, then pushed out and turned.
							a = loc.x * Config.square_size
							b = panel_height - (loc.y * Config.square_size) + radius
							cx = Config.square_size + center + a * F64.cos(theta) - b * F64.sin(theta)
							cy = Config.square_size + center + a * F64.sin(theta) + b * F64.cos(theta)
							slot(game, active_player, interactive, reach, { zone: NormalColor(zone_color), id: loc.id }, cx, cy)
						},
					)
				},
			),
		)
		bulls_eye = slot(game, active_player, interactive, reach, { zone: BullsEyeZone, id: "bullseye" }, Config.square_size + center, Config.square_size + center)
		List.append(zones, bulls_eye)
	}

	## `drawLocationAtCoords`.
	slot : Type.Game, Type.Player, Bool, List(Reach.Best), Type.PieceLocation, F64, F64 -> Wire.Slot
	slot = |game, active_player, interactive, reach, piece_location, cx, cy| {
		# The fewest cards home from here, and the cards that start the way;
		# nothing for squares a piece of this color never stands on.
		best = List.get(reach, Agent.index_of(game.zone_colors, piece_location)) ?? { cards: Agent.far, first: [] }
		(label, hint) =
			if best.cards >= Agent.far {
				("", "")
			} else {
				# Plain cards in deck order, then the ways with a face card.
				plain = List.keep_if(Reach.cards, |c| List.contains(best.first, c))
				with_face = List.keep_if(best.first, |c| Str.contains(c, "face"))
				cards = List.map(List.concat(plain, with_face), |c| Str.replace_each(c, "4", "4 back"))
				(I64.to_str(best.cards), if List.is_empty(cards) { "home" } else { Str.concat("start with ", Str.join_with(cards, ", ")) })
			}
		zone_color = match piece_location.zone {
			BullsEyeZone => "black"
			NormalColor(color) => color
		}
		my_piece = Piece.get_piece(game.piece_map, piece_location)
		is_me = my_piece == Ok(active_player.color)
		is_selected_piece = Player.get_start_location(active_player) == Ok(piece_location)
		is_start_loc = Assoc.set_member(Player.start_locs_for_player(active_player), piece_location)
		is_reachable = Assoc.set_member(Player.end_locs_for_player(active_player), piece_location)
		fill =
			if is_selected_piece {
				"lightblue"
			} else if is_start_loc {
				"lightcyan"
			} else if is_reachable {
				"lightgreen"
			} else if is_me {
				"mintcream"
			} else {
				"white"
			}
		click =
			if !interactive {
				0
			} else if is_start_loc {
				Codes.start_location(game.zone_colors, piece_location)
			} else if is_reachable {
				Codes.end_location(game.zone_colors, piece_location)
			} else {
				0
			}
		piece_r =
			if is_selected_piece {
				7.0
			} else if is_start_loc {
				6.0
			} else {
				4.0
			}
		{
			square: Config.is_holding_pen_id(piece_location.id) or Config.is_base_id(piece_location.id),
			cx,
			cy,
			size: Config.square_size - Config.gutter_size,
			fill,
			stroke: if is_start_loc { "black" } else { zone_color },
			piece: my_piece ?? "",
			piece_r,
			click,
			label,
			hint,
		}
	}

	cheat_sheet_cards : Type.Player -> Assoc.AssocSet(Str)
	cheat_sheet_cards = |player|
		match player.turn {
			TurnNeedCard(_) => Player.get_playable_cards(player)
			TurnNeedStartLoc(info) => [LegalMove.get_card_for_play_type(info.play_type)]
			_ => []
		}

	player_view : Type.Player, Str, List(Page.Tree) -> Page.Tree
	player_view = |player, color, undo_button| {
		playable_cards = Player.get_playable_cards(player)
		hand_cards = List.map_with_index(player.hand, |card, idx| hand_card_view(color, player, playable_cards, idx, card))
		hand = span(List.join([hand_cards, undo_button, rotate_button_view(player)]))
		console = match player.turn {
			TurnNeedDiscard => div([text("click a card to discard")])
			TurnNeedCover => div([text("click a card to cover")])
			TurnNeedCard(_) => div([div([text("click a card above")])])
			TurnNeedStartLoc(info) => div([active_card_view(LegalMove.get_card_for_play_type(info.play_type), color, need_start_instructions(info.play_type))])
			TurnNeedEndLoc(info) => div([active_card_view(LegalMove.get_card_for_play_type(info.play_type), color, "now click piece's end location")])
			TurnDone => div([text("ok, now hit 'done' if you're happy")])
			_ => div([])
		}
		div(List.concat([hand, credits_view(player), console], team_line(player)))
	}

	need_start_instructions : Type.PlayType -> Str
	need_start_instructions = |play_type|
		match play_type {
			PlayCard(_) => "click a piece to start move"
			FinishSeven(count) => "click a piece to finish split (moving ${I64.to_str(count)})"
		}

	hand_card_view : Str, Type.Player, Assoc.AssocSet(Str), U64, Str -> Page.Tree
	hand_card_view = |color, player, playable_cards, idx, card| {
		action = match player.turn {
			TurnNeedCard(_) => if Assoc.set_member(playable_cards, card) { CanActivate } else { Ignore }
			TurnNeedDiscard => CanDiscard
			TurnNeedCover => CanCover
			_ => Ignore
		}
		label = [text(card)]
		match action {
			CanActivate => el("button", card_css(color, color), Codes.activate_card(idx), Bool.False, label)
			CanDiscard => el("button", card_css("gray", color), Codes.discard_card(idx), Bool.False, label)
			CanCover => el("button", card_css("gray", color), Codes.cover_card(idx), Bool.False, label)
			Ignore => el("button", card_css("gray", "gray"), 0, Bool.True, label)
		}
	}

	active_card_view : Str, Str, Str -> Page.Tree
	active_card_view = |active_card, color, instructions|
		span([bold("color: ${color}; padding: 4px; margin: 5px; font-size: 110%", [text(active_card)]), text(instructions)])

	card_css : Str, Str -> Str
	card_css = |border_color, color|
		"border-color: ${border_color}; color: ${color}; background: white; padding: 4px; margin: 3px; font-size: 110%; min-width: 30px"

	credits_view : Type.Player -> Page.Tree
	credits_view = |player|
		if player.get_out_credits > 0 {
			div([text("You have "), bold("", [text(I64.to_str(player.get_out_credits))]), text(" credits (you need 5 to get out)")])
		} else {
			span([])
		}

	rotate_button_view : Type.Player -> List(Page.Tree)
	rotate_button_view = |player|
		match player.turn {
			TurnDone => [button("background: lightgreen", Codes.rotate_board, [text("done")])]
			_ => []
		}

	cheat_sheet_view : Type.Player -> Page.Tree
	cheat_sheet_view = |player| {
		cards = cheat_sheet_cards(player)
		if List.is_empty(cards) {
			div([])
		} else {
			hints = List.map(List.sort_by(cards, Config.card_value), |card| div([text("${card} - ${Config.hint_for_card(card)}")]))
			div([el("br", "", 0, Bool.False, []), bold("", [text("Cheat sheet:")]), div(hints)])
		}
	}
}
