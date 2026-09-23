# Analysis: which cards win games. Every seat plays Strategy.champion; each
# game runs to the first player home (Arena.tally_game). A card the winner
# played or discarded scores +3, one a loser played or discarded -1 -- a
# discard is a use too, a credit toward getting out -- and the cards are
# counted too. With the cards in hand when the game is won, the plays and
# discards are every card each player drew, and the cards are ranked by the
# winner's share of a card's draws: the deal decides much of the game, so
# what matters is whether a card went to the winner. Then the table of what
# the winner does (Tables.winner_table).
#
#   fasttrack/run_exp.sh exp_cards
app [main!] { pf: platform "cli/platform/main.roc" }

import pf.Echo
import Arena
import Tables
import Strategy

cards : List(Str)
cards = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "joker"]

count : List(Str), Str -> I64
count = |xs, card| U64.to_i64_wrap(List.count_if(xs, |c| c == card))

## A fraction as .ddd.
thousandths : F64 -> Str
thousandths = |x| {
	t = F64.to_i64_wrap(x * 1000.0 + 0.5)
	pad = if t < 10 { "00" } else if t < 100 { "0" } else { "" }
	".${pad}${I64.to_str(t)}"
}

main! = |_args| {
	seats = List.repeat(Plays(Strategy.champion), 4)
	games = 200
	var $all = []
	for seed in List.map_with_index(List.repeat(0, games), |_, i| i + 1) {
		ts = Arena.tally_game(seats, seed)
		$all = List.append($all, ts)
		Echo.line!(Tables.tally_line(seed, ts))
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
			wd = count(won_discards, card)
			ld = count(lost_discards, card)
			wh = count(won_hands, card)
			lh = count(lost_hands, card)
			dw = w + wd + wh
			dl = l + ld + lh
			share = if dw + dl == 0 { 0.0 } else { I64.to_f64(dw) / I64.to_f64(dw + dl) }
			se = if dw + dl == 0 { 0.0 } else { F64.sqrt(share * (1.0 - share) / I64.to_f64(dw + dl)) }
			{ card, score: 3 * (w + wd) - (l + ld), w, l, wd, ld, wh, lh, dw, dl, share, se }
		},
	)
	ranked = List.sort_with(rows, |a, b| if a.share > b.share { Before } else if a.share < b.share { After } else { Same })
	Echo.line!("\n## Which cards win\n\n${U64.to_str(games)} games, seeds 1-${U64.to_str(games)}, four champions, each game to the first player home. A card the winner played or discarded scores +3, one a loser played or discarded -1.\n")
	all_w = List.fold(rows, 0, |t, r| t + r.dw)
	all_l = List.fold(rows, 0, |t, r| t + r.dl)
	Echo.line!("Drawn is played + discarded + in hand at the end. Ranked by the winner's share of a card's draws; over every card it is ${thousandths(I64.to_f64(all_w) / I64.to_f64(all_w + all_l))} (winners draw more cards), and the ± is one standard error, counting draws as independent.\n")
	Echo.line!("| rank | card | winner's share of draws | drawn: winner / losers | played: winner / losers | discarded: winner / losers | in hand at the end: winner / losers | score, +3 / -1 |")
	Echo.line!("|---|---|---|---|---|---|---|---|")
	for r in List.map_with_index(ranked, |r, i| { card: r.card, score: r.score, w: r.w, l: r.l, wd: r.wd, ld: r.ld, wh: r.wh, lh: r.lh, dw: r.dw, dl: r.dl, share: r.share, se: r.se, rank: i + 1 }) {
		Echo.line!("| ${U64.to_str(r.rank)} | ${r.card} | ${thousandths(r.share)} ± ${thousandths(r.se)} | ${I64.to_str(r.dw)} / ${I64.to_str(r.dl)} | ${I64.to_str(r.w)} / ${I64.to_str(r.l)} | ${I64.to_str(r.wd)} / ${I64.to_str(r.ld)} | ${I64.to_str(r.wh)} / ${I64.to_str(r.lh)} | ${I64.to_str(r.score)} |")
	}
	Echo.line!("\n## What the winner does\n\nThe same ${U64.to_str(games)} games.\n")
	Echo.line!(Tables.winner_table($all, []))
	Ok({})
}
