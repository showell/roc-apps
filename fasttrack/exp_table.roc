# Analysis: what the winner does that the losers do not. Red, blue and purple
# play Strategy.champion; green plays the first legal move it finds. Each game
# runs to the first player home, and every player's turns, cards played, idle
# turns (discards and no card), fast-track landings and hops, and captures
# made and suffered are counted (Arena.tally_game).
#
#   fasttrack/run_exp.sh exp_table
import Arena
import Tables
import Strategy

## echo! writes no newline.
line! = |s| echo!(Str.concat(s, "\n"))

main! = |_args| {
	champion = Plays(Strategy.champion)
	seats = [champion, champion, FirstLegal, champion]
	games = 80
	var $all = []
	for seed in List.map_with_index(List.repeat(0, games), |_, i| i + 1) {
		ts = Arena.tally_game(seats, seed)
		$all = List.append($all, ts)
		line!(Tables.tally_line(seed, ts))
	}
	line!("\n## Who wins, and what the winner does\n\n${U64.to_str(games)} games, seeds 1-${U64.to_str(games)}; red, blue and purple play Strategy.champion, green the first legal move it finds. Each game stops at the first player home.\n")
	line!(Tables.winner_table($all, [2]))
	Ok({})
}
