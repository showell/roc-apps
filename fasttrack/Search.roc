# Search -- a computer player's turn: every line of play to the turn's end,
# and the one its Strategy likes best.
#
# A line is a sequence of the messages Game.update_game already answers -- a
# card, a starting square, an end square, a card to discard or cover -- so the
# search plays the real rules and has no copy of them to drift. A play is a
# card and every click it takes, a split seven's two halves included; a
# move-again card goes on to the next play, and a player holding a playable
# card must play one. The same position reached two ways is kept once. A line
# stops where the hand is refilled, so the computer never sees a card it has
# not drawn; it searches again with the cards it drew.
import Board
import Config
import Game
import History
import Player
import Strategy
import Type

Search :: [].{
	Line : { game : Type.Game, msgs : List(Type.GameMsg), drew : Bool }

	## Every choice the turn offers now, one per distinct card.
	options : Type.Game -> List(Type.GameMsg)
	options = |game| {
		player = Player.get_active_player(game)
		match player.turn {
			TurnNeedCard(_) => {
				playable = Player.get_playable_cards(player)
				first_of_each(player.hand, |card| List.contains(playable, card), |i| ActivateCard(i))
			}
			TurnNeedStartLoc(info) => List.map(info.start_locs, |loc| SetStartLocation(loc))
			TurnNeedEndLoc(info) => List.map(info.end_locs, |loc| SetEndLocation(loc))
			TurnNeedDiscard => first_of_each(player.hand, |_| Bool.True, |i| DiscardCard(i))
			TurnNeedCover => first_of_each(player.hand, |_| Bool.True, |i| CoverCard(i))
			_ => []
		}
	}

	## Cards the rules treat alike: a Q and a K both move one and go again.
	same_card : Str, Str -> Bool
	same_card = |a, b| a == b or (List.contains(["Q", "K"], a) and List.contains(["Q", "K"], b))

	## The index of the first copy of each card `keep` accepts: two 5s are
	## one choice, and so are a Q and a K.
	first_of_each : List(Str), (Str -> Bool), (U64 -> Type.GameMsg) -> List(Type.GameMsg)
	first_of_each = |hand, keep, make|
		List.join(
			List.map_with_index(
				hand,
				|card, i|
					if keep(card) and List.find_first_index(hand, |c| same_card(c, card)) == Ok(i) {
						[make(i)]
					} else {
						[]
					},
			),
		)

	hand_size : Type.Game -> U64
	hand_size = |game| List.len(Player.get_active_player(game).hand)

	apply : Search.Line, Type.GameMsg -> Search.Line
	apply = |line, msg| {
		(_, game) = Game.update_game(msg, History.init, line.game)
		{ game, msgs: List.append(line.msgs, msg), drew: line.drew or hand_size(game) > hand_size(line.game) }
	}

	## A line the search goes on with: the player is choosing a card, or
	## what to discard or cover, and has drawn nothing new.
	is_open : Search.Line -> Bool
	is_open = |line|
		if line.drew {
			Bool.False
		} else {
			match Player.get_active_player(line.game).turn {
				TurnNeedCard(_) => Bool.True
				TurnNeedDiscard => Bool.True
				TurnNeedCover => Bool.True
				_ => Bool.False
			}
		}

	## Mid-play (a card chosen, its squares not yet), every way to finish it.
	settle : Search.Line -> List(Search.Line)
	settle = |line| {
		mid_play = match Player.get_active_player(line.game).turn {
			TurnNeedStartLoc(_) => Bool.True
			TurnNeedEndLoc(_) => Bool.True
			_ => Bool.False
		}
		choices = options(line.game)
		if mid_play and !line.drew and !List.is_empty(choices) {
			List.join_map(choices, |msg| settle(apply(line, msg)))
		} else {
			[line]
		}
	}

	## One card play further, every way.
	expand : Search.Line -> List(Search.Line)
	expand = |line| List.join_map(options(line.game), |msg| settle(apply(line, msg)))

	## The same position reached two ways is one line.
	distinct_lines : List(Search.Line) -> List(Search.Line)
	distinct_lines = |lines|
		List.fold(lines, [], |kept, line| if List.any(kept, |k| k.game == line.game) { kept } else { List.append(kept, line) })

	## What `strategy` makes of a line from `game`: the mover's team's board,
	## the hand it keeps unless it drew, less the leader's board if it plays
	## against the leader (when behind, for LeaderWhenBehind: judged on `game`).
	score : Strategy.Strategy, Type.Game, Search.Line -> I64
	score = |strategy, game, line| {
		mover = Player.get_active_player(game)
		colors = Strategy.team(mover)
		kept = if line.drew { 0 } else { Strategy.hand(Strategy.hoard_worths(strategy, game, mover.color), Player.get_active_player(line.game).hand) }
		against = match strategy.opponents {
			Ignore => 0
			Leader => Strategy.leader(strategy, line.game, colors)
			LeaderWhenBehind =>
				if Strategy.leader(strategy, game, colors) > Strategy.board(strategy, game, colors) {
					Strategy.leader(strategy, line.game, colors)
				} else {
					0
				}
		}
		Strategy.board(strategy, line.game, colors) + kept - against
	}

	## Every line through the rest of the mover's turn. `cut` says the search
	## stopped before every line had ended.
	all_lines : Type.Game -> { lines : List(Search.Line), cut : Bool }
	all_lines = |game| {
		start = settle({ game, msgs: [], drew: Bool.False })
		var $level = start
		var $done = List.drop_if(start, is_open)
		var $depth = 0
		while List.any($level, is_open) and $depth < 8 {
			grown = List.join_map(List.keep_if($level, is_open), expand)
			$level = distinct_lines(grown)
			$done = List.concat($done, List.drop_if($level, is_open))
			$depth = $depth + 1
		}
		{
			lines: List.keep_if(List.concat($done, List.keep_if($level, is_open)), |l| !List.is_empty(l.msgs)),
			cut: List.any($level, is_open),
		}
	}

	## The line that takes the first choice offered at every step, through
	## the rest of the turn: a player who plays the first legal move it finds.
	first_line : Type.Game -> Try(Search.Line, [NoPlay])
	first_line = |game| {
		var $line = { game, msgs: [], drew: Bool.False }
		var $steps = 0
		while !$line.drew and Player.get_active_player($line.game).turn != TurnDone and $steps < 1000 {
			match options($line.game) {
				[first, ..] => {
					$line = apply($line, first)
				}
				[] => {
					$steps = 1000
				}
			}
			$steps = $steps + 1
		}
		if List.is_empty($line.msgs) { Err(NoPlay) } else { Ok($line) }
	}

	## A line's position as numbers, whatever order the board keeps its
	## pieces in: every piece as its square and color (Board.index_of), then
	## the mover's hand as a multiset, its discard credits, and whether it
	## drew.
	position_key : Search.Line -> List(U64)
	position_key = |line| {
		g = line.game
		p = Player.get_active_player(g)
		color_num = |c| List.find_first_index(g.zone_colors, |z| z == c) ?? 9
		ascending = |xs| List.sort_with(xs, |a, b| if a < b { Before } else if a > b { After } else { Same })
		pieces = ascending(List.map(g.piece_map, |e| 10 * Board.index_of(g.zone_colors, e.key) + color_num(e.value)))
		cards = ascending(List.map(p.hand, |c| I64.to_u64_wrap(Config.card_value(c))))
		List.join([pieces, [999], cards, [999, I64.to_u64_wrap(p.get_out_credits), if line.drew { 1 } else { 0 }]])
	}

	## Lexicographic order on keys.
	key_before : List(U64), List(U64) -> Bool
	key_before = |a, b| {
		var $i = 0
		var $answer = List.len(a) < List.len(b)
		var $decided = Bool.False
		while !$decided and $i < List.len(a) and $i < List.len(b) {
			x = List.get(a, $i) ?? 0
			y = List.get(b, $i) ?? 0
			if x != y {
				$answer = x < y
				$decided = Bool.True
			}
			$i = $i + 1
		}
		$answer
	}

	## The best line through the rest of the mover's turn, or Err when it has
	## no play. Lines that score the same are told apart by their positions
	## (position_key), never by the order the search met them, so the choice
	## does not hang on the order the rules list the moves in.
	best_line : Strategy.Strategy, Type.Game -> Try({ line : Search.Line, cut : Bool }, [NoPlay])
	best_line = |strategy, game| {
		found = all_lines(game)
		best = List.fold(
			found.lines,
			{ line: { game, msgs: [], drew: Bool.False }, score: 0, found: Bool.False },
			|acc, line| {
				s = score(strategy, game, line)
				better = !acc.found or s > acc.score or (s == acc.score and key_before(position_key(line), position_key(acc.line)))
				if better { { line, score: s, found: Bool.True } } else { acc }
			},
		)
		if best.found { Ok({ line: best.line, cut: found.cut }) } else { Err(NoPlay) }
	}
}

expect Search.first_of_each(["K", "7", "Q", "K"], |_| Bool.True, |i| ActivateCard(i)) == [ActivateCard(0), ActivateCard(1)]
