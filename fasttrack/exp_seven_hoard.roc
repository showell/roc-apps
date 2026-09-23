# Experiment: does hoarding 7s help? A split 7 packs pieces into the base in
# the end game. Red hoards the 7 beside the champion's A, joker and J, worth
# less as pieces come home (1500, 1000, 500, 0 by pieces home, as the
# champion's hoard) or more (0, 500, 1000, 1500), against the champion.
#
#   fasttrack/run_exp.sh exp_seven_hoard
app [main!] { pf: platform "cli/platform/main.roc" }

import pf.Echo
import Arena
import Strategy

main! = |_args| {
	champion = Strategy.champion
	games = 1000
	# Built with List.map: a literal list of these records crashes `roc
	# check` (nightly 09-07).
	variants = List.map(
		[{ label: "the champion", worth: [] }, { label: "7s worth less as pieces come home", worth: [1500, 1000, 500, 0] }, { label: "7s worth more as pieces come home", worth: [0, 500, 1000, 1500] }],
		|v| {
			hoards = if List.is_empty(v.worth) { champion.hoards } else { List.append(champion.hoards, { cards: ["7"], worth: v.worth }) }
			{ label: v.label, seats: [Plays({ ..champion, hoards }), Plays(champion), Plays(champion), Plays(champion)] }
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
	Echo.line!("\n${Arena.report("Hoarding the 7, 1000 games", $all)}")
	Ok({})
}
