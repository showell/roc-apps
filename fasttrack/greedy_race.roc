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
# argument gives red alone a bonus of that much a step down its base (B1
# once, B4 four times).
#
#   cd fasttrack && roc build greedy_race.roc --opt=speed && ./greedy_race 20 100
import Agent
import Game
import History
import Piece
import Player
import Rank
import Type

colors : List(Str)
colors = ["red", "blue", "green", "purple"]

## Each color's value for every square, indexed as Agent.all_locs.
values : List(List(I64))
values =
	List.map(
		colors,
		|color| {
			p = Rank.places(colors, color, "B1")
			List.map(p.place, |place| if place == U64.highest { 0 } else { 100 * (U64.to_i64_wrap(p.worst) - U64.to_i64_wrap(place)) })
		},
	)

## Red's values with `bonus` more a step down its base: B1 + bonus, B2 +
## 2 bonus, B3 + 3, B4 + 4. The other colors keep theirs.
with_bonus : I64 -> List(List(I64))
with_bonus = |bonus|
	List.map_with_index(
		values,
		|table, owner|
			if owner != 0 {
				table
			} else {
				List.map_with_index(
					table,
					|v, i|
						match List.get(Agent.all_locs(colors), i) {
							Ok(loc) if loc.zone == NormalColor("red") =>
								match loc.id {
									"B1" => v + bonus
									"B2" => v + 2 * bonus
									"B3" => v + 3 * bonus
									"B4" => v + 4 * bonus
									_ => v
								}
							_ => v
						},
				)
			},
	)

board_score : List(List(I64)), Type.Game, U64 -> I64
board_score = |tables, game, owner| {
	color = List.get(colors, owner) ?? ""
	table = List.get(tables, owner) ?? []
	List.fold(game.piece_map, 0, |total, e| if e.value == color { total + (List.get(table, Agent.index_of(colors, e.key)) ?? 0) } else { total })
}

## The game after the mover's best line of play through the rest of its
## turn -- every line, the same position reached two ways counted once -- or
## the game unchanged when it has no play.
greedy_turn : List(List(I64)), Type.Game -> Type.Game
greedy_turn = |tables, game| {
	owner = game.active_player_idx
	start = Agent.settle({ game, msgs: [], drew: Bool.False })
	var $level = start
	var $done = List.drop_if(start, Agent.is_open)
	var $depth = 0
	while List.any($level, Agent.is_open) and $depth < 8 {
		grown = List.join_map(List.keep_if($level, Agent.is_open), Agent.expand)
		$level = Agent.distinct_lines(grown)
		$done = List.concat($done, List.drop_if($level, Agent.is_open))
		$depth = $depth + 1
	}
	finals = List.concat($done, List.keep_if($level, Agent.is_open))
	best = List.fold(
		finals,
		{ game, score: I64.lowest, moved: Bool.False },
		|acc, line| {
			s = board_score(tables, line.game, owner)
			if !List.is_empty(line.msgs) and (!acc.moved or s > acc.score) { { game: line.game, score: s, moved: Bool.True } } else { acc }
		},
	)
	best.game
}

home : Type.Game, U64 -> Bool
home = |game, owner| Piece.all_home(game.piece_map, List.get(colors, owner) ?? "")

## The next player who is not yet home (red always plays until it is).
rotate : Type.Game -> Type.Game
rotate = |game| {
	var $g = Game.update_game(RotateBoard, History.init, game).1
	var $guard = 0
	while $g.active_player_idx != 0 and home($g, $g.active_player_idx) and $guard < 4 {
		$g = Game.update_game(RotateBoard, History.init, $g).1
		$guard = $guard + 1
	}
	$g
}

## Red's turns until its four pieces are home (or `cap`).
red_turns : List(List(I64)), U64, U64 -> U64
red_turns = |tables, seed, cap| {
	var $g = Game.begin_game(seed, Normal, Solo)
	var $turns = 1
	var $steps = 0
	while !home($g, 0) and $turns < cap and $steps < 100000 {
		player = Player.get_active_player($g)
		next =
			if player.turn == TurnDone {
				rotate($g)
			} else {
				played = greedy_turn(tables, $g)
				# No play at all (should not happen): end the turn.
				if played == $g { rotate($g) } else { played }
			}
		if next.active_player_idx == 0 and $g.active_player_idx != 0 {
			$turns = $turns + 1
		}
		$g = next
		$steps = $steps + 1
	}
	$turns
}

main! = |args| {
	n = match List.first(args) {
		Ok(t) => U64.from_str(t) ?? 20
		Err(_) => 20
	}
	bonus = match List.get(args, 1) {
		Ok(t) => I64.from_str(t) ?? 0
		Err(_) => 0
	}
	tables = with_bonus(bonus)
	cap = 1000
	results = List.map_with_index(List.repeat(0, n), |_, i| red_turns(tables, i + 1, cap))
	each = Str.join_with(List.map(results, U64.to_str), " ")
	total = List.fold(results, 0, |t, r| t + r)
	lo = List.fold(results, cap, |m, r| if r < m { r } else { m })
	hi = List.fold(results, 0, |m, r| if r > m { r } else { m })
	red = List.first(tables) ?? []
	echo!("red's base bonus ${I64.to_str(bonus)} a step: B4 is ${I64.to_str(List.get(red, Agent.index_of(colors, { zone: NormalColor("red"), id: "B4" })) ?? -1)}\n")
	blue_r4 = List.get(List.first(values) ?? [], Agent.index_of(colors, { zone: NormalColor("blue"), id: "R4" })) ?? -1
	echo!("red's values: B4 ${I64.to_str(List.get(List.first(values) ?? [], Agent.index_of(colors, { zone: NormalColor("red"), id: "B4" })) ?? -1)}, blue's R4 ${I64.to_str(blue_r4)}, pen ${I64.to_str(List.get(List.first(values) ?? [], Agent.index_of(colors, { zone: NormalColor("red"), id: "HP1" })) ?? -1)}\n")
	echo!("red's turns to get all four home, ${U64.to_str(n)} games: ${each}\n")
	echo!("mean ${U64.to_str(total // n)}.${U64.to_str((10 * total // n) % 10)}, min ${U64.to_str(lo)}, max ${U64.to_str(hi)}\n")
	Ok({})
}
