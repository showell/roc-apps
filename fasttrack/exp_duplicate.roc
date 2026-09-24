# Experiment, dealt as duplicate bridge: every seed is played four times, the
# decks turned a seat each time (Game.begin_dealt), so red plays every
# player's deck. Red plays the champion and each of `variants` on the same
# deals; the other seats play the champion. Earlier variants are in TUNING.md
# and git (hoarding 7s at 900/600/300/0, no J hoard, playing against a leader
# three home, base bonus 2500).
#
# For each variant the report sets the ways of judging its difference from
# the champion side by side: as if the games were unrelated, paired deal by
# deal (the same deal for both), and by seed (the same four deals for both).
#
#   fasttrack/run_exp.sh exp_duplicate
app [main!] { pf: platform "cli/platform/main.roc" }

import pf.Echo
import Arena
import Strategy

## The strategies under test: the champion's base worth more a step (B1 x1
## .. B4 x4) than its 1000.
variants : List({ label : Str, strategy : Strategy.Strategy })
variants = List.map([1500, 2500, 4000], |b| { label: "base bonus ${I64.to_str(b)}", strategy: { ..Strategy.champion, base_bonus: b } })

## Seeds first_seed, first_seed + 1, ...; each is dealt four times.
first_seed : U64
first_seed = 501

seeds : U64
seeds = 500

rotations : List(U64)
rotations = [0, 1, 2, 3]

thousandths : F64 -> Str
thousandths = |x| {
	t = F64.to_i64_wrap(F64.abs(x) * 1000.0 + 0.5)
	sign = if x < 0.0 and t > 0 { "-" } else { "" }
	pad = if t % 1000 < 10 { "00" } else if t % 1000 < 100 { "0" } else { "" }
	"${sign}${I64.to_str(t // 1000)}.${pad}${I64.to_str(t % 1000)}"
}

sd : List(F64) -> F64
sd = |xs| {
	n = U64.to_f64(List.len(xs))
	m = List.fold(xs, 0.0, |t, x| t + x) / n
	F64.sqrt(List.fold(xs, 0.0, |t, x| t + (x - m) * (x - m)) / (n - 1.0))
}

win : Bool -> F64
win = |w| if w { 1.0 } else { 0.0 }

main! = |args| {
	champion = Strategy.champion
	# Tied to the arguments so the compiler cannot run the games while it
	# compiles (see exp_rollout.roc).
	start = first_seed + 0 * List.len(args)
	strategies = List.prepend(List.map(variants, |v| v.strategy), champion)
	labels = List.prepend(List.map(variants, |v| v.label), "the champion")
	# Per seed, per rotation: whether red won as each strategy, the champion first.
	var $blocks = []
	for seed in List.map_with_index(List.repeat(0, seeds), |_, i| start + i) {
		block = List.map(rotations, |k| List.map(strategies, |st| Arena.play_dealt([Plays(st), Plays(champion), Plays(champion), Plays(champion)], seed, k).red_won))
		$blocks = List.append($blocks, block)
		counts = List.map_with_index(labels, |label, j| "${label} won ${U64.to_str(List.count_if(block, |deal| List.get(deal, j) == Ok(Bool.True)))} of 4")
		Echo.line!("seed ${U64.to_str(seed)} | ${Str.join_with(counts, " | ")}")
	}
	deals = List.join($blocks)
	n = U64.to_f64(List.len(deals))
	won = |j| List.count_if(deals, |deal| List.get(deal, j) == Ok(Bool.True))
	Echo.line!("\n## ${Str.join_with(List.map(variants, |v| v.label), ", ")}, dealt as duplicate\n")
	Echo.line!("Seeds ${U64.to_str(start)}-${U64.to_str(start + seeds - 1)}, each dealt four times with the decks turned a seat, so red plays every player's deck: ${U64.to_str(List.len(deals))} games per strategy. Red is the strategy; the other seats play Strategy.champion. Each game stops at the first player home.\n")
	Echo.line!("| red plays as | red won | win rate | wins with the decks turned 0 / 1 / 2 / 3 seats |")
	Echo.line!("|---|---|---|---|")
	for j in List.map_with_index(labels, |_, i| i) {
		by_rotation = Str.join_with(List.map(rotations, |k| U64.to_str(List.count_if($blocks, |bl| List.get(List.get(bl, k) ?? [], j) == Ok(Bool.True)))), " / ")
		Echo.line!("| ${List.get(labels, j) ?? ""} | ${U64.to_str(won(j))} of ${U64.to_str(List.len(deals))} | ${thousandths(U64.to_f64(won(j)) / n)} | ${by_rotation} |")
	}
	Echo.line!("\nEach against the champion, on the same deals:\n")
	Echo.line!("| red plays as | difference a game | deals only it won / only the champion won | standard error: unrelated / paired / by seed | paired, in standard errors |")
	Echo.line!("|---|---|---|---|---|")
	for j in List.map_with_index(variants, |_, i| i + 1) {
		a = |deal| List.get(deal, 0) == Ok(Bool.True)
		b = |deal| List.get(deal, j) == Ok(Bool.True)
		pa = U64.to_f64(won(0)) / n
		pb = U64.to_f64(won(j)) / n
		diff = pb - pa
		unrelated = F64.sqrt(pa * (1.0 - pa) / n + pb * (1.0 - pb) / n)
		paired = sd(List.map(deals, |deal| win(b(deal)) - win(a(deal)))) / F64.sqrt(n)
		by_seed = sd(List.map($blocks, |bl| (U64.to_f64(List.count_if(bl, b)) - U64.to_f64(List.count_if(bl, a))) / 4.0)) / F64.sqrt(U64.to_f64(List.len($blocks)))
		only = "${U64.to_str(List.count_if(deals, |deal| b(deal) and !a(deal)))} / ${U64.to_str(List.count_if(deals, |deal| a(deal) and !b(deal)))}"
		Echo.line!("| ${List.get(labels, j) ?? ""} | ${thousandths(diff)} | ${only} | ${thousandths(unrelated)} / ${thousandths(paired)} / ${thousandths(by_seed)} | ${thousandths(diff / paired)} |")
	}
	Ok({})
}
