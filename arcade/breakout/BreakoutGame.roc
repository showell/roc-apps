# BreakoutGame -- Breakout as a value the arcade can run.
#
# Hand-written: the rules are Rules.roc with Ball, Bricks and Paddle beside it,
# the drawing is BreakoutDraw.roc, and what is left here is the keyboard, the
# clock and the sounds -- everything that lived in roc-ray's main.roc driver.
#
# `read_controls` is upstream's, word for word. Like Pong it reads HELD keys,
# so the paddle slides while an arrow is down, and the edge for SPACE.
import lib.Game
import lib.Keys
import lib.Shapes
import Rules
import BreakoutDraw

BreakoutGame :: [].{
	Model : { world : Rules.World, elapsed : F64, sounds : U32 }


	game : Game.Game(BreakoutGame.Model)
	game = {
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

	## Translates keyboard bindings into paddle movement and buttons.
	read_controls : Keys.Snapshot -> Rules.Controls
	read_controls = |devices| {
		left = devices.key_down(KeyLeft) or devices.key_down(KeyA)
		right = devices.key_down(KeyRight) or devices.key_down(KeyD)
		{
			move: if left { Left } else if right { Right } else { Still },
			action_pressed: devices.key_pressed(KeySpace)
		}
	}

	step : BreakoutGame.Model, Keys.Snapshot, F32 -> BreakoutGame.Model
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
