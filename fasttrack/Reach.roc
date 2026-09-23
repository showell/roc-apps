# Reach -- where one card takes a piece, and how few cards get it home.
#
# On an empty board, for a piece of one color: every card's landing squares
# from every square (the rules' own `end_locations`), and from those, worked
# back from B4, the fewest cards that reach B4 from each square and which
# cards start the way. Opponents are ignored, and so are cards that let a
# player go again: a card is one card -- except that, if asked, every card
# may be played after one free face card (Steve's tweak: a player nearly
# always holds a face card, and plays it first).
#
# A card here is played whole: the 4 backwards only, the 7 as seven (a split
# needs a second piece), a 6 from the pen one square. Leaving the pen takes an
# A, 6 or joker; leaving the bullseye a J, Q or K; a fast-track hop only a
# move that starts on a fast-track square.
import Agent
import Config
import LegalMove
import Type

Reach :: [].{
	cards : List(Str)
	cards = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "joker"]

	## Where one card takes a piece of `color` from `loc`, on an empty board.
	lands : List(Str), Str, Type.PieceLocation, Str -> List(Type.PieceLocation)
	lands = |zone_colors, color, loc, card| {
		params = {
			reverse_mode: card == "4",
			can_fast_track: loc.id == "FT",
			can_leave_pen: List.contains(["A", "6", "joker"], card),
			can_leave_bulls_eye: List.contains(["J", "Q", "K"], card) and loc.zone == BullsEyeZone,
			piece_color: color,
			piece_map: [],
			zone_colors,
		}
		LegalMove.end_locations(params, loc, Config.move_count_for_card(card, loc.id))
	}

	Move : { from : U64, to : U64, card : Str }

	## Where a free face card takes a piece: one square on (a J, Q or K moves
	## one), or out of the bullseye. It does not leave the pen.
	face_steps : List(Str), Str, Type.PieceLocation -> List(Type.PieceLocation)
	face_steps = |zone_colors, color, loc| lands(zone_colors, color, loc, "Q")

	## Every square to every square by one card, indexed as Agent.all_locs.
	## With `free_face`, a card may also be played after one free face card --
	## face cards are always played first (Steve: DS to B4 is Q then 3, one
	## card); such a move's card reads "face+3".
	moves : List(Str), Str, Bool -> List(Reach.Move)
	moves = |zone_colors, color, free_face|
		List.join(
			List.map_with_index(
				Agent.all_locs(zone_colors),
				|loc, from|
					List.join_map(
						cards,
						|card| {
							plain = List.map(lands(zone_colors, color, loc, card), |to| { from, to: Agent.index_of(zone_colors, to), card })
							if free_face {
								with_face = List.join_map(face_steps(zone_colors, color, loc), |step| List.map(lands(zone_colors, color, step, card), |to| { from, to: Agent.index_of(zone_colors, to), card: "face+${card}" }))
								List.concat(plain, with_face)
							} else {
								plain
							}
						},
					),
			),
		)

	## For each square, indexed as Agent.all_locs: the fewest cards to B4
	## (`far` where no cards do), and every card that starts such a way.
	Best : { cards : I64, first : List(Str) }

	fewest_cards : List(Str), Str, Bool -> List(Reach.Best)
	fewest_cards = |zone_colors, color, free_face| {
		edges = moves(zone_colors, color, free_face)
		far = Agent.far
		home = Agent.index_of(zone_colors, { zone: NormalColor(color), id: "B4" })
		start = List.set(List.repeat({ cards: far, first: [] }, List.len(Agent.all_locs(zone_colors))), home, { cards: 0, first: [] }) ?? crash("Reach: no home")
		# A pass says whether it changed anything (findings/llvm-closure-loop-alias).
		relax = |d|
			List.fold(
				edges,
				{ d, changed: Bool.False },
				|acc, e| {
					via = (List.get(acc.d, e.to) ?? { cards: far, first: [] }).cards + 1
					here = List.get(acc.d, e.from) ?? { cards: far, first: [] }
					if via < here.cards {
						{ d: List.set(acc.d, e.from, { cards: via, first: [e.card] }) ?? crash("Reach: edge out of range"), changed: Bool.True }
					} else if via == here.cards and !List.contains(here.first, e.card) {
						{ d: List.set(acc.d, e.from, { cards: via, first: List.append(here.first, e.card) }) ?? crash("Reach: edge out of range"), changed: Bool.True }
					} else {
						acc
					}
				},
			)
		var $pass = relax(start)
		while $pass.changed {
			$pass = relax($pass.d)
		}
		$pass.d
	}
}

# Steve's expectations, for red: B4 0; B3 .. R4 one card; L0 .. L2 two.
expect {
	colors = ["red", "blue", "green", "purple"]
	best = Reach.fewest_cards(colors, "red", Bool.False)
	n = |id| (List.get(best, Agent.index_of(colors, { zone: NormalColor("red"), id })) ?? { cards: 0, first: [] }).cards
	n("B4") == 0 and n("B3") == 1 and n("B1") == 1 and n("BR") == 1 and n("R0") == 1 and n("R4") == 1 and n("L0") == 2 and n("L1") == 2
}

# With a free face card, DS is one card (Q then 3), and so is L2's way
# through it: 4 back to DS, then the face card and a 3.
expect {
	colors = ["red", "blue", "green", "purple"]
	best = Reach.fewest_cards(colors, "red", Bool.True)
	n = |id| (List.get(best, Agent.index_of(colors, { zone: NormalColor("red"), id })) ?? { cards: 0, first: [] }).cards
	n("B4") == 0 and n("B3") == 1 and n("DS") == 1 and n("L2") == 2
}
