## Tape is the engine both chess toys run on. A search speaks only by
## appending moves to an event tape, one byte a move: the top bit says
## whether a piece was placed or removed, and the low six bits name the
## square. The board a viewer sees is a cursor walking that tape, applying
## each move forward or undoing it backward, so pausing, stepping and
## scrubbing in both directions fall out of the data. A remove always takes
## the newest piece, so every move undoes itself.
##
## The red overlay lives here too. A square is a dead end when a piece placed
## there was found doomed and pulled off, and none has come back since. It is
## marked when the piece is retracted, never predicted, so marks build up as a
## doomed branch unwinds and a square clears when the search enters it again.
## A square's moves alternate place and remove, so a dead end is exactly an
## empty square that some move before the cursor touched: one count a square,
## kept in both directions.
Tape :: {
	events : List(U8),
	cursor : U64,
	board : List(I8),
	pieces_shown : U64,
	touches : List(U32),
	search : [Waiting, Running, Solved, Exhausted],
	target_count : U64,
	pieces_at_end : U64,
	deepest : U64,
}.{

	## What a search does at one transition: place a piece, take the newest
	## one off, take it off and stop because nothing is left to try, or stop
	## with nothing to take off.
	Move : [Place(U8), Remove(U8), RemoveAndGiveUp(U8), GiveUp]

	## Where a search stands at the tape's end. `Waiting` is the board before
	## anyone has clicked.
	Search : [Waiting, Running, Solved, Exhausted]

	## A tape moved one step forward, with the machine that may have made the
	## move, and whether the board moved.
	Stepped(machine) : { tape : Tape, machine : machine, step : [Moved, Stuck] }

	## The board before any search: empty, with nothing on the tape.
	empty : Tape
	empty = Tape.(empty_parts)

	## A new search whose first piece is on `square`, already shown, which is
	## solved when `target_count` pieces stand on the board.
	start : { square : U8, target_count : U64 } -> Tape
	start = |{ square, target_count }| {
		running = Tape.({ ..empty_parts, search: Running, target_count })
		placed = running.with_move(Place(U8.bitwise_and(square, square_bits)))
		match placed.step_forward() {
			Ok(shown) => shown
			Err(AtEnd) => crash "Tape.start: the first piece was appended and could not be shown"
		}
	}

	## The tape with `move` appended at its end. The display doesn't move.
	with_move : Tape, Tape.Move -> Tape
	with_move = |Tape.(tape), move|
		match move {
			Place(square) => {
				at_end = tape.pieces_at_end + 1
				search =
					if at_end == tape.target_count {
						Solved
					} else {
						tape.search
					}
				Tape.(
					{
						..tape,
						events: tape.events.append(U8.bitwise_or(place_bit, square)),
						pieces_at_end: at_end,
						deepest: U64.max(tape.deepest, at_end),
						search,
					},
				)
			}
			Remove(square) => Tape.({ ..tape, events: tape.events.append(square), pieces_at_end: tape.pieces_at_end - 1 })
			RemoveAndGiveUp(square) =>
				Tape.(
					{
						..tape,
						events: tape.events.append(square),
						pieces_at_end: tape.pieces_at_end - 1,
						search: Exhausted,
					},
				)
			GiveUp => Tape.({ ..tape, search: Exhausted })
		}

	## Whether the next step forward needs a new move: the cursor is at the
	## tape's end, the search still runs, and the tape has room.
	should_generate : Tape -> Bool
	should_generate = |Tape.(tape)|
		tape.cursor == tape.events.len()
			and tape.events.len() < capacity
			and match tape.search {
				Running => Bool.True
				Waiting | Solved | Exhausted => Bool.False
			}

	## One step forward on the display. At the tape's end, while the search
	## runs, `next_move` makes the move first. The board doesn't move once the
	## search is solved or spent and the cursor has reached the end.
	forward : Tape,
	{
		machine : machine,
		next_move : machine -> (machine, Tape.Move),
	} -> Tape.Stepped(machine)
	forward = |tape, { machine, next_move }| {
		(made, moved_machine) =
			if tape.should_generate() {
				(machine_after, move) = next_move(machine)
				(tape.with_move(move), machine_after)
			} else {
				(tape, machine)
			}
		match made.step_forward() {
			Ok(stepped) => { tape: stepped, machine: moved_machine, step: Moved }
			Err(AtEnd) => { tape: made, machine: moved_machine, step: Stuck }
		}
	}

	## The display one move further along the tape, or `AtEnd` when it shows
	## every move there is.
	step_forward : Tape -> Try(Tape, [AtEnd])
	step_forward = |Tape.(tape)|
		match tape.events.get(tape.cursor) {
			Err(OutOfBounds) => Err(AtEnd)
			Ok(event) => {
				square = U8.bitwise_and(event, square_bits).to_u64()
				touched = tape.touches.get(square) ?? crash "Tape.step_forward: a square past the board"
				if U8.bitwise_and(event, place_bit) != 0 {
					Ok(
						Tape.(
							{
								..tape,
								cursor: tape.cursor + 1,
								touches: tape.touches.set(square, touched + 1) ?? crash "Tape.step_forward: a square past the board",
								board: tape.board.set(square, move_number(tape.pieces_shown)) ?? crash "Tape.step_forward: a square past the board",
								pieces_shown: tape.pieces_shown + 1,
							},
						),
					)
				} else {
					Ok(
						Tape.(
							{
								..tape,
								cursor: tape.cursor + 1,
								touches: tape.touches.set(square, touched + 1) ?? crash "Tape.step_forward: a square past the board",
								board: tape.board.set(square, -1) ?? crash "Tape.step_forward: a square past the board",
								pieces_shown: tape.pieces_shown - 1,
							},
						),
					)
				}
			}
		}

	## The display one move back, undoing it, or `AtStart` at the tape's
	## first move.
	step_back : Tape -> Try(Tape, [AtStart])
	step_back = |Tape.(tape)|
		if tape.cursor == 0 {
			Err(AtStart)
		} else {
			cursor = tape.cursor - 1
			event = tape.events.get(cursor) ?? crash "Tape.step_back: the cursor is past the tape"
			square = U8.bitwise_and(event, square_bits).to_u64()
			touched = tape.touches.get(square) ?? crash "Tape.step_back: a square past the board"
			if U8.bitwise_and(event, place_bit) != 0 {
				Ok(
					Tape.(
						{
							..tape,
							cursor,
							touches: tape.touches.set(square, touched - 1) ?? crash "Tape.step_back: a square past the board",
							board: tape.board.set(square, -1) ?? crash "Tape.step_back: a square past the board",
							pieces_shown: tape.pieces_shown - 1,
						},
					),
				)
			} else {
				Ok(
					Tape.(
						{
							..tape,
							cursor,
							touches: tape.touches.set(square, touched - 1) ?? crash "Tape.step_back: a square past the board",
							board: tape.board.set(square, move_number(tape.pieces_shown)) ?? crash "Tape.step_back: a square past the board",
							pieces_shown: tape.pieces_shown + 1,
						},
					),
				)
			}
		}

	## The board shown: a move number for each of the 64 squares, 0 for the
	## first piece, or -1 for an empty square. Square 0 is a1 and 63 is h8.
	board : Tape -> List(I8)
	board = |Tape.(tape)| tape.board

	## How many pieces the display shows.
	pieces_shown : Tape -> U64
	pieces_shown = |Tape.(tape)| tape.pieces_shown

	## How many pieces mean the search is solved.
	target_count : Tape -> U64
	target_count = |Tape.(tape)| tape.target_count

	## How many moves the display has applied.
	cursor : Tape -> U64
	cursor = |Tape.(tape)| tape.cursor

	## How many moves the search has made.
	move_count : Tape -> U64
	move_count = |Tape.(tape)| tape.events.len()

	## The most pieces the search has had on the board at once, whatever the
	## display shows: the closest it has come.
	deepest : Tape -> U64
	deepest = |Tape.(tape)| tape.deepest

	## Where the search stands at the tape's end.
	search : Tape -> Tape.Search
	search = |Tape.(tape)| tape.search

	## The square of the newest piece shown, the search's frontier.
	head : Tape -> Try(U8, [EmptyBoard])
	head = |Tape.(tape)|
		if tape.pieces_shown == 0 {
			Err(EmptyBoard)
		} else {
			newest = move_number(tape.pieces_shown - 1)
			match tape.board.find_first_index(|number| number == newest) {
				Ok(square) => Ok(square.to_u8_wrap())
				Err(NotFound) => crash "Tape.head: pieces are shown and none holds the newest number"
			}
		}

	## Each square's dead-end mark, in square order: the square is empty and a
	## piece placed there has been retracted.
	dead_ends : Tape -> List(Bool)
	dead_ends = |Tape.(tape)|
		List.map2(tape.board, tape.touches, |number, touched| number < 0 and touched > 0)

	is_eq : _
}

