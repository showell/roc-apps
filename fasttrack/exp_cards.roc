# Analysis: which cards win games. Every seat plays Strategy.champion; each
# game runs to the first player home (Arena.tally_game). A card the winner
# played scores +3, a card a loser played -1, and the cards are ranked by
# score. Discards are counted beside, unscored.
#
#   fasttrack/run_exp.sh exp_cards
import Arena
import Strategy

## echo! writes no newline.
line! = |s| echo!(Str.concat(s, "\n"))

cards : List(Str)
cards = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "joker"]

count : List(Str), Str -> I64
count = |xs, card| U64.to_i64_wrap(List.count_if(xs, |c| c == card))

main! = |_args| {
	seats = List.repeat(Plays(Strategy.champion), 4)
	games = 80
	var $all = []
	for seed in List.map_with_index(List.repeat(0, games), |_, i| i + 1) {
		ts = Arena.tally_game(seats, seed)
		$all = List.append($all, ts)
		winner = List.find_first(ts, |t| t.won) ?? Arena.no_tally
		line!("seed ${U64.to_str(seed)} | winner played ${Str.join_with(winner.played, " ")}")
	}
	tallies = List.join($all)
	won = List.join_map(List.keep_if(tallies, |t| t.won), |t| t.played)
	lost = List.join_map(List.keep_if(tallies, |t| !t.won), |t| t.played)
	won_discards = List.join_map(List.keep_if(tallies, |t| t.won), |t| t.discarded)
	lost_discards = List.join_map(List.keep_if(tallies, |t| !t.won), |t| t.discarded)
	rows = List.map(
		cards,
		|card| {
			w = count(won, card)
			l = count(lost, card)
			{ card, score: 3 * w - l, w, l, wd: count(won_discards, card), ld: count(lost_discards, card) }
		},
	)
	ranked = List.sort_with(rows, |a, b| if a.score > b.score { Before } else if a.score < b.score { After } else { Same })
	line!("\n## Which cards win\n\n${U64.to_str(games)} games, seeds 1-${U64.to_str(games)}, four champions, each game to the first player home. A card the winner played scores +3, a card a loser played -1.\n")
	line!("| rank | card | score | played by the winner | played by losers | discarded by the winner | discarded by losers |")
	line!("|---|---|---|---|---|---|---|")
	for r in List.map_with_index(ranked, |r, i| { card: r.card, score: r.score, w: r.w, l: r.l, wd: r.wd, ld: r.ld, rank: i + 1 }) {
		line!("| ${U64.to_str(r.rank)} | ${r.card} | ${I64.to_str(r.score)} | ${I64.to_str(r.w)} | ${I64.to_str(r.l)} | ${I64.to_str(r.wd)} | ${I64.to_str(r.ld)} |")
	}
	Ok({})
}
