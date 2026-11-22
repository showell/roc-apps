# The Knight's Tour's frozen answers, natively, on Roc's echo platform. It
# runs the search from each of the 64 starts to its end and prints how many
# moves each took, which freezes the move order: a change that makes the toy
# animate differently changes a count. canvas_apps/chess_kit/gates/run.shale
# holds the output to knights_tour.expected beside this file.
#
# It also checks, at every step of e4's search, that each overlay means what
# it says, and plays g6's search, the longest, through the page's own steps
# at the slider's top speed, so a copy of the tape on each step would show as
# a run that never ends.
#
#   roc build --opt=dev KnightProof.roc --output=<bin>; <bin>
app [main!] { chess: "../chess_kit/main.roc", lib: "../lib/main.roc" }

import chess.Tape
import lib.Input
import lib.Mouse
import Knight
import KnightsTourApp

main! = |arguments| {
	# A square tied to the arguments, so `roc check` doesn't run the searches.
	nothing = 0 * arguments.len().to_u8_wrap()
	var $bad = 0
	for square in List.from_iter(U8.until(0, 64)) {
		finished = searched(square + nothing)
		if !is_full_tour(finished) {
			$bad = $bad + 1
		}
		echo!("${square_name(square)} ${finished.move_count().to_str()} ${verdict(is_full_tour(finished))}\n")
	}
	overlay_faults = e4_overlay_faults(28 + nothing)
	echo!("e4 overlays: ${overlay_faults.to_str()} faults\n")
	played = played_on_page(46 + nothing)
	echo!("g6 played on the page at the top speed: ${played.to_str()} moves\n")
	total = $bad + overlay_faults
	echo!(
		if total == 0 {
			"every start finished a tour\n"
		} else {
			"${total.to_str()} faults\n"
		},
	)
	Ok({})
}

## The tape of the search from `square`, shown to its end.
searched : U8 -> Tape
searched = |square| {
	var $tape = Tape.start({ square, target_count: 64 })
	var $knight = Knight.start(square)
	var $going = Bool.True
	while $going {
		stepped = $tape.forward({ machine: $knight, next_move: Knight.next_move })
		$tape = stepped.tape
		$knight = stepped.machine
		$going =
			match stepped.step {
				Moved => Bool.True
				Stuck => Bool.False
			}
	}
	$tape
}

## Whether the tape ends solved, with every move number from 0 to 63 on the
## board once.
is_full_tour : Tape -> Bool
is_full_tour = |tape| {
	numbers = tape.board().map(|number| number.to_i64())
	every_number = List.from_iter(I64.until(0, 64)).all(|wanted| numbers.contains(wanted))
	tape.search() == Solved and every_number
}

## At every step of e4's search: a square is red exactly when it is empty and
## a retraction touched it; an indigo square is empty, and so is each of its
## empty knight-neighbours; no empty neighbour of the newest knight is
## indigo; and the solved board has neither overlay.
e4_overlay_faults : U8 -> U64
e4_overlay_faults = |e4| {
	var $faults = 0
	var $tape = Tape.start({ square: e4, target_count: 64 })
	var $knight = Knight.start(e4)
	var $going = Bool.True
	var $seen_red = Bool.False
	var $seen_indigo = Bool.False
	while $going {
		board = $tape.board()
		impossible = Knight.impossible_squares($tape)
		red = $tape.dead_ends()
		is_empty = |square| (board.get(square.to_u64()) ?? crash "a square on the board") < 0
		is_indigo = |square| impossible.get(square.to_u64()) ?? crash "a square on the board"
		for square in List.from_iter(U8.until(0, 64)) {
			if red.get(square.to_u64()) ?? crash "a square on the board" {
				$seen_red = Bool.True
				if !is_empty(square) {
					$faults = $faults + 1
				}
			}
			if is_indigo(square) {
				$seen_indigo = Bool.True
				if !is_empty(square) {
					$faults = $faults + 1
				}
				for neighbour in Knight.moves_from.get(square.to_u64()) ?? crash "a square on the board" {
					if is_empty(neighbour) and !is_indigo(neighbour) {
						$faults = $faults + 1
					}
				}
			}
		}
		match $tape.head() {
			Ok(head) =>
				for neighbour in Knight.moves_from.get(head.to_u64()) ?? crash "a square on the board" {
					if is_empty(neighbour) and is_indigo(neighbour) {
						$faults = $faults + 1
					}
				}
			Err(EmptyBoard) => {}
		}
		stepped = $tape.forward({ machine: $knight, next_move: Knight.next_move })
		$tape = stepped.tape
		$knight = stepped.machine
		$going =
			match stepped.step {
				Moved => Bool.True
				Stuck => Bool.False
			}
	}
	end_marks = Knight.impossible_squares($tape).any(|mark| mark) or $tape.dead_ends().any(|mark| mark)
	missing_sightings =
		if $seen_red and $seen_indigo {
			0
		} else {
			1
		}
	ending_faults =
		if end_marks {
			1
		} else {
			0
		}
	$faults + missing_sightings + ending_faults
}

## How many moves the page's tape holds after a click on `square` and play at
## the slider's top speed until the page pauses itself at the tape's end.
played_on_page : U8 -> U64
played_on_page = |square| {
	tour = KnightsTourApp.canvas_app
	file = (square % 8).to_f32()
	rank = (square // 8).to_f32()
	click = Input.none.with_mouse(Mouse.of({ held: 1, struck: 1, at: { x: 58 + file * 68 + 30, y: 54 + (7 - rank) * 68 + 30 }, wheel: 0 }))
	var $model = (tour.model_at_next_step)({ ..tour.init, speed: 17 }, click, 0)
	while $model.playing == Playing {
		$model = (tour.model_at_next_step)($model, Input.none, 0)
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
		"tour"
	} else {
		"NO TOUR"
	}
