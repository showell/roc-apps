## Queens is the Eight Queens machine: eight queens on the board, none
## attacking another. The tape, the display and the dead-end overlay are the
## chess kit's; what is queen-shaped is here: the search, and which squares
## are attacked.
##
## The click pins the first queen. It is move 0, it is never retracted, and
## the search fills the other seven rows in order around it, one queen a row
## by construction, so it branches only on columns: the classic depth-first
## search, trying the next column in this row that no queen attacks, and
## with none left taking the previous row's queen back off and resuming from
## its next column. Every square of the board is on some solution, so no pin
## exhausts; QueensProof.roc holds every pin's count.
import chess.Backtrack
import chess.Tape

## The backtracking search for a solution, its choices the squares the queens
## stand on.
Queens :: Backtrack(Queens.Position, U8).{

	## Where a partial solution stands: the pin's row, how many other rows hold
	## a queen, and the columns and the two families of diagonals the queens on
	## the board, the pin among them, attack, a bit each.
	Position : { pin_row : U8, rows_filled : U8, columns : U16, sums : U16, differences : U16 }

	## The search with its pinned queen on `square`.
	start : U8 -> Queens
	start = |square| {
		empty = { pin_row: square // 8, rows_filled: 0, columns: 0, sums: 0, differences: 0 }
		Queens.(Backtrack.start(with_attacks(empty, square), square))
	}

	## The search one transition on: a queen in the next open column of the
	## row being filled, or, with none, the previous row's queen taken off.
	next_move : Queens -> (Queens, Tape.Move)
	next_move = |Queens.(search)| {
		(stepped, step) = search.step(solution)
		move =
			match step {
				Entered(square) => Place(square)
				Left(square) => Remove(square)
				Exhausted(_) => GiveUp
			}
		(Queens.(stepped), move)
	}

	## Each empty square a queen on the board attacks, along a row, a column
	## or a diagonal, whatever stands between: no queen can live there now.
	impossible_squares : Tape -> List(Bool)
	impossible_squares = |tape| {
		board = tape.board()
		queens = board.map_with_index(|number, square| (number, square.to_u8_wrap())).keep_if(|(number, _)| number >= 0).map(|(_, square)| square)
		board.map_with_index(|number, square| number < 0 and queens.any(|queen| is_attack(queen, square.to_u8_wrap())))
	}

	## The squares a queen on each square attacks, in square order.
	moves_from : List(List(U8))
	moves_from = List.from_iter(U8.until(0, 64)).map(|square| List.from_iter(U8.until(0, 64)).keep_if(|other| other != square and is_attack(square, other)))
}

## Whether queens on the two squares share a row, a column or a diagonal.
is_attack : U8, U8 -> Bool
is_attack = |from, to| {
	from_row = (from // 8).to_i64()
	from_column = (from % 8).to_i64()
	to_row = (to // 8).to_i64()
	to_column = (to % 8).to_i64()
	from_row == to_row or from_column == to_column or from_row + from_column == to_row + to_column or from_row - from_column == to_row - to_column
}

## Eight Queens as a puzzle: from a position, the squares of the next row
## to fill, and a square some queen attacks refused.
solution : Backtrack.Puzzle(Queens.Position, U8)
solution = {
	options: |position| row_squares.get(next_row(position).to_u64()) ?? crash "Queens.solution: every row is filled, and the search is solved then",
	child: |position, square|
		if is_attacked(position, square) {
			Err(Refused)
		} else {
			Ok({ ..with_attacks(position, square), rows_filled: position.rows_filled + 1 })
		},
}

## The row the search fills next: the rows in order, the pin's left out.
next_row : Queens.Position -> U8
next_row = |{ pin_row, rows_filled, .. }|
	if rows_filled < pin_row {
		rows_filled
	} else {
		rows_filled + 1
	}

## Each row's squares, a list a row.
row_squares : List(List(U8))
row_squares = List.from_iter(U8.until(0, 8)).map(|row| List.from_iter(U8.until(row * 8, row * 8 + 8)))

## The position with a queen on `square` added to its attacks, or, where one
## is there, taken out: each bit flips.
with_attacks : Queens.Position, U8 -> Queens.Position
with_attacks = |position, square| {
	row = square // 8
	column = square % 8
	{
		..position,
		columns: U16.bitwise_xor(position.columns, U16.shl_wrap(1, column)),
		sums: U16.bitwise_xor(position.sums, U16.shl_wrap(1, row + column)),
		differences: U16.bitwise_xor(position.differences, U16.shl_wrap(1, row + 7 - column)),
	}
}

## Whether a queen on the board attacks `square`, along its column or a
## diagonal; the search never puts two queens in a row.
is_attacked : Queens.Position, U8 -> Bool
is_attacked = |position, square| {
	row = square // 8
	column = square % 8
	U16.bitwise_and(position.columns, U16.shl_wrap(1, column)) != 0
		or U16.bitwise_and(position.sums, U16.shl_wrap(1, row + column)) != 0
		or U16.bitwise_and(position.differences, U16.shl_wrap(1, row + 7 - column)) != 0
}

# A queen on a1 attacks 21 squares, one on d4 27, each attack goes both ways,
# and the board holds 1,456 in all.
expect {
	counts = Queens.moves_from.map(List.len)
	is_symmetric =
		Queens.moves_from.map_with_index(
			|attacked, square| attacked.all(|other| (Queens.moves_from.get(other.to_u64()) ?? crash "an attack lands on the board").contains(square.to_u8_wrap())),
		).all(|holds| holds)
	counts.get(0) == Ok(21) and counts.get(27) == Ok(27) and counts.sum() == 1456 and is_symmetric
}

# A pin on d4 leaves its row out of the search, and the first queen goes in
# the first open column of rank 1.
expect {
	(_, move) = Queens.next_move(Queens.start(27))
	move == Place(1)
}
