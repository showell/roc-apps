# The computer's distance table, as a person can check it: for each square a
# red piece can stand on, in the order a lap visits them, the steps left to
# red's B4, the formula those steps are (how many of each kind of edge), and
# the route square by square. It reads Agent.routes, the same graph the
# computer plays on, so the table cannot disagree with the player.
#
#   cd fasttrack && roc distance_table.roc > table.md
#
# Squares are written zone letter and id: r red (the mover), b blue (next),
# g green, p purple (the zone before red's). In a route, -> is a walk, => a
# fast-track hop or entering the bullseye, ~> leaving the pen or the
# bullseye, <- a 4 played backwards.
import Agent
import Config

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

name : U64 -> Str
name = |i| {
	per_zone = List.len(Config.config_locations)
	if i == List.len(colors) * per_zone {
		"bullseye"
	} else {
		zone = List.get(colors, i // per_zone) ?? "?"
		square = List.get(Config.config_locations, i % per_zone) ?? { x: 0.0, y: 0.0, id: "?" }
		"${letter(zone)}${square.id}"
	}
}

at : Str, Str -> U64
at = |zone, id| Agent.index_of(colors, { zone: NormalColor(zone), id })

## The squares of a lap, from red's pen to red's base.
lap : List(U64)
lap = {
	pen = List.map(["HP1"], |id| at("red", id))
	start = List.map(["L0", "L1", "L2", "L3", "L4", "FT"], |id| at("red", id))
	other = |zone| List.map(["R4", "R3", "R2", "R1", "R0", "BR", "DS", "HH", "L0", "L1", "L2", "L3", "L4", "FT"], |id| at(zone, id))
	finish = List.map(["R4", "R3", "R2", "R1", "R0", "BR", "DS", "B1", "B2", "B3", "B4"], |id| at("red", id))
	List.join([pen, start, other("blue"), other("green"), other("purple"), finish, [List.len(colors) * List.len(Config.config_locations)]])
}

arrow : [Walk, Hop, LeavePen, LeaveBullsEye, Back4] -> Str
arrow = |kind|
	match kind {
		Walk => " -> "
		Hop => " => "
		LeavePen => " ~> "
		LeaveBullsEye => " ~> "
		Back4 => " <- "
	}

## The route from square `i`, and how many edges of each kind it takes.
Walked : { path : Str, walk : I64, hop : I64, pen : I64, bull : I64, back : I64 }

walk_from : List(Agent.Route), U64 -> Walked
walk_from = |routes, i| {
	var $at = i
	var $w = { path: name(i), walk: 0, hop: 0, pen: 0, bull: 0, back: 0 }
	var $guard = 0
	while (List.get(routes, $at) ?? { steps: 0, first: { from: 0, to: 0, cost: 0, kind: Walk } }).steps > 0 and $guard < 100 {
		e = (List.get(routes, $at) ?? { steps: 0, first: { from: 0, to: 0, cost: 0, kind: Walk } }).first
		counted = match e.kind {
			Walk => { ..$w, walk: $w.walk + 1 }
			Hop => { ..$w, hop: $w.hop + 1 }
			LeavePen => { ..$w, pen: $w.pen + 1 }
			LeaveBullsEye => { ..$w, bull: $w.bull + 1 }
			Back4 => { ..$w, back: $w.back + 1 }
		}
		$w = { ..counted, path: Str.concat(Str.concat(counted.path, arrow(e.kind)), name(e.to)) }
		$at = e.to
		$guard = $guard + 1
	}
	$w
}

formula : Walked -> Str
formula = |w| {
	terms = List.join(
		[
			if w.walk > 0 { ["${I64.to_str(w.walk)}"] } else { [] },
			if w.hop > 0 { ["${I64.to_str(w.hop)}·hop"] } else { [] },
			if w.pen > 0 { ["(1 + pen)"] } else { [] },
			if w.bull > 0 { ["(1 + 6)"] } else { [] },
			if w.back > 0 { ["${I64.to_str(w.back)}·back4"] } else { [] },
		],
	)
	if List.is_empty(terms) { "0" } else { Str.join_with(terms, " + ") }
}

table : Str, I64, I64, I64 -> Str
table = |title, hop, pen, back4| {
	routes = Agent.routes(colors, "red", hop, pen, back4)
	rows = List.map(
		lap,
		|i| {
			w = walk_from(routes, i)
			steps = (List.get(routes, i) ?? { steps: 0, first: { from: 0, to: 0, cost: 0, kind: Walk } }).steps
			"| ${name(i)} | ${I64.to_str(steps)} | ${formula(w)} | ${w.path} |"
		},
	)
	header = "## ${title}\n\nhop ${I64.to_str(hop)}, pen ${I64.to_str(pen)}, back4 ${if back4 == 0 { "off" } else { I64.to_str(back4) }}\n\n| square | steps | formula | route |\n|---|---|---|---|\n"
	Str.concat(header, Str.join_with(rows, "\n"))
}

main! = |_args| {
	echo!(table("Without the 4 played backwards", 1, 4, 0))
	echo!(table("The computer today: a 4 played backwards costs 6", 1, 4, 6))
	Ok({})
}
