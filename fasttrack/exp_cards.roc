# Analysis: which cards win games. Every seat plays Strategy.champion; each
# game runs to the first player home (Arena.tally_game). A card the winner
# played or discarded scores +3, one a loser played or discarded -1 -- a
# discard is a use too, a credit toward getting out -- and the cards are
# ranked by score. The cards in hand when the game is won are counted beside,
# unscored; with the plays and discards they are every card each player drew.
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
	won_hands = List.join_map(List.keep_if(tallies, |t| t.won), |t| t.in_hand)
	lost_hands = List.join_map(List.keep_if(tallies, |t| !t.won), |t| t.in_hand)
	rows = List.map(
		cards,
		|card| {
			w = count(won, card)
			l = count(lost, card)
			{ card, score: 3 * (w + count(won_discards, card)) - (l + count(lost_discards, card)), w, l, wd: count(won_discards, card), ld: count(lost_discards, card), wh: count(won_hands, card), lh: count(lost_hands, card) }
		},
	)
	ranked = List.sort_with(rows, |a, b| if a.score > b.score { Before } else if a.score < b.score { After } else { Same })
	line!("\n## Which cards win\n\n${U64.to_str(games)} games, seeds 1-${U64.to_str(games)}, four champions, each game to the first player home. A card the winner played or discarded scores +3, one a loser played or discarded -1.\n")
	line!("Drawn is played + discarded + in hand at the end; the winner's share of a card's draws is 1/4 if the deal favors no one.\n")
	line!("| rank | card | score | played: winner / losers | discarded: winner / losers | in hand at the end: winner / losers | drawn: winner / losers | winner's share of draws |")
	line!("|---|---|---|---|---|---|---|---|")
	for r in List.map_with_index(ranked, |r, i| { card: r.card, score: r.score, w: r.w, l: r.l, wd: r.wd, ld: r.ld, wh: r.wh, lh: r.lh, rank: i + 1 }) {
		dw = r.w + r.wd + r.wh
		dl = r.l + r.ld + r.lh
		share = if dw + dl == 0 { 0 } else { (1000 * dw) // (dw + dl) }
		line!("| ${U64.to_str(r.rank)} | ${r.card} | ${I64.to_str(r.score)} | ${I64.to_str(r.w)} / ${I64.to_str(r.l)} | ${I64.to_str(r.wd)} / ${I64.to_str(r.ld)} | ${I64.to_str(r.wh)} / ${I64.to_str(r.lh)} | ${I64.to_str(dw)} / ${I64.to_str(dl)} | .${I64.to_str(share)} |")
	}
	Ok({})
}
