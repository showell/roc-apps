# Analysis: what the winner does that the losers do not. Red, blue and purple
# play Strategy.champion; green plays the first legal move it finds. Each game
# runs to the first player home, and every player's turns, cards played, idle
# turns (discards and no card), fast-track landings and hops, and captures
# made and suffered are counted (Arena.tally_game).
#
#   fasttrack/run_exp.sh exp_table
import Arena
import Strategy

## echo! writes no newline.
line! = |s| echo!(Str.concat(s, "\n"))

colors : List(Str)
colors = ["red", "blue", "green", "purple"]

Stat : { label : Str, of : Arena.Tally -> U64 }

hundredths : F64 -> Str
hundredths = |x| {
	t = F64.to_i64_wrap(x * 100.0 + 0.5)
	frac = t % 100
	"${I64.to_str(t // 100)}.${if frac < 10 { "0" } else { "" }}${I64.to_str(frac)}"
}

mean : List(U64) -> F64
mean = |xs| if List.is_empty(xs) { 0.0 } else { U64.to_f64(List.fold(xs, 0, |t, x| t + x)) / U64.to_f64(List.len(xs)) }

game_line : U64, List(Arena.Tally) -> Str
game_line = |seed, ts| {
	winner = List.find_first_index(ts, |t| t.won) ?? 4
	players = List.map_with_index(
		ts,
		|t, i|
			"${List.get(colors, i) ?? ""} ${U64.to_str(t.turns)}t ${U64.to_str(t.cards)}c ${U64.to_str(t.idle)}i ${U64.to_str(t.ft_landings)}ft ${U64.to_str(t.ft_hops)}hop ${U64.to_str(t.captures)}took ${U64.to_str(t.captured)}lost",
	)
	"seed ${U64.to_str(seed)} | ${List.get(colors, winner) ?? "nobody"} wins | ${Str.join_with(players, " | ")}"
}

main! = |_args| {
	champion = Plays(Strategy.champion)
	seats = [champion, champion, FirstLegal, champion]
	games = 80
	var $all = []
	for seed in List.map_with_index(List.repeat(0, games), |_, i| i + 1) {
		ts = Arena.tally_game(seats, seed)
		$all = List.append($all, ts)
		line!(game_line(seed, ts))
	}
	# Built with List.map: a literal list of records holding functions is
	# the shape that crashes `roc check` (nightly 09-07).
	stats = List.map(
		["turns", "cards played", "idle turns", "fast-track landings", "fast-track hops", "captures made", "times captured"],
		|label| {
			label,
			of: |t|
				match label {
					"turns" => t.turns
					"cards played" => t.cards
					"idle turns" => t.idle
					"fast-track landings" => t.ft_landings
					"fast-track hops" => t.ft_hops
					"captures made" => t.captures
					_ => t.captured
				},
		},
	)
	wins = List.map_with_index(colors, |c, i| "${c} ${U64.to_str(List.count_if($all, |ts| (List.get(ts, i) ?? Arena.no_tally).won))}")
	line!("\n## Who wins, and what the winner does\n\n${U64.to_str(games)} games, seeds 1-${U64.to_str(games)}; red, blue and purple play Strategy.champion, green the first legal move it finds. Each game stops at the first player home.\n\nWins: ${Str.join_with(wins, ", ")}.\n")
	line!("Means per player per game. \"Winner vs losers\" counts the games where the winner's number is above, equal to, or below the mean of the champions who lost that game.\n")
	line!("| | winner | champions who lost | green, when it lost | winner vs losers: above / equal / below |")
	line!("|---|---|---|---|---|")
	for st in stats {
		# `of(t)` would be a method call.
		of = st.of
		winners = List.join_map($all, |ts| List.map(List.keep_if(ts, |t| t.won), of))
		losers = List.join_map($all, |ts| List.join(List.map_with_index(ts, |t, i| if !t.won and i != 2 { [of(t)] } else { [] })))
		green = List.join_map($all, |ts| List.join(List.map_with_index(ts, |t, i| if !t.won and i == 2 { [of(t)] } else { [] })))
		cmp = List.map(
			$all,
			|ts| {
				w = U64.to_f64(List.fold(List.keep_if(ts, |t| t.won), 0, |a, t| a + of(t)))
				m = mean(List.join(List.map_with_index(ts, |t, i| if !t.won and i != 2 { [of(t)] } else { [] })))
				if w > m { 1 } else if w < m { -1 } else { 0 }
			},
		)
		above = List.count_if(cmp, |x| x == 1)
		equal = List.count_if(cmp, |x| x == 0)
		below = List.count_if(cmp, |x| x == -1)
		line!("| ${st.label} | ${hundredths(mean(winners))} | ${hundredths(mean(losers))} | ${hundredths(mean(green))} | ${U64.to_str(above)} / ${U64.to_str(equal)} / ${U64.to_str(below)} |")
	}
	Ok({})
}
