# Rank -- Steve's ranking of the squares, for a piece of one color, counting
# the way to a peak (B3 once B4 is taken; B1 to rank against the base as a
# whole) with a free face card played first. Best first:
#
#   1. the piece's own base squares above everything else, the deeper first;
#   2. fewer cards to the peak, with every card but the joker;
#   3. then more routes -- every shortest sequence of moves, a move being a
#      card or a face card and a card;
#   4. then, while still tied, the same two (fewer cards, more routes) with the
#      6 gone from the deck; then the 7 too; then the 4; then the J, Q and K,
#      and with them the free face card -- late, so that face + 8 still counts
#      as a cheaper play than face + 7; and last the 9 and 10, so a square
#      reached with a 2 or 3 beats one reached with a 9 or 10.
#
# rank_board.roc prints it; the page's heat map colors the board by it.
import Agent
import Reach
import Type

Rank :: [].{
	## The decks, stage by stage: each drops more kinds of card.
	stages : List({ title : Str, hand : List(Str) })
	stages = {
		all = List.drop_if(Reach.cards, |c| c == "joker")
		no6 = List.drop_if(all, |c| c == "6")
		no7 = List.drop_if(no6, |c| c == "7")
		no4 = List.drop_if(no7, |c| c == "4")
		no_face = List.drop_if(no4, |c| List.contains(["J", "Q", "K"], c))
		no_high = List.drop_if(no_face, |c| c == "9" or c == "10")
		[
			{ title: "no joker", hand: all },
			{ title: "no 6", hand: no6 },
			{ title: "no 7", hand: no7 },
			{ title: "no 4", hand: no4 },
			{ title: "no J/Q/K", hand: no_face },
			{ title: "no 9/10", hand: no_high },
		]
	}

	## A square that can reach the peak: where it is (indexed as
	## Agent.all_locs), its base depth for rule 2, and its cards and routes
	## at each stage.
	Row : { at : U64, loc : Type.PieceLocation, base : I64, stage : List(Reach.Routes) }

	## Base depth, for rule 1: B4 4, B3 3, B2 2, B1 1, anything else 0.
	base_depth : Str -> I64
	base_depth = |id|
		match id {
			"B1" => 1
			"B2" => 2
			"B3" => 3
			"B4" => 4
			_ => 0
		}

	## One stage: fewer cards, then more routes. -1 when `a` is better.
	by_stage : Reach.Routes, Reach.Routes -> I64
	by_stage = |a, b|
		if a.cards != b.cards {
			if a.cards < b.cards { -1 } else { 1 }
		} else if a.routes != b.routes {
			if a.routes > b.routes { -1 } else { 1 }
		} else {
			0
		}

	## -1 when `a` ranks above `b`, 1 below, 0 a tie at every stage.
	compare : Rank.Row, Rank.Row -> I64
	compare = |a, b| {
		first = |r| List.first(r.stage) ?? { cards: Agent.far, routes: 0 }
		if a.base != b.base {
			if a.base > b.base { -1 } else { 1 }
		} else if first(a).cards != first(b).cards {
			if first(a).cards < first(b).cards { -1 } else { 1 }
		} else {
			List.fold(
				List.map_with_index(a.stage, |sa, i| by_stage(sa, List.get(b.stage, i) ?? { cards: Agent.far, routes: 0 })),
				0,
				|decided, c| if decided != 0 { decided } else { c },
			)
		}
	}

	## Every square a piece of `color` can reach the peak from, best first
	## (ties in board order).
	ranked : List(Str), Str, Str -> List(Rank.Row)
	ranked = |zone_colors, color, peak| ranked_in(Reach.grid(zone_colors, color), zone_colors, color, peak)

	## `ranked`, over a color's grid built once (Reach.grid).
	ranked_in : List(Reach.Move), List(Str), Str, Str -> List(Rank.Row)
	ranked_in = |grid, zone_colors, color, peak| {
		tables = List.map(stages, |st| Reach.routes_in(grid, zone_colors, color, Bool.True, peak, st.hand))
		rows = List.join(
			List.map_with_index(
				Agent.all_locs(zone_colors),
				|loc, i| {
					stage = List.map(tables, |t| List.get(t, i) ?? { cards: Agent.far, routes: 0 })
					id = if loc.zone == NormalColor(color) { loc.id } else { "" }
					base = base_depth(id)
					# The base squares past the peak count too: they rank first.
					if base == 0 and (List.first(stage) ?? { cards: Agent.far, routes: 0 }).cards >= Agent.far {
						[]
					} else {
						[{ at: i, loc, base, stage }]
					}
				},
			),
		)
		List.sort_with(
			rows,
			|a, b| {
				c = compare(a, b)
				if c < 0 { Before } else if c > 0 { After } else if a.at < b.at { Before } else { After }
			},
		)
	}

	## For each square, indexed as Agent.all_locs: its place in the ranking,
	## 0 the best, a tie sharing the better place; U64.highest where it cannot reach
	## the peak. `worst` is the place of the last square.
	Places : { place : List(U64), worst : U64 }

	places : List(Str), Str, Str -> Rank.Places
	places = |zone_colors, color, peak| places_in(Reach.grid(zone_colors, color), zone_colors, color, peak)

	places_in : List(Reach.Move), List(Str), Str, Str -> Rank.Places
	places_in = |grid, zone_colors, color, peak| {
		order = ranked_in(grid, zone_colors, color, peak)
		start = List.repeat(U64.highest, List.len(Agent.all_locs(zone_colors)))
		settled = List.fold(
			List.map_with_index(order, |row, i| { row, i }),
			{ place: start, prev: { row: List.first(order) ?? { at: 0, loc: { zone: BullsEyeZone, id: "" }, base: 0, stage: [] }, place: 0 } },
			|acc, x| {
				p = if x.i > 0 and compare(acc.prev.row, x.row) == 0 { acc.prev.place } else { x.i }
				{ place: List.set(acc.place, x.row.at, p) ?? crash("Rank: square out of range"), prev: { row: x.row, place: p } }
			},
		)
		worst = List.fold(settled.place, 0, |m, p| if p != U64.highest and p > m { p } else { m })
		{ place: settled.place, worst }
	}
}

# Red's places to B3: B4 first (a base square), then B3, B2 and B1; R4 above
# R3; DS above R4; the pen squares share one place.
expect {
	colors = ["red", "blue", "green", "purple"]
	p = Rank.places(colors, "red", "B3")
	at = |id| List.get(p.place, Agent.index_of(colors, { zone: NormalColor("red"), id })) ?? U64.highest
	at("B4") == 0 and at("B3") == 1 and at("B2") == 2 and at("B1") == 3 and at("DS") < at("R4") and at("R4") < at("R3") and at("HP1") == at("HP4")
}

# To B1: B4, B3, B2, B1 first, in that order; then BR, with five one-card
# ways in (2, or a face card then A, J, Q or K), above DS, with four (A, J,
# Q, K -- no joker).
expect {
	colors = ["red", "blue", "green", "purple"]
	p = Rank.places(colors, "red", "B1")
	at = |id| List.get(p.place, Agent.index_of(colors, { zone: NormalColor("red"), id })) ?? U64.highest
	at("B4") == 0 and at("B3") == 1 and at("B2") == 2 and at("B1") == 3 and at("BR") == 4 and at("DS") == 5
}
