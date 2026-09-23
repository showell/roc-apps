# RulesTests -- elm-fasttrack's tests/Example.elm, test for test.
#
# Elm compared sets of moves; these compare the same sets, each move written
# as one string: the move type as Example.elm's `fixMoveType` spells it, then
# where from and where to, as `zone.id`, with the bullseye's zone as `BE`.
#
# Elm's tests played on three zones; these play on the game's four. No route
# in them wraps round the board, so every expectation is Elm's.
import Assoc
import Board
import LegalMove
import Piece
import Type

RulesTests :: [].{
	zone_colors : List(Str)
	zone_colors = ["red", "blue", "green", "purple"]

	blue : U64
	blue = 1

	board : List((Str, Str, Str)) -> Type.Board
	board = |pieces| Piece.board_of(zone_colors, pieces)

	at : Str, Str -> U64
	at = |zone, id| if zone == "BE" { Board.bullseye } else { Board.index_of(zone_colors, { zone: NormalColor(zone), id }) }

	show_loc : U64 -> Str
	show_loc = |s|
		if s == Board.bullseye {
			"BE.bullseye"
		} else {
			loc = Board.loc_of(zone_colors, s)
			"${List.get(zone_colors, Board.zone(s)) ?? "?"}.${loc.id}"
		}

	show_move_type : Type.MoveType -> Str
	show_move_type = |move_type|
		match move_type {
			WithCard(card) => card
			Reverse(card) => "R${card}"
			StartSplit(count) => "SS${I64.to_str(count)}"
			FinishSplit(count, _) => "FS${I64.to_str(count)}"
			_ => "other"
		}

	show_move : Type.Move -> Str
	show_move = |move| "${show_move_type(move.kind)} ${show_loc(move.start)} ${show_loc(move.end)}"

	## Set equality, which is what the Elm tests asserted after sorting.
	same_set : List(Str), List(Str) -> Bool
	same_set = |actual, expected| {
		a = Assoc.set_from_list(actual)
		e = Assoc.set_from_list(expected)
		List.len(a) == List.len(e) and List.all(a, |x| List.contains(e, x))
	}

	moves_are : List(Type.Move), List(Str) -> Bool
	moves_are = |moves, expected| same_set(List.map(moves, show_move), expected)

	locs_are : List(U64), List(Str) -> Bool
	locs_are = |locs, expected| same_set(List.map(locs, show_loc), expected)

	## Where a blue piece on `start` lands after `n` steps forward.
	ends : Type.Board, U64, I64 -> List(U64)
	ends = |b, start, n| LegalMove.ends(b, blue, start, n, Bool.False, Bool.False, Bool.False)

	for_cards : List(Str), Type.Board -> List(Type.Move)
	for_cards = |cards, b| LegalMove.get_moves_for_cards(Assoc.set_from_list(cards), b, zone_colors, ["blue"])

	end_locs_of : List(Type.Move) -> List(U64)
	end_locs_of = |moves| List.map(moves, |m| m.end)
}

# testZoneColors lives in Color.roc.

# testGetMovesForCards

# get moves 2/3 away
expect {
	b = RulesTests.board([("red", "L0", "blue"), ("green", "R3", "blue"), ("blue", "L3", "blue"), ("blue", "L0", "blue"), ("green", "L3", "green")])
	RulesTests.moves_are(RulesTests.for_cards(["2", "3"], b),
		[
			"2 red.L0 red.L2",
			"2 green.R3 green.R1",
			"2 blue.L3 blue.FT",
			"2 blue.L0 blue.L2",
			"3 red.L0 red.L3",
			"3 blue.L3 green.R4",
			"3 blue.L3 BE.bullseye",
			"3 green.R3 green.R0",
		],
	)
}

# get forced reverse
expect {
	b = RulesTests.board([("blue", "B1", "blue"), ("blue", "B2", "blue"), ("blue", "R0", "blue")])
	RulesTests.moves_are(RulesTests.for_cards(["3", "8"], b), ["R3 blue.R0 blue.R3", "R8 blue.R0 red.L2"])
}

# reverse with seven
expect {
	b = RulesTests.board([("blue", "B3", "blue"), ("blue", "B1", "blue"), ("blue", "R0", "blue")])
	RulesTests.moves_are(RulesTests.for_cards(["7"], b), ["R7 blue.R0 red.L3"])
}

# seven with FT edge case: a split's first part may not land on the fast track
expect {
	b = RulesTests.board([("blue", "B1", "blue"), ("blue", "L0", "blue")])
	RulesTests.moves_are(
		RulesTests.for_cards(["7"], b),
		[
			"SS1 blue.B1 blue.B2",
			"SS2 blue.B1 blue.B3",
			"SS3 blue.B1 blue.B4",
			"SS4 blue.L0 blue.L4",
			"SS6 blue.L0 green.R4",
			"7 blue.L0 green.R3",
		],
	)
}

# testGetMovesForMoveType

# get locs 2 away
expect {
	b = RulesTests.board([("red", "L0", "blue"), ("green", "R4", "blue"), ("blue", "L3", "blue"), ("green", "L3", "green")])
	moves = LegalMove.get_moves_for_move_type(WithCard("2"), b, RulesTests.zone_colors, ["blue"])
	RulesTests.moves_are(moves, ["2 red.L0 red.L2", "2 green.R4 green.R2", "2 blue.L3 blue.FT"])
}

