# Config -- the board's layout and the cards' meanings, from Config.elm.
import Type

Config :: [].{
	## Discards that bring a piece out of the pen. Elm had 5; Steve's game
	## has 4.
	num_credits_to_get_out : I64
	num_credits_to_get_out = 4

	gutter_size : F64
	gutter_size = 4.0

	square_size : F64
	square_size = 26.0

	base_locations : List(Str)
	base_locations = ["B1", "B2", "B3", "B4"]

	is_base_id : Str -> Bool
	is_base_id = |id| List.contains(base_locations, id)

	holding_pen_locations : List(Str)
	holding_pen_locations = ["HP1", "HP2", "HP3", "HP4"]

	is_holding_pen_id : Str -> Bool
	is_holding_pen_id = |id| List.contains(holding_pen_locations, id)

	is_move_again_card : Str -> Bool
	is_move_again_card = |card| List.contains(["A", "K", "Q", "J", "joker", "6"], card)

	## One zone's squares, in the panel's own coordinates: x across, y up
	## from the edge of the board.
	config_locations : List(Type.Location)
	config_locations = [
		# holding pen
		{ x: -4.2, y: 1.7, id: "HP1" },
		{ x: -3.2, y: 1.7, id: "HP2" },
		{ x: -4.2, y: 0.7, id: "HP3" },
		{ x: -3.2, y: 0.7, id: "HP4" },
		# base
		{ x: 0.0, y: 1.0, id: "B1" },
		{ x: 0.0, y: 2.0, id: "B2" },
		{ x: 0.0, y: 3.0, id: "B3" },
		{ x: 0.0, y: 4.0, id: "B4" },
		# bottom
		{ x: -1.0, y: 0.0, id: "HH" },
		{ x: 0.0, y: 0.0, id: "DS" },
		{ x: 1.0, y: 0.0, id: "BR" },
		# left
		{ x: -2.0, y: 0.0, id: "L0" },
		{ x: -2.0, y: 1.0, id: "L1" },
		{ x: -2.0, y: 2.0, id: "L2" },
		{ x: -2.0, y: 3.0, id: "L3" },
		{ x: -2.0, y: 4.0, id: "L4" },
		{ x: -2.0, y: 5.0, id: "FT" },
		# right
		{ x: 2.0, y: 0.0, id: "R0" },
		{ x: 2.0, y: 1.0, id: "R1" },
		{ x: 2.0, y: 2.0, id: "R2" },
		{ x: 2.0, y: 3.0, id: "R3" },
		{ x: 2.0, y: 4.0, id: "R4" },
	]

	## For sorting the cheat sheet, and nothing else.
	card_value : Str -> I64
	card_value = |card|
		match card {
			"A" => 1
			"2" => 2
			"3" => 3
			"4" => 4
			"5" => 5
			"6" => 6
			"7" => 7
			"8" => 8
			"9" => 9
			"10" => 10
			"J" => 11
			"Q" => 12
			"K" => 13
			"joker" => 14
			_ => 0
		}

	hint_for_card : Str -> Str
	hint_for_card = |card|
		match card {
			"A" => "move 1 or get out"
			"2" => "move 2"
			"3" => "move 3"
			"4" => "move backward 4"
			"5" => "move 5"
			"6" => "move 6 or get out"
			"7" => "move 7 or split"
			"8" => "move 8"
			"9" => "move 9"
			"10" => "move 10"
			"J" => "move 1 or trade pieces"
			"Q" => "move 1"
			"K" => "move 1"
			"joker" => "move 1 or get out"
			_ => ""
		}

	move_count_for_card : Str, Str -> I64
	move_count_for_card = |active_card, id|
		match active_card {
			"A" => 1
			"2" => 2
			"3" => 3
			"4" => 4
			"5" => 5
			"6" => if is_holding_pen_id(id) { 1 } else { 6 }
			"7" => 7
			"8" => 8
			"9" => 9
			"10" => 10
			"J" => 1
			"Q" => 1
			"K" => 1
			"joker" => 1
			_ => 0
		}

	## Neither holding-pen nor fast-track squares: the caller handles those.
	next_ids_in_zone : Str, Str, Str -> List(Str)
	next_ids_in_zone = |id, piece_color, zone_color|
		match id {
			"HH" => ["L0"]
			"L0" => ["L1"]
			"L1" => ["L2"]
			"L2" => ["L3"]
			"L3" => ["L4"]
			"L4" => ["FT"]
			"R4" => ["R3"]
			"R3" => ["R2"]
			"R2" => ["R1"]
			"R1" => ["R0"]
			"R0" => ["BR"]
			"BR" => ["DS"]
			"DS" => if zone_color == piece_color { ["B1"] } else { ["HH"] }
			"B1" => ["B2"]
			"B2" => ["B3"]
			"B3" => ["B4"]
			# B4 is home.
			_ => []
		}

	## Only the squares with an obvious predecessor: the caller handles R4,
	## the holding pen and the base.
	prev_id_in_zone : Str -> Str
	prev_id_in_zone = |id|
		match id {
			"HH" => "DS"
			"L0" => "HH"
			"L1" => "L0"
			"L2" => "L1"
			"L3" => "L2"
			"L4" => "L3"
			"FT" => "L4"
			"R3" => "R4"
			"R2" => "R3"
			"R1" => "R2"
			"R0" => "R1"
			"BR" => "R0"
			"DS" => "BR"
			_ => "bogus"
		}

	## Suits do not matter in Fast Track. Each player's copy is shuffled once
	## before the game and drawn from the top (Player.shuffle).
	full_deck : List(Str)
	full_deck = List.join(List.repeat(["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"], 4)).concat(["joker", "joker"])
}

expect List.len(Config.full_deck) == 54
expect List.take_first(Config.full_deck, 14) == ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A", "2"]
expect Config.move_count_for_card("6", "HP2") == 1 and Config.move_count_for_card("6", "L2") == 6
