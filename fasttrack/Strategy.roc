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
#
# `champion` is what the page's computers play. TUNING.md says how each number
# was chosen; a new experiment is a new value (Arena, the exp_*.roc apps).
import Config
import Game
import Player
import SquareValues
import Type

Strategy :: [].{
	Hoard : { cards : List(Str), worth : List(I64) }

	Strategy : { base_bonus : I64, hoards : List(Strategy.Hoard), opponents : [Ignore, Leader] }

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

	base_step : Str -> I64
	base_step = |id|
		match id {
			"B1" => 1
			"B2" => 2
			"B3" => 3
			"B4" => 4
			_ => 0
		}

	## What the squares of these colors' pieces are worth.
	board : Strategy.Strategy, Type.Game, List(Str) -> I64
	board = |strategy, game, colors|
		List.fold(
			game.piece_map,
			0,
			|total, e|
				if List.contains(colors, e.value) {
					own_base = if e.key.zone == NormalColor(e.value) { base_step(e.key.id) } else { 0 }
					total + SquareValues.value(game.zone_colors, e.value, e.key) + own_base * strategy.base_bonus
				} else {
					total
				},
		)

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

	## A player's pieces in its own base.
	in_base : Type.Game, Str -> U64
	in_base = |game, color| List.count_if(game.piece_map, |e| e.value == color and e.key.zone == NormalColor(color) and Config.is_base_id(e.key.id))

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
	colors = ["red", "blue", "green", "purple"]
	at = |zone, id| { zone: NormalColor(zone), id }
	SquareValues.value(colors, "red", at("red", "B4")) == 6100
	and SquareValues.value(colors, "red", at("blue", "R4")) == 100
	and SquareValues.value(colors, "red", at("red", "HP1")) == 0
	and SquareValues.value(colors, "blue", at("blue", "B4")) == 6100
	and SquareValues.value(colors, "blue", at("green", "R4")) == 100
}

# The champion's hoard: 1500 an A, joker or J with none home, 500 with two.
expect {
	start = Game.begin_game(0, Normal, Solo)
	two_home = { ..start, piece_map: [{ key: { zone: NormalColor("red"), id: "B1" }, value: "red" }, { key: { zone: NormalColor("red"), id: "B2" }, value: "red" }] }
	Strategy.hoard_worths(Strategy.champion, start, "red") == [{ cards: ["A", "joker", "J"], worth: 1500 }]
	and Strategy.hoard_worths(Strategy.champion, two_home, "red") == [{ cards: ["A", "joker", "J"], worth: 500 }]
	and Strategy.board(Strategy.champion, two_home, ["red"]) == 5800 + 1000 + 5900 + 2000
}
