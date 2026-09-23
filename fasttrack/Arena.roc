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
import Color
import Game
import History
import Player
import Search
import Strategy
import Type

Arena :: [].{
	## A seat plays a Strategy through the whole-turn search, or takes the
	## first legal move it finds.
	Seat : [Plays(Strategy.Strategy), FirstLegal]

	Variant : { label : Str, seats : List(Arena.Seat) }

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

	Step : { game : Type.Game, msgs : List(Type.GameMsg), skipped : Bool, cut : Bool }

	## The mover's whole turn, or a finished turn passed on.
	step : List(Arena.Seat), Type.Game -> Arena.Step
	step = |seats, g|
		if Player.get_active_player(g).turn == TurnDone {
			{ game: rotate(g), msgs: [], skipped: Bool.False, cut: Bool.False }
		} else {
			found = match List.get(seats, g.active_player_idx) ?? Plays(Strategy.champion) {
				Plays(strategy) => Search.best_line(strategy, g)
				FirstLegal => Try.map_ok(Search.first_line(g), |line| { line, cut: Bool.False })
			}
			match found {
				Ok(best) => { game: best.line.game, msgs: best.line.msgs, skipped: Bool.False, cut: best.cut }
				# No play at all: the turn passes, which is right only when
				# there was nothing to play.
				Err(_) => { game: rotate(g), msgs: [], skipped: !List.is_empty(Search.options(g)), cut: Bool.False }
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

	play : List(Arena.Seat), U64 -> Arena.Result
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

	## One player's game, to the first player home.
	Tally : { won : Bool, turns : U64, idle : U64, cards : U64, ft_landings : U64, ft_hops : U64, captures : U64, captured : U64, played : List(Str), discarded : List(Str) }

	no_tally : Arena.Tally
	no_tally = { won: Bool.False, turns: 0, idle: 0, cards: 0, ft_landings: 0, ft_hops: 0, captures: 0, captured: 0, played: [], discarded: [] }

	## The moves a turn's messages made, each with its kind. A start with one
	## end moves at once (Move.maybe_auto_move), with no end click.
	moves_of : Type.Game, List(Type.GameMsg) -> List(Type.Move)
	moves_of = |g0, msgs| {
		var $g = g0
		var $moves = []
		for msg in msgs {
			match (Player.get_active_player($g).turn, msg) {
				(TurnNeedStartLoc(info), SetStartLocation(start)) => {
					from = List.keep_if(info.moves, |m| m.start == start)
					match from {
						[first, ..] if List.all(from, |m| m.end == first.end) => {
							$moves = List.append($moves, first)
						}
						_ => {}
					}
				}
				(TurnNeedEndLoc(info), SetEndLocation(end)) => {
					match List.find_first(info.moves, |m| m.start == info.start_location and m.end == end) {
						Ok(m) => {
							$moves = List.append($moves, m)
						}
						Err(_) => {}
					}
				}
				_ => {}
			}
			$g = Game.update_game(msg, History.init, $g).1
		}
		$moves
	}

	## The cards a turn's messages played and discarded, read from the hand
	## as each was chosen.
	cards_of : Type.Game, List(Type.GameMsg) -> { played : List(Str), discarded : List(Str) }
	cards_of = |g0, msgs| {
		var $g = g0
		var $played = []
		var $discarded = []
		for msg in msgs {
			hand = Player.get_active_player($g).hand
			match msg {
				ActivateCard(i) => {
					$played = List.append($played, List.get(hand, i) ?? "?")
				}
				DiscardCard(i) => {
					$discarded = List.append($discarded, List.get(hand, i) ?? "?")
				}
				_ => {}
			}
			$g = Game.update_game(msg, History.init, $g).1
		}
		{ played: $played, discarded: $discarded }
	}

	forward : Type.Move -> Bool
	forward = |m|
		match m.kind {
			Reverse(_) => Bool.False
			JackTrade => Bool.False
			_ => Bool.True
		}

	## A move along the fast track: from a fast-track square to another, or
	## past the zone a piece leaving it the ordinary way would enter.
	ft_hop : List(Str), Type.Move -> Bool
	ft_hop = |zone_colors, m|
		if forward(m) and m.start.id == "FT" {
			match (m.start.zone, m.end.zone) {
				(NormalColor(a), NormalColor(b)) => m.end.id == "FT" or b != Color.next_zone_color(a, zone_colors)
				_ => Bool.False
			}
		} else {
			Bool.False
		}

	bump : List(Arena.Tally), U64, (Arena.Tally -> Arena.Tally) -> List(Arena.Tally)
	bump = |ts, i, f| List.set(ts, i, f(List.get(ts, i) ?? no_tally)) ?? ts

	## Every player's game, played to the first player home. A turn is idle
	## when the player discarded and played no card.
	tally_game : List(Arena.Seat), U64 -> List(Arena.Tally)
	tally_game = |seats, seed| {
		var $g = Game.begin_game(seed, Normal, Solo)
		var $t = List.repeat(no_tally, 4)
		var $prev = 4
		var $played = Bool.False
		var $discarded = Bool.False
		var $over = Bool.False
		var $steps = 0
		while !$over and $steps < 100000 {
			a = $g.active_player_idx
			if a != $prev {
				if $prev < 4 and !$played and $discarded {
					$t = bump($t, $prev, |x| { ..x, idle: x.idle + 1 })
				}
				$t = bump($t, a, |x| { ..x, turns: x.turns + 1 })
				$played = Bool.False
				$discarded = Bool.False
				$prev = a
			}
			s = step(seats, $g)
			moves = moves_of($g, s.msgs)
			cards = List.count_if(
				s.msgs,
				|m|
					match m {
						ActivateCard(_) => Bool.True
						_ => Bool.False
					},
			)
			discards = List.count_if(
				s.msgs,
				|m|
					match m {
						DiscardCard(_) => Bool.True
						_ => Bool.False
					},
			)
			$played = $played or cards > 0
			$discarded = $discarded or discards > 0
			landings = List.count_if(moves, |m| forward(m) and m.end.id == "FT")
			hops = List.count_if(moves, |m| ft_hop($g.zone_colors, m))
			turn_cards = cards_of($g, s.msgs)
			$t = bump($t, a, |x| { ..x, cards: x.cards + cards, ft_landings: x.ft_landings + landings, ft_hops: x.ft_hops + hops, played: List.concat(x.played, turn_cards.played), discarded: List.concat(x.discarded, turn_cards.discarded) })
			for c in [0, 1, 2, 3] {
				color = List.get($g.zone_colors, c) ?? ""
				before = in_pen($g, color)
				after = in_pen(s.game, color)
				if after > before {
					$t = bump($t, c, |x| { ..x, captured: x.captured + after - before })
					$t = bump($t, a, |x| { ..x, captures: x.captures + after - before })
				}
			}
			if home(s.game, a) {
				$t = bump($t, a, |x| { ..x, won: Bool.True })
				$over = Bool.True
			}
			$g = s.game
			$steps = $steps + 1
		}
		$t
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

# The fast track runs red, blue, green, purple: from red's FT to blue's is a
# hop; from red's FT into blue's R4 is the ordinary way; backwards is neither.
expect {
	colors = ["red", "blue", "green", "purple"]
	ft = |zone, id| { zone: NormalColor(zone), id }
	Arena.ft_hop(colors, { kind: WithCard("2"), start: ft("red", "FT"), end: ft("blue", "FT") })
	and Arena.ft_hop(colors, { kind: WithCard("3"), start: ft("red", "FT"), end: ft("green", "R4") })
	and !Arena.ft_hop(colors, { kind: WithCard("2"), start: ft("red", "FT"), end: ft("blue", "R3") })
	and !Arena.ft_hop(colors, { kind: Reverse("4"), start: ft("red", "FT"), end: ft("red", "L1") })
}

# A move with one end is made by its start click alone, and still counted:
# red's one piece on L0 with a 2 can only go to L2.
expect {
	start = Game.begin_game(0, Normal, Solo)
	players = Player.update_player(start.players, 0, |p| { ..p, hand: ["2"], turn: TurnBegin })
	g0 = Player.set_turn_to_need_card({ ..start, piece_map: [{ key: { zone: NormalColor("red"), id: "L0" }, value: "red" }], players })
	found = Search.first_line(g0) ?? crash("no line")
	Arena.moves_of(g0, found.msgs) == [{ kind: WithCard("2"), start: { zone: NormalColor("red"), id: "L0" }, end: { zone: NormalColor("red"), id: "L2" } }]
}
