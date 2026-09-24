# Rollouts: which of red's lines wins more from one position -- the way to
# judge a single decision, where whole games drown it in luck.
#
# Plays `seed` with four champions to the start of red's turn `red_turn`.
# From there the champion's pick (Search.best_line) and its next best lines
# by its own score, one per board, `lines` in all, are each played out
# `rollouts` times to the first player home, every player a champion, each
# time with every player's undrawn cards shuffled afresh. (A line that drew a
# card mid-turn plays the rest of its turn with the cards it drew.) Rollout k shuffles the same way for every line, so the
# lines are compared on the same futures. If the champion's pick is not the
# line that wins most, its values are wrong somewhere (TUNING.md, seed 69).
#
#   fasttrack/run_exp.sh exp_rollout
app [main!] { pf: platform "cli/platform/main.roc" }

import pf.Echo
import Arena
import Board
import ElmRandom
import Game
import Player
import Search
import Strategy
import Type

seed : U64
seed = 69

red_turn : U64
red_turn = 7

lines : U64
lines = 5

rollouts : U64
rollouts = 1000

colors : List(Str)
colors = ["red", "blue", "green", "purple"]

loc_str : U64 -> Str
loc_str = |s| if s == Board.bullseye { "bullseye" } else { "${List.get(colors, Board.zone(s)) ?? "?"}.${Board.loc_of(colors, s).id}" }

## The pieces a line moved: where they left and where they went.
moved : Type.Game, Type.Game -> Str
moved = |before, after| {
	changed = List.keep_if(Board.squares, |s| List.get(before.board, s) != List.get(after.board, s))
	left = List.keep_if(changed, |s| (List.get(before.board, s) ?? 0) != 0)
	went = List.keep_if(changed, |s| (List.get(after.board, s) ?? 0) != 0)
	show = |b, ss| Str.join_with(List.map(ss, |s| "${List.get(colors, U8.to_u64(List.get(b, s) ?? 1) - 1) ?? "?"}@${loc_str(s)}"), " ")
	"${show(before.board, left)} -> ${show(after.board, went)}"
}

## Every player's undrawn cards shuffled afresh for rollout `k`.
reshuffled : Type.Game, U64 -> Type.Game
reshuffled = |g, k| {
	players = List.map_with_index(
		g.players,
		|p, i| {
			s = Player.shuffle_cards(p.deck, ElmRandom.initial_seed(7919 * (k + 1) + i))
			{ ..p, deck: s.deck, seed: s.seed }
		},
	)
	{ ..g, players }
}

main! = |args| {
	champion = Strategy.champion
	# Tied to the arguments, or the compiler plays the games while it
	# compiles (it evaluates a pure call on constants).
	g = Arena.position(seed + 0 * List.len(args), red_turn)
	red = Player.get_active_player(g)
	found = Search.all_lines(g)
	by_score = List.sort_with(
		found.lines,
		|x, y| {
			sx = Search.score(champion, g, x)
			sy = Search.score(champion, g, y)
			if sx > sy { Before } else if sx < sy { After } else { Same }
		},
	)
	pick = (Search.best_line(champion, g) ?? crash("red has no play here")).line
	alternatives = List.fold(by_score, [], |kept, l| if l.game.board == pick.game.board or List.any(kept, |k| k.game.board == l.game.board) { kept } else { List.append(kept, l) })
	candidates = List.prepend(List.take_first(alternatives, lines - 1), pick)
	Echo.line!("## Rollouts at seed ${U64.to_str(seed)}, red's turn ${U64.to_str(red_turn)}\n")
	Echo.line!("Red holds ${Str.join_with(red.hand, " ")}. The champion's best ${U64.to_str(List.len(candidates))} lines, each played out ${U64.to_str(rollouts)} times from the end of red's turn, every player a champion, the undrawn cards shuffled afresh each time (the same ${U64.to_str(rollouts)} shuffles for every line).\n")
	var $results = []
	for c in candidates {
		wins = List.map(Board.indices(rollouts), |k| Arena.winner_from(List.repeat(Plays(champion), 4), reshuffled(c.game, k)))
		$results = List.append($results, { line: c, wins })
		Echo.line!("done: ${moved(g, c.game)}: red won ${U64.to_str(List.count_if(wins, |w| w == 0))} of ${U64.to_str(rollouts)}")
	}
	base = (List.first($results) ?? crash("no lines")).wins
	n = U64.to_f64(rollouts)
	Echo.line!("\n| line | pieces | champion's score | red won | red's win rate | vs the champion's pick, paired | blue / green / purple won |")
	Echo.line!("|---|---|---|---|---|---|---|")
	for r in $results {
		red_wins = List.count_if(r.wins, |w| w == 0)
		rate = U64.to_f64(red_wins) / n
		diffs = List.map_with_index(r.wins, |w, k| (if w == 0 { 1.0 } else { 0.0 }) - (if (List.get(base, k) ?? 4) == 0 { 1.0 } else { 0.0 }))
		mean = List.fold(diffs, 0.0, |t, d| t + d) / n
		sd = F64.sqrt(List.fold(diffs, 0.0, |t, d| t + (d - mean) * (d - mean)) / (n - 1.0))
		tag = if r.line.game.board == pick.game.board { "champion's pick" } else { "" }
		others = Str.join_with(List.map([1, 2, 3], |c| U64.to_str(List.count_if(r.wins, |w| w == c))), " / ")
		Echo.line!("| ${tag} | ${moved(g, r.line.game)} | ${I64.to_str(Search.score(champion, g, r.line))} | ${U64.to_str(red_wins)} | ${Arena.percent(rate)} ± ${Arena.percent(F64.sqrt(rate * (1.0 - rate) / n))} | ${Arena.percent(mean)} ± ${Arena.percent(sd / F64.sqrt(n))} | ${others} |")
	}
	Ok({})
}
