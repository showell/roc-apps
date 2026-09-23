# How many turns the greedy player takes to get all four pieces home.
#
# Every square is worth 100 points a place in Steve's ranking to B1
# (Rank.places): the best square (B4) 6100, the worst (the pen) 0. Each turn
# the greedy player tries every sequence of plays its hand allows to the
# turn's end -- a play being a card and every click it takes, a split seven's
# two halves included, and a move-again card going on to the next -- and
# keeps the one that leaves its own pieces worth the most: A, 6, Q, K, 9 from
# the pen to B3 is one candidate. Jack trades are plays like any other.
# Nothing counts an opponent's pieces, so a capture is only ever an
# accident. Where the hand is refilled mid-turn the search stops, and the
# player searches again with the cards it drew.
#
# All four seats play greedy, each on its own color's values. Red's turns are
# counted until red's four pieces are in its base; a player already home is
# skipped. N games (default 20; the first argument), seeds 1 .. N. A second
# argument gives every player a bonus of that much a step down its own base
# (B1 once, B4 four times); a third is what red alone counts each A, joker
# or J it keeps in its hand at the end of its turn.
#
#   cd fasttrack && roc build greedy_race.roc --opt=speed && ./greedy_race 20 1000 500
import Agent
import GreedyRace

main! = |args| {
	n = match List.first(args) {
		Ok(t) => U64.from_str(t) ?? 20
		Err(_) => 20
	}
	bonus = match List.get(args, 1) {
		Ok(t) => I64.from_str(t) ?? 0
		Err(_) => 0
	}
	hand_value = match List.get(args, 2) {
		Ok(t) => I64.from_str(t) ?? 0
		Err(_) => 0
	}
	tables = GreedyRace.with_bonus(bonus)
	strategy = { tables, hand_value }
	cap = 1000
	results = List.map_with_index(List.repeat(0, n), |_, i| GreedyRace.red_turns(strategy, i + 1, cap))
	turns = List.map(results, |r| r.turns)
	total = List.fold(turns, 0, |t, r| t + r)
	lo = List.fold(turns, cap, |m, r| if r < m { r } else { m })
	hi = List.fold(turns, 0, |m, r| if r > m { r } else { m })
	caught = List.fold(results, 0, |t, r| t + r.captured)
	red = List.first(tables) ?? []
	echo!("every player's base bonus ${I64.to_str(bonus)} a step (B4 is ${I64.to_str(List.get(red, Agent.index_of(GreedyRace.colors, { zone: NormalColor("red"), id: "B4" })) ?? -1)}); red values each A, joker or J it keeps at ${I64.to_str(hand_value)}\n")
	echo!("| game | ${Str.join_with(List.map_with_index(results, |_, i| U64.to_str(i + 1)), " | ")} |\n")
	echo!("| turns | ${Str.join_with(List.map(turns, U64.to_str), " | ")} |\n")
	echo!("| red captured | ${Str.join_with(List.map(results, |r| U64.to_str(r.captured)), " | ")} |\n")
	skips = List.fold(results, 0, |t, r| t + r.skips)
	cuts = List.fold(results, 0, |t, r| t + r.cuts)
	echo!("mean ${U64.to_str(total // n)}.${U64.to_str((10 * total // n) % 10)} turns, min ${U64.to_str(lo)}, max ${U64.to_str(hi)}; red captured ${U64.to_str(caught)} times in all\n")
	echo!("turns skipped with a legal play: ${U64.to_str(skips)}; searches cut short: ${U64.to_str(cuts)}\n")
	Ok({})
}
