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
# **THE HEURISTIC** starts from distance: how many steps each piece has left
# to the deepest square of its own base, walking the board's real graph on an
# empty board. Waiting in the pen for a card that lets a piece out, and in the
# bullseye for a face card, cost extra steps. A position is worth the
# opponents' distance less four times the mover's own, so sending a piece
# home counts, but moving your own counts more. Three weighted terms, in the
# same units (a step of the mover's own is 4), are the mover's alone:
#
#   - `danger`, for each piece an opponent could land on next: one card away
#     from an opponent piece (1 to 10 forward, 4 back, out of the pen);
#   - `out_of_pen`, for each piece out of the pen;
#   - `home`, for each piece in its base, where nothing can touch it.
#
# The weights are a seat's own (FastTrack.Seat), so two computers with
# different ones can race (web/race.mjs).
import Config
import Piece
import Game
import History
import LegalMove
import Player
import Type

Agent :: [].{
	Line : { game : Type.Game, msgs : List(Type.GameMsg), drew : Bool }

	Weights : { danger : I64, out_of_pen : I64, home : I64 }

	## The weights a computer seat plays with unless told otherwise.
	default_weights : Agent.Weights
	default_weights = { danger: 0, out_of_pen: 0, home: 0 }

	## Where an opponent piece could land with one card: `lands` from
	## `from`, while a piece of `color` is still there.
	Threat : { from : Type.PieceLocation, color : Str, lands : List(Type.PieceLocation) }

	## What a plan's scoring needs that does not change inside a turn.
	Context : { tabs : Agent.Tables, threats : List(Agent.Threat), weights : Agent.Weights, color : Str }

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

	## Every square an opponent piece could land on with one card, from the
	## position a turn starts in. An opponent with a piece on the fast track
	## must move that one, so its others threaten nothing.
	threats : Type.Game, Str -> List(Agent.Threat)
	threats = |game, mover|
		List.join_map(
			game.piece_map,
			|entry| {
				color = entry.value
				loc = entry.key
				on_fast_track = loc.id == "FT"
				if color == mover or Config.is_base_id(loc.id) or (!on_fast_track and Piece.has_piece_on_fast_track(game.piece_map, color)) {
					[]
				} else {
					params = {
						reverse_mode: Bool.False,
						can_fast_track: on_fast_track,
						can_leave_pen: Bool.True,
						can_leave_bulls_eye: Bool.True,
						piece_color: color,
						piece_map: game.piece_map,
						zone_colors: game.zone_colors,
					}
					lands =
						if Config.is_holding_pen_id(loc.id) or loc.zone == BullsEyeZone {
							LegalMove.end_locations(params, loc, 1)
						} else {
							forward = List.join_map([1, 2, 3, 5, 6, 7, 8, 9, 10], |n| LegalMove.end_locations(params, loc, n))
							List.concat(forward, LegalMove.end_locations({ ..params, reverse_mode: Bool.True }, loc, 4))
						}
					[{ from: loc, color, lands }]
				}
			},
		)

	## A piece of the mover's on the open track that an opponent, still where
	## it was, could land on.
	endangered : Agent.Context, Type.Game, Type.PieceLocation -> Bool
	endangered = |ctx, game, loc|
		if Config.is_holding_pen_id(loc.id) or Config.is_base_id(loc.id) {
			Bool.False
		} else {
			List.any(ctx.threats, |t| List.contains(t.lands, loc) and Piece.get_piece(game.piece_map, t.from) == Ok(t.color))
		}

	context : Agent.Weights, Type.Game -> Agent.Context
	context = |weights, game| {
		color = Player.get_active_player(game).color
		{ tabs: tables(game.zone_colors), threats: threats(game, color), weights, color }
	}

	## Higher is better for the mover.
	score : Agent.Context, Type.Game -> I64
	score = |ctx, game| {
		w = ctx.weights
		List.fold(
			game.piece_map,
			0,
			|total, entry| {
				loc = entry.key
				steps = steps_left(ctx.tabs, game.zone_colors, entry.value, loc)
				if entry.value == ctx.color {
					out = if Config.is_holding_pen_id(loc.id) { 0 } else { w.out_of_pen }
					home = if Config.is_base_id(loc.id) { w.home } else { 0 }
					danger = if w.danger != 0 and endangered(ctx, game, loc) { w.danger } else { 0 }
					total - 4 * steps + out + home - danger
				} else {
					total + steps
				}
			},
		)
	}

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

	best_first : Agent.Context, List(Agent.Line) -> List(Agent.Line)
	best_first = |ctx, lines| {
		scored = List.map_with_index(lines, |line, i| { line, value: score(ctx, line.game), i })
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
	plan : Agent.Weights, Type.Game -> List(Type.GameMsg)
	plan = |weights, game| {
		ctx = context(weights, game)
		var $level = settle({ game, msgs: [], drew: Bool.False })
		var $finished = []
		var $depth = 0
		while List.any($level, is_open) and $depth < 8 {
			$finished = List.concat($finished, List.drop_if($level, is_open))
			grown = List.join_map(List.keep_if($level, is_open), expand)
			$level = List.take_first(best_first(ctx, distinct_lines(grown)), beam_width)
			$depth = $depth + 1
		}
		match List.first(best_first(ctx, List.concat($finished, $level))) {
			Ok(line) => line.msgs
			Err(_) => []
		}
	}

	## The next click for the computer, or the naive player that always takes
	## the first choice it is offered (the baseline the computer is measured
	## against). A finished turn is passed to the next player.
	next_msg : [Computer(Agent.Weights), Naive], Type.Game -> Try(Type.GameMsg, [NothingToDo])
	next_msg = |kind, game| {
		player = Player.get_active_player(game)
		if player.turn == TurnDone {
			Ok(RotateBoard)
		} else {
			choices = match kind {
				Computer(weights) => plan(weights, game)
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
	finished = List.fold(Agent.plan(Agent.default_weights, game), game, |g, msg| Game.update_game(msg, History.init, g).1)
	Piece.get_piece(finished.piece_map, { zone: NormalColor("red"), id: "L3" }) == Ok("red")
	and Piece.get_piece(finished.piece_map, { zone: NormalColor("blue"), id: "HP1" }) == Ok("blue")
}

# Red's piece on red's L2: a blue piece on red's L0 lands on it with a 2; one
# on red's L3 cannot -- forward it is a lap away, and a 4 back lands on HH.
expect {
	start = Game.begin_game(0, Normal)
	piece_map = [{ key: { zone: NormalColor("red"), id: "L2" }, value: "red" }, { key: { zone: NormalColor("red"), id: "L0" }, value: "blue" }]
	game = { ..start, piece_map }
	ctx = Agent.context({ danger: 1, out_of_pen: 0, home: 0 }, game)
	Agent.endangered(ctx, game, { zone: NormalColor("red"), id: "L2" })
}
expect {
	start = Game.begin_game(0, Normal)
	piece_map = [{ key: { zone: NormalColor("red"), id: "L2" }, value: "red" }, { key: { zone: NormalColor("red"), id: "L3" }, value: "blue" }]
	game = { ..start, piece_map }
	ctx = Agent.context({ danger: 1, out_of_pen: 0, home: 0 }, game)
	!Agent.endangered(ctx, game, { zone: NormalColor("red"), id: "L2" })
}
