# Arena -- experiments on the computer's strategy.
#
# An experiment is a list of variants, each a Strategy for every seat; the
# variant under test is seat 0 (red), the others usually Strategy.champion.
# Each game is played to its end -- the first player with all four pieces
# home wins -- and on until red's four are home too, a finished player's turns
# skipped, so red's turns home count in every game. Seeds 1 .. N, each player's
# deck shuffled once from its seed, so every variant is dealt the same cards.
#
# The report is a markdown table per variant: red's wins, red's turns home
# (mean and standard error), idle turns (red's turns begun with a discard),
# captures of red pieces, and two checks that should read 0 -- turns a player
# skipped holding a legal play, and searches cut short.
#
# An experiment is an app beside this module (exp_*.roc) that builds the
# variants and prints Arena.report.
import Game
import History
import Player
import Search
import Strategy
import Type

Arena :: [].{
	Variant : { label : Str, seats : List(Strategy.Strategy) }

	Result : { red_won : Bool, turns : U64, idle : U64, captured : U64, skips : U64, cuts : U64 }

	home : Type.Game, U64 -> Bool
	home = |game, seat| {
		color = List.get(game.zone_colors, seat) ?? ""
		Strategy.in_base(game, color) == 4
	}

	## The next player not yet home; red plays until it is.
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

	Step : { game : Type.Game, skipped : Bool, cut : Bool }

	## The mover's whole turn, or a finished turn passed on.
	step : List(Strategy.Strategy), Type.Game -> Arena.Step
	step = |seats, g|
		if Player.get_active_player(g).turn == TurnDone {
			{ game: rotate(g), skipped: Bool.False, cut: Bool.False }
		} else {
			strategy = List.get(seats, g.active_player_idx) ?? Strategy.champion
			match Search.best_line(strategy, g) {
				Ok(best) => { game: best.line.game, skipped: Bool.False, cut: best.cut }
				# No play at all: the turn passes, which is right only when
				# there was nothing to play.
				Err(_) => { game: rotate(g), skipped: !List.is_empty(Search.options(g)), cut: Bool.False }
			}
		}

	red_in_pen : Type.Game -> U64
	red_in_pen = |g| List.count_if(g.piece_map, |e| e.value == "red" and e.key.zone == NormalColor("red") and List.contains(["HP1", "HP2", "HP3", "HP4"], e.key.id))

	play : List(Strategy.Strategy), U64 -> Arena.Result
	play = |seats, seed| {
		var $g = Game.begin_game(seed, Normal, Solo)
		var $r = { red_won: Bool.False, turns: 1, idle: 0, captured: 0, skips: 0, cuts: 0 }
		var $decided = Bool.False
		var $idle_turn = 0
		var $steps = 0
		while !home($g, 0) and $steps < 100000 {
			if $g.active_player_idx == 0 and Player.get_active_player($g).turn == TurnNeedDiscard and $idle_turn != $r.turns {
				$r = { ..$r, idle: $r.idle + 1 }
				$idle_turn = $r.turns
			}
			s = step(seats, $g)
			next = s.game
			caught = if $g.active_player_idx != 0 and red_in_pen(next) > red_in_pen($g) { red_in_pen(next) - red_in_pen($g) } else { 0 }
			turned = next.active_player_idx == 0 and $g.active_player_idx != 0
			$r = {
				..$r,
				captured: $r.captured + caught,
				skips: if s.skipped { $r.skips + 1 } else { $r.skips },
				cuts: if s.cut { $r.cuts + 1 } else { $r.cuts },
				turns: if turned { $r.turns + 1 } else { $r.turns },
			}
			# The first player home wins.
			if !$decided and List.any([1, 2, 3], |seat| home(next, seat)) {
				$decided = Bool.True
			}
			$g = next
			$steps = $steps + 1
		}
		{ ..$r, red_won: !$decided }
	}

	tenths : F64 -> Str
	tenths = |x| {
		t = F64.to_i64_wrap(x * 10.0 + 0.5)
		"${I64.to_str(t // 10)}.${I64.to_str(t % 10)}"
	}

	## One row: the variant's label and what its games came to.
	row : Arena.Variant, U64 -> Str
	row = |variant, games| {
		results = List.map_with_index(List.repeat(0, games), |_, i| play(variant.seats, i + 1))
		n = U64.to_f64(games)
		turns = List.map(results, |r| U64.to_f64(r.turns))
		mean = List.fold(turns, 0.0, |t, x| t + x) / n
		var_ = List.fold(turns, 0.0, |t, x| t + (x - mean) * (x - mean)) / (n - 1.0)
		se = F64.sqrt(var_ / n)
		wins = List.count_if(results, |r| r.red_won)
		idle = List.fold(results, 0, |t, r| t + r.idle)
		caught = List.fold(results, 0, |t, r| t + r.captured)
		skips = List.fold(results, 0, |t, r| t + r.skips)
		cuts = List.fold(results, 0, |t, r| t + r.cuts)
		"| ${variant.label} | ${U64.to_str(wins)} of ${U64.to_str(games)} | ${tenths(mean)} ± ${tenths(se)} | ${tenths(U64.to_f64(idle) / n)} | ${U64.to_str(caught)} | ${U64.to_str(skips)} / ${U64.to_str(cuts)} |"
	}

	report : Str, List(Arena.Variant), U64 -> Str
	report = |title, variants, games| {
		header = "## ${title}\n\n${U64.to_str(games)} games per variant, seeds 1-${U64.to_str(games)}; red is the variant, the other seats Strategy.champion.\n\n| variant | red won | red's turns home | idle turns a game | red captured | skipped / cut |\n|---|---|---|---|---|---|\n"
		Str.concat(header, Str.join_with(List.map(variants, |v| row(v, games)), "\n"))
	}
}
