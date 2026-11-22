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
import chess.Tape

## The rows the search fills, in order, the pin's left out; the column of
## each queen it has placed, a row each; the column to try next in the row
## being filled; and the columns and the two families of diagonals the
## queens on the board, the pin among them, attack, a bit each.
Queens :: {
	rows : List(U8),
	columns_placed : List(U8),
	trying : U8,
	columns : U16,
	sums : U16,
	differences : U16,
}.{

	## The search with its pinned queen on `square`.
	start : U8 -> Queens
	start = |square| {
		pin_row = square // 8
		with_attacks(
			Queens.(
				{
					rows: List.from_iter(U8.until(0, 8)).drop_if(|row| row == pin_row),
					columns_placed: [],
					trying: 0,
					columns: 0,
					sums: 0,
					differences: 0,
				},
			),
			{ row: pin_row, column: square % 8 },
		)
	}

	## The search one transition on: a queen in the next open column of the
	## row being filled, or, with none, the previous row's queen taken off.
	next_move : Queens -> (Queens, Tape.Move)
	next_move = |queens| {
		Queens.(search) = queens
		row = search.rows.get(search.columns_placed.len()) ?? crash "Queens.next_move: every row is filled, and the search is solved then"
		match first_open_column(queens, { row, from: search.trying }) {
			Ok(column) => {
				Queens.(attacked) = with_attacks(queens, { row, column })
				(Queens.({ ..attacked, columns_placed: attacked.columns_placed.append(column), trying: 0 }), Place(row * 8 + column))
			}
			Err(NoColumn) =>
				match search.columns_placed.last() {
					Err(ListWasEmpty) => (queens, GiveUp)
					Ok(column) => {
						placed = search.columns_placed.drop_last(1)
						back_row = search.rows.get(placed.len()) ?? crash "Queens.next_move: a placed queen has its row"
						Queens.(freed) = with_attacks(queens, { row: back_row, column })
						(Queens.({ ..freed, columns_placed: placed, trying: column + 1 }), Remove(back_row * 8 + column))
					}
				}
		}
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

## The search with a queen at `row` and `column` added to its attacks, or,
## where one is there, taken out: each bit flips.
with_attacks : Queens, { row : U8, column : U8 } -> Queens
with_attacks = |Queens.(search), { row, column }|
	Queens.(
		{
			..search,
			columns: U16.bitwise_xor(search.columns, U16.shl_wrap(1, column)),
			sums: U16.bitwise_xor(search.sums, U16.shl_wrap(1, row + column)),
			differences: U16.bitwise_xor(search.differences, U16.shl_wrap(1, row + 7 - column)),
		},
	)

## The first column of `row`, from `from` on, that no queen attacks.
first_open_column : Queens, { row : U8, from : U8 } -> Try(U8, [NoColumn])
first_open_column = |Queens.(search), { row, from }| {
	is_free = |column|
		U16.bitwise_and(search.columns, U16.shl_wrap(1, column)) == 0
			and U16.bitwise_and(search.sums, U16.shl_wrap(1, row + column)) == 0
			and U16.bitwise_and(search.differences, U16.shl_wrap(1, row + 7 - column)) == 0
	match List.from_iter(U8.until(from, 8)).find_first(is_free) {
		Ok(column) => Ok(column)
		Err(NotFound) => Err(NoColumn)
	}
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
