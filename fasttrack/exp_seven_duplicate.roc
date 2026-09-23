# Experiment, dealt as duplicate bridge: every seed is played four times, the
# decks turned a seat each time (Game.begin_dealt), so red plays every
# player's deck. Red hoards 7s at 900, 600, 300, 0 by pieces home, beside
# the champion's A, joker and J, against the champion; the other seats play
# the champion.
#
# The report sets the ways of judging the difference side by side: as if
# the games were unrelated, paired game by game (the same deal for both), and
# by seed (the same four deals for both).
#
#   fasttrack/run_exp.sh exp_seven_duplicate
app [main!] { pf: platform "cli/platform/main.roc" }

import pf.Echo
import Arena
import Strategy

rotations : List(U64)
rotations = [0, 1, 2, 3]

thousandths : F64 -> Str
thousandths = |x| {
	t = F64.to_i64_wrap(F64.abs(x) * 1000.0 + 0.5)
	sign = if x < 0.0 and t > 0 { "-" } else { "" }
	pad = if t % 1000 < 10 { "00" } else if t % 1000 < 100 { "0" } else { "" }
	"${sign}${I64.to_str(t // 1000)}.${pad}${I64.to_str(t % 1000)}"
}

main! = |_args| {
	champion = Strategy.champion
	games = 1000
	sevens = { ..champion, hoards: List.append(champion.hoards, { cards: ["7"], worth: [900, 600, 300, 0] }) }
	seats_a = List.repeat(Plays(champion), 4)
	seats_b = [Plays(sevens), Plays(champion), Plays(champion), Plays(champion)]
	# Per seed, per rotation: did red win as the champion (a), hoarding 7s (b)?
	var $blocks = []
	for seed in List.map_with_index(List.repeat(0, games), |_, i| i + 1) {
		block = List.map(rotations, |k| { a: Arena.play_dealt(seats_a, seed, k).red_won, b: Arena.play_dealt(seats_b, seed, k).red_won })
		$blocks = List.append($blocks, block)
		wins = |f| U64.to_str(List.count_if(block, f))
		Echo.line!("seed ${U64.to_str(seed)} | the champion won ${wins(|x| x.a)} of 4 | hoarding 7s won ${wins(|x| x.b)} of 4")
	}
	all = List.join($blocks)
	n = U64.to_f64(List.len(all))
	wins_a = List.count_if(all, |x| x.a)
	wins_b = List.count_if(all, |x| x.b)
	only_a = List.count_if(all, |x| x.a and !x.b)
	only_b = List.count_if(all, |x| x.b and !x.a)
	pa = U64.to_f64(wins_a) / n
	pb = U64.to_f64(wins_b) / n
	diff = pb - pa
	# Unrelated games: two binomials.
	se_unrelated = F64.sqrt(pa * (1.0 - pa) / n + pb * (1.0 - pb) / n)
	# Paired: each deal's difference, -1, 0 or 1.
	per_game = List.map(all, |x| (if x.b { 1.0 } else { 0.0 }) - (if x.a { 1.0 } else { 0.0 }))
	sd = |xs| {
		m = List.fold(xs, 0.0, |t, x| t + x) / U64.to_f64(List.len(xs))
		F64.sqrt(List.fold(xs, 0.0, |t, x| t + (x - m) * (x - m)) / (U64.to_f64(List.len(xs)) - 1.0))
	}
	se_paired = sd(per_game) / F64.sqrt(n)
	# By seed: each seed's four deals together.
	per_seed = List.map($blocks, |bl| (U64.to_f64(List.count_if(bl, |x| x.b)) - U64.to_f64(List.count_if(bl, |x| x.a))) / 4.0)
	se_seed = sd(per_seed) / F64.sqrt(U64.to_f64(List.len(per_seed)))
	by_rotation = |f| Str.join_with(List.map(rotations, |k| U64.to_str(List.count_if($blocks, |bl| f(List.get(bl, k) ?? { a: Bool.False, b: Bool.False })))), " / ")
	Echo.line!("\n## Hoarding the 7 at 900/600/300/0, dealt as duplicate\n")
	Echo.line!("${U64.to_str(games)} seeds, each dealt four times with the decks turned a seat, so red plays every player's deck: ${U64.to_str(List.len(all))} games per variant. Red is the variant; the other seats play Strategy.champion. Each game stops at the first player home.\n")
	Echo.line!("| red plays as | red won | win rate | wins with the decks turned 0 / 1 / 2 / 3 seats |")
	Echo.line!("|---|---|---|---|")
	Echo.line!("| the champion | ${U64.to_str(wins_a)} of ${U64.to_str(List.len(all))} | ${thousandths(pa)} | ${by_rotation(|x| x.a)} |")
	Echo.line!("| hoarding 7s | ${U64.to_str(wins_b)} of ${U64.to_str(List.len(all))} | ${thousandths(pb)} | ${by_rotation(|x| x.b)} |")
	Echo.line!("\nThe difference, hoarding 7s less the champion: ${thousandths(diff)} a game. Deals only hoarding won: ${U64.to_str(only_b)}; only the champion won: ${U64.to_str(only_a)}.\n")
	Echo.line!("| judged as | standard error of the difference | the difference in standard errors |")
	Echo.line!("|---|---|---|")
	Echo.line!("| unrelated games | ${thousandths(se_unrelated)} | ${thousandths(diff / se_unrelated)} |")
	Echo.line!("| paired, deal by deal | ${thousandths(se_paired)} | ${thousandths(diff / se_paired)} |")
	Echo.line!("| by seed, four turned deals together | ${thousandths(se_seed)} | ${thousandths(diff / se_seed)} |")
	Ok({})
}
