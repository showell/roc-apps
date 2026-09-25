# Tables -- what the winner does that the losers do not, from Arena.tally_game:
# a line a game, and a table of every player's numbers, the winner's against
# those of the players who lost. A seat named in `apart` (a seat playing
# something other than the champion) is left out of the losers and shown in
# a column of its own.
import Arena

Tables :: [].{
	colors : List(Str)
	colors = ["red", "blue", "green", "purple"]

	hundredths : F64 -> Str
	hundredths = |x| {
		t = F64.to_i64_wrap(x * 100.0 + 0.5)
		frac = t % 100
		"${I64.to_str(t // 100)}.${if frac < 10 { "0" } else { "" }}${I64.to_str(frac)}"
	}

	mean : List(U64) -> F64
	mean = |xs| if List.is_empty(xs) { 0.0 } else { U64.to_f64(List.fold(xs, 0, |t, x| t + x)) / U64.to_f64(List.len(xs)) }

	## One game: who won, and each player's numbers.
	tally_line : U64, List(Arena.Tally) -> Str
	tally_line = |seed, ts| {
		winner = List.find_first_index(ts, |t| t.won) ?? 4
		players = List.map_with_index(
			ts,
			|t, i|
				"${List.get(colors, i) ?? ""} ${U64.to_str(t.turns)}t ${U64.to_str(t.cards)}c ${U64.to_str(t.idle)}i ${U64.to_str(t.ft_landings)}ft ${U64.to_str(t.ft_hops)}hop ${U64.to_str(t.captures)}took ${U64.to_str(t.captured)}lost",
		)
		"seed ${U64.to_str(seed)} | ${List.get(colors, winner) ?? "nobody"} wins | ${Str.join_with(players, " | ")}"
	}

	## One number of a player's game.
	stat : Str, Arena.Tally -> U64
	stat = |label, t|
		match label {
			"turns" => t.turns
			"cards played" => t.cards
			"idle turns" => t.idle
			"fast-track landings" => t.ft_landings
			"fast-track hops" => t.ft_hops
			"captures made" => t.captures
			_ => t.captured
		}

	stats : List(Str)
	stats = ["turns", "cards played", "idle turns", "fast-track landings", "fast-track hops", "captures made", "times captured"]

	## Wins by color, and the table.
	winner_table : List(List(Arena.Tally)), List(U64) -> Str
	winner_table = |all, apart| {
		wins = List.map_with_index(colors, |c, i| "${c} ${U64.to_str(List.count_if(all, |ts| (List.get(ts, i) ?? Arena.no_tally).won))}")
		apart_names = Str.join_with(List.map(apart, |i| List.get(colors, i) ?? ""), " and ")
		apart_head = if List.is_empty(apart) { "" } else { " ${apart_names}, when it lost |" }
		losers_of = |ts, label| List.join(List.map_with_index(ts, |t, i| if !t.won and !List.contains(apart, i) { [stat(label, t)] } else { [] }))
		rows = List.map(
			stats,
			|label| {
				winners = List.join_map(all, |ts| List.map(List.keep_if(ts, |t| t.won), |t| stat(label, t)))
				losers = List.join_map(all, |ts| losers_of(ts, label))
				set_apart = List.join_map(all, |ts| List.join(List.map_with_index(ts, |t, i| if !t.won and List.contains(apart, i) { [stat(label, t)] } else { [] })))
				cmp : List([Above, Below, Equal])
				cmp = List.map(
					all,
					|ts| {
						w = U64.to_f64(List.fold(List.keep_if(ts, |t| t.won), 0, |a, t| a + stat(label, t)))
						m = mean(losers_of(ts, label))
						if w > m { Above } else if w < m { Below } else { Equal }
					},
				)
				apart_cell = if List.is_empty(apart) { "" } else { " ${hundredths(mean(set_apart))} |" }
				"| ${label} | ${hundredths(mean(winners))} | ${hundredths(mean(losers))} |${apart_cell} ${U64.to_str(List.count_if(cmp, |x| x == Above))} / ${U64.to_str(List.count_if(cmp, |x| x == Equal))} / ${U64.to_str(List.count_if(cmp, |x| x == Below))} |"
			},
		)
		apart_rule = if List.is_empty(apart) { "" } else { "---|" }
		Str.join_with(
			[
				"Wins: ${Str.join_with(wins, ", ")}.\n",
				"Means per player per game. \"Winner vs losers\" counts the games where the winner's number is above, equal to, or below the mean of the players who lost that game${if List.is_empty(apart) { "" } else { " (not ${apart_names})" }}. The turns row is an artifact: the game stops at the winner's turn.\n",
				"| | winner | players who lost |${apart_head} winner vs losers: above / equal / below |",
				"|---|---|---|${apart_rule}---|",
				Str.join_with(rows, "\n"),
			],
			"\n",
		)
	}
}
