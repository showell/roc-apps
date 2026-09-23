# Experiment: does playing to win beat playing for speed? Red scores its own
# pieces less the leading opponent's at the end of its turn (Strategy's
# `opponents: Leader`) against the champion, which counts only its own.
#
#   cd fasttrack && roc build exp_win_focus.roc --opt=speed && ./exp_win_focus
import Arena
import Strategy

main! = |_args| {
	champion = Strategy.champion
	# Built with List.map: a literal list of these records crashes `roc
	# check` (nightly 09-07).
	variants = List.map(
		[Ignore, Leader],
		|opponents| {
			label: if opponents == Leader { "own less the leader" } else { "own pieces only" },
			seats: [{ ..champion, opponents }, champion, champion, champion],
		},
	)
	echo!(Arena.report("Playing to win", variants, 80))
	echo!("\n")
	Ok({})
}
