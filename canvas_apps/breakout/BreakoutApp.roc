# BreakoutApp -- Breakout as a value canvas_apps can run.
#
# Hand-written: the rules are Rules.roc with Ball, Bricks and Paddle beside it,
# the drawing is BreakoutDraw.roc, and what is left here is the keyboard, the
# clock and the sounds -- everything that lived in roc-ray's main.roc driver.
#
# `read_controls` is upstream's, word for word. Like Pong it reads HELD keys,
# so the paddle slides while an arrow is down, and the edge for SPACE.
import lib.CanvasApp
import lib.Input
import lib.Keys
import lib.Shapes
import Rules
import BreakoutDraw

BreakoutApp :: [].{
	Model : { world : Rules.World, elapsed : F64, sounds : U32 }


	canvas_app : CanvasApp.CanvasApp(BreakoutApp.Model)
	canvas_app = {
		size: { width: BreakoutDraw.w, height: BreakoutDraw.h },
		fps: 60,
		init: { world: Rules.new_world(), elapsed: 0.0, sounds: 0 },
		advance: |m, keys, dt| step(m, keys, dt),
		frame: |m| BreakoutDraw.frame(m.world, m.elapsed),
		sounds: |m| m.sounds,
		# Start, wall, paddle, brick, lost -- the five tones upstream generates.
		tones: [{ freq: 360, ms: 80 }, { freq: 220, ms: 50 }, { freq: 440, ms: 60 }, { freq: 660, ms: 45 }, { freq: 120, ms: 180 }],
		title: "Breakout",
	}

	## Translates input into paddle movement and buttons.
	##
	## **THE POINTER IS AN AIM, NOT A PUSH.** Holding the left button steers
	## the paddle to where the pointer is, which is how this game was played
	## before it had arrow keys; the keys still work and take over the moment
	## the button is let go.
	read_controls : Input.Snapshot -> Rules.Controls
	read_controls = |devices| {
		left = devices.key_down(KeyLeft) or devices.key_down(KeyA)
		right = devices.key_down(KeyRight) or devices.key_down(KeyD)
		pointer = devices.mouse
		{
			move: if left { Left } else if right { Right } else { Still },
			aim: if pointer.button_down(Left) { AimAt(pointer.position().x) } else { NoAim },
			action_pressed: devices.key_pressed(KeySpace) or pointer.button_pressed(Left)
		}
	}

	step : BreakoutApp.Model, Input.Snapshot, F32 -> BreakoutApp.Model
	step = |m, keys, dt| {
		(world, events) = Rules.update(m.world, read_controls(keys), dt)
		{ world, elapsed: m.elapsed + F32.to_f64(dt), sounds: rung(events) }
	}

	## Which tones the step set off, a bit each, in `tones` order. A cleared
	## wall rings the same tone as a start, as upstream has it.
	rung : List(Rules.Event) -> U32
	rung = |events| {
		n = List.len(events)
		var $bits = 0
		var $i = 0
		while $i < n {
			$bits = U32.bitwise_or(
				$bits,
				match List.get(events, $i) ?? GameStarted {
					GameStarted => 1
					WallHit => 2
					PaddleHit => 4
					BrickHit(_) => 8
					LifeLost(_) => 16
					WallCleared => 1
				},
			)
			$i = $i + 1
		}
		$bits
	}
}