# finish split
expect {
	exclude = RulesTests.at("green", "R4")
	b = RulesTests.board([("green", "R4", "blue"), ("blue", "B1", "blue"), ("green", "L2", "blue"), ("red", "L2", "red")])
	moves = LegalMove.get_moves_for_move_type(FinishSplit(3, exclude), b, RulesTests.zone_colors, ["blue"])
	RulesTests.moves_are(moves, ["FS3 blue.B1 blue.B4", "FS3 green.L2 green.FT"])
}

# testMovablePieces: find my pieces
expect {
	b = RulesTests.board(
		[
			("red", "L0", "blue"),
			("red", "L2", "red"),
			("green", "FT", "blue"),
			("blue", "L3", "blue"),
			("blue", "L4", "green"),
			("blue", "HP1", "blue"),
			("blue", "HP2", "blue"),
			("blue", "B2", "blue"),
			("blue", "FT", "red"),
		],
	)
	RulesTests.locs_are(Piece.movable_pieces(b, RulesTests.blue), ["red.L0", "green.FT", "blue.L3", "blue.HP2", "blue.B2"])
}

# testOtherNonPenPieces: other pieces can be found
expect {
	b = RulesTests.board(
		[
			("red", "L1", "blue"),
			("green", "FT", "blue"),
			("blue", "L3", "blue"),
			("blue", "HP1", "blue"),
			("blue", "B2", "blue"),
			("blue", "FT", "red"),
		],
	)
	RulesTests.locs_are(Piece.other_non_pen_pieces(b, RulesTests.blue, RulesTests.at("red", "L1")), ["green.FT", "blue.L3", "blue.B2"])
}

# testEndLocs

# can move 8
expect RulesTests.locs_are(RulesTests.ends(Piece.empty, RulesTests.at("red", "L1"), 8), ["blue.R1"])

# seven full
expect {
	b = RulesTests.board([("blue", "L2", "blue")])
	moves = LegalMove.get_moves_from_location(WithCard("7"), b, RulesTests.zone_colors, RulesTests.at("blue", "L2"), ["blue"])
	RulesTests.locs_are(RulesTests.end_locs_of(moves), ["green.R1"])
}

# seven split
expect {
	b = RulesTests.board([("blue", "R1", "blue"), ("blue", "B1", "blue")])
	moves = LegalMove.get_moves_from_location(WithCard("7"), b, RulesTests.zone_colors, RulesTests.at("blue", "B1"), ["blue"])
	RulesTests.locs_are(RulesTests.end_locs_of(moves), ["blue.B3", "blue.B4"])
}

# can only move FT piece
expect {
	b = RulesTests.board([("green", "FT", "blue"), ("red", "L1", "blue")])
	moves = LegalMove.get_moves_from_location(WithCard("8"), b, RulesTests.zone_colors, RulesTests.at("red", "L1"), ["blue"])
	List.is_empty(moves)
}

# can't jump own piece
expect {
	b = RulesTests.board([("blue", "R3", "blue")])
	List.is_empty(RulesTests.ends(b, RulesTests.at("red", "L1"), 8))
}

# testHasPieceOnFastTrack
expect Piece.has_piece_on_fast_track(RulesTests.board([("red", "FT", "blue")]), RulesTests.blue)
expect !Piece.has_piece_on_fast_track(RulesTests.board([("red", "FT", "green")]), RulesTests.blue)
expect !Piece.has_piece_on_fast_track(RulesTests.board([("blue", "L0", "blue"), ("green", "R4", "blue")]), RulesTests.blue)

# testSwappableLocs
expect {
	b = RulesTests.board(
		[
			("blue", "L0", "blue"),
			("green", "L1", "blue"),
			("green", "HP1", "green"),
			("red", "HP1", "red"),
			("red", "B1", "red"),
			("green", "L0", "green"),
			("blue", "L1", "green"),
			("red", "R3", "red"),
		],
	)
	RulesTests.locs_are(Piece.swappable_locs(b, RulesTests.blue), ["green.L0", "blue.L1", "red.R3"])
}

# testCanGoNSpaces
expect LegalMove.get_can_go_n_spaces(RulesTests.board([("red", "L1", "blue")]), RulesTests.at("red", "L1"), RulesTests.zone_colors, 7, ["blue"])
expect !LegalMove.get_can_go_n_spaces(RulesTests.board([("red", "L1", "blue"), ("green", "FT", "blue")]), RulesTests.at("red", "L1"), RulesTests.zone_colors, 1, ["blue"])
expect !LegalMove.get_can_go_n_spaces(RulesTests.board([("red", "L1", "blue"), ("red", "L3", "blue")]), RulesTests.at("red", "L1"), RulesTests.zone_colors, 2, ["blue"])
expect LegalMove.get_can_go_n_spaces(RulesTests.board([("blue", "DS", "blue")]), RulesTests.at("blue", "DS"), RulesTests.zone_colors, 4, ["blue"])
expect LegalMove.get_can_go_n_spaces(RulesTests.board([("red", "L1", "blue"), ("blue", "R4", "blue")]), RulesTests.at("red", "L1"), RulesTests.zone_colors, 4, ["blue"])
expect !LegalMove.get_can_go_n_spaces(RulesTests.board([("red", "L1", "blue"), ("blue", "R4", "blue")]), RulesTests.at("red", "L1"), RulesTests.zone_colors, 5, ["blue"])

# A guard on the guard: a wrong expectation must not pass.
expect !RulesTests.moves_are(RulesTests.for_cards(["7"], RulesTests.board([("blue", "B1", "blue"), ("blue", "L0", "blue")])), ["7 blue.L0 green.R3"])
