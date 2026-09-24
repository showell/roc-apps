# Rollouts: which of red's lines wins more from one position -- the way to
# judge a single decision, where whole games drown it in luck.
#
# Plays `seed` with four champions to the start of red's turn `red_turn`.
# From there the champion's best `lines` lines (by its own score, one per
# board) are each played out `rollouts` times to the first player home,
# every player a champion, each time with every player's undrawn cards
# shuffled afresh. Rollout k shuffles the same way for every line, so the
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

## A fraction as a percentage, one decimal.
percent : F64 -> Str
percent = |x| {
	t = F64.to_i64_wrap(F64.abs(x) * 1000.0 + 0.5)
	sign = if x < 0.0 and t > 0 { "-" } else { "" }
	"${sign}${I64.to_str(t // 10)}.${I64.to_str(t % 10)}%"
}

## The pieces a line moved: where they left and where they went.
moved : Type.Game, Type.Game -> Str
moved = |before, after| {
	changed = List.keep_if(Board.squares, |s| List.get(before.board, s) != List.get(after.board, s))
	left = List.keep_if(changed, |s| (List.get(before.board, s) ?? 0) != 0)
	went = List.keep_if(changed, |s| (List.get(after.board, s) ?? 0) != 0)
	show = |b, ss| Str.join_with(List.map(ss, |s| "${List.get(colors, U8.to_u64(List.get(b, s) ?? 1) - 1) ?? "?"}@${loc_str(s)}"), " ")
	"${show(before.board, left)} -> ${show(after.board, went)}"
}

## The position at the start of red's turn `turn`.
position : U64, U64 -> Type.Game
position = |s, turn| {
	seats = List.repeat(Plays(Strategy.champion), 4)
	var $g = Game.begin_game(s, Normal, Solo)
	var $turn = 1
	var $steps = 0
	while $turn < turn and $steps < 100000 {
		next = Arena.step(seats, $g).game
		if next.active_player_idx == 0 and $g.active_player_idx != 0 {
			$turn = $turn + 1
		}
		$g = next
		$steps = $steps + 1
	}
	$g
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

## Who gets home first, from here, four champions playing.
winner : Type.Game -> U64
winner = |from| {
	seats = List.repeat(Plays(Strategy.champion), 4)
	var $g = from
	var $won = 4
	var $steps = 0
	while $won == 4 and $steps < 100000 {
		a = $g.active_player_idx
		$g = Arena.step(seats, $g).game
		if Arena.home($g, a) {
			$won = a
		}
		$steps = $steps + 1
	}
	$won
}

main! = |args| {
	champion = Strategy.champion
	# Tied to the arguments, or the compiler plays the games while it
	# compiles (it evaluates a pure call on constants).
	g = position(seed + 0 * List.len(args), red_turn)
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
	candidates = List.take_first(List.fold(by_score, [], |kept, l| if List.any(kept, |k| k.game.board == l.game.board) { kept } else { List.append(kept, l) }), lines)
	Echo.line!("## Rollouts at seed ${U64.to_str(seed)}, red's turn ${U64.to_str(red_turn)}\n")
	Echo.line!("Red holds ${Str.join_with(red.hand, " ")}. The champion's best ${U64.to_str(List.len(candidates))} lines, each played out ${U64.to_str(rollouts)} times from the end of red's turn, every player a champion, the undrawn cards shuffled afresh each time (the same ${U64.to_str(rollouts)} shuffles for every line).\n")
	var $results = []
	for c in candidates {
		wins = List.map(List.map_with_index(List.repeat(0, rollouts), |_, k| k), |k| winner(reshuffled(c.game, k)))
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
		tag = if r.line.game.board == (List.first(candidates) ?? r.line).game.board { "champion's pick" } else { "" }
		others = Str.join_with(List.map([1, 2, 3], |c| U64.to_str(List.count_if(r.wins, |w| w == c))), " / ")
		Echo.line!("| ${tag} | ${moved(g, r.line.game)} | ${I64.to_str(Search.score(champion, g, r.line))} | ${U64.to_str(red_wins)} | ${percent(rate)} ± ${percent(F64.sqrt(rate * (1.0 - rate) / n))} | ${percent(mean)} ± ${percent(sd / F64.sqrt(n))} | ${others} |")
	}
	Ok({})
}
