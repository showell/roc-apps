## PongApp is Pong as a value canvas_apps can run.
##
## The module is written by hand. The rules are Rules.roc and the drawing is
## PongDraw.roc, so what is left here is the keyboard, the clock and the
## sounds.
##
## `read_controls` reads a held key: the paddle moves for as long as W or S is
## down, where Snake only asks whether a key was struck. So both halves of an
## input snapshot carry something.
import lib.CanvasApp
import lib.Input
import lib.Random
import Rules
import PongDraw

PongApp :: [].{
	Model : { world : Rules.World, sounds : U32 }

	canvas_app : CanvasApp.CanvasApp(PongApp.Model)
	canvas_app = {
		size: { width: 800.0, height: 600.0 },
		frames_a_second: 60,
		init: { world: Rules.new_match(Rules.opening(Random.seed(7))), sounds: 0 },
		model_at_next_step: |model, keys, dt| step(model, keys, dt),
		frame_shapes: |model| PongDraw.frame_shapes(model.world),
		sounds: |model| model.sounds,
		# Paddle, wall, point -- the three tones upstream generates.
		tones: [{ hertz: 440, milliseconds: 60 }, { hertz: 220, milliseconds: 50 }, { hertz: 160, milliseconds: 200 }],
		title: "Pong",
	}

	## Translates input into paddle movement and buttons.
	##
	## **THE POINTER IS AN AIM, NOT A PUSH.** Holding the left button puts the
	## paddle where you point; W and S still push it and take over the moment
	## the button is let go.
	read_controls : Input.Snapshot -> Rules.Controls
	read_controls = |devices| {
		pointer = devices.mouse
		{
			move: if devices.key_down(KeyW) {
				-1
			} else if devices.key_down(KeyS) {
				1
			} else {
				0
			},
			aim: if pointer.button_down(Left) {
				AimAt(pointer.position().y)
			} else {
				NoAim
			},
			new_match_pressed: devices.key_pressed(KeySpace) or pointer.button_pressed(Left),
		}
	}

	step : PongApp.Model, Input.Snapshot, F32 -> PongApp.Model
	step = |model, keys, dt| {
		controls = read_controls(keys)
		(world, events) = if Rules.is_over(model.world) {
			Rules.step_game_over(model.world, controls)
		} else {
			Rules.step_playing(model.world, controls, dt)
		}
		{ world, sounds: rung(events) }
	}

	## Which tones the step set off, a bit each, in `tones` order.
	rung : List(Rules.GameEvent) -> U32
	rung = |events| {
		event_count = List.len(events)
		var $bits = 0
		var $i = 0
		while $i < event_count {
			$bits = U32.bitwise_or(
				$bits,
				match List.get(events, $i) ?? PaddleHit {
					PaddleHit => 1
					WallHit => 2
					PointScored => 4
				},
			)
			$i = $i + 1
		}
		$bits
	}
}
