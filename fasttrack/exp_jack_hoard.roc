# Experiment: what is a J kept in hand worth? It tapers like the A and joker
# hoard: the full value with no piece in the base, then 2/3, 1/3 and 0.
#
#   cd fasttrack && roc build exp_jack_hoard.roc --opt=speed && ./exp_jack_hoard
import Arena
import Strategy

jacks : I64 -> Strategy.Strategy
jacks = |max| {
	..Strategy.champion,
	hoards: List.append(Strategy.champion.hoards, { cards: ["J"], worth: [max, (2 * max) // 3, max // 3, 0] }),
}

main! = |_args| {
	champion = Strategy.champion
	variants = List.map([0, 300, 900, 1500, 3000], |max| { label: "J up to ${I64.to_str(max)}", seats: [jacks(max), champion, champion, champion] })
	echo!(Arena.report("Hoarding the J", variants, 30))
	echo!("\n")
	Ok({})
}
