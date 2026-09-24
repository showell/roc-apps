# Experiment: is a variant of the champion better? Every seed is dealt four
# times with the decks turned a seat (duplicate deals), and red plays the
# champion and each variant on the same deals against three champions
# (Arena.compare). The report judges each variant against the champion.
#
# To try something, change `variants` (and the seeds); Strategy.roc says
# what a strategy is. Past variants and their results are in TUNING.md.
#
#   fasttrack/run_exp.sh exp_duplicate
app [main!] { pf: platform "cli/platform/main.roc" }

import pf.Echo
import Arena
import Strategy

## The variants under test, each against Strategy.champion.
variants : List({ label : Str, strategy : Strategy.Strategy })
variants = List.map([1500, 4000], |b| { label: "base bonus ${I64.to_str(b)}", strategy: { ..Strategy.champion, base_bonus: b } })

## Seeds first_seed, first_seed + 1, ...; each is dealt four times. Use
## seeds no earlier experiment chose its winner on: 1-1000 went on the base
## bonus (TUNING.md).
first_seed : U64
first_seed = 1001

seeds : U64
seeds = 500

main! = |args| {
	# Tied to the arguments, or the compiler plays the games while it
	# compiles (it evaluates a pure call on constants).
	start = first_seed + 0 * List.len(args)
	labels = List.prepend(List.map(variants, |v| v.label), "the champion")
	strategies = List.prepend(List.map(variants, |v| v.strategy), Strategy.champion)
	var $blocks = []
	for seed in start..<(start + seeds) {
		block = Arena.compare(strategies, seed)
		$blocks = List.append($blocks, block)
		Echo.line!(Arena.block_line(labels, seed, block))
	}
	Echo.line!("\n## ${Str.join_with(List.drop_first(labels, 1), ", ")}, dealt as duplicate\n")
	Echo.line!(Arena.compare_report(labels, start, $blocks))
	Ok({})
}
