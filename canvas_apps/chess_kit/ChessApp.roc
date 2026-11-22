## ChessApp turns a chess toy into a canvas app. A toy is a search machine
## that answers four questions: how many pieces mean solved, its next move,
## how it starts from a clicked square, and which squares no piece can live
## on right now. The rest is shared: the tape the machine writes, the board
## that replays it, the transport row and the keys.
##
## A click on a square starts a search there and plays it. Play and rewind
## walk the tape at the slider's rate, and stop at either end; a step button,
## or the Left and Right keys, pauses and moves one step; Space plays or
## pauses. A held key repeats, after half a second, thirty times a second, as
## a browser's key repeat does.
import lib.Brush
import lib.CanvasApp
import lib.Input
import lib.Pixels
import lib.Point
import lib.Shapes
import ChessBoard
import ChessControls
import Tape

ChessApp :: [].{

	## The words a toy's page uses.
	Words : {
		title : Str,
		piece : Str,
		noun : Str,
		one_noun : Str,
		hover_hint : Str,
		click_hint : Str,
		start_hint : Str,
		indigo_hint : Str,
		solved_message : Str,
		exhausted_message : Str,
	}

	## A toy: its machine's four answers, the squares a piece on each square
	## reaches, which the hover marks, and its words.
	Toy(machine) : {
		target_count : U64,
		next_move : machine -> (machine, Tape.Move),
		start : U8 -> machine,
		impossible_squares : Tape -> List(Bool),
		moves_from : List(List(U8)),
		words : ChessApp.Words,
	}

	## A toy's page at one step. `owed` banks the slider's rate each step, in
	## sixtieths of a move, so the moves a step takes come out exact.
	Model(machine) : {
		tape : Tape,
		machine : [Unstarted, Started(machine)],
		playing : [Paused, Playing, Rewinding],
		speed : U64,
		owed : U64,
		hover : [Over(U8), Away],
		slider : [Held, Free],
		keys_held : { space : U64, left : U64, right : U64 },
	}

	## The toy as a canvas app.
	canvas_app : ChessApp.Toy(machine) -> CanvasApp.CanvasApp(ChessApp.Model(machine))
	canvas_app = |toy| {
		size: { width: ChessControls.width, height: ChessControls.height },
		frames_a_second: steps_a_second,
		init: {
			tape: Tape.empty,
			machine: Unstarted,
			playing: Paused,
			speed: 3,
			owed: 0,
			hover: Away,
			slider: Free,
			keys_held: { space: 0, left: 0, right: 0 },
		},
		model_at_next_step: CanvasApp.untimed_model_at_next_step(|model, input| ChessApp.model_at_next_step(toy, { model, input })),
		frame_shapes: |model| ChessApp.frame_shapes(toy, model),
		sounds: |_model| 0,
		tones: [],
		title: toy.words.title,
	}

	## One step: the pointer, the slider, a click, the keys, then the moves
	## the rate owes.
	model_at_next_step : ChessApp.Toy(machine), { model : ChessApp.Model(machine), input : Input.Snapshot } -> ChessApp.Model(machine)
	model_at_next_step = |toy, { model, input }| {
		pointer = input.mouse.position()
		pressed = input.mouse.button_pressed(Left)
		down = input.mouse.button_down(Left)
		hover =
			match ChessBoard.square_at(pointer) {
				Ok(square) => Over(square)
				Err(OffBoard) => Away
			}
		spot = ChessControls.spot_at(pointer)
		slider =
			match (pressed, spot) {
				(Bool.True, OnSlider) => Held
				_ =>
					if down {
						model.slider
					} else {
						Free
					}
			}
		speed =
			match slider {
				Held => ChessControls.speed_at(pointer)
				Free => model.speed
			}
		pointed = { ..model, hover, slider, speed }
		clicked =
			if pressed {
				match (hover, spot) {
					(Over(square), _) => act(toy, { model: pointed, action: Start(square) })
					(Away, OnButton(button)) => act(toy, { model: pointed, action: button_action(button) })
					(Away, OnSlider) | (Away, Elsewhere) => pointed
				}
			} else {
				pointed
			}
		keyed = keys_acted(toy, { model: clicked, input })
		moves_played(toy, keyed)
	}

	## What the page shows.
	frame_shapes : ChessApp.Toy(machine), ChessApp.Model(machine) -> List(Shapes.Shape)
	frame_shapes = |toy, model| {
		tape = model.tape
		words = toy.words
		List.join([
			[background],
			ChessBoard.board_shapes({
				board: tape.board(),
				pieces_shown: tape.pieces_shown(),
				dead_ends: tape.dead_ends(),
				impossible: (toy.impossible_squares)(tape),
				hover: model.hover,
				moves_from: toy.moves_from,
				piece: words.piece,
			}),
			ChessControls.controls_shapes({
				title: words.title,
				status: ChessApp.status_line(words, tape),
				hint: "hover · ${words.hover_hint}    click · ${words.click_hint}    SPACE play/pause · ←/→ step",
				legend: "red · a ${words.one_noun} was retracted here    indigo · ${words.indigo_hint}",
				playing: model.playing,
				speed: model.speed,
			}),
		])
	}

	## The line under the board: how many pieces of the target are shown,
	## where the cursor is on the tape and how long the tape is when they
	## differ, the deepest the search has gone, and at the tape's end whether
	## it is solved or spent.
	status_line : ChessApp.Words, Tape -> Str
	status_line = |words, tape|
		match tape.search() {
			Waiting => words.start_hint
			Running | Solved | Exhausted => {
				cursor = tape.cursor()
				length = tape.move_count()
				tail =
					if cursor < length {
						" / ${ChessControls.grouped(length)}"
					} else {
						""
					}
				ending =
					if cursor == length {
						match tape.search() {
							Solved => " — ${words.solved_message}"
							Exhausted => " — ${words.exhausted_message}"
							Waiting | Running => ""
						}
					} else {
						""
					}
				"${tape.pieces_shown().to_str()}/${tape.target_count().to_str()} ${words.noun} · step ${ChessControls.grouped(cursor)}${tail} · deepest ${tape.deepest().to_str()}${ending}"
			}
		}
}

