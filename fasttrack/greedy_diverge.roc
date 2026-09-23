# One game of greedy_race.roc, played twice in lockstep -- red with no base
# bonus, and red with one -- to find the first step where red plays
# differently, show that position and both choices, and then follow the
# bonus game: every capture of a red piece, and when red finishes.
#
#   cd fasttrack && roc build greedy_diverge.roc --opt=speed && ./greedy_diverge 5 100
import Agent
import Game
import GreedyRace
import Player
import Type

letter : Str -> Str
letter = |color|
	match color {
		"red" => "r"
		"blue" => "b"
		"green" => "g"
		_ => "p"
	}

square : Type.PieceLocation -> Str
square = |loc|
	match loc.zone {
		BullsEyeZone => "bullseye"
		NormalColor(zone) => "${letter(zone)}${loc.id}"
	}

## The squares a color's pieces stand on, with each one's value.
pieces : List(List(I64)), Type.Game, Str -> Str
pieces = |tables, g, color| {
	owner = List.find_first_index(GreedyRace.colors, |c| c == color) ?? 0
	table = List.get(tables, owner) ?? []
	on = List.keep_if(g.piece_map, |e| e.value == color)
	Str.join_with(List.map(on, |e| "${square(e.key)} (${I64.to_str(List.get(table, Agent.index_of(GreedyRace.colors, e.key)) ?? 0)})"), ", ")
}

main! = |args| {
	seed = match List.first(args) {
		Ok(t) => U64.from_str(t) ?? 5
		Err(_) => 5
	}
	bonus = match List.get(args, 1) {
		Ok(t) => I64.from_str(t) ?? 100
		Err(_) => 100
	}
	plain = { tables: GreedyRace.with_bonus(0), hand_value: 0, hoard: [] }
	tucked = { tables: GreedyRace.with_bonus(bonus), hand_value: 0, hoard: [] }
	var $a = Game.begin_game(seed, Normal, Solo)
	var $b = $a
	var $turn = 1
	var $steps = 0
	var $split = Bool.False
	while !$split and $steps < 5000 {
		na = GreedyRace.step(plain, $a)
		nb = GreedyRace.step(tucked, $b)
		if na != nb {
			hand = Player.get_active_player($a).hand
			echo!("game ${U64.to_str(seed)}: red first plays differently on its turn ${U64.to_str($turn)}\n\n")
			echo!("hand: ${Str.join_with(hand, " ")}\n")
			echo!("red before: ${pieces(plain.tables, $a, "red")}\n")
			for_color = |c| if c == "red" { "" } else { "${c}: ${pieces(plain.tables, $a, c)}\n" }
			echo!(Str.join_with(List.map(GreedyRace.colors, for_color), ""))
			echo!("\nno bonus plays to:  ${pieces(plain.tables, na, "red")} -- worth ${I64.to_str(GreedyRace.board_score(plain.tables, na, 0))} without the bonus, ${I64.to_str(GreedyRace.board_score(tucked.tables, na, 0))} with it\n")
			echo!("bonus plays to:     ${pieces(tucked.tables, nb, "red")} -- worth ${I64.to_str(GreedyRace.board_score(plain.tables, nb, 0))} without the bonus, ${I64.to_str(GreedyRace.board_score(tucked.tables, nb, 0))} with it\n")
			$split = Bool.True
		} else {
			if na.active_player_idx == 0 and $a.active_player_idx != 0 {
				$turn = $turn + 1
			}
			$a = na
			$b = nb
			$steps = $steps + 1
		}
	}
	# The bonus game from here: red's captures, and its finish.
	echo!("\nthe bonus game from there:\n")
	var $g = $b
	var $t = $turn
	var $n = 0
	while !GreedyRace.home($g, 0) and $n < 5000 {
		next = GreedyRace.step(tucked, $g)
		if $g.active_player_idx != 0 and GreedyRace.red_in_pen(next) > GreedyRace.red_in_pen($g) {
			mover = List.get(GreedyRace.colors, $g.active_player_idx) ?? "?"
			echo!("  red's turn ${U64.to_str($t)}: ${mover} sends a red piece home. red before: ${pieces(tucked.tables, $g, "red")}; ${mover} before: ${pieces(tucked.tables, $g, mover)}\n")
		}
		if next.active_player_idx == 0 and $g.active_player_idx != 0 {
			$t = $t + 1
		}
		$g = next
		$n = $n + 1
	}
	echo!("  red home on its turn ${U64.to_str($t)}\n")
	Ok({})
}
