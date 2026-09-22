# Agent -- a computer player.
#
# **IT PLAYS THE REAL RULES.** A choice is a message Game.update_game already
# answers -- a card, a starting square, an end square, a card to discard or
# cover -- and a line of play is those messages applied to a real Game. There
# is no second copy of the rules to drift (Elm's WhatIf.elm had one, and it
# did not draw cards).
#
# A turn is searched a card play at a time: a play is a card and every click
# it takes to finish, a split seven included. The best few positions after
# each play are kept (a beam), and the best position at the end of the turn
# wins. A line stops where the hand is refilled, so the agent never looks at
# a card it has not drawn.
#
# **THE HEURISTIC** is distance: how many steps each piece has left to the
# deepest square of its own base, walking the board's real graph on an empty
# board. Waiting in the pen for a card that lets a piece out, and in the
# bullseye for a face card, cost extra steps. A position is worth the
# opponents' distance less four times the mover's own, so sending a piece
# home counts, but moving your own counts more.
import Config
import Piece
import Game
import History
import LegalMove
import Player
import Type

Agent :: [].{
	Line : { game : Type.Game, msgs : List(Type.GameMsg), drew : Bool }

	## Extra steps for waiting on A, 6 or joker to leave the pen.
	pen_wait : I64
	pen_wait = 4

	## Extra steps for waiting on J, Q or K to leave the bullseye.
	bulls_eye_wait : I64
	bulls_eye_wait = 6

	beam_width : U64
	beam_width = 6

	far : I64
	far = 1000

	## Every square, zone by zone in the game's own color order, each in
	## Config.config_locations order; then the bullseye.
	all_locs : List(Str) -> List(Type.PieceLocation)
	all_locs = |zone_colors|
		List.append(
			List.join_map(zone_colors, |color| List.map(Config.config_locations, |l| { zone: NormalColor(color), id: l.id })),
			{ zone: BullsEyeZone, id: "bullseye" },
		)

	index_of : List(Str), Type.PieceLocation -> U64
	index_of = |zone_colors, loc| {
		per_zone = List.len(Config.config_locations)
		match loc.zone {
			BullsEyeZone => List.len(zone_colors) * per_zone
			NormalColor(color) => {
				zone = List.find_first_index(zone_colors, |c| c == color) ?? crash("Agent.index_of: no such zone")
				square = List.find_first_index(Config.config_locations, |l| l.id == loc.id) ?? crash("Agent.index_of: no such square")
				zone * per_zone + square
			}
		}
	}

	## Steps left for a piece of `color` on each square, indexed as `all_locs`:
	## Bellman-Ford over the empty board's edges, walked backwards from B4.
	distances : List(Str), Str -> List(I64)
	distances = |zone_colors, color| {
		locs = all_locs(zone_colors)
		params = {
			reverse_mode: Bool.False,
			can_fast_track: Bool.True,
			can_leave_pen: Bool.True,
			can_leave_bulls_eye: Bool.True,
			piece_color: color,
			piece_map: [],
			zone_colors,
		}
		edges = List.join(
			List.map_with_index(
				locs,
				|loc, from| {
					cost =
						if Config.is_holding_pen_id(loc.id) {
							1 + pen_wait
						} else if loc.zone == BullsEyeZone {
							1 + bulls_eye_wait
						} else {
							1
						}
					List.map(LegalMove.get_next_locs(params, loc), |next| { from, to: index_of(zone_colors, next), cost })
				},
			),
		)
		home = index_of(zone_colors, { zone: NormalColor(color), id: "B4" })
		start = List.set(List.repeat(far, List.len(locs)), home, 0) ?? crash("Agent.distances: no home square")
		relax = |d|
			List.fold(
				edges,
				d,
				|acc, e| {
					via = (List.get(acc, e.to) ?? far) + e.cost
					if via < (List.get(acc, e.from) ?? far) {
						List.set(acc, e.from, via) ?? crash("Agent.distances: edge out of range")
					} else {
						acc
					}
				},
			)
		var $d = start
		var $next = relax(start)
		while $next != $d {
			$d = $next
			$next = relax($d)
		}
		$d
	}

	Tables : List({ color : Str, steps : List(I64) })

	tables : List(Str) -> Agent.Tables
	tables = |zone_colors| List.map(zone_colors, |color| { color, steps: distances(zone_colors, color) })

	steps_left : Agent.Tables, List(Str), Str, Type.PieceLocation -> I64
	steps_left = |tabs, zone_colors, color, loc|
		match List.find_first(tabs, |t| t.color == color) {
			Ok(t) => List.get(t.steps, index_of(zone_colors, loc)) ?? far
			Err(_) => far
		}

	## Higher is better for `color`.
	score : Agent.Tables, Type.Game, Str -> I64
	score = |tabs, game, color|
		List.fold(
			game.piece_map,
			0,
			|total, entry| {
				steps = steps_left(tabs, game.zone_colors, entry.value, entry.key)
				if entry.value == color { total - 4 * steps } else { total + steps }
			},
		)

	## Every choice the turn offers now, one per distinct card.
	options : Type.Game -> List(Type.GameMsg)
	options = |game| {
		player = Player.get_active_player(game)
		match player.turn {
			TurnNeedCard(_) => {
				playable = Player.get_playable_cards(player)
				first_of_each(player.hand, |card| List.contains(playable, card), |i| ActivateCard(i))
			}
			TurnNeedStartLoc(info) => List.map(info.start_locs, |loc| SetStartLocation(loc))
			TurnNeedEndLoc(info) => List.map(info.end_locs, |loc| SetEndLocation(loc))
			TurnNeedDiscard => first_of_each(player.hand, |_| Bool.True, |i| DiscardCard(i))
			TurnNeedCover => first_of_each(player.hand, |_| Bool.True, |i| CoverCard(i))
			_ => []
		}
	}

	## The index of the first copy of each card `keep` accepts: two 5s are
	## one choice.
	first_of_each : List(Str), (Str -> Bool), (U64 -> Type.GameMsg) -> List(Type.GameMsg)
	first_of_each = |hand, keep, make|
		List.join(
			List.map_with_index(
				hand,
				|card, i|
					if keep(card) and List.find_first_index(hand, |c| c == card) == Ok(i) {
						[make(i)]
					} else {
						[]
					},
			),
		)

	hand_size : Type.Game -> U64
	hand_size = |game| List.len(Player.get_active_player(game).hand)

	apply : Agent.Line, Type.GameMsg -> Agent.Line
	apply = |line, msg| {
		(_, game) = Game.update_game(msg, History.init, line.game)
		{ game, msgs: List.append(line.msgs, msg), drew: line.drew or hand_size(game) > hand_size(line.game) }
	}

	## A line the search goes on with: the player is choosing a card, or
	## what to discard or cover, and has drawn nothing new.
	is_open : Agent.Line -> Bool
	is_open = |line|
		if line.drew {
			Bool.False
		} else {
			match Player.get_active_player(line.game).turn {
				TurnNeedCard(_) => Bool.True
				TurnNeedDiscard => Bool.True
				TurnNeedCover => Bool.True
				_ => Bool.False
			}
		}

	## Mid-play (a card chosen, its squares not yet), every way to finish it.
	settle : Agent.Line -> List(Agent.Line)
	settle = |line| {
		mid_play = match Player.get_active_player(line.game).turn {
			TurnNeedStartLoc(_) => Bool.True
			TurnNeedEndLoc(_) => Bool.True
			_ => Bool.False
		}
		choices = options(line.game)
		if mid_play and !line.drew and !List.is_empty(choices) {
			List.join_map(choices, |msg| settle(apply(line, msg)))
		} else {
			[line]
		}
	}

	## One card play further, every way.
	expand : Agent.Line -> List(Agent.Line)
	expand = |line| List.join_map(options(line.game), |msg| settle(apply(line, msg)))

	best_first : Agent.Tables, Str, List(Agent.Line) -> List(Agent.Line)
	best_first = |tabs, color, lines| {
		scored = List.map_with_index(lines, |line, i| { line, value: score(tabs, line.game, color), i })
		sorted = List.sort_with(
			scored,
			|a, b|
				if a.value > b.value {
					Before
				} else if a.value < b.value {
					After
				} else if a.i < b.i {
					Before
				} else if a.i > b.i {
					After
				} else {
					Same
				},
		)
		List.map(sorted, |s| s.line)
	}

	## The same position reached two ways is one line.
	distinct_lines : List(Agent.Line) -> List(Agent.Line)
	distinct_lines = |lines|
		List.fold(lines, [], |kept, line| if List.any(kept, |k| k.game == line.game) { kept } else { List.append(kept, line) })

	## The messages of the best line through the rest of this turn.
	plan : Type.Game -> List(Type.GameMsg)
	plan = |game| {
		tabs = tables(game.zone_colors)
		color = Player.get_active_player(game).color
		var $level = settle({ game, msgs: [], drew: Bool.False })
		var $finished = []
		var $depth = 0
		while List.any($level, is_open) and $depth < 8 {
			$finished = List.concat($finished, List.drop_if($level, is_open))
			grown = List.join_map(List.keep_if($level, is_open), expand)
			$level = List.take_first(best_first(tabs, color, distinct_lines(grown)), beam_width)
			$depth = $depth + 1
		}
		match List.first(best_first(tabs, color, List.concat($finished, $level))) {
			Ok(line) => line.msgs
			Err(_) => []
		}
	}

	## The next click for the computer, or the naive player that always takes
	## the first choice it is offered (the baseline the computer is measured
	## against). A finished turn is passed to the next player.
	next_msg : [Computer, Naive], Type.Game -> Try(Type.GameMsg, [NothingToDo])
	next_msg = |kind, game| {
		player = Player.get_active_player(game)
		if player.turn == TurnDone {
			Ok(RotateBoard)
		} else {
			choices = match kind {
				Computer => plan(game)
				Naive => options(game)
			}
			match List.first(choices) {
				Ok(msg) => Ok(msg)
				Err(_) => Err(NothingToDo)
			}
		}
	}
}

