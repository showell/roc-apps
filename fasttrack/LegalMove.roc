# LegalMove -- every move a card allows, from LegalMove.elm.
#
# A move is a walk over the board's graph: `get_next_locs` and `get_prev_locs`
# are the edges out of a square, which depend on the piece's color, the card
# (leaving the pen, leaving the bullseye, going backwards) and what else is on
# the board, since a piece may not pass its own color.
import Assoc
import Color
import Config
import Graph
import Piece
import Type

LegalMove :: [].{
	## Only while splitting a seven, so no card here can leave the pen.
	get_can_go_n_spaces : Type.PieceMap, Type.PieceLocation, List(Str), I64 -> Bool
	get_can_go_n_spaces = |piece_map, loc, zone_colors, n| {
		can_fast_track = loc.id == "FT"
		piece_color = Piece.get_the_piece(piece_map, loc)
		can_move = can_fast_track or !Piece.has_piece_on_fast_track(piece_map, piece_color)
		if can_move {
			params = {
				reverse_mode: Bool.False,
				can_fast_track,
				can_leave_pen: Bool.False,
				can_leave_bulls_eye: Bool.False,
				piece_color,
				piece_map,
				zone_colors,
			}
			Graph.can_travel_n_edges(|l| get_next_locs(params, l), n, loc)
		} else {
			Bool.False
		}
	}

	## Every forward move the hand allows; when there is none, every move
	## backwards instead.
	get_moves_for_cards : Assoc.AssocSet(Str), Type.PieceMap, List(Str), Str -> List(Type.Move)
	get_moves_for_cards = |cards, piece_map, zone_colors, active_color| {
		moves_for = |make_move_type|
			List.join_map(cards, |card| get_moves_for_move_type(make_move_type(card), piece_map, zone_colors, active_color))
		forward_moves = moves_for(|card| if card == "4" { Reverse(card) } else { WithCard(card) })
		if List.is_empty(forward_moves) {
			moves_for(|card| Reverse(card))
		} else {
			forward_moves
		}
	}

	get_moves_for_move_type : Type.MoveType, Type.PieceMap, List(Str), Str -> List(Type.Move)
	get_moves_for_move_type = |move_type, piece_map, zone_colors, active_color| {
		start_locs = match move_type {
			FinishSplit(_, exclude_loc) => Piece.other_non_pen_pieces(piece_map, active_color, exclude_loc)
			_ => Piece.movable_pieces(piece_map, active_color)
		}
		List.join_map(start_locs, |start_loc| get_moves_from_location(move_type, piece_map, zone_colors, start_loc))
	}

	get_moves_from_location : Type.MoveType, Type.PieceMap, List(Str), Type.PieceLocation -> List(Type.Move)
	get_moves_from_location = |move_type, piece_map, zone_colors, start_loc| {
		id = start_loc.id
		can_fast_track = id == "FT"
		piece_color = Piece.get_the_piece(piece_map, start_loc)
		active_card = get_card_for_move_type(move_type)
		can_leave_bulls_eye = List.contains(["J", "Q", "K"], active_card) and id == "bullseye"
		can_leave_pen = List.contains(["A", "joker", "6"], active_card)
		reverse_mode = match move_type {
			Reverse(_) => Bool.True
			_ => active_card == "4"
		}
		moves_left = move_count_for_move_type(move_type, id)
		can_move = can_fast_track or !Piece.has_piece_on_fast_track(piece_map, piece_color)
		if can_move {
			params = { reverse_mode, can_fast_track, can_leave_pen, can_leave_bulls_eye, piece_color, piece_map, zone_colors }
			if move_type == WithCard("7") {
				get_moves_for_seven(params, start_loc)
			} else if move_type == WithCard("J") {
				get_moves_for_jack(params, start_loc)
			} else {
				List.map(end_locations(params, start_loc, moves_left), |end_loc| { kind: move_type, start: start_loc, end: end_loc })
			}
		} else {
			[]
		}
	}

	can_finish_split : List(Str), Assoc.AssocSet(Type.PieceLocation), Type.PieceMap, I64, Type.Move -> Bool
	can_finish_split = |zone_colors, other_locs, piece_map, count, move| {
		modified_piece_map = Piece.move_piece(move, piece_map)
		List.any(other_locs, |other_loc| get_can_go_n_spaces(modified_piece_map, other_loc, zone_colors, count))
	}

	## A jack moves one square, or trades places with a piece of another
	## color on the open track.
	get_moves_for_jack : Type.FindLocParams, Type.PieceLocation -> List(Type.Move)
	get_moves_for_jack = |params, start_loc| {
		piece_color = Piece.get_the_piece(params.piece_map, start_loc)
		forward_moves = List.map(end_locations(params, start_loc, 1), |end_loc| { kind: WithCard("J"), start: start_loc, end: end_loc })
		trade_moves =
			if Piece.is_normal_loc(start_loc) {
				List.map(Piece.swappable_locs(params.piece_map, piece_color), |end_loc| { kind: JackTrade, start: start_loc, end: end_loc })
			} else {
				[]
			}
		List.concat(forward_moves, trade_moves)
	}

	## A seven moves one piece seven, or splits between two: the first part
	## is offered only if some other piece can then finish the split.
	get_moves_for_seven : Type.FindLocParams, Type.PieceLocation -> List(Type.Move)
	get_moves_for_seven = |params, start_loc| {
		piece_map = params.piece_map
		piece_color = Piece.get_the_piece(piece_map, start_loc)
		full_moves = List.map(end_locations(params, start_loc, 7), |end_loc| { kind: WithCard("7"), start: start_loc, end: end_loc })
		other_locs = Piece.other_non_pen_pieces(piece_map, piece_color, start_loc)
		if List.is_empty(other_locs) {
			full_moves
		} else {
			partial_moves = List.join_map(
				[1, 2, 3, 4, 5, 6],
				|move_count| {
					candidates =
						end_locations(params, start_loc, move_count)
						.drop_if(|end_loc| end_loc == { zone: BullsEyeZone, id: "bullseye" })
						.map(|end_loc| { kind: StartSplit(move_count), start: start_loc, end: end_loc })
					List.keep_if(candidates, |move| can_finish_split(params.zone_colors, other_locs, piece_map, 7 - move_count, move))
				},
			)
			List.concat(partial_moves, full_moves)
		}
	}

	end_locations : Type.FindLocParams, Type.PieceLocation, I64 -> List(Type.PieceLocation)
	end_locations = |params, start_loc, moves_left|
		if params.reverse_mode {
			Graph.get_nodes_n_edges_away(|l| get_prev_locs(params, l), moves_left, start_loc)
		} else {
			Graph.get_nodes_n_edges_away(|l| get_next_locs(params, l), moves_left, start_loc)
		}

	get_next_locs : Type.FindLocParams, Type.PieceLocation -> List(Type.PieceLocation)
	get_next_locs = |params, loc| {
		piece_color = params.piece_color
		free = |locs| List.keep_if(locs, |l| is_loc_free(params.piece_map, piece_color, l))
		id = loc.id
		match loc.zone {
			BullsEyeZone =>
				if params.can_leave_bulls_eye {
					free([{ zone: NormalColor(Color.prev_zone_color(piece_color, params.zone_colors)), id: "FT" }])
				} else {
					[]
				}
			NormalColor(zone_color) => {
				next_zone = NormalColor(Color.next_zone_color(zone_color, params.zone_colors))
				if Config.is_holding_pen_id(id) {
					if params.can_leave_pen { free([{ zone: loc.zone, id: "L0" }]) } else { [] }
				} else if id == "FT" {
					if piece_color == zone_color {
						if params.can_fast_track {
							free([{ zone: next_zone, id: "FT" }, { zone: next_zone, id: "R4" }, { zone: BullsEyeZone, id: "bullseye" }])
						} else {
							free([{ zone: next_zone, id: "R4" }, { zone: BullsEyeZone, id: "bullseye" }])
						}
					} else if params.can_fast_track and NormalColor(piece_color) != next_zone {
						free([{ zone: next_zone, id: "FT" }, { zone: next_zone, id: "R4" }])
					} else {
						free([{ zone: next_zone, id: "R4" }])
					}
				} else {
					free(List.map(Config.next_ids_in_zone(id, piece_color, zone_color), |next_id| { zone: NormalColor(zone_color), id: next_id }))
				}
			}
		}
	}

	get_prev_locs : Type.FindLocParams, Type.PieceLocation -> List(Type.PieceLocation)
	get_prev_locs = |params, loc|
		match loc.zone {
			BullsEyeZone => []
			NormalColor(zone_color) => {
				free = |locs| List.keep_if(locs, |l| is_loc_free(params.piece_map, params.piece_color, l))
				id = loc.id
				if Config.is_holding_pen_id(id) {
					[]
				} else if Config.is_base_id(id) {
					[]
				} else if id == "R4" {
					free([{ zone: NormalColor(Color.prev_zone_color(zone_color, params.zone_colors)), id: "FT" }])
				} else {
					free([{ zone: NormalColor(zone_color), id: Config.prev_id_in_zone(id) }])
				}
			}
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

	move_count_for_move_type : Type.MoveType, Str -> I64
	move_count_for_move_type = |move_type, id|
		match move_type {
			WithCard(card) => Config.move_count_for_card(card, id)
			Reverse(card) => Config.move_count_for_card(card, id)
			StartSplit(count) => count
			FinishSplit(count, _) => count
			# never asked of a trade
			JackTrade => 0
		}

	## Free unless a piece of the mover's own color is there.
	is_loc_free : Type.PieceMap, Str, Type.PieceLocation -> Bool
	is_loc_free = |piece_map, piece_color, loc|
		match Piece.get_piece(piece_map, loc) {
			Ok(color) => color != piece_color
			Err(_) => Bool.True
		}
}
