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
# captures made by red and of red's pieces, and two checks that should read 0
# -- turns a player skipped holding a legal play, and searches cut short.
# With two variants it also says, game by game, which games only one won.
#
# An experiment is an app beside this module (exp_*.roc) that builds the
# variants, plays them seed by seed, printing Arena.game_line after each game,
# and ends with Arena.report. run_exp.sh builds one and runs it, each line of
# its log stamped with the time.
import Game
import History
import Player
import Search
import Strategy
import Type

Arena :: [].{
	Variant : { label : Str, seats : List(Strategy.Strategy) }

	Result : { red_won : Bool, turns : U64, idle : U64, captured : U64, captures : U64, skips : U64, cuts : U64 }

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

	## A color's pieces in its pen.
	in_pen : Type.Game, Str -> U64
	in_pen = |g, color| List.count_if(g.piece_map, |e| e.value == color and e.key.zone == NormalColor(color) and List.contains(["HP1", "HP2", "HP3", "HP4"], e.key.id))

	red_in_pen : Type.Game -> U64
	red_in_pen = |g| in_pen(g, "red")

	## The other colors' pieces in their pens.
	others_in_pen : Type.Game -> U64
	others_in_pen = |g| List.fold(["blue", "green", "purple"], 0, |t, c| t + in_pen(g, c))

	play : List(Strategy.Strategy), U64 -> Arena.Result
	play = |seats, seed| {
		var $g = Game.begin_game(seed, Normal, Solo)
		var $r = { red_won: Bool.False, turns: 1, idle: 0, captured: 0, captures: 0, skips: 0, cuts: 0 }
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
			took = if $g.active_player_idx == 0 and others_in_pen(next) > others_in_pen($g) { others_in_pen(next) - others_in_pen($g) } else { 0 }
			turned = next.active_player_idx == 0 and $g.active_player_idx != 0
			$r = {
				..$r,
				captured: $r.captured + caught,
				captures: $r.captures + took,
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

	## One game, as the log shows it.
	game_line : Str, U64, Arena.Result -> Str
	game_line = |label, seed, r| {
		outcome = if r.red_won { "won " } else { "lost" }
		"seed ${U64.to_str(seed)} | ${label} | ${outcome} | ${U64.to_str(r.turns)} turns home | ${U64.to_str(r.idle)} idle | took ${U64.to_str(r.captures)} | captured ${U64.to_str(r.captured)}"
	}

	## One row: the variant's label and what its games came to.
	row : Str, List(Arena.Result) -> Str
	row = |label, rs| {
		n = U64.to_f64(List.len(rs))
		turns = List.map(rs, |r| U64.to_f64(r.turns))
		mean = List.fold(turns, 0.0, |t, x| t + x) / n
		var_ = List.fold(turns, 0.0, |t, x| t + (x - mean) * (x - mean)) / (n - 1.0)
		se = F64.sqrt(var_ / n)
		wins = List.count_if(rs, |r| r.red_won)
		idle = List.fold(rs, 0, |t, r| t + r.idle)
		caught = List.fold(rs, 0, |t, r| t + r.captured)
		took = List.fold(rs, 0, |t, r| t + r.captures)
		skips = List.fold(rs, 0, |t, r| t + r.skips)
		cuts = List.fold(rs, 0, |t, r| t + r.cuts)
		"| ${label} | ${U64.to_str(wins)} of ${U64.to_str(List.len(rs))} | ${tenths(mean)} ± ${tenths(se)} | ${tenths(U64.to_f64(idle) / n)} | ${U64.to_str(took)} | ${U64.to_str(caught)} | ${U64.to_str(skips)} / ${U64.to_str(cuts)} |"
	}

	## Two variants on the same deals, game by game: which games only one of
	## them won.
	paired : Str, List(Arena.Result), Str, List(Arena.Result) -> Str
	paired = |label_a, a, label_b, b| {
		pairs = List.map_with_index(a, |ra, i| { a: ra.red_won, b: (List.get(b, i) ?? ra).red_won, seed: i + 1 })
		only_a = List.keep_if(pairs, |p| p.a and !p.b)
		only_b = List.keep_if(pairs, |p| p.b and !p.a)
		seeds = |ps| Str.join_with(List.map(ps, |p| U64.to_str(p.seed)), ", ")
		"Game by game: red won ${U64.to_str(List.len(only_b))} games only as ${label_b} (seeds ${seeds(only_b)}) and ${U64.to_str(List.len(only_a))} only as ${label_a} (seeds ${seeds(only_a)}); the other ${U64.to_str(List.len(pairs) - List.len(only_a) - List.len(only_b))} came out the same."
	}

	## The table, from every variant's games, seeds 1 up.
	report : Str, List({ label : Str, rs : List(Arena.Result) }) -> Str
	report = |title, all| {
		games = U64.to_str(List.len((List.first(all) ?? { label: "", rs: [] }).rs))
		header = "## ${title}\n\n${games} games per variant, seeds 1-${games}; red is the variant, the other seats Strategy.champion.\n\n| variant | red won | red's turns home | idle turns a game | captures by red | red captured | skipped / cut |\n|---|---|---|---|---|---|---|\n"
		rows = Str.join_with(List.map(all, |x| row(x.label, x.rs)), "\n")
		pair =
			if List.len(all) == 2 {
				a = List.get(all, 0) ?? crash("Arena.report: no first variant")
				b = List.get(all, 1) ?? crash("Arena.report: no second variant")
				"\n\n${paired(a.label, a.rs, b.label, b.rs)}"
			} else {
				""
			}
		Str.concat(Str.concat(header, rows), pair)
	}
}