## The page steps sixty times a second.
steps_a_second : U32
steps_a_second = 60

## What a click, a button or a key asks for.
Action : [Start(U8), ToggleRewind, StepBack, TogglePlay, StepForward]

button_action : ChessControls.Button -> Action
button_action = |button|
	match button {
		Rewind => ToggleRewind
		StepBack => StepBack
		Play => TogglePlay
		StepForward => StepForward
	}

## The model after an action. A change of playing drops what the rate owed.
act : ChessApp.Toy(machine), { model : ChessApp.Model(machine), action : Action } -> ChessApp.Model(machine)
act = |toy, { model, action }|
	match action {
		Start(square) =>
			{
				..model,
				tape: Tape.start({ square, target_count: toy.target_count }),
				machine: Started((toy.start)(square)),
				playing: Playing,
				owed: 0,
			}
		ToggleRewind =>
			match model.playing {
				Rewinding => { ..model, playing: Paused, owed: 0 }
				Paused | Playing => { ..model, playing: Rewinding, owed: 0 }
			}
		TogglePlay =>
			match model.playing {
				Playing => { ..model, playing: Paused, owed: 0 }
				Paused | Rewinding => { ..model, playing: Playing, owed: 0 }
			}
		StepBack => {
			paused = { ..model, playing: Paused, owed: 0 }
			match paused.tape.step_back() {
				Ok(tape) => { ..paused, tape }
				Err(AtStart) => paused
			}
		}
		StepForward => forward_one(toy, { ..model, playing: Paused, owed: 0 }).model
	}

