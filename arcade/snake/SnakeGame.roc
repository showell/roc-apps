# SnakeGame -- Snake as a value the arcade can run.
#
# Hand-written, and small on purpose: the rules are Rules.roc, the drawing is
# SnakeDraw.roc, and what is left here is the keyboard, the clock and the
# sounds -- everything that used to live in roc-ray's main.roc driver.
#
# `read_controls` is the port's whole point. Upstream it takes a
# `Devices.Snapshot`; here it takes a `Keys.Snapshot`, which is shaped the same
# on purpose, so the function below is the upstream one with its type changed
# and nothing else.
import Game
import Keys
import Random
import Shapes
import Rules
import SnakeDraw

SnakeGame :: [].{
	Model : { world : Rules.World, elapsed : F64, sounds : U32 }

	# A fixed sixtieth, so the rules are a function of the ticks and the keys
	# rather than of how long a frame happened to take.
	step_dt : F32
	step_dt = 0.016666666666666666

	game : Game.Game(SnakeGame.Model)
	game = {
		size: { width: SnakeDraw.screen_w, height: SnakeDraw.screen_h },
		fps: 60,
		init: { world: Rules.new_world(Random.seed(1)), elapsed: 0.0, sounds: 0 },
		advance: |m, keys| step(m, keys),
		frame: |m| SnakeDraw.frame(m.world, m.elapsed),
		sounds: |m| m.sounds,
		# Eaten, crashed, started -- the three tones upstream generates.
		tones: [{ freq: 620, ms: 70 }, { freq: 120, ms: 180 }, { freq: 360, ms: 80 }],
		title: "Snake",
		stem: "snake",
	}

	## Translates keyboard bindings into a requested Snake turn and buttons.
	read_controls : Keys.Snapshot -> Rules.Controls
	read_controls = |devices| {
		requested_direction =
			if devices.key_pressed(KeyUp) or devices.key_pressed(KeyW) {
				Turn(Up)
			} else if devices.key_pressed(KeyDown) or devices.key_pressed(KeyS) {
				Turn(Down)
			} else if devices.key_pressed(KeyLeft) or devices.key_pressed(KeyA) {
				Turn(Left)
			} else if devices.key_pressed(KeyRight) or devices.key_pressed(KeyD) {
				Turn(Right)
			} else {
				KeepDirection
			}
		{ requested_direction, restart_pressed: devices.key_pressed(KeySpace), quit_pressed: devices.key_pressed(KeyEscape) }
	}

	step : SnakeGame.Model, Keys.Snapshot -> SnakeGame.Model
	step = |m, keys| {
		controls = read_controls(keys)
		(world, events) = Rules.update(m.world, controls, step_dt)
		{ world, elapsed: m.elapsed + 0.016666666666666666, sounds: rung(events, 0) }
	}

	## Which tones the step set off, a bit each, in `tones` order.
	rung : List(Rules.Event), U32 -> U32
	rung = |events, so_far| {
		n = List.len(events)
		var $bits = so_far
		var $i = 0
		while $i < n {
			$bits = U32.bitwise_or(
				$bits,
				match List.get(events, $i) ?? FoodEaten {
					FoodEaten => 1
					SnakeCrashed => 2
					GameStarted => 4
				},
			)
			$i = $i + 1
		}
		$bits
	}
}
