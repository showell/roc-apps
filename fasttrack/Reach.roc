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
import Board
import Config
import LegalMove
import Piece

Reach :: [].{
	cards : List(Str)
	cards = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "joker"]

	## Where one card takes a piece of `color` from square `s`, on an empty
	## board.
	lands : List(Str), Str, U64, Str -> List(U64)
	lands = |zone_colors, color, s, card|
		LegalMove.ends(
			Piece.empty,
			Board.color_index(zone_colors, color),
			s,
			Config.move_count_for_card(card, Board.is_pen(s)),
			if (card == "4") Backward else Forward,
			if (["A", "6", "joker"].contains(card)) LeavePen else StayInPen,
			if (
				[
					"J",
					"Q",
					"K",
				].contains(card) and s == Board.bullseye
			) LeaveBullseye else StayInBullseye,
		)

	Move : {
		from : U64,
		to : U64,
		card : Str,
	}

	## Where a free face card takes a piece: one square on (a J, Q or K moves
	## one), or out of the bullseye. It does not leave the pen.
	face_steps : List(Str), Str, U64 -> List(U64)
	face_steps = |zone_colors, color, s| lands(zone_colors, color, s, "Q")

	## A color's grid: every square to every square by one card, indexed as
	## Board.all_locs, and by a card played after one free face card -- face
	## cards are always played first (Steve: DS to B4 is Q then 3, one card);
	## such a move's card reads "face+3". Built once; every table filters it
	## (`usable`).
	##
	## Squares a piece of this color never stands on -- the other colors' pens
	## and bases -- have no moves.
	grid : List(Str), Str -> List(Reach.Move)
	grid = |zone_colors, color|
		Board.squares.map_with_index(
			|from, _|
				if Board.zone(from) != Board.color_index(
					zone_colors,
					color,
				) and !Board.is_track(from) {
					[]
				} else {
					cards.join_map(
						|card| {
							plain = lands(
								zone_colors,
								color,
								from,
								card,
							).map(|to| { from, to, card })
							with_face = face_steps(zone_colors, color, from).join_map(
								|step| lands(zone_colors, color, step, card).map(
									|to| { from, to, card: "face+${card}" },
								),
							)
							plain.concat(with_face)
						},
					)
				},
		).join()

	## For each square, indexed as Board.all_locs: the fewest cards to the
	## peak (`far` where no cards do), and every card that starts such a way.
	Best : { cards : I64, first : List(Str) }

	## Whose way home, and to where: the seating, the piece's color, and its
	## `peak`, the deepest base square it can still enter: B4, or B3 once B4
	## is occupied, and so on.
	Target : {
		zone_colors : List(Str),
		color : Str,
		peak : Str,
	}

	## What a table may play: these kinds of card, and whether a free face
	## card may go first.
	Deck : { hand : List(Str), face : [FreeFace, CardsOnly] }

	## The fewest cards home with the whole deck. A move landing deeper than
	## the peak is dropped; one landing on the peak or short of it never
	## passes the occupied squares.
	fewest_cards : Reach.Target, [FreeFace, CardsOnly] -> List(Reach.Best)
	fewest_cards = |target, face| fewest_over(
		usable(
			grid(target.zone_colors, target.color),
			target,
			{ hand: cards, face },
		),
		target,
	)

	## Whether a move may be played from this hand of card kinds: its card,
	## and its free face card (a J, Q or K) if it has one.
	is_allowed : List(Str), Str -> Bool
	is_allowed = |hand, card|
		if card.starts_with("face+") {
			hand.contains(card.drop_prefix("face+")) and ["J", "Q", "K"].any(|f| hand.contains(f))
		} else {
			hand.contains(card)
		}

	## The grid's moves a table may use: no face card first unless the deck
	## has a free one, only the deck's kinds of card, and nothing landing
	## deeper than the peak -- B4 once it is taken, and so on. A move landing
	## on the peak or short of it never passes the occupied squares.
	usable : List(Reach.Move), Reach.Target, Reach.Deck -> List(Reach.Move)
	usable = |all, target, deck| {
		peak_at = Config.base_locations.find_first_index(|id| id == target.peak) ?? crash ("Reach: the peak is a base square")
		occupied = Config.base_locations.drop_first(peak_at + 1).map(
			|id| Board.index_of(target.zone_colors, { zone: NormalColor(target.color), id }),
		)
		all.drop_if(
			|e| (deck.face == CardsOnly and e.card.starts_with("face+")) or occupied.contains(e.to) or !is_allowed(
				deck.hand,
				e.card,
			),
		)
	}

	## The fewest cards home over these moves.
	fewest_over : List(Reach.Move), Reach.Target -> List(Reach.Best)
	fewest_over = |edges, target| {
		far = Board.far
		home = Board.index_of(
			target.zone_colors,
			{ zone: NormalColor(target.color), id: target.peak },
		)
		start = List.repeat(
			{ cards: far, first: [] },
			Board.all_locs(target.zone_colors).len(),
		).set(home, { cards: 0, first: [] }) ?? crash ("Reach: no home")
		# A pass says whether it changed anything: LLVM has ended a `while $next != $d`
		# loop after one pass when the pass is a local closure (README.md).
		relax = |d|
			edges.fold(
				{ d, changed: Bool.False },
				|acc, e| {
					via = (acc.d.get(e.to) ?? { cards: far, first: [] }).cards + 1
					here = acc.d.get(e.from) ?? { cards: far, first: [] }
					if via < here.cards {
						{
							d: acc.d.set(
								e.from,
								{ cards: via, first: [e.card] },
							) ?? crash ("Reach: edge out of range"),
							changed: Bool.True,
						}
					} else if via == here.cards and !here.first.contains(e.card) {
						{
							d: acc.d.set(
								e.from,
								{ cards: via, first: here.first.append(e.card) },
							) ?? crash ("Reach: edge out of range"),
							changed: Bool.True,
						}
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

	## For each square, indexed as Board.all_locs: the fewest cards to the
	## peak with these kinds of card, and how many shortest routes there are --
	## every sequence of moves, a move being a card or a face card and a card.
	Routes : { cards : I64, routes : U64 }

	## Over a color's grid (`grid`, built once by the caller).
	routes : List(Reach.Move), Reach.Target, Reach.Deck -> List(Reach.Routes)
	routes = |all, target, deck| {
		edges = usable(all, target, deck)
		best = fewest_over(edges, target)
		cards_at = |i| (best.get(i) ?? { cards: Board.far, first: [] }).cards
		home = Board.index_of(
			target.zone_colors,
			{ zone: NormalColor(target.color), id: target.peak },
		)
		start = best.map_with_index(
			|b, i| {
				cards: b.cards,
				routes: if i == home {
					1
				} else {
					0
				},
			},
		)
		# Squares n cards out take their routes from squares n - 1 out, so
		# one sweep per distance settles every count.
		deepest = best.fold(
			0,
			|m, b| if b.cards < Board.far and b.cards > m {
				b.cards
			} else {
				m
			},
		)
		var $counts = start
		var $n = 1
		while $n <= deepest {
			level = $n
			sweep = edges.fold(
				$counts,
				|acc, e|
					if cards_at(e.from) == level and cards_at(e.to) == level - 1 {
						here = acc.get(e.from) ?? { cards: 0, routes: 0 }
						via = (acc.get(e.to) ?? { cards: 0, routes: 0 }).routes
						acc.set(
							e.from,
							{ ..here, routes: here.routes + via },
						) ?? crash ("Reach: edge out of range")
					} else {
						acc
					},
			)
			$counts = sweep
			$n = $n + 1
		}
		$counts
	}
}

colors : List(Str)
colors = ["red", "blue", "green", "purple"]

## Red's square of this id, indexed as Board.all_locs.
red_square : Str -> U64
red_square = |id| Board.index_of(colors, { zone: NormalColor("red"), id })

## Red's fewest cards to `peak` from each of its squares, by the square's id.
cards_by_id : Str, [FreeFace, CardsOnly] -> (Str -> I64)
cards_by_id = |peak, face| {
	best = Reach.fewest_cards({ zone_colors: colors, color: "red", peak }, face)
	|id| (best.get(red_square(id)) ?? crash "Reach's expects: every square is in the table").cards
}

# Steve's expectations, for red: B4 0; B3 .. R4 one card; L0 .. L2 two.
expect {
	n = cards_by_id("B4", CardsOnly)
	n("B4") == 0 and n("B3") == 1 and n("B1") == 1 and n("BR") == 1 and n("R0") == 1 and n("R4") == 1 and n("L0") == 2 and n("L1") == 2
}

# With a free face card, DS is one card (Q then 3), and so is L2's way
# through it: 4 back to DS, then the face card and a 3.
expect {
	n = cards_by_id("B4", FreeFace)
	n("B4") == 0 and n("B3") == 1 and n("DS") == 1 and n("L2") == 2
}

# With B4 taken, B3 is the peak: B3 is 0, B2 and B1 one card, and DS one (a
# face card, then a 2); nothing lands on B4.
expect {
	n = cards_by_id("B3", FreeFace)
	n("B3") == 0 and n("B2") == 1 and n("B1") == 1 and n("DS") == 1 and n("B4") >= Board.far
}

# R1 and R3 to B3, with a free face card and no joker: one card each, two
# routes each (F+5 or 6; F+7 or 8). Without the 6, R1 keeps one route and R3
# two.
expect {
	no_joker = Reach.cards.drop_if(|c| c == "joker")
	grid = Reach.grid(colors, "red")
	at = |hand, id| Reach.routes(
		grid,
		{
			zone_colors: colors,
			color: "red",
			peak: "B3",
		},
		{ hand, face: FreeFace },
	).get(red_square(id)) ?? crash "Reach's expects: every square is in the table"
	no_six = no_joker.drop_if(|c| c == "6")
	at(no_joker, "R1") == { cards: 1, routes: 2 } and at(no_joker, "R3") == {
		cards: 1,
		routes: 2,
	} and at(no_six, "R1") == {
		cards: 1,
		routes: 1,
	} and at(no_six, "R3") == { cards: 1, routes: 2 }
}
