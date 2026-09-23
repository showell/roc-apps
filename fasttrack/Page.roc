# Page -- the page as data, from View.elm and Polygon.elm.
#
# Elm built Html and Svg and let its virtual DOM find the differences. Here
# the page is a flat list of Wire.Node, which a page replaces wholesale on
# every click -- it is a handful of buttons and lines -- and the board is a
# fixed list of Wire.Slot, which a page draws once and then patches, because
# the board never changes shape. It is drawn as red sees it whoever is
# playing, so a slot's place in the list is its square's number.
#
# **THE GEOMETRY IS Polygon.elm's.** Each zone is a panel drawn upright,
# pushed out by the incircle radius, rotated a side's angle about the centre,
# and the whole board nudged a square in. With four sides every angle is a
# multiple of 90 degrees, so a square stays a square and a slot needs only a
# centre.
import pf.Wire
import Assoc
import Board
import Codes
import Config
import LegalMove
import Piece
import Player
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
	## and once someone has won, and then nothing takes a click. `motions`
	## are what the last click moved (Motion.roc), for the page to animate.
	Flags : { interactive : Bool, show_undo : Bool, tick : U32, winner : Str, motion_id : U32, motions : List(Wire.Motion) }

	view : Type.Game, Page.Flags -> Wire.View
	view = |game, flags| {
		active_player = Player.get_active_player(game)
		active_color = active_player.color
		# The board is always drawn as red sees it, so a slot's place is its
		# square's number (Board.roc).
		zone_colors = game.zone_colors
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
			slots: board_view(game, zone_colors, active_player, flags.interactive),
			labels: labels_view(game),
			nodes: el(
				"div",
				"display: flex; flex-direction: row",
				0,
				Bool.False,
				[
					div([div([div([el("board", "", 0, Bool.False, [])]), el("hr", "", 0, Bool.False, []), console])]),
					div([cheat_sheet_view(active_player)]),
				],
			),
			tick: flags.tick,
			winner: flags.winner,
			motion_id: flags.motion_id,
			motions: flags.motions,
		}
	}

	## Each player's discards toward leaving the pen, beside its pen, while
	## it has any.
	labels_view : Type.Game -> List(Wire.Label)
	labels_view = |game| {
		side_count = List.len(game.zone_colors)
		List.join(
			List.map_with_index(
				game.players,
				|p, i|
					if p.get_out_credits > 0 {
						at = spot(side_count, i, -3.7, 2.6)
						n = I64.to_str(p.get_out_credits)
						[{ x: at.x, y: at.y, text: "${n} discard${if p.get_out_credits == 1 { "" } else { "s" }}", fill: p.color }]
					} else {
						[]
					},
			),
		)
	}

	## Where a point of a zone's panel lands on the board (Polygon.elm): the
	## panel upright, pushed out by the incircle radius, turned by its side's
	## angle.
	spot : U64, U64, F64, F64 -> { x : F64, y : F64 }
	spot = |side_count, zone, px, py| {
		theta = 2.0 * F64.pi / U64.to_f64(side_count) * U64.to_f64(zone)
		center = center_offset(side_count)
		a = px * Config.square_size
		b = panel_height - (py * Config.square_size) + incircle_radius(side_count)
		{
			x: Config.square_size + center + a * F64.cos(theta) - b * F64.sin(theta),
			y: Config.square_size + center + a * F64.sin(theta) + b * F64.cos(theta),
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

	board_view : Type.Game, List(Str), Type.Player, Bool -> List(Wire.Slot)
	board_view = |game, zone_colors, active_player, interactive| {
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
							slot(game, active_player, interactive, { zone: NormalColor(zone_color), id: loc.id }, cx, cy)
						},
					)
				},
			),
		)
		bulls_eye = slot(game, active_player, interactive, { zone: BullsEyeZone, id: "bullseye" }, Config.square_size + center, Config.square_size + center)
		List.append(zones, bulls_eye)
	}

	## `drawLocationAtCoords`.
	slot : Type.Game, Type.Player, Bool, Type.PieceLocation, F64, F64 -> Wire.Slot
	slot = |game, active_player, interactive, piece_location, cx, cy| {
		zone_color = match piece_location.zone {
			BullsEyeZone => "black"
			NormalColor(color) => color
		}
		square = Board.index_of(game.zone_colors, piece_location)
		my_piece = Piece.get_piece(game.board, game.zone_colors, square)
		is_me = my_piece == Ok(active_player.color)
		is_selected_piece = Player.get_start_location(active_player) == Ok(square)
		is_start_loc = Assoc.set_member(Player.start_locs_for_player(active_player), square)
		is_reachable = Assoc.set_member(Player.end_locs_for_player(active_player), square)
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
				Codes.start_location(square)
			} else if is_reachable {
				Codes.end_location(square)
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
			div([text("You have "), bold("", [text(I64.to_str(player.get_out_credits))]), text(" credits (you need ${I64.to_str(Config.num_credits_to_get_out)} to get out)")])
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
