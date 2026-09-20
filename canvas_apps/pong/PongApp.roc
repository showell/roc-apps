# PongApp -- Pong as a value canvas_apps can run.
#
# Hand-written: the rules are Rules.roc and the drawing is PongDraw.roc, so
# what is left here is the keyboard, the clock and the sounds -- everything
# that lived in roc-ray's main.roc driver.
#
# `read_controls` is upstream's, word for word. **IT IS THE FIRST HERE TO READ
# A HELD KEY**: the paddle moves for as long as W or S is down, where Snake
# only ever asks whether a key was struck. Both halves of a snapshot are now
# carrying something.
import lib.CanvasApp
import lib.Input
import lib.Keys
import lib.Random
import lib.Shapes
import Rules
import PongDraw

PongApp :: [].{
	Model : { world : Rules.World, sounds : U32 }


	canvas_app : CanvasApp.CanvasApp(PongApp.Model)
	canvas_app = {
		size: { width: 800.0, height: 600.0 },
		fps: 60,
		init: { world: Rules.new_match(Rules.opening(Random.seed(7))), sounds: 0 },
		advance: |m, keys, dt| step(m, keys, dt),
		frame: |m| PongDraw.frame(m.world),
		sounds: |m| m.sounds,
		# Paddle, wall, point -- the three tones upstream generates.
		tones: [{ freq: 440, ms: 60 }, { freq: 220, ms: 50 }, { freq: 160, ms: 200 }],
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
			move: if devices.key_down(KeyW) { -1 } else if devices.key_down(KeyS) { 1 } else { 0 },
			aim: if pointer.button_down(Left) { AimAt(pointer.position().y) } else { NoAim },
			new_match_pressed: devices.key_pressed(KeySpace) or pointer.button_pressed(Left),
		}
	}

	step : PongApp.Model, Input.Snapshot, F32 -> PongApp.Model
	step = |m, keys, dt| {
		controls = read_controls(keys)
		(world, events) = if Rules.is_over(m.world) {
			Rules.step_game_over(m.world, controls)
		} else {
			Rules.step_playing(m.world, controls, dt)
		}
		{ world, sounds: rung(events) }
	}

	## Which tones the step set off, a bit each, in `tones` order.
	rung : List(Rules.GameEvent) -> U32
	rung = |events| {
		n = List.len(events)
		var $bits = 0
		var $i = 0
		while $i < n {
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
