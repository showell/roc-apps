# GreedyRace -- the greedy player of greedy_race.roc, as a module: square
# values by Steve's ranking to B1, a whole-turn search for the best board for
# the mover's own pieces, and a game played out step by step. greedy_race.roc
# races it; greedy_diverge.roc takes one game apart.
import Agent
import Game
import History
import Piece
import Player
import Rank
import Type


GreedyRace :: [].{
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

	## One step of a game: the mover's whole turn, or a finished turn passed on.
	step : List(List(I64)), Type.Game -> Type.Game
	step = |tables, g|
		if Player.get_active_player(g).turn == TurnDone {
			rotate(g)
		} else {
			played = greedy_turn(tables, g)
			# No play at all (should not happen): end the turn.
			if played == g { rotate(g) } else { played }
		}

	## Red's pieces in its pen.
	red_in_pen : Type.Game -> U64
	red_in_pen = |g| List.count_if(g.piece_map, |e| e.value == "red" and e.key.zone == NormalColor("red") and List.contains(["HP1", "HP2", "HP3", "HP4"], e.key.id))

	## Red's turns until its four pieces are home (or `cap`), and how many
	## times an opponent sent a red piece back to the pen.
	red_turns : List(List(I64)), U64, U64 -> { turns : U64, captured : U64 }
	red_turns = |tables, seed, cap| {
		var $g = Game.begin_game(seed, Normal, Solo)
		var $turns = 1
		var $captured = 0
		var $steps = 0
		while !home($g, 0) and $turns < cap and $steps < 100000 {
			next = step(tables, $g)
			if $g.active_player_idx != 0 and red_in_pen(next) > red_in_pen($g) {
				$captured = $captured + (red_in_pen(next) - red_in_pen($g))
			}
			if next.active_player_idx == 0 and $g.active_player_idx != 0 {
				$turns = $turns + 1
			}
			$g = next
			$steps = $steps + 1
		}
		{ turns: $turns, captured: $captured }
	}
}
