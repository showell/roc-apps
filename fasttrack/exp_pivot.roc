# Analysis: the pivotal move in games red won only as the champion. Red plays
# each seed twice -- as the champion and as the leader-chaser (`opponents:
# Leader`) -- the other seats the champion in both. The games run in step
# until red's two strategies first choose differently; that position is shown
# with every line red had, and then each game is played out to its winner.
#
# Board values are each player's own, as the champion values its pieces.
#
#   fasttrack/run_exp.sh exp_pivot
import Arena
import Game
import Player
import Search
import Strategy
import Type

## echo! writes no newline.
line! = |s| echo!(Str.concat(s, "\n"))

colors : List(Str)
colors = ["red", "blue", "green", "purple"]

value : Type.Game, Str -> I64
value = |game, color| Strategy.board(Strategy.champion, game, [color])

values : Type.Game -> Str
values = |game| Str.join_with(List.map(colors, |c| "${c} ${I64.to_str(value(game, c))}"), ", ")

loc_str : Type.PieceLocation -> Str
loc_str = |loc|
	match loc.zone {
		BullsEyeZone => "bullseye"
		NormalColor(zone) => "${zone}.${loc.id}"
	}

## The pieces a line moved: where they left and where they went.
moved : Type.Game, Type.Game -> Str
moved = |before, after| {
	left = List.keep_if(before.piece_map, |e| !List.contains(after.piece_map, e))
	went = List.keep_if(after.piece_map, |e| !List.contains(before.piece_map, e))
	show = |es| Str.join_with(List.map(es, |e| "${e.value}@${loc_str(e.key)}"), " ")
	"${show(left)} -> ${show(went)}"
}

## What a line did to each player whose value it changed.
impact : Type.Game, Type.Game -> Str
impact = |before, after| {
	changed = List.keep_if(colors, |c| value(before, c) != value(after, c))
	Str.join_with(
		List.map(
			changed,
			|c| {
				d = value(after, c) - value(before, c)
				sign = if d > 0 { "+" } else { "" }
				"${c} ${sign}${I64.to_str(d)}"
			},
		),
		", ",
	)
}

## The opponent whose pieces are worth most.
leading : Type.Game -> Str
leading = |game|
	List.fold(
		["blue", "green", "purple"],
		{ color: "", v: I64.lowest },
		|best, c| {
			v = value(game, c)
			if v > best.v { { color: c, v } } else { best }
		},
	).color

## Where the two strategies first part, and the game before it.
Pivot : { game : Type.Game, turn : U64, champion : Search.Line, chaser : Search.Line }

find_pivot : U64 -> Try(Pivot, [Same])
find_pivot = |seed| {
	champion = Strategy.champion
	chaser = { ..champion, opponents: Leader }
	seats = [champion, champion, champion, champion]
	var $g = Game.begin_game(seed, Normal, Solo)
	var $turn = 1
	var $pivot = Err(Same)
	var $steps = 0
	while Try.is_err($pivot) and !Arena.home($g, 0) and $steps < 100000 {
		red_to_search = $g.active_player_idx == 0 and Player.get_active_player($g).turn != TurnDone
		a = if red_to_search { Search.best_line(champion, $g) } else { Err(NoPlay) }
		b = if red_to_search { Search.best_line(chaser, $g) } else { Err(NoPlay) }
		match (a, b) {
			(Ok(x), Ok(y)) if x.line.game != y.line.game => {
				$pivot = Ok({ game: $g, turn: $turn, champion: x.line, chaser: y.line })
			}
			_ => {
				next = match a {
					Ok(best) => best.line.game
					Err(_) => Arena.step(seats, $g).game
				}
				if next.active_player_idx == 0 and $g.active_player_idx != 0 {
					$turn = $turn + 1
				}
				$g = next
			}
		}
		$steps = $steps + 1
	}
	$pivot
}

