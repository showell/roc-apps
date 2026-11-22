## Knight is the Knight's Tour machine: a depth-first search for a path
## that visits all 64 squares exactly once, a knight's move at a time. The
## tape, the display and the dead-end overlay are the chess kit's; what is
## knight-shaped is here: the move graph, the search, and which squares the
## tour can no longer reach.
##
## Each square's moves are tried in order of how few onward moves their
## target has, fewest first, ties in the order the graph lists them: a
## frozen Warnsdorff. In the plain geometric order the search fails to finish
## from 54 of the 64 starts within 200 million moves; in this one it
## finishes from every start, within 2,520,884 moves from g6, the worst, and
## with no backtracking at all from b2. KnightProof.roc holds every start's
## count.
import chess.Tape

## The search's path from the first knight, each knight with the index of the
## next of its moves to try, and the squares the path covers, a bit each.
Knight :: { path : List({ square : U8, next : U64 }), visited : U64 }.{

	## The tour's first knight, on `square`.
	start : U8 -> Knight
	start = |square| Knight.({ path: [{ square, next: 0 }], visited: square_bit(square) })

	## The search one transition on: the newest knight's next untried move to
	## an empty square, or, with none left, that knight taken off.
	next_move : Knight -> (Knight, Tape.Move)
	next_move = |Knight.(knight)| {
		last = knight.path.len() - 1
		newest = knight.path.get(last) ?? crash "Knight.next_move: the search has given up, and no move is asked of it then"
		landings = knight_moves.get(newest.square.to_u64()) ?? crash "Knight.next_move: a square past the board"
		match first_open_move(landings, { from: newest.next, visited: knight.visited }) {
			Ok({ index, square }) => {
				marked = knight.path.set(last, { ..newest, next: index + 1 }) ?? crash "Knight.next_move: the newest knight is on the path"
				(
					Knight.({ path: marked.append({ square, next: 0 }), visited: U64.bitwise_or(knight.visited, square_bit(square)) }),
					Place(square),
				)
			}
			Err(NoneOpen) => {
				path = knight.path.drop_last(1)
				visited = U64.bitwise_xor(knight.visited, square_bit(newest.square))
				move =
					if path.is_empty() {
						RemoveAndGiveUp(newest.square)
					} else {
						Remove(newest.square)
					}
				(Knight.({ path, visited }), move)
			}
		}
	}

	## Each empty square the tour can never enter from where it stands: no
	## path of empty squares joins it to the newest knight. Where the newest
	## knight has no empty neighbour, every empty square is, and the search is
	## about to back up.
	impossible_squares : Tape -> List(Bool)
	impossible_squares = |tape| {
		board = tape.board()
		match tape.head() {
			Err(EmptyBoard) => List.repeat(Bool.False, 64)
			Ok(head) => {
				reached = squares_reached(board, head)
				board.map_with_index(|number, square| number < 0 and U64.bitwise_and(reached, square_bit(square.to_u8_wrap())) == 0)
			}
		}
	}

	## The squares a knight reaches from each square, in the order the search
	## tries them.
	moves_from : List(List(U8))
	moves_from = knight_moves
}

square_bit : U8 -> U64
square_bit = |square| U64.shl_wrap(1, square)

## The first of `landings`, from index `from` on, whose square is empty.
first_open_move : List(U8), { from : U64, visited : U64 } -> Try({ index : U64, square : U8 }, [NoneOpen])
first_open_move = |landings, { from, visited }| {
	var $index = from
	var $found = Err(NoneOpen)
	while $index < landings.len() {
		square = landings.get($index) ?? crash "Knight.first_open_move: the index is inside the list"
		if U64.bitwise_and(visited, square_bit(square)) == 0 {
			$found = Ok({ index: $index, square })
			$index = landings.len()
		} else {
			$index = $index + 1
		}
	}
	$found
}

## The empty squares a flood reaches from `head` through empty squares, a bit
## each.
squares_reached : List(I8), U8 -> U64
squares_reached = |board, head| {
	is_empty = |square| (board.get(square.to_u64()) ?? crash "Knight.squares_reached: a square past the board") < 0
	var $reached = 0
	var $frontier = [head]
	while !$frontier.is_empty() {
		square = $frontier.last() ?? crash "Knight.squares_reached: the frontier is not empty"
		$frontier = $frontier.drop_last(1)
		for target in knight_moves.get(square.to_u64()) ?? crash "Knight.squares_reached: a square past the board" {
			if is_empty(target) and U64.bitwise_and($reached, square_bit(target)) == 0 {
				$reached = U64.bitwise_or($reached, square_bit(target))
				$frontier = $frontier.append(target)
			}
		}
	}
	$reached
}

## Every square's knight moves, each list in the search's order.
knight_moves : List(List(U8))
knight_moves = {
	geometric = List.from_iter(U64.until(0, 64)).map(geometric_moves)
	geometric.map(|landings| by_fewest_onward(landings, geometric))
}

## The squares a knight reaches from `square`, in the order the deltas
## below go round.
geometric_moves : U64 -> List(U8)
geometric_moves = |square| {
	rank = square.to_i64_wrap() // 8
	file = square.to_i64_wrap() % 8
	deltas = [(1, 2), (2, 1), (2, -1), (1, -2), (-1, -2), (-2, -1), (-2, 1), (-1, 2)]
	var $landings = []
	for (rank_step, file_step) in deltas {
		to_rank = rank + rank_step
		to_file = file + file_step
		if to_rank >= 0 and to_rank <= 7 and to_file >= 0 and to_file <= 7 {
			$landings = $landings.append((to_rank * 8 + to_file).to_u8_wrap())
		}
	}
	$landings
}

## `landings` in order of how many moves each has in `graph`, fewest first;
## the sort is an insertion sort, so ties keep their order.
by_fewest_onward : List(U8), List(List(U8)) -> List(U8)
by_fewest_onward = |landings, graph| {
	degree = |square| (graph.get(square.to_u64()) ?? crash "Knight.by_fewest_onward: a square past the board").len()
	var $sorted = []
	for target in landings {
		var $count = 0
		while $count < $sorted.len() and degree($sorted.get($count) ?? crash "Knight.by_fewest_onward: the count is inside the list") <= degree(target) {
			$count = $count + 1
		}
		count = $count
		$sorted = List.join([$sorted.take_first(count), [target], $sorted.drop_first(count)])
	}
	$sorted
}

# The graph has 336 moves, each one two ways; a corner has 2 and the centre 8.
expect {
	counts = knight_moves.map(List.len)
	is_symmetric =
		knight_moves.map_with_index(
			|landings, square| landings.all(|target| (knight_moves.get(target.to_u64()) ?? crash "a move lands on the board").contains(square.to_u8_wrap())),
		).all(|holds| holds)
	counts.sum() == 336 and counts.get(0) == Ok(2) and counts.get(27) == Ok(8) and is_symmetric
}

# From a1, c2 and b3 have six moves each, so they keep the graph's order.
expect knight_moves.get(0) == Ok([10, 17])

# Every square's moves go fewest onward moves first.
expect {
	degree = |square| (knight_moves.get(square.to_u64()) ?? crash "a move lands on the board").len()
	knight_moves.all(
		|landings| {
			degrees = landings.map(degree)
			List.map2(degrees, degrees.drop_first(1), |before, after| before <= after).all(|holds| holds)
		},
	)
}
