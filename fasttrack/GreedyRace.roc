# GreedyRace -- the greedy player of greedy_race.roc, as a module: square
# values by Steve's ranking to B1, a whole-turn search for the best board for
# the mover's own pieces, and a game played out step by step. greedy_race.roc
# races it; greedy_diverge.roc takes one game apart.
import Agent
import Config
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

	## What a player plays for: its square values, and what each card it
	## hoards (`hoard`: an A or joker to get out, a J for a late swap) still in
	## its hand at the end of its turn is worth (red only).
	##
	## `hand_value` is by how many of red's pieces are already in its base at
	## the start of the turn: the first entry with none in, the next with one,
	## and so on, the last entry standing for more (Steve: hoarding late in the
	## game is dumb).
	Strategy : { tables : List(List(I64)), hand_value : List(I64), hoard : List(Str) }

	## Red's pieces in its base.
	red_in_base : Type.Game -> U64
	red_in_base = |g| List.count_if(g.piece_map, |e| e.value == "red" and e.key.zone == NormalColor("red") and Config.is_base_id(e.key.id))

	## What each hoarded card is worth to red this turn.
	hoard_value : Strategy, Type.Game -> I64
	hoard_value = |strategy, g| {
		n = red_in_base(g)
		last = List.len(strategy.hand_value)
		if last == 0 {
			0
		} else {
			List.get(strategy.hand_value, if n < last { n } else { last - 1 }) ?? 0
		}
	}

	## Every color's values with `bonus` more a step down its own base: B1 +
	## bonus, B2 + 2 bonus, B3 + 3, B4 + 4.
	with_bonus : I64 -> List(List(I64))
	with_bonus = |bonus|
		List.map_with_index(
			values,
			|table, owner| {
				color = List.get(colors, owner) ?? ""
				List.map_with_index(
						table,
						|v, i|
							match List.get(Agent.all_locs(colors), i) {
								Ok(loc) if loc.zone == NormalColor(color) =>
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

	## A line's worth to the mover: its pieces' squares, and for red, each
	## hoarded card it kept -- none when the line refilled its hand, since the
	## cards it drew were not chosen.
	line_score : Strategy, I64, Agent.Line, U64 -> I64
	line_score = |strategy, worth, line, owner| {
		kept =
			if owner != 0 or line.drew or worth == 0 {
				0
			} else {
				hand = (List.get(line.game.players, owner) ?? Player.get_active_player(line.game)).hand
				U64.to_i64_wrap(List.count_if(hand, |c| List.contains(strategy.hoard, c))) * worth
			}
		board_score(strategy.tables, line.game, owner) + kept
	}

	## The game after the mover's best line of play through the rest of its
	## turn -- every line, the same position reached two ways counted once -- or
	## the game unchanged when it has no play. Every line the search keeps is
	## a whole turn: a player holding a playable card plays it, and a
	## move-again card is followed by the next play when there is one.
	## `cut` says the search stopped before every line had ended.
	greedy_turn : Strategy, Type.Game -> { game : Type.Game, cut : Bool }
	greedy_turn = |strategy, game| {
		owner = game.active_player_idx
		worth = hoard_value(strategy, game)
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
				s = line_score(strategy, worth, line, owner)
				if !List.is_empty(line.msgs) and (!acc.moved or s > acc.score) { { game: line.game, score: s, moved: Bool.True } } else { acc }
			},
		)
		{ game: best.game, cut: List.any($level, Agent.is_open) }
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

	## One step of a game: the mover's whole turn, or a finished turn passed
	## on. `skipped` says the mover had a legal play and played nothing;
	## `cut` that the search stopped short.
	step_checked : Strategy, Type.Game -> { game : Type.Game, skipped : Bool, cut : Bool }
	step_checked = |strategy, g|
		if Player.get_active_player(g).turn == TurnDone {
			{ game: rotate(g), skipped: Bool.False, cut: Bool.False }
		} else {
			played = greedy_turn(strategy, g)
			if played.game == g {
				# No play at all: the turn passes, which is right only when
				# there was nothing to play.
				{ game: rotate(g), skipped: !List.is_empty(Agent.options(g)), cut: played.cut }
			} else {
				{ game: played.game, skipped: Bool.False, cut: played.cut }
			}
		}

	step : Strategy, Type.Game -> Type.Game
	step = |strategy, g| step_checked(strategy, g).game

	## Red's pieces in its pen.
	red_in_pen : Type.Game -> U64
	red_in_pen = |g| List.count_if(g.piece_map, |e| e.value == "red" and e.key.zone == NormalColor("red") and List.contains(["HP1", "HP2", "HP3", "HP4"], e.key.id))

	## Red's turns until its four pieces are home (or `cap`), and how many
	## times an opponent sent a red piece back to the pen.
	## `skips` counts steps where a player with a legal play played nothing,
	## and `cuts` searches that stopped short; both should be 0. `idle` counts
	## red's turns that began with a discard: no piece could move.
	red_turns : Strategy, U64, U64 -> { turns : U64, captured : U64, skips : U64, cuts : U64, idle : U64 }
	red_turns = |strategy, seed, cap| {
		var $g = Game.begin_game(seed, Normal, Solo)
		var $turns = 1
		var $captured = 0
		var $skips = 0
		var $cuts = 0
		var $idle = 0
		var $idle_turn = 0
		var $steps = 0
		while !home($g, 0) and $turns < cap and $steps < 100000 {
			if $g.active_player_idx == 0 and Player.get_active_player($g).turn == TurnNeedDiscard and $idle_turn != $turns {
				$idle = $idle + 1
				$idle_turn = $turns
			}
			checked = step_checked(strategy, $g)
			next = checked.game
			$skips = if checked.skipped { $skips + 1 } else { $skips }
			$cuts = if checked.cut { $cuts + 1 } else { $cuts }
			if $g.active_player_idx != 0 and red_in_pen(next) > red_in_pen($g) {
				$captured = $captured + (red_in_pen(next) - red_in_pen($g))
			}
			if next.active_player_idx == 0 and $g.active_player_idx != 0 {
				$turns = $turns + 1
			}
			$g = next
			$steps = $steps + 1
		}
		{ turns: $turns, captured: $captured, skips: $skips, cuts: $cuts, idle: $idle }
	}
}