## The model one move forward, and whether it moved.
forward_one : ChessApp.Toy(machine), ChessApp.Model(machine) -> { model : ChessApp.Model(machine), step : [Moved, Stuck] }
forward_one = |toy, model|
	match model.machine {
		Unstarted => { model, step: Stuck }
		Started(machine) => {
			stepped = model.tape.forward({ machine, next_move: toy.next_move })
			{ model: { ..model, tape: stepped.tape, machine: Started(stepped.machine) }, step: stepped.step }
		}
	}

## The steps a held key has been down, and whether it fires this step: when
## it goes down, then after half a second every second step.
key_repeat : { held_steps : U64, is_down : Bool, is_struck : Bool } -> { held_steps : U64, fires : Bool }
key_repeat = |{ held_steps, is_down, is_struck }| {
	steps =
		if is_struck {
			1
		} else if is_down {
			held_steps + 1
		} else {
			0
		}
	fires = steps == 1 or (steps > repeat_delay_steps and (steps - repeat_delay_steps) % repeat_every_steps == 0)
	{ held_steps: steps, fires }
}

## Half a second of steps before a held key repeats.
repeat_delay_steps : U64
repeat_delay_steps = 30

## A held key repeats every second step, thirty times a second.
repeat_every_steps : U64
repeat_every_steps = 2

## The model after the keys: Space plays or pauses, Left and Right pause and
## step, each held key repeating.
keys_acted : ChessApp.Toy(machine), { model : ChessApp.Model(machine), input : Input.Snapshot } -> ChessApp.Model(machine)
keys_acted = |toy, { model, input }| {
	space = key_repeat({ held_steps: model.keys_held.space, is_down: input.key_down(KeySpace), is_struck: input.key_pressed(KeySpace) })
	left = key_repeat({ held_steps: model.keys_held.left, is_down: input.key_down(KeyLeft), is_struck: input.key_pressed(KeyLeft) })
	right = key_repeat({ held_steps: model.keys_held.right, is_down: input.key_down(KeyRight), is_struck: input.key_pressed(KeyRight) })
	fired = [(space.fires, TogglePlay), (right.fires, StepForward), (left.fires, StepBack)]
	var $acted = { ..model, keys_held: { space: space.held_steps, left: left.held_steps, right: right.held_steps } }
	for (fires, action) in fired {
		if fires {
			$acted = act(toy, { model: $acted, action })
		}
	}
	$acted
}

## The model after the moves the rate owes this step, playing forward or
## rewinding. Reaching either end of the tape pauses.
moves_played : ChessApp.Toy(machine), ChessApp.Model(machine) -> ChessApp.Model(machine)
moves_played = |toy, model|
	match model.playing {
		Paused => model
		Playing | Rewinding => {
			banked = model.owed + ChessControls.steps_a_second(model.speed)
			due = banked // steps_a_second.to_u64()
			var $played = { ..model, owed: banked % steps_a_second.to_u64() }
			var $left = due
			while $left > 0 {
				match $played.playing {
					Playing => {
						stepped = forward_one(toy, $played)
						$played = stepped.model
						$left =
							match stepped.step {
								Moved => $left - 1
								Stuck => 0
							}
						$played =
							match stepped.step {
								Moved => $played
								Stuck => { ..$played, playing: Paused, owed: 0 }
							}
					}
					Rewinding =>
						match $played.tape.step_back() {
							Ok(tape) => {
								$played = { ..$played, tape }
								$left = $left - 1
							}
							Err(AtStart) => {
								$played = { ..$played, playing: Paused, owed: 0 }
								$left = 0
							}
						}
					Paused => {
						$left = 0
					}
				}
			}
			$played
		}
	}

## The page's dark ground, under everything.
background : Shapes.Shape
background = Shapes.rectangle({
	top_left: Point.at(0.0, 0.0),
	width: Pixels.of(ChessControls.width),
	height: Pixels.of(ChessControls.height),
	fill: Flat(ground),
})

ground : Brush.Rgba
ground = { r: 11.0, g: 11.0, b: 13.0, a: 1.0 }
