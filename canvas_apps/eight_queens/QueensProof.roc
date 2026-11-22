# Eight Queens' frozen answers, natively, on Roc's echo platform. It runs the
# search from a pin on each of the 64 squares to its end and prints how many
# moves each took, which freezes the search order: a change that makes the
# toy animate differently changes a count. Each solution is checked legal,
# with the pin still move 0, and every square turns out to be on some
# solution. canvas_apps/chess_kit/gates/run.shale holds the output to
# QueensProof.expected beside this file.
#
# It also checks, at every step of a1's search, that each overlay means what
# it says, scrubs a1's search back and forth, and plays g8's search, the
# longest, through the page's own steps.
#
#   roc build --opt=dev QueensProof.roc --output=<bin>; <bin>
app [main!] { chess: "../chess_kit/main.roc", lib: "../lib/main.roc" }

import chess.Tape
import lib.Input
import lib.Mouse
import EightQueensApp
import Queens

main! = |arguments| {
	# A square tied to the arguments, so `roc check` doesn't run the searches.
	nothing = 0 * arguments.len().to_u8_wrap()
	var $bad = 0
	for square in List.from_iter(U8.until(0, 64)) {
		finished = searched(square + nothing)
		holds = is_legal_solution(finished, square)
		if !holds {
			$bad = $bad + 1
		}
		echo!("${square_name(square)} ${finished.move_count().to_str()} ${verdict(holds)}\n")
	}
	overlay_faults = a1_overlay_faults(0 + nothing)
	echo!("a1 overlays: ${overlay_faults.to_str()} faults\n")
	scrub_faults = a1_scrub_faults(0 + nothing)
	echo!("a1 scrubbed back and forth: ${scrub_faults.to_str()} faults\n")
	played = played_on_page(62 + nothing)
	echo!("g8 played on the page: ${played.to_str()} moves\n")
	total = $bad + overlay_faults + scrub_faults
	echo!(
		if total == 0 {
			"every pin found a solution\n"
		} else {
			"${total.to_str()} faults\n"
		},
	)
	Ok({})
}

## The search with its pin on `square` and its tape.
Run : { tape : Tape, queens : Queens }

## The search from a pin on `square`, its tape not yet stepped past the pin.
started : U8 -> Run
started = |square| { tape: Tape.start({ square, target_count: 8 }), queens: Queens.start(square) }

## The run one step on, and whether it moved.
stepped_run : Run -> { run : Run, step : [Moved, Stuck] }
stepped_run = |{ tape, queens }| {
	stepped = tape.forward({ machine: queens, next_move: Queens.next_move })
	{ run: { tape: stepped.tape, queens: stepped.machine }, step: stepped.step }
}

## The tape of the search from `square`, shown to its end.
searched : U8 -> Tape
searched = |square| {
	var $run = started(square)
	var $going = Bool.True
	while $going {
		next = stepped_run($run)
		$run = next.run
		$going = next.step == Moved
	}
	$run.tape
}

## Whether the tape ends solved, with eight queens none of which attacks
## another, and the pin on `pin` still move 0.
is_legal_solution : Tape, U8 -> Bool
is_legal_solution = |tape, pin| {
	board = tape.board()
	queens = List.from_iter(U8.until(0, 64)).keep_if(|square| (board.get(square.to_u64()) ?? crash "a square on the board") >= 0)
	no_attack = queens.all(|queen| queens.all(|other| other == queen or !(Queens.moves_from.get(queen.to_u64()) ?? crash "a square on the board").contains(other)))
	tape.search() == Solved and queens.len() == 8 and no_attack and board.get(pin.to_u64()) == Ok(0)
}

## At every step of a1's search: a square is indigo exactly when it is empty
## and a queen on the board attacks it, counted afresh here, and red exactly
## when it is empty and a retraction touched it, which needs a red to show up
## at least once.
a1_overlay_faults : U8 -> U64
a1_overlay_faults = |a1| {
	var $faults = 0
	var $seen_red = Bool.False
	var $run = started(a1)
	var $going = Bool.True
	while $going {
		board = $run.tape.board()
		impossible = Queens.impossible_squares($run.tape)
		red = $run.tape.dead_ends()
		for square in List.from_iter(U8.until(0, 64)) {
			index = square.to_u64()
			is_empty = (board.get(index) ?? crash "a square on the board") < 0
			attacked = List.from_iter(U8.until(0, 64)).any(
				|queen| (board.get(queen.to_u64()) ?? crash "a square on the board") >= 0 and (Queens.moves_from.get(queen.to_u64()) ?? crash "a square on the board").contains(square),
			)
			if (impossible.get(index) ?? crash "a square on the board") != (is_empty and attacked) {
				$faults = $faults + 1
			}
			if red.get(index) ?? crash "a square on the board" {
				$seen_red = Bool.True
				if !is_empty {
					$faults = $faults + 1
				}
			}
		}
		next = stepped_run($run)
		$run = next.run
		$going = next.step == Moved
	}
	if $seen_red {
		$faults
	} else {
		$faults + 1
	}
}

## a1's search 40 steps on, then 30 more and 30 back, shows the board it
## showed at 40; rewound all the way, even the pin comes off.
a1_scrub_faults : U8 -> U64
a1_scrub_faults = |a1| {
	var $run = started(a1)
	for _ in List.from_iter(U64.until(0, 40)) {
		$run = stepped_run($run).run
	}
	snapshot = $run.tape.board()
	for _ in List.from_iter(U64.until(0, 30)) {
		$run = stepped_run($run).run
	}
	var $tape = $run.tape
	for _ in List.from_iter(U64.until(0, 30)) {
		$tape = $tape.step_back() ?? crash "the scrub stays past the start"
	}
	same = $tape.board() == snapshot
	while $tape.cursor() > 0 {
		$tape = $tape.step_back() ?? crash "the cursor is past the start"
	}
	emptied = $tape.pieces_shown() == 0
	[same, emptied].keep_if(|holds| !holds).len()
}

## How many moves the page's tape holds after a click on `square` and play at
## the slider's top speed until the page pauses itself at the tape's end.
played_on_page : U8 -> U64
played_on_page = |square| {
	toy = EightQueensApp.canvas_app
	file = (square % 8).to_f32()
	rank = (square // 8).to_f32()
	click = Input.none.with_mouse(Mouse.of({ held: 1, struck: 1, at: { x: 58 + file * 68 + 30, y: 54 + (7 - rank) * 68 + 30 }, wheel: 0 }))
	var $model = (toy.model_at_next_step)({ ..toy.init, speed: 17 }, click, 0)
	while $model.playing == Playing {
		$model = (toy.model_at_next_step)($model, Input.none, 0)
	}
	$model.tape.move_count()
}

square_name : U8 -> Str
square_name = |square| {
	file = Str.from_utf8([97 + square % 8]) ?? crash "a file letter is ASCII"
	"${file}${(square // 8 + 1).to_str()}"
}

verdict : Bool -> Str
verdict = |holds|
	if holds {
		"solved"
	} else {
		"NOT SOLVED"
	}
