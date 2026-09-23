# Strategy -- what a computer player plays for, as a value.
#
# A position is worth the squares its team's pieces stand on (SquareValues,
# Steve's ranking), plus `base_bonus` a step down its own base (B1 once, B4
# four times), plus what the cards it hoards are worth while they stay in its
# hand. A hoard is worth less as pieces reach the base -- `worth` is by how
# many are in at the start of the turn, the last entry standing for more --
# because hoarding late in the game is dumb.
#
# `opponents` says whether the other players count. `Ignore`: not at all, so
# a capture is only ever an accident. `Leader`: the line is worth the mover's
# team less the leading opposing team, judged at the end of the turn -- two
# opponents close together make slowing one of them a poor sacrifice.
# `LeaderWhenBehind`: `Leader` when the leading opposing team's board is
# ahead of the mover's as the search starts, `Ignore` otherwise.
# `LeaderNearHome`: less the board of one opponent -- of those with three
# pieces in their base as the search starts, the one whose board is worth
# most then -- judged at the end of the turn; nobody otherwise. Capturing
# (or trading away) such a player's last piece out is what it pays for.
#
# `champion` is what the page's computers play. TUNING.md says how each number
# was chosen; a new experiment is a new value (Arena, the exp_*.roc apps).
import Board
import Game
import Piece
import Player
import SquareValues
import Type

Strategy :: [].{
	Hoard : { cards : List(Str), worth : List(I64) }

	Strategy : { base_bonus : I64, hoards : List(Strategy.Hoard), opponents : [Ignore, Leader, LeaderWhenBehind, LeaderNearHome] }

	champion : Strategy.Strategy
	champion = {
		base_bonus: 1000,
		hoards: [{ cards: ["A", "joker", "J"], worth: [1500, 1000, 500, 0] }],
		opponents: Ignore,
	}

	## The colors a player scores: its own, and its partner's.
	team : Type.Player -> List(Str)
	team = |player|
		match player.team {
			Solo => [player.color]
			Partner(p) => [player.color, p]
			PartnerOnceHome(p) => [player.color, p]
		}

	## What the squares of these colors' pieces are worth.
	board : Strategy.Strategy, Type.Game, List(Str) -> I64
	board = |strategy, game, colors| {
		cs = List.map(colors, |c| Board.color_index(game.zone_colors, c))
		var $total = 0
		var $s = 0
		while $s < Board.count {
			match Piece.at(game.board, $s) {
				Ok(c) if List.contains(cs, c) => {
					own_base = if Board.is_base($s) and Board.zone($s) == c { U64.to_i64_wrap(Board.local($s)) - 3 } else { 0 }
					$total = $total + SquareValues.value(c, $s) + own_base * strategy.base_bonus
				}
				_ => {}
			}
			$s = $s + 1
		}
		$total
	}

	## What the leading opposing team's pieces are worth: every other
	## player's team, valued as the mover values its own (board only -- their
	## hands are hidden).
	leader : Strategy.Strategy, Type.Game, List(Str) -> I64
	leader = |strategy, game, own|
		List.fold(
			game.players,
			I64.lowest,
			|best, p|
				if List.contains(own, p.color) {
					best
				} else {
					v = board(strategy, game, team(p))
					if v > best { v } else { best }
				},
		)

	## Of the other teams with a player three pieces home, the one whose
	## board is worth most.
	near_home_leader : Strategy.Strategy, Type.Game, List(Str) -> Try(List(Str), [Nobody])
	near_home_leader = |strategy, game, own| {
		best = List.fold(
			game.players,
			{ team: [], v: I64.lowest },
			|acc, p|
				if List.contains(own, p.color) or in_base(game, p.color) < 3 {
					acc
				} else {
					v = board(strategy, game, team(p))
					if v > acc.v { { team: team(p), v } } else { acc }
				},
		)
		if List.is_empty(best.team) { Err(Nobody) } else { Ok(best.team) }
	}

	## A player's pieces in its own base.
	in_base : Type.Game, Str -> U64
	in_base = |game, color| Piece.in_base(game.board, Board.color_index(game.zone_colors, color))

	## What each hoard's cards are worth this turn, given the board it starts
	## from.
	hoard_worths : Strategy.Strategy, Type.Game, Str -> List({ cards : List(Str), worth : I64 })
	hoard_worths = |strategy, game, color| {
		n = in_base(game, color)
		List.map(
			strategy.hoards,
			|h| {
				last = List.len(h.worth)
				worth = if last == 0 { 0 } else { List.get(h.worth, if n < last { n } else { last - 1 }) ?? 0 }
				{ cards: h.cards, worth }
			},
		)
	}

	## What a hand is worth: each hoarded card still in it.
	hand : List({ cards : List(Str), worth : I64 }), List(Str) -> I64
	hand = |worths, cards|
		List.fold(worths, 0, |total, h| total + U64.to_i64_wrap(List.count_if(cards, |c| List.contains(h.cards, c))) * h.worth)
}

# The table's corners (SquareValues, from Steve's ranking), and the base bonus.
expect {
	b4 = 7
	SquareValues.value(0, Board.at(0, b4)) == 6100
	and SquareValues.value(0, Board.at(1, Board.r4)) == 100
	and SquareValues.value(0, Board.at(0, 0)) == 0
	and SquareValues.value(1, Board.at(1, b4)) == 6100
	and SquareValues.value(1, Board.at(2, Board.r4)) == 100
}

# The champion's hoard: 1500 an A, joker or J with none home, 500 with two.
expect {
	start = Game.begin_game(0, Normal, Solo)
	two_home = { ..start, board: Piece.board_of(start.zone_colors, [("red", "B1", "red"), ("red", "B2", "red")]) }
	Strategy.hoard_worths(Strategy.champion, start, "red") == [{ cards: ["A", "joker", "J"], worth: 1500 }]
	and Strategy.hoard_worths(Strategy.champion, two_home, "red") == [{ cards: ["A", "joker", "J"], worth: 500 }]
	and Strategy.board(Strategy.champion, two_home, ["red"]) == 5800 + 1000 + 5900 + 2000
}