## The squares on a board.
square_count : U64
square_count = 64

## What the empty board holds: no moves, no pieces, no search.
empty_parts : {
	events : List(U8),
	cursor : U64,
	board : List(I8),
	pieces_shown : U64,
	touches : List(U32),
	search : [Waiting, Running, Solved, Exhausted],
	target_count : U64,
	pieces_at_end : U64,
	deepest : U64,
}
empty_parts = {
	events: [],
	cursor: 0,
	board: List.repeat(-1, square_count),
	pieces_shown: 0,
	touches: List.repeat(0, square_count),
	search: Waiting,
	target_count: square_count,
	pieces_at_end: 0,
	deepest: 0,
}

## The top bit of an event marks a place; a remove leaves it clear.
place_bit : U8
place_bit = 0x80

## The low six bits of an event name its square.
square_bits : U8
square_bits = 63

## The most moves a tape holds. The longest search either toy makes, the
## knight's from g6, takes 2,520,884.
capacity : U64
capacity = 4194304

## A piece's move number, as the board holds it.
move_number : U64 -> I8
move_number = |pieces| pieces.to_i8_try() ?? crash "Tape.move_number: more than 127 pieces on a board of 64 squares"

## A knight's walk along a1, b3, c5, then back off c5: moves the tests replay.
three_and_back : Tape
three_and_back =
	Tape.start({ square: 0, target_count: 64 })
		.with_move(Place(17))
		.with_move(Place(34))
		.with_move(Remove(34))