## The rest of a game from red's line at the pivot: every round's values,
## every capture, and who got home first.
play_out : List(Strategy.Strategy), Type.Game, U64 -> Str
play_out = |seats, from, turn0| {
	var $g = from
	var $turn = turn0
	var $log = []
	var $winner = ""
	var $steps = 0
	while !Arena.home($g, 0) and $steps < 100000 {
		next = Arena.step(seats, $g).game
		mover = List.get(colors, $g.active_player_idx) ?? ""
		for c in colors {
			if Arena.in_pen(next, c) > Arena.in_pen($g, c) {
				$log = List.append($log, "    turn ${U64.to_str($turn)}: ${mover} captured ${c}")
			}
		}
		if $winner == "" {
			for c in ["blue", "green", "purple"] {
				if $winner == "" and Strategy.in_base(next, c) == 4 {
					$winner = c
					$log = List.append($log, "    turn ${U64.to_str($turn)}: ${c} home -- ${c} wins")
				}
			}
		}
		if next.active_player_idx == 0 and $g.active_player_idx != 0 {
			$turn = $turn + 1
			$log = List.append($log, "  turn ${U64.to_str($turn)}: ${values(next)}")
		}
		$g = next
		$steps = $steps + 1
	}
	outcome = if $winner == "" { "red wins, home on turn ${U64.to_str($turn)}" } else { "${$winner} wins; red home on turn ${U64.to_str($turn)}" }
	"${Str.join_with($log, "\n")}\n  => ${outcome}"
}

main! = |_args| {
	champion = Strategy.champion
	chaser = { ..champion, opponents: Leader }
	for seed in [74, 21, 22, 43, 55, 60, 69, 76, 79] {
		match find_pivot(seed) {
			Err(_) => line!("\n## seed ${U64.to_str(seed)}: the two strategies never part")
			Ok(p) => {
				g = p.game
				hand = Player.get_active_player(g).hand
				line!("\n## seed ${U64.to_str(seed)}, red's turn ${U64.to_str(p.turn)}, hand ${Str.join_with(hand, " ")}")
				line!("before: ${values(g)}")
				found = Search.all_lines(g)
				ranked = |s|
					List.sort_with(
						found.lines,
						|x, y| {
							sx = Search.score(s, g, x)
							sy = Search.score(s, g, y)
							if sx > sy { Before } else if sx < sy { After } else { Same }
						},
					)
				top = if List.len(found.lines) <= 40 { ranked(champion) } else { List.concat(List.take_first(ranked(champion), 4), List.take_first(ranked(chaser), 4)) }
				shown = List.fold(top, [], |kept, l| if List.any(kept, |k| k.game == l.game) { kept } else { List.append(kept, l) })
				who = leading(g)
				others = List.drop_if(colors, |c| c == "red" or c == who)
				delta = |l, c| {
					d = value(l.game, c) - value(g, c)
					if d > 0 { "+${I64.to_str(d)}" } else { I64.to_str(d) }
				}
				line!("${U64.to_str(List.len(found.lines))} lines, ${U64.to_str(List.len(shown))} shown: ${if List.len(found.lines) <= 40 { "all" } else { "the best four by each scoring" }}, by the champion's score. The leader is ${who}.")
				line!("| line | pieces | red | ${who} (leader) | others | champion's score | chaser's score |")
				line!("|---|---|---|---|---|---|---|")
				for l in shown {
					tag = if l.game == p.champion.game { "champion's pick" } else if l.game == p.chaser.game { "chaser's pick" } else { "" }
					rest = Str.join_with(List.map(List.keep_if(others, |c| value(l.game, c) != value(g, c)), |c| "${c} ${delta(l, c)}"), ", ")
					line!("| ${tag} | ${moved(g, l.game)} | ${delta(l, "red")} | ${delta(l, who)} | ${rest} | ${I64.to_str(Search.score(champion, g, l))} | ${I64.to_str(Search.score(chaser, g, l))} |")
				}
				line!("\nred as the champion, from its pick:")
				line!(play_out([champion, champion, champion, champion], p.champion.game, p.turn))
				line!("\nred as the chaser, from its pick:")
				line!(play_out([chaser, champion, champion, champion], p.chaser.game, p.turn))
			}
		}
	}
	Ok({})
}