# Red's distances on a four-color board, worked by hand. From red's FT the
# shortest way is three hops along the fast track to purple's FT (the zone
# before red's), then R4 .. DS and the base: 3 + 7 + 4 = 14. L0 is five steps
# before that; the pen one step and the wait before L0; the bullseye the wait
# and one step before purple's FT (11).
expect {
	colors = ["red", "blue", "green", "purple"]
	d = |zone, id| Agent.steps_left(Agent.tables(colors), colors, "red", { zone: NormalColor(zone), id })
	d("red", "B4") == 0 and d("red", "B1") == 3 and d("red", "FT") == 14 and d("red", "L0") == 19 and d("red", "HP1") == 24 and d("purple", "FT") == 11
}
expect {
	colors = ["red", "blue", "green", "purple"]
	Agent.steps_left(Agent.tables(colors), colors, "red", { zone: BullsEyeZone, id: "bullseye" }) == 18
}

# With a 2 and a 3, red takes the 3 that lands on blue and sends it home.
expect {
	start = Game.begin_game(0, Normal)
	piece_map = [{ key: { zone: NormalColor("red"), id: "L0" }, value: "red" }, { key: { zone: NormalColor("red"), id: "L3" }, value: "blue" }]
	players = Player.update_player(start.players, 0, |p| { ..p, hand: ["2", "3"], turn: TurnBegin })
	game = Player.set_turn_to_need_card({ ..start, piece_map, players })
	finished = List.fold(Agent.plan(game), game, |g, msg| Game.update_game(msg, History.init, g).1)
	Piece.get_piece(finished.piece_map, { zone: NormalColor("red"), id: "L3" }) == Ok("red")
	and Piece.get_piece(finished.piece_map, { zone: NormalColor("blue"), id: "HP1" }) == Ok("blue")
}
