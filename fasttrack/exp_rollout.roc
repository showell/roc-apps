# Rollouts at a pivot: which of red's lines wins more from one position.
#
# Plays `seed` with four champions to red's first turn where the champion
# and the leader-chaser (`opponents: Leader`) choose differently. From that
# position each candidate line -- the best few by the champion's score, and
# the chaser's -- is played out `rollouts` times to the first player home,
# every player a champion, each time with every player's undrawn cards
# shuffled afresh. Rollout k shuffles the same way for every candidate, so
# the candidates are compared on the same futures.
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

## The position before red's first turn where the two strategies part.
pivot : U64 -> Try({ game : Type.Game, turn : U64, chaser : Search.Line }, [Same])
pivot = |s| {
	champion = Strategy.champion
	chaser = { ..champion, opponents: Leader }
	seats = List.repeat(Plays(champion), 4)
	var $g = Game.begin_game(s, Normal, Solo)
	var $turn = 1
	var $found = Err(Same)
	var $steps = 0
	while Try.is_err($found) and $steps < 100000 {
		red_to_search = $g.active_player_idx == 0 and Player.get_active_player($g).turn != TurnDone
		a = if red_to_search { Search.best_line(champion, $g) } else { Err(NoPlay) }
		b = if red_to_search { Search.best_line(chaser, $g) } else { Err(NoPlay) }
		match (a, b) {
			(Ok(x), Ok(y)) if x.line.game.board != y.line.game.board => {
				$found = Ok({ game: $g, turn: $turn, chaser: y.line })
			}
			_ => {
				next = Arena.step(seats, $g).game
				if next.active_player_idx == 0 and $g.active_player_idx != 0 {
					$turn = $turn + 1
				}
				$g = next
			}
		}
		$steps = $steps + 1
	}
	$found
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
	# Tied to the arguments so the compiler cannot run the games while it
	# compiles: with a constant seed it evaluates pivot(seed) at compile
	# time, and crashes (nightly 09-07).
	at_run_time = seed + 0 * List.len(args)
	p = pivot(at_run_time) ?? crash("the strategies never part on this seed")
	g = p.game
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
	distinct = List.fold(by_score, [], |kept, l| if List.any(kept, |k| k.game.board == l.game.board) { kept } else { List.append(kept, l) })
	top = List.take_first(distinct, 5)
	candidates = if List.any(top, |l| l.game.board == p.chaser.game.board) { top } else { List.append(top, p.chaser) }
	Echo.line!("## Rollouts at seed ${U64.to_str(seed)}'s pivot\n")
	Echo.line!("Red's turn ${U64.to_str(p.turn)}, hand ${Str.join_with(red.hand, " ")}. ${U64.to_str(List.len(candidates))} lines, each played out ${U64.to_str(rollouts)} times from the end of red's turn, every player a champion, the undrawn cards shuffled afresh each time (the same ${U64.to_str(rollouts)} shuffles for every line).\n")
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
		tag = if r.line.game.board == p.chaser.game.board { "the capture (chaser's pick)" } else if r.line.game.board == (List.first(candidates) ?? r.line).game.board { "champion's pick" } else { "" }
		others = Str.join_with(List.map([1, 2, 3], |c| U64.to_str(List.count_if(r.wins, |w| w == c))), " / ")
		Echo.line!("| ${tag} | ${moved(g, r.line.game)} | ${I64.to_str(Search.score(champion, g, r.line))} | ${U64.to_str(red_wins)} | ${percent(rate)} ± ${percent(F64.sqrt(rate * (1.0 - rate) / n))} | ${percent(mean)} ± ${percent(sd / F64.sqrt(n))} | ${others} |")
	}
	Ok({})
}
