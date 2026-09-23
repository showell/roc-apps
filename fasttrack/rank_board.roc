# Steve's ranking of the squares, for a red piece with B4 taken (the peak is
# B3) and a free face card played first. Best first:
#
#   1. fewer cards to the peak, with every card but the joker;
#   2. among equals, a base square above the rest, the deeper first;
#   3. then more routes -- every shortest sequence of moves, a move being a
#      card or a face card and a card;
#   4. then, while still tied, the same two (fewer cards, more routes) with the
#      6 gone from the deck; then the 7 too; then the 4; and last the J, Q and
#      K, and with them the free face card -- last, so that face + 8 still
#      counts as a cheaper play than face + 7.
#
# Squares that still tie after every stage are listed at the end.
#
#   cd fasttrack && roc rank_board.roc > rank.md
import Agent
import Config
import Reach

colors : List(Str)
colors = ["red", "blue", "green", "purple"]

letter : Str -> Str
letter = |color|
	match color {
		"red" => "r"
		"blue" => "b"
		"green" => "g"
		_ => "p"
	}

## The decks, stage by stage: each drops more kinds of card.
stages : List({ title : Str, hand : List(Str) })
stages = {
	all = List.drop_if(Reach.cards, |c| c == "joker")
	no6 = List.drop_if(all, |c| c == "6")
	no7 = List.drop_if(no6, |c| c == "7")
	no4 = List.drop_if(no7, |c| c == "4")
	no_face = List.drop_if(no4, |c| List.contains(["J", "Q", "K"], c))
	[
		{ title: "no joker", hand: all },
		{ title: "no 6", hand: no6 },
		{ title: "no 7", hand: no7 },
		{ title: "no 4", hand: no4 },
		{ title: "no J/Q/K", hand: no_face },
	]
}

Row : { name : Str, at : U64, base : I64, stage : List(Reach.Routes) }

## Base depth, for rule 2: B3 3, B2 2, B1 1, anything else 0.
base_depth : Str -> I64
base_depth = |id|
	match id {
		"B1" => 1
		"B2" => 2
		"B3" => 3
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
compare : Row, Row -> I64
compare = |a, b| {
	first = |r| List.first(r.stage) ?? { cards: Agent.far, routes: 0 }
	if first(a).cards != first(b).cards {
		if first(a).cards < first(b).cards { -1 } else { 1 }
	} else if a.base != b.base {
		if a.base > b.base { -1 } else { 1 }
	} else {
		List.fold(
			List.map_with_index(a.stage, |sa, i| by_stage(sa, List.get(b.stage, i) ?? { cards: Agent.far, routes: 0 })),
			0,
			|decided, c| if decided != 0 { decided } else { c },
		)
	}
}

rows : List(Row)
rows = {
	tables = List.map(stages, |st| Reach.routes_with(colors, "red", Bool.True, "B3", st.hand))
	List.join(
		List.map_with_index(
			Agent.all_locs(colors),
			|loc, i| {
				stage = List.map(tables, |t| List.get(t, i) ?? { cards: Agent.far, routes: 0 })
				if (List.first(stage) ?? { cards: Agent.far, routes: 0 }).cards >= Agent.far {
					[]
				} else {
					name = match loc.zone {
						BullsEyeZone => "bullseye"
						NormalColor(zone) => "${letter(zone)}${loc.id}"
					}
					id = if loc.zone == NormalColor("red") { loc.id } else { "" }
					[{ name, at: i, base: base_depth(id), stage }]
				}
			},
		),
	)
}

## A stage's cell: cards and routes, "-" where the square cannot reach the
## peak with that deck.
cell : Reach.Routes -> Str
cell = |r| if r.cards >= Agent.far { "-" } else { "${I64.to_str(r.cards)} / ${U64.to_str(r.routes)}" }

ranked : List(Row)
ranked = List.sort_with(rows, |a, b| {
	c = compare(a, b)
	if c < 0 { Before } else if c > 0 { After } else if a.at < b.at { Before } else { After }
})

main! = |_args| {
	lines = List.map(ranked, |r| "| ${r.name} | ${Str.join_with(List.map(r.stage, cell), " | ")} |")
	header = "| square | ${Str.join_with(List.map(stages, |st| st.title), " | ")} |\n|---|---|---|---|---|---|\n"
	echo!(Str.concat(header, Str.join_with(lines, "\n")))
	echo!("\n\n")
	# Neighbours in the ranking that compare equal: the ties.
	ties = List.join(
		List.map_with_index(
			ranked,
			|r, i|
				match List.get(ranked, i + 1) {
					Ok(next) if compare(r, next) == 0 => ["${r.name} = ${next.name}"]
					_ => []
				},
		),
	)
	echo!("ties: ${Str.join_with(ties, ", ")}\n")
	Ok({})
}
