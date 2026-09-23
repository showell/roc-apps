# The board, square by square, as Reach.fewest_cards sees it for a red piece
# holding a free face card (F+3 is a face card, then a 3):
# each zone drawn upright the way the page draws its panel, each square with
# the fewest cards that take a red piece from it to red's B4 and the cards
# that start such a way.
#
#   cd fasttrack && roc reach_board.roc > board.md
import Agent
import Reach

colors : List(Str)
colors = ["red", "blue", "green", "purple"]

## A zone's panel, row by row from the top: pen, L side, HH, base, BR, R side.
## "" is no square.
layout : List(List(Str))
layout = [
	["", "FT", "", "", "", ""],
	["", "L4", "", "B4", "", "R4"],
	["", "L3", "", "B3", "", "R3"],
	["", "L2", "", "B2", "", "R2"],
	["HP1", "L1", "", "B1", "", "R1"],
	["", "L0", "HH", "DS", "BR", "R0"],
]

show_card : Str -> Str
show_card = |card|
	match card {
		"4" => "4 back"
		"joker" => "Jo"
		_ => Str.replace_each(Str.replace_each(card, "face+", "F+"), "+4", "+4 back")
	}

cell : List(Reach.Best), Str, Str -> Str
cell = |best, zone, id|
	if id == "" {
		""
	} else if zone != "red" and (id == "HP1" or List.contains(["B1", "B2", "B3", "B4"], id)) {
		""
	} else {
		b = List.get(best, Agent.index_of(colors, { zone: NormalColor(zone), id })) ?? { cards: 0, first: [] }
		shown = if b.cards >= Agent.far { "never" } else { I64.to_str(b.cards) }
		# In deck order, whatever order the search found them in.
		in_order = List.concat(List.keep_if(Reach.cards, |c| List.contains(b.first, c)), List.keep_if(b.first, |c| Str.contains(c, "face")))
		how = if List.is_empty(in_order) { "" } else { " · ${Str.join_with(List.map(in_order, show_card), ", ")}" }
		label = if id == "HP1" { "pen" } else { id }
		"**${label}** ${shown}${how}"
	}

panel : List(Reach.Best), Str, Str -> Str
panel = |best, zone, caption| {
	rows = List.map(layout, |row| "| ${Str.join_with(List.map(row, |id| cell(best, zone, id)), " | ")} |")
	Str.join_with(List.concat(["### ${caption}", "", "| | | | | | |", "|---|---|---|---|---|---|"], rows), "\n")
}

main! = |_args| {
	best = Reach.fewest_cards(colors, "red", Bool.True)
	bulls = List.get(best, Agent.index_of(colors, { zone: BullsEyeZone, id: "bullseye" })) ?? { cards: 0, first: [] }
	echo!(panel(best, "red", "Red's zone (the mover's own)"))
	echo!("\n\n")
	echo!(panel(best, "blue", "Blue's zone (next after red's)"))
	echo!("\n\n")
	echo!(panel(best, "green", "Green's zone"))
	echo!("\n\n")
	echo!(panel(best, "purple", "Purple's zone (the one before red's)"))
	echo!("\n\n")
	echo!("### The bullseye\n\n**bullseye** ${I64.to_str(bulls.cards)} · ${Str.join_with(List.map(List.keep_if(Reach.cards, |c| List.contains(bulls.first, c)), show_card), ", ")}\n")
	Ok({})
}
