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
# **THE HEURISTIC IS SYMMETRIC.** Every player's position is valued by the
# same function, and a line is worth the mover's value less the leading
# opponent's. A player's value, in units where one step is 4:
#
#   - minus 4 for every step its pieces have left to the deepest square of
#     their base, on the board's real graph (below);
#   - `out_of_pen` for each piece out of the pen;
#   - `home` for each piece in its base, where nothing can touch it;
#   - minus `danger` for each piece on the open track that another player's
#     piece could land on with one card (1 to 10 forward, 4 back, out of the
#     pen or the bullseye).
#
# Because danger is everyone's, a move that puts an opponent in danger lowers
# that opponent's value: chasing pays, and so does sending a piece home.
#
# **A SHORTCUT NEEDS AN EXACT LANDING.** A piece hops the fast track, or
# enters the bullseye, only from a move that ends on a fast-track square.
# Walking the graph as if that were free makes the whole board short -- the
# pen came out 24 steps from home -- and shrinks what every move and capture
# is worth. So those two edges cost `hop` steps rather than one; 14 is what
# walking a zone costs. Waiting in the pen for an A, 6 or joker, and in the
# bullseye for a face card, cost extra steps too.
#
# Danger is read off tables worked out once per plan on an empty board, so it
# does not see a piece blocked by one of its own.
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

	Weights : { danger : I64, out_of_pen : I64, home : I64, hop : I64, pen : I64, back4 : I64 }

	## The weights a computer seat plays with unless told otherwise: the
	## winners of the races in TUNING.md.
	default_weights : Agent.Weights
	default_weights = { danger: 0, out_of_pen: 0, home: 10, hop: 1, pen: 4, back4: 0 }

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

	## A piece of `color` moving with every freedom a card can give.
	free_params : List(Str), Str, Bool -> Type.FindLocParams
	free_params = |zone_colors, color, on_fast_track| {
		reverse_mode: Bool.False,
		can_fast_track: on_fast_track,
		can_leave_pen: Bool.True,
		can_leave_bulls_eye: Bool.True,
		piece_color: color,
		piece_map: [],
		zone_colors,
	}

	## A zone's squares from its R4 to its DS: the last stretch before the base.
	home_stretch : List(Str)
	home_stretch = ["R4", "R3", "R2", "R1", "R0", "BR", "DS"]

	## One edge of a piece's way home, and what kind of step it is.
	Edge : { from : U64, to : U64, cost : I64, kind : [Walk, Hop, LeavePen, LeaveBullsEye, Back4] }

	## The board as a piece of `color` sees it on an empty board, every edge
	## costed: a walk 1; a fast-track hop, or entering the bullseye, `hop`
	## (both need an exact landing); leaving the pen 1 + `pen`, the wait for
	## an A, 6 or joker; leaving the bullseye 1 + the wait for a face card;
	## and, when `back4` is not 0, a 4 played backwards, `back4` -- coming out
	## of the pen and going back 4 puts a piece on its own R0, 6 from home.
	## Only a 4 that lands a piece in its own home stretch counts: chaining
	## 4s backwards round the board is no plan anyone can deal themselves.
	graph : List(Str), Str, I64, I64, I64 -> List(Agent.Edge)
	graph = |zone_colors, color, hop, pen, back4| {
		locs = all_locs(zone_colors)
		params = free_params(zone_colors, color, Bool.True)
		forward = List.join(
			List.map_with_index(
				locs,
				|loc, from|
					List.map(
						LegalMove.get_next_locs(params, loc),
						|next| {
							to = index_of(zone_colors, next)
							if Config.is_holding_pen_id(loc.id) {
								{ from, to, cost: 1 + pen, kind: LeavePen }
							} else if loc.zone == BullsEyeZone {
								{ from, to, cost: 1 + bulls_eye_wait, kind: LeaveBullsEye }
							} else if loc.id == "FT" and (next.id == "FT" or next.zone == BullsEyeZone) {
								{ from, to, cost: hop, kind: Hop }
							} else {
								{ from, to, cost: 1, kind: Walk }
							}
						},
					),
			),
		)
		backwards =
			if back4 == 0 {
				[]
			} else {
				back_params = { ..free_params(zone_colors, color, Bool.False), reverse_mode: Bool.True }
				List.join(
					List.map_with_index(
						locs,
						|loc, from|
							LegalMove.end_locations(back_params, loc, 4)
							.keep_if(|back| back.zone == NormalColor(color) and List.contains(home_stretch, back.id))
							.map(|back| { from, to: index_of(zone_colors, back), cost: back4, kind: Back4 }),
					),
				)
			}
		List.concat(forward, backwards)
	}

	## For every square, indexed as `all_locs`: the steps left to B4 and the
	## first edge of the shortest way there (`first` is meaningless where
	## `steps` is 0 or `far`). Bellman-Ford over `graph`, walked backwards
	## from B4.
	Route : { steps : I64, first : Agent.Edge }

	routes : List(Str), Str, I64, I64, I64 -> List(Agent.Route)
	routes = |zone_colors, color, hop, pen, back4| {
		edges = graph(zone_colors, color, hop, pen, back4)
		none = { from: 0, to: 0, cost: 0, kind: Walk }
		home = index_of(zone_colors, { zone: NormalColor(color), id: "B4" })
		start = List.set(List.repeat({ steps: far, first: none }, List.len(all_locs(zone_colors))), home, { steps: 0, first: none }) ?? crash("Agent.routes: no home square")
		# A pass says whether it changed anything. **NOT `while $next != $d`**:
		# with the pass a closure over the edges, the LLVM build (nightly
		# 09-07) lets it write into the list `$d` still names, so the two
		# compare equal after one pass and every square but B3 and B4 stays
		# `far`. The dev build gets it right (findings/llvm-closure-loop-alias).
		relax = |d|
			List.fold(
				edges,
				{ d, changed: Bool.False },
				|acc, e| {
					via = (List.get(acc.d, e.to) ?? { steps: far, first: none }).steps + e.cost
					if via < (List.get(acc.d, e.from) ?? { steps: far, first: none }).steps {
						{ d: List.set(acc.d, e.from, { steps: via, first: e }) ?? crash("Agent.routes: edge out of range"), changed: Bool.True }
					} else {
						acc
					}
				},
			)
		var $pass = relax(start)
		while $pass.changed {
			$pass = relax($pass.d)
		}
		$pass.d
	}

	## Steps left for a piece of `color` on each square, indexed as `all_locs`.
	distances : List(Str), Str, I64, I64, I64 -> List(I64)
	distances = |zone_colors, color, hop, pen, back4| List.map(routes(zone_colors, color, hop, pen, back4), |r| r.steps)

	## Every square a piece of `color` on each square could land on with one
	## card, indexed as `all_locs`, on an empty board.
	reach : List(Str), Str -> List(List(U64))
	reach = |zone_colors, color|
		List.map(
			all_locs(zone_colors),
			|loc| {
				params = free_params(zone_colors, color, loc.id == "FT")
				lands =
					if Config.is_holding_pen_id(loc.id) or loc.zone == BullsEyeZone {
						LegalMove.end_locations(params, loc, 1)
					} else {
						forward = List.join_map([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], |n| LegalMove.end_locations(params, loc, n))
						List.concat(forward, LegalMove.end_locations({ ..params, reverse_mode: Bool.True }, loc, 4))
					}
				List.map(lands, |l| index_of(zone_colors, l))
			},
		)

	## What scoring needs that a plan does not change: per color, in the
	## game's color order, steps left and one-card reach from every square.
	Knowledge : { weights : Agent.Weights, steps : List(List(I64)), reach : List(List(List(U64))) }

	knowledge : Agent.Weights, List(Str) -> Agent.Knowledge
	knowledge = |weights, zone_colors| {
		weights,
		steps: List.map(zone_colors, |color| distances(zone_colors, color, weights.hop, weights.pen, weights.back4)),
		reach: List.map(zone_colors, |color| reach(zone_colors, color)),
	}

	## A piece where the tables can find it: its color's place, its square's.
	Placed : { owner : U64, at : U64, loc : Type.PieceLocation }

	placed : Type.Game -> List(Agent.Placed)
	placed = |game|
		List.map(
			game.piece_map,
			|entry| {
				owner: List.find_first_index(game.zone_colors, |c| c == entry.value) ?? crash("Agent.placed: no such color"),
				at: index_of(game.zone_colors, entry.key),
				loc: entry.key,
			},
		)

	## Whether an opponent's piece could land on this one. A player with a
	## piece on the fast track must move that one, so its others do not
	## count. A partner could, but would not.
	in_danger : Agent.Knowledge, List(Agent.Placed), Agent.Placed, List(U64) -> Bool
	in_danger = |k, pieces, piece, partner_list|
		if Config.is_holding_pen_id(piece.loc.id) or Config.is_base_id(piece.loc.id) {
			Bool.False
		} else {
			List.any(
				pieces,
				|other| {
					forced = List.any(pieces, |p| p.owner == other.owner and p.loc.id == "FT")
					partner = List.get(partner_list, piece.owner) ?? piece.owner
					if other.owner == piece.owner or other.owner == partner or (forced and other.loc.id != "FT") {
						Bool.False
					} else {
						lands = List.get(List.get(k.reach, other.owner) ?? [], other.at) ?? []
						List.contains(lands, piece.at)
					}
				},
			)
		}

	## Each player's partner, by place in the game's color order; a player
	## alone is its own.
	partners : Type.Game -> List(U64)
	partners = |game|
		List.map_with_index(
			game.players,
			|player, i|
				match player.team {
					Solo => i
					# One arm each: `Partner(p) | PartnerOnceHome(p)` here makes
					# `roc check` fail with OutOfMemory (nightly 09-07).
					Partner(p) => List.find_first_index(game.zone_colors, |c| c == p) ?? i
					PartnerOnceHome(p) => List.find_first_index(game.zone_colors, |c| c == p) ?? i
				},
		)

	## Each player's value, in the game's color order.
	values : Agent.Knowledge, Type.Game -> List(I64)
	values = |k, game| {
		w = k.weights
		pieces = placed(game)
		partner_list = partners(game)
		List.map_with_index(
			game.zone_colors,
			|_, owner|
				List.fold(
					List.keep_if(pieces, |p| p.owner == owner),
					0,
					|total, p| {
						steps = List.get(List.get(k.steps, owner) ?? [], p.at) ?? far
						out = if Config.is_holding_pen_id(p.loc.id) { 0 } else { w.out_of_pen }
						home = if Config.is_base_id(p.loc.id) { w.home } else { 0 }
						danger = if w.danger != 0 and in_danger(k, pieces, p, partner_list) { w.danger } else { 0 }
						total - 4 * steps + out + home - danger
					},
				),
		)
	}

	## The mover's value less the leading opponent's; in a partnership, the
	## team's value (both partners') less the leading other team's.
	score : Agent.Knowledge, Type.Game -> I64
	score = |k, game| {
		vals = values(k, game)
		partner_list = partners(game)
		team_value = |i| {
			p = List.get(partner_list, i) ?? i
			own = List.get(vals, i) ?? 0
			if p == i { own } else { own + (List.get(vals, p) ?? 0) }
		}
		mover = game.active_player_idx
		mover_partner = List.get(partner_list, mover) ?? mover
		best_other = List.fold(
			List.map_with_index(vals, |_, i| i),
			-1000000,
			|best, i| if i == mover or i == mover_partner { best } else if team_value(i) > best { team_value(i) } else { best },
		)
		team_value(mover) - best_other
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

	best_first : Agent.Knowledge, List(Agent.Line) -> List(Agent.Line)
	best_first = |k, lines| {
		scored = List.map_with_index(lines, |line, i| { line, value: score(k, line.game), i })
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
	## `k` is built once per seat (FastTrack.Seat): its tables depend only on
	## the colors and the weights.
	plan : Agent.Knowledge, Type.Game -> List(Type.GameMsg)
	plan = |k, game| {
		var $level = settle({ game, msgs: [], drew: Bool.False })
		var $finished = []
		var $depth = 0
		while List.any($level, is_open) and $depth < 8 {
			$finished = List.concat($finished, List.drop_if($level, is_open))
			grown = List.join_map(List.keep_if($level, is_open), expand)
			$level = List.take_first(best_first(k, distinct_lines(grown)), beam_width)
			$depth = $depth + 1
		}
		match List.first(best_first(k, List.concat($finished, $level))) {
			Ok(line) => line.msgs
			Err(_) => []
		}
	}

	## The next click for the computer, or the naive player that always takes
	## the first choice it is offered (the baseline the computer is measured
	## against). A finished turn is passed to the next player.
	next_msg : [Computer(Agent.Knowledge), Naive], Type.Game -> Try(Type.GameMsg, [NothingToDo])
	next_msg = |kind, game| {
		player = Player.get_active_player(game)
		if player.turn == TurnDone {
			Ok(RotateBoard)
		} else {
			choices = match kind {
				Computer(k) => plan(k, game)
				Naive => options(game)
			}
			match List.first(choices) {
				Ok(msg) => Ok(msg)
				Err(_) => Err(NothingToDo)
			}
		}
	}
}

# Red's distances on a four-color board, worked by hand, with a free hop.
# From red's FT the shortest way is three hops along the fast track to
# purple's FT (the zone before red's), then R4 .. DS and the base: 3 + 7 + 4
# = 14. L0 is five steps before that; the pen one step and the wait before
# L0; the bullseye the wait and one step before purple's FT (11).
expect {
	colors = ["red", "blue", "green", "purple"]
	d = Agent.distances(colors, "red", 1, 4, 0)
	at = |zone, id| List.get(d, Agent.index_of(colors, { zone: NormalColor(zone), id })) ?? 0
	at("red", "B4") == 0 and at("red", "B1") == 3 and at("red", "FT") == 14 and at("red", "L0") == 19 and at("red", "HP1") == 24 and at("purple", "FT") == 11
}
expect {
	colors = ["red", "blue", "green", "purple"]
	List.get(Agent.distances(colors, "red", 1, 4, 0), Agent.index_of(colors, { zone: BullsEyeZone, id: "bullseye" })) == Ok(18)
}

# Steve's two squares: six past red's pen without the bullseye is blue's R4,
# 13 to blue's fast track and 13 more home (26); landing on blue's FT
# instead leaves the 13. With a 4-step wait, red's pen is 24 -- better than
# being out and stuck on blue's R4, which is what the `pen` weight is for.
expect {
	colors = ["red", "blue", "green", "purple"]
	d = Agent.distances(colors, "red", 1, 4, 0)
	at = |zone, id| List.get(d, Agent.index_of(colors, { zone: NormalColor(zone), id })) ?? 0
	at("blue", "R4") == 26 and at("blue", "FT") == 13 and at("red", "HP1") == 24
}

# Steve: out of the pen and back 4 is the game's best legal cheat. With the
# 4 costing one step, red's L0 is 7: back to red's R0, then BR, DS and B1..B4.
expect {
	colors = ["red", "blue", "green", "purple"]
	d = Agent.distances(colors, "red", 1, 4, 1)
	at = |zone, id| List.get(d, Agent.index_of(colors, { zone: NormalColor(zone), id })) ?? 0
	at("red", "L0") == 7 and at("red", "R0") == 6 and at("red", "HP1") == 12
}

# With a hop as dear as walking a zone (14), red's FT is 32 from home: into
# the bullseye (14), the wait and a step out (7), then purple's FT's 11.
# Walking the three zones would be 42 + 11.
expect {
	colors = ["red", "blue", "green", "purple"]
	List.get(Agent.distances(colors, "red", 14, 4, 0), Agent.index_of(colors, { zone: NormalColor("red"), id: "FT" })) == Ok(32)
}

# With a 2 and a 3, red takes the 3 that lands on blue and sends it home.
expect {
	start = Game.begin_game(0, Normal, Solo)
	piece_map = [{ key: { zone: NormalColor("red"), id: "L0" }, value: "red" }, { key: { zone: NormalColor("red"), id: "L3" }, value: "blue" }]
	players = Player.update_player(start.players, 0, |p| { ..p, hand: ["2", "3"], turn: TurnBegin })
	game = Player.set_turn_to_need_card({ ..start, piece_map, players })
	finished = List.fold(Agent.plan(Agent.knowledge(Agent.default_weights, game.zone_colors), game), game, |g, msg| Game.update_game(msg, History.init, g).1)
	Piece.get_piece(finished.piece_map, { zone: NormalColor("red"), id: "L3" }) == Ok("red")
	and Piece.get_piece(finished.piece_map, { zone: NormalColor("blue"), id: "HP1" }) == Ok("blue")
}

# Red's piece on red's L2: a blue piece on red's L0 lands on it with a 2; one
# on red's L3 cannot -- forward it is a lap away, and a 4 back lands on HH.
# Danger is everyone's: blue on L0 is safe from red (a 4 back from L2 lands
# on DS), but blue on L3 is one step ahead of red.
expect {
	colors = ["red", "blue", "green", "purple"]
	k = Agent.knowledge({ ..Agent.default_weights, danger: 1 }, colors)
	danger = |blue_id| {
		game = { ..Game.begin_game(0, Normal, Solo), piece_map: [{ key: { zone: NormalColor("red"), id: "L2" }, value: "red" }, { key: { zone: NormalColor("red"), id: blue_id }, value: "blue" }] }
		List.map(Agent.placed(game), |p| Agent.in_danger(k, Agent.placed(game), p, [0, 1, 2, 3]))
	}
	danger("L0") == [Bool.True, Bool.False] and danger("L3") == [Bool.False, Bool.True]
}
