# Arena -- games for experiments on the computer's strategy.
#
# Red, seat 0, plays the strategy under test; the other seats play
# Strategy.champion. A game is played to the first player home and no
# further: what happens after the win is noise. A seed deals every player's
# deck (shuffled once from the seed and the seat), so every strategy on the
# same seed is dealt the same cards; `rotation` turns the decks a seat, so
# red can be dealt every player's deck (duplicate deals).
#
# `compare` is the tool for "is B better than A": a block of four turned
# deals per seed, every strategy in red's seat, and `compare_report` judges
# each strategy against the first on the same deals (exp_duplicate.roc).
# `tally_game` counts every player's game (exp_table.roc, exp_cards.roc).
import Board
import Game
import History
import Move
import Piece
import Player
import Search
import Strategy
import Type

Arena :: [].{
	## A seat plays a Strategy through the whole-turn search, or takes the
	## first legal move it finds.
	Seat : [Plays(Strategy.Strategy), FirstLegal]

	## A game from red's seat: whether red won, and two counts that should
	## be 0 -- turns passed holding a legal play, and searches cut short.
	Result : { red_won : Bool, skips : U64, cuts : U64 }

	home : Type.Game, U64 -> Bool
	home = |game, seat| {
		color = List.get(game.zone_colors, seat) ?? ""
		Strategy.in_base(game, color) == 4
	}

	## The next player's turn.
	rotate : Type.Game -> Type.Game
	rotate = |game| Game.update_game(RotateBoard, History.init, game).1

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
	in_pen = |g, color| Piece.in_pen(g.board, Board.color_index(g.zone_colors, color))

	## A game with its decks turned `rotation` seats (Game.begin_dealt).
	play_dealt : List(Arena.Seat), U64, U64 -> Arena.Result
	play_dealt = |seats, seed, rotation| {
		var $g = Game.begin_dealt(seed, Normal, Solo, rotation)
		var $r = no_result
		var $winner = 4
		var $steps = 0
		while $winner == 4 and $steps < 100000 {
			s = step(seats, $g)
			$r = { ..$r, skips: $r.skips + (if s.skipped { 1 } else { 0 }), cuts: $r.cuts + (if s.cut { 1 } else { 0 }) }
			# The first player home wins, and the game stops.
			$winner = List.find_first([0, 1, 2, 3], |seat| home(s.game, seat)) ?? 4
			$g = s.game
			$steps = $steps + 1
		}
		{ ..$r, red_won: $winner == 0 }
	}

	## The start of red's turn `turn` of a seed, four champions playing.
	position : U64, U64 -> Type.Game
	position = |seed, turn| {
		seats = List.repeat(Plays(Strategy.champion), 4)
		var $g = Game.begin_game(seed, Normal, Solo)
		var $turn = 1
		var $steps = 0
		while $turn < turn and $steps < 100000 {
			next = step(seats, $g).game
			if next.active_player_idx == 0 and $g.active_player_idx != 0 {
				$turn = $turn + 1
			}
			$g = next
			$steps = $steps + 1
		}
		$g
	}

	## Who gets home first from here: a seat, or 4 if nobody in time.
	winner_from : List(Arena.Seat), Type.Game -> U64
	winner_from = |seats, from| {
		var $g = from
		var $won = 4
		var $steps = 0
		while $won == 4 and $steps < 100000 {
			a = $g.active_player_idx
			$g = step(seats, $g).game
			if home($g, a) {
				$won = a
			}
			$steps = $steps + 1
		}
		$won
	}

	## One player's game, to the first player home.
	Tally : { won : Bool, turns : U64, idle : U64, cards : U64, ft_landings : U64, ft_hops : U64, captures : U64, captured : U64, played : List(Str), discarded : List(Str), in_hand : List(Str) }

	no_tally : Arena.Tally
	no_tally = { won: Bool.False, turns: 0, idle: 0, cards: 0, ft_landings: 0, ft_hops: 0, captures: 0, captured: 0, played: [], discarded: [], in_hand: [] }

	## The moves a turn's messages made, each with its kind. A start with one
	## end moves at once (Move.maybe_auto_move), with no end click.
	moves_of : Type.Game, List(Type.GameMsg) -> List(Type.Move)
	moves_of = |g0, msgs| {
		var $g = g0
		var $moves = []
		for msg in msgs {
			$moves = List.concat($moves, Move.made($g, msg))
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
	ft_hop : Type.Move -> Bool
	ft_hop = |m|
		forward(m)
		and Board.is_ft(m.start)
		and m.end != Board.bullseye
		and (Board.is_ft(m.end) or Board.zone(m.end) != (Board.zone(m.start) + 1) % Board.zones)

	bump : List(Arena.Tally), U64, (Arena.Tally -> Arena.Tally) -> List(Arena.Tally)
	bump = |ts, i, f| List.set(ts, i, f(List.get(ts, i) ?? no_tally)) ?? ts

	## Every player's game, played to the first player home and no further,
	## with the hand each holds at the end. A turn is idle when the player
	## discarded and played no card.
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
			landings = List.count_if(moves, |m| forward(m) and Board.is_ft(m.end))
			hops = List.count_if(moves, ft_hop)
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
		List.map_with_index($t, |x, i| { ..x, in_hand: Player.get_player($g.players, i).hand })
	}

	## One seed's four turned deals, every strategy in red's seat against
	## three champions: [rotation][strategy].
	compare : List(Strategy.Strategy), U64 -> List(List(Arena.Result))
	compare = |strategies, seed|
		List.map(
			[0, 1, 2, 3],
			|k| List.map(strategies, |st| play_dealt([Plays(st), Plays(Strategy.champion), Plays(Strategy.champion), Plays(Strategy.champion)], seed, k)),
		)

	## A seed's block, as the log shows it.
	block_line : List(Str), U64, List(List(Arena.Result)) -> Str
	block_line = |labels, seed, block| {
		counts = List.map_with_index(labels, |label, j| "${label} won ${U64.to_str(List.count_if(block, |deal| won(deal, j)))} of 4")
		"seed ${U64.to_str(seed)} | ${Str.join_with(counts, " | ")}"
	}

	won : List(Arena.Result), U64 -> Bool
	won = |deal, j| (List.get(deal, j) ?? no_result).red_won

	no_result : Arena.Result
	no_result = { red_won: Bool.False, skips: 0, cuts: 0 }

	## A fraction as a percentage, one decimal.
	percent : F64 -> Str
	percent = |x| {
		t = F64.to_i64_wrap(F64.abs(x) * 1000.0 + 0.5)
		sign = if x < 0.0 and t > 0 { "-" } else { "" }
		"${sign}${I64.to_str(t // 10)}.${I64.to_str(t % 10)}%"
	}

	thousandths : F64 -> Str
	thousandths = |x| {
		t = F64.to_i64_wrap(F64.abs(x) * 1000.0 + 0.5)
		sign = if x < 0.0 and t > 0 { "-" } else { "" }
		pad = if t % 1000 < 10 { "00" } else if t % 1000 < 100 { "0" } else { "" }
		"${sign}${I64.to_str(t // 1000)}.${pad}${I64.to_str(t % 1000)}"
	}

	sd : List(F64) -> F64
	sd = |xs| {
		n = U64.to_f64(List.len(xs))
		m = List.fold(xs, 0.0, |t, x| t + x) / n
		F64.sqrt(List.fold(xs, 0.0, |t, x| t + (x - m) * (x - m)) / (n - 1.0))
	}

	## Every strategy's wins, then each against the first on the same deals:
	## the difference judged as if the games were unrelated, paired deal by
	## deal, and by seed. A cut search hit Search.max_lines; a skipped turn
	## was passed holding a legal play, which would be a bug.
	compare_report : List(Str), U64, List(List(List(Arena.Result))) -> Str
	compare_report = |labels, first_seed, blocks| {
		deals = List.join(blocks)
		n = U64.to_f64(List.len(deals))
		wins = |j| List.count_if(deals, |deal| won(deal, j))
		win = |b| if b { 1.0 } else { 0.0 }
		last_seed = first_seed + List.len(blocks) - 1
		rows = List.map_with_index(
			labels,
			|label, j| {
				by_rotation = Str.join_with(List.map([0, 1, 2, 3], |k| U64.to_str(List.count_if(blocks, |bl| won(List.get(bl, k) ?? [], j)))), " / ")
				cuts = List.fold(deals, 0, |t, deal| t + (List.get(deal, j) ?? no_result).cuts)
				skips = List.fold(deals, 0, |t, deal| t + (List.get(deal, j) ?? no_result).skips)
				"| ${label} | ${U64.to_str(wins(j))} of ${U64.to_str(List.len(deals))} | ${thousandths(U64.to_f64(wins(j)) / n)} | ${by_rotation} | ${U64.to_str(cuts)} / ${U64.to_str(skips)} |"
			},
		)
		against = List.map(
			List.drop_first(List.map_with_index(labels, |label, j| { label, j }), 1),
			|x| {
				pa = U64.to_f64(wins(0)) / n
				pb = U64.to_f64(wins(x.j)) / n
				diff = pb - pa
				unrelated = F64.sqrt(pa * (1.0 - pa) / n + pb * (1.0 - pb) / n)
				paired = sd(List.map(deals, |deal| win(won(deal, x.j)) - win(won(deal, 0)))) / F64.sqrt(n)
				by_seed = sd(List.map(blocks, |bl| (U64.to_f64(List.count_if(bl, |deal| won(deal, x.j))) - U64.to_f64(List.count_if(bl, |deal| won(deal, 0)))) / 4.0)) / F64.sqrt(U64.to_f64(List.len(blocks)))
				only = "${U64.to_str(List.count_if(deals, |deal| won(deal, x.j) and !won(deal, 0)))} / ${U64.to_str(List.count_if(deals, |deal| won(deal, 0) and !won(deal, x.j)))}"
				"| ${x.label} | ${thousandths(diff)} | ${only} | ${thousandths(unrelated)} / ${thousandths(paired)} / ${thousandths(by_seed)} | ${if paired > 0.0 { thousandths(diff / paired) } else { "-" }} |"
			},
		)
		Str.join_with(
			[
				"Seeds ${U64.to_str(first_seed)}-${U64.to_str(last_seed)}, each dealt four times with the decks turned a seat, so red plays every player's deck: ${U64.to_str(List.len(deals))} games per strategy. Red is the strategy; the other seats play Strategy.champion. Each game stops at the first player home.\n",
				"| red plays as | red won | win rate | wins with the decks turned 0 / 1 / 2 / 3 seats | searches cut / turns skipped (both should be 0) |",
				"|---|---|---|---|---|",
				Str.join_with(rows, "\n"),
				"\nEach against ${List.first(labels) ?? "the first"}, on the same deals:\n",
				"| red plays as | difference a game | deals only it won / only the first won | standard error: unrelated / paired / by seed | paired, in standard errors |",
				"|---|---|---|---|---|",
				Str.join_with(against, "\n"),
			],
			"\n",
		)
	}
}

# The fast track runs red, blue, green, purple: from red's FT to blue's is a
# hop; from red's FT into blue's R4 is the ordinary way; backwards is neither.
expect {
	ft = Board.at(0, Board.ft)
	Arena.ft_hop({ kind: WithCard("2"), start: ft, end: Board.at(1, Board.ft) })
	and Arena.ft_hop({ kind: WithCard("3"), start: ft, end: Board.at(2, Board.r4) })
	and !Arena.ft_hop({ kind: WithCard("2"), start: ft, end: Board.at(1, 20) })
	and !Arena.ft_hop({ kind: Reverse("4"), start: ft, end: Board.at(0, 12) })
}

# A move with one end is made by its start click alone, and still counted:
# red's one piece on L0 with a 2 can only go to L2.
expect {
	start = Game.begin_game(0, Normal, Solo)
	players = Player.update_player(start.players, 0, |p| { ..p, hand: ["2"], turn: TurnBegin })
	g0 = Player.set_turn_to_need_card({ ..start, board: Piece.board_of(start.zone_colors, [("red", "L0", "red")]), players })
	found = Search.first_line(g0) ?? crash("no line")
	Arena.moves_of(g0, found.msgs) == [{ kind: WithCard("2"), start: Board.at(0, Board.l0), end: Board.at(0, 13) }]
}
