# Experiment: does hoarding 7s help? A split 7 packs pieces into the base in
# the end game. Red hoards the 7 like the champion's A, joker and J (1500,
# 1000, 500, 0 by pieces home) against the champion, which does not.
#
#   fasttrack/run_exp.sh exp_seven_hoard
app [main!] { pf: platform "cli/platform/main.roc" }

import pf.Echo
import Arena
import Strategy

main! = |_args| {
	champion = Strategy.champion
	games = 200
	# Built with List.map: a literal list of these records crashes `roc
	# check` (nightly 09-07).
	variants = List.map(
		[Bool.False, Bool.True],
		|sevens| {
			hoards = if sevens { List.append(champion.hoards, { cards: ["7"], worth: [1500, 1000, 500, 0] }) } else { champion.hoards }
			{
				label: if sevens { "hoards the 7 too" } else { "the champion" },
				seats: [Plays({ ..champion, hoards }), Plays(champion), Plays(champion), Plays(champion)],
			}
		},
	)
	var $all = List.map(variants, |v| { label: v.label, rs: [] })
	for seed in List.map_with_index(List.repeat(0, games), |_, i| i + 1) {
		$all = List.map_with_index(
			$all,
			|x, i| {
				r = Arena.play((List.get(variants, i) ?? crash("no variant")).seats, seed)
				{ ..x, rs: List.append(x.rs, r) }
			},
		)
		for x in $all {
			Echo.line!(Arena.game_line(x.label, seed, List.last(x.rs) ?? crash("no game")))
		}
	}
	Echo.line!("\n${Arena.report("Hoarding the 7", $all)}")
	Ok({})
}