## The tape stepped forward until it shows every move it has.
shown_to_end : Tape -> Tape
shown_to_end = |tape| {
	var $shown = tape
	var $going = Bool.True
	while $going {
		match $shown.step_forward() {
			Ok(next) => {
				$shown = next
			}
			Err(AtEnd) => {
				$going = Bool.False
			}
		}
	}
	$shown
}

# The empty board shows nothing, marks nothing, and waits for a click.
expect {
	tape = Tape.empty
	tape.board().all(|number| number == -1)
		and tape.dead_ends().all(|mark| !mark)
		and !tape.should_generate()
		and tape.head() == Err(EmptyBoard)
		and tape.step_back() == Err(AtStart)
}

# A start shows its first piece at once, as move 0 at the tape's first move.
expect {
	tape = Tape.start({ square: 27, target_count: 8 })
	tape.board().get(27) == Ok(0)
		and tape.cursor() == 1
		and tape.move_count() == 1
		and tape.pieces_shown() == 1
		and tape.head() == Ok(27)
		and tape.should_generate()
}

# A retracted piece's square turns red at its retraction, and one step back,
# with the piece restored, it is clear again.
expect {
	tape = shown_to_end(three_and_back)
	marks = tape.dead_ends()
	before = tape.step_back() ?? crash "the test's tape has moves to undo"
	marks.get(34) == Ok(Bool.True)
		and marks.keep_if(|mark| mark).len() == 1
		and before.dead_ends().get(34) == Ok(Bool.False)
		and before.board().get(34) == Ok(2)
		and tape.head() == Ok(17)
}

# A cascade of retractions keeps every mark, and the search entering a red
# square again clears it.
expect {
	cascade = shown_to_end(three_and_back.with_move(Remove(17)))
	reentered = shown_to_end(cascade.with_move(Place(34)))
	cascade.dead_ends().keep_if(|mark| mark).len() == 2
		and reentered.dead_ends().get(34) == Ok(Bool.False)
		and reentered.dead_ends().get(17) == Ok(Bool.True)
		and reentered.board().get(34) == Ok(1)
}

# Scrubbed home, every count is back to zero and no square is marked.
expect {
	tape = shown_to_end(three_and_back.with_move(Remove(17)))
	var $home = tape
	while $home.cursor() > 0 {
		$home = $home.step_back() ?? crash "the cursor is past the start"
	}
	$home.board().all(|number| number == -1) and $home.dead_ends().all(|mark| !mark) and $home.pieces_shown() == 0
}

# The deepest the search reached stays when pieces come off, and the target
# count solves the search when the last piece lands, not before.
expect {
	tape = three_and_back.with_move(Remove(17))
	two = Tape.start({ square: 0, target_count: 2 })
	tape.deepest() == 3
		and two.search() == Running
		and two.with_move(Place(10)).search() == Solved
}

# A search that gives up stops generating, with or without a last removal.
expect {
	gave_up = Tape.start({ square: 5, target_count: 64 }).with_move(RemoveAndGiveUp(5))
	stuck = Tape.start({ square: 5, target_count: 8 }).with_move(GiveUp)
	shown = shown_to_end(gave_up)
	gave_up.search() == Exhausted
		and stuck.search() == Exhausted
		and !shown.should_generate()
		and !stuck.should_generate()
		and shown.pieces_shown() == 0
}
