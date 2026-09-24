# Routes -- every way a piece can walk n squares, worked out once.
#
# The board's graph as a piece sees it from its own zone (Board.relative):
# the rules of LegalMove.elm's getNextLocs and getPrevLocs, written for red
# and so for every color. From a square, `forward` and `backward` hold every
# walk of 1 to 10 steps, each the squares it passes through ending where it
# lands, in the order Elm's graph walk (depth first) finds them. A walk that
# reaches the same square two ways is two walks: the rules count them.
#
# The board decides which walks are open (a piece may not pass or land on its
# own color: LegalMove.ends); the card decides whether a walk may leave the
# pen or the bullseye at all. So the table is built with a pen square
# allowed to leave the pen and the bullseye allowed to leave the bullseye,
# and a walk from a fast-track square allowed to take the fast track.
import Board

Routes :: [].{
	## The longest walk a card asks for: a 10.
	longest : U64
	longest = 10

	## The squares after `r`, for a piece whose own zone is zone 0.
	next : U64, Bool, Bool, Bool -> List(U64)
	next = |r, fast, leave_pen, leave_bulls|
		if r == Board.bullseye {
			if leave_bulls { [Board.at(3, Board.ft)] } else { [] }
		} else {
			z = Board.zone(r)
			l = Board.local(r)
			nz = (z + 1) % Board.zones
			if l < 4 {
				if leave_pen { [Board.at(z, Board.l0)] } else { [] }
			} else if l == Board.ft {
				if z == 0 {
					if fast { [Board.at(nz, Board.ft), Board.at(nz, Board.r4), Board.bullseye] } else { [Board.at(nz, Board.r4), Board.bullseye] }
				} else if fast and nz != 0 {
					[Board.at(nz, Board.ft), Board.at(nz, Board.r4)]
				} else {
					[Board.at(nz, Board.r4)]
				}
			} else {
				# HH, L0-L4 up to FT; R4 down to R0, BR, DS; DS into the base
				# at home, else on to HH; B1-B4.
				to = match l {
					8 => [Board.l0]
					11 => [12]
					12 => [13]
					13 => [14]
					14 => [15]
					15 => [Board.ft]
					21 => [20]
					20 => [19]
					19 => [18]
					18 => [17]
					17 => [10]
					10 => [Board.ds]
					9 => if z == 0 { [4] } else { [Board.hh] }
					4 => [5]
					5 => [6]
					6 => [7]
					_ => []
				}
				List.map(to, |t| Board.at(z, t))
			}
		}

	## The squares before `r`, walking backwards: none from the pen, the base
	## or the bullseye; R4 back to the fast-track square of the zone before.
	prev : U64 -> List(U64)
	prev = |r|
		if r == Board.bullseye or Board.is_pen(r) or Board.is_base(r) {
			[]
		} else {
			z = Board.zone(r)
			l = Board.local(r)
			if l == Board.r4 {
				[Board.at((z + Board.zones - 1) % Board.zones, Board.ft)]
			} else {
				back = match l {
					8 => Board.ds
					11 => Board.hh
					16 => 15
					17 => 18
					18 => 19
					19 => 20
					20 => 21
					10 => 17
					9 => 10
					_ => l - 1
				}
				[Board.at(z, back)]
			}
		}

	## Every walk of `n` steps from `r`, depth first.
	walks : (U64 -> List(U64)), U64, U64 -> List(List(U64))
	walks = |step, n, r|
		if n == 0 {
			[[]]
		} else {
			List.join_map(step(r), |s| List.map(walks(step, n - 1, s), |rest| List.prepend(rest, s)))
		}

	## Indexed by `r * (longest + 1) + n`.
	forward : List(List(List(U64)))
	forward =
		List.join_map(
			Board.squares,
			|r| {
				fast = r != Board.bullseye and Board.local(r) == Board.ft
				step = |s| next(s, fast, Board.is_pen(r), r == Board.bullseye)
				List.map(Board.indices(longest + 1), |n| walks(step, n, r))
			},
		)

	backward : List(List(List(U64)))
	backward = List.join_map(Board.squares, |r| List.map(Board.indices(longest + 1), |n| walks(prev, n, r)))

	forward_walks : U64, U64 -> List(List(U64))
	forward_walks = |r, n| List.get(forward, r * (longest + 1) + n) ?? []

	backward_walks : U64, U64 -> List(List(U64))
	backward_walks = |r, n| List.get(backward, r * (longest + 1) + n) ?? []
}

# From L1, 8 steps: L2 L3 L4 FT, then the next zone's R4 R3 R2 R1.
expect Routes.forward_walks(Board.at(0, 12), 8) == [[13, 14, 15, 16, 43, 42, 41, 40]]
# From a piece's own FT, one step: the fast track, the next zone's R4, or the
# bullseye.
expect Routes.forward_walks(Board.at(0, Board.ft), 1) == [[Board.at(1, Board.ft)], [Board.at(1, Board.r4)], [Board.bullseye]]
# Home: DS into the base.
expect Routes.forward_walks(Board.at(0, Board.ds), 4) == [[4, 5, 6, 7]]
# Back 4 from L0: HH, DS, BR, R0.
expect Routes.backward_walks(Board.at(0, Board.l0), 4) == [[8, 9, 10, 17]]
