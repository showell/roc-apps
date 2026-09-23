# Steve's ranking of the squares (Rank.roc), printed: for a red piece, every
# square it can reach B3 from, best first, with its cards / routes at each
# stage of the cascade, and the squares that still tie at the end.
#
#   cd fasttrack && roc rank_board.roc > rank.md
import Agent
import Rank
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

name : Rank.Row -> Str
name = |r|
	match r.loc.zone {
		BullsEyeZone => "bullseye"
		NormalColor(zone) => "${letter(zone)}${r.loc.id}"
	}

## A stage's cell: cards and routes, "-" where the square cannot reach the
## peak with that deck.
cell : Reach.Routes -> Str
cell = |r| if r.cards >= Agent.far { "-" } else { "${I64.to_str(r.cards)} / ${U64.to_str(r.routes)}" }

main! = |_args| {
	ranked = Rank.ranked(colors, "red")
	lines = List.map(ranked, |r| "| ${name(r)} | ${Str.join_with(List.map(r.stage, cell), " | ")} |")
	header = "| square | ${Str.join_with(List.map(Rank.stages, |st| st.title), " | ")} |\n|---|---|---|---|---|---|---|\n"
	echo!(Str.concat(header, Str.join_with(lines, "\n")))
	echo!("\n\n")
	# Neighbours in the ranking that compare equal: the ties.
	ties = List.join(
		List.map_with_index(
			ranked,
			|r, i|
				match List.get(ranked, i + 1) {
					Ok(next) if Rank.compare(r, next) == 0 => ["${name(r)} = ${name(next)}"]
					_ => []
				},
		),
	)
	echo!("ties: ${Str.join_with(ties, ", ")}\n")
	Ok({})
}
