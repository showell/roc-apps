# Experiment: does playing to win beat playing for speed? Red scores its own
# pieces less the leading opponent's at the end of its turn -- only when it
# starts the turn behind the leader (Strategy's `opponents:
# LeaderWhenBehind`) -- against the champion, which counts only its own.
# `opponents: Leader` (always) lost: TUNING.md.
#
#   fasttrack/run_exp.sh exp_win_focus
import Arena
import Strategy

## echo! writes no newline.
line! = |s| echo!(Str.concat(s, "\n"))

main! = |_args| {
	champion = Strategy.champion
	games = 80
	# Built with List.map: a literal list of these records crashes `roc
	# check` (nightly 09-07).
	variants = List.map(
		[Ignore, LeaderWhenBehind],
		|opponents| {
			label: if opponents == LeaderWhenBehind { "less the leader when behind" } else { "own pieces only" },
			seats: [{ ..champion, opponents }, champion, champion, champion],
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
			line!(Arena.game_line(x.label, seed, List.last(x.rs) ?? crash("no game")))
		}
	}
	line!("\n${Arena.report("Playing to win when behind", $all)}")
	Ok({})
}
