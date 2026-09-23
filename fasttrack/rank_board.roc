# Steve's ranking of the squares, for a red piece with B4 taken (the peak is
# B3) and a free face card. Best first:
#
#   1. fewer cards to the peak;
#   2. among equals, a base square above the rest, the deeper first;
#   3. then more ways in: the distinct first cards of a shortest way, "face
#      then 5" apart from "6";
#   4. then more of those ways on an expendable card -- 2, 3, 5, 8, 9 or 10,
#      which do not leave the pen, go backwards, split, or let a player go
#      again.
#
# Squares that still tie after all four are listed at the end.
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

expendable : List(Str)
expendable = ["2", "3", "5", "8", "9", "10"]

## The card a way is played with, after any free face card.
played : Str -> Str
played = |way| Str.drop_prefix(way, "face+")

show_way : Str -> Str
show_way = |way| Str.replace_each(Str.replace_each(Str.replace_each(way, "face+", "F+"), "joker", "Jo"), "4", "4 back")

Row : { name : Str, at : U64, cards : I64, base : I64, ways : List(Str), spare : U64 }

## Base depth, for rule 2: B2 is 2, B1 1, anything else 0.
base_depth : Str -> I64
base_depth = |id|
	match id {
		"B1" => 1
		"B2" => 2
		"B3" => 3
		_ => 0
	}

## -1 when `a` ranks above `b`, 1 below, 0 a tie.
compare : Row, Row -> I64
compare = |a, b|
	if a.cards != b.cards {
		if a.cards < b.cards { -1 } else { 1 }
	} else if a.base != b.base {
		if a.base > b.base { -1 } else { 1 }
	} else if List.len(a.ways) != List.len(b.ways) {
		if List.len(a.ways) > List.len(b.ways) { -1 } else { 1 }
	} else if a.spare != b.spare {
		if a.spare > b.spare { -1 } else { 1 }
	} else {
		0
	}

rows : List(Row)
rows = {
	best = Reach.fewest_cards(colors, "red", Bool.True, "B3")
	List.join(
		List.map_with_index(
			Agent.all_locs(colors),
			|loc, i| {
				b = List.get(best, i) ?? { cards: Agent.far, first: [] }
				if b.cards >= Agent.far {
					[]
				} else {
					name = match loc.zone {
						BullsEyeZone => "bullseye"
						NormalColor(zone) => "${letter(zone)}${loc.id}"
					}
					id = if loc.zone == NormalColor("red") { loc.id } else { "" }
					[{ name, at: i, cards: b.cards, base: base_depth(id), ways: b.first, spare: List.count_if(b.first, |w| List.contains(expendable, played(w))) }]
				}
			},
		),
	)
}

ranked : List(Row)
ranked = List.sort_with(rows, |a, b| {
	c = compare(a, b)
	if c < 0 { Before } else if c > 0 { After } else if a.at < b.at { Before } else { After }
})

main! = |_args| {
	lines = List.map(
		ranked,
		|r| "| ${r.name} | ${I64.to_str(r.cards)} | ${U64.to_str(List.len(r.ways))} | ${U64.to_str(r.spare)} | ${Str.join_with(List.map(r.ways, show_way), ", ")} |",
	)
	echo!(Str.concat("| square | cards | ways | expendable | ways in |\n|---|---|---|---|---|\n", Str.join_with(lines, "\n")))
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
