# PongGame -- Pong as a value the arcade can run.
#
# Hand-written: the rules are Rules.roc and the drawing is PongDraw.roc, so
# what is left here is the keyboard, the clock and the sounds -- everything
# that lived in roc-ray's main.roc driver.
#
# `read_controls` is upstream's, word for word. **IT IS THE FIRST HERE TO READ
# A HELD KEY**: the paddle moves for as long as W or S is down, where Snake
# only ever asks whether a key was struck. Both halves of a snapshot are now
# carrying something.
import lib.Game
import lib.Keys
import lib.Random
import lib.Shapes
import Rules
import PongDraw

PongGame :: [].{
	Model : { world : Rules.World, sounds : U32 }

	# A fixed sixtieth, so a rally is a function of the ticks and the keys.
	step_dt : F32
	step_dt = 0.016666666666666666

	game : Game.Game(PongGame.Model)
	game = {
		size: { width: 800.0, height: 600.0 },
		fps: 60,
		init: { world: Rules.new_match(Rules.opening(Random.seed(7))), sounds: 0 },
		advance: |m, keys| step(m, keys),
		frame: |m| PongDraw.frame(m.world),
		sounds: |m| m.sounds,
		# Paddle, wall, point -- the three tones upstream generates.
		tones: [{ freq: 440, ms: 60 }, { freq: 220, ms: 50 }, { freq: 160, ms: 200 }],
		title: "Pong",
		stem: "pong",
	}

	## Translates keyboard bindings into paddle movement and buttons.
	read_controls : Keys.Snapshot -> Rules.Controls
	read_controls = |devices| {
		move: if devices.key_down(KeyW) -1 else if devices.key_down(KeyS) 1 else 0,
		new_match_pressed: devices.key_pressed(KeySpace),
		quit_pressed: devices.key_pressed(KeyEscape),
	}

	step : PongGame.Model, Keys.Snapshot -> PongGame.Model
	step = |m, keys| {
		controls = read_controls(keys)
		(world, events) = if Rules.is_over(m.world) {
			Rules.step_game_over(m.world, controls)
		} else {
			Rules.step_playing(m.world, controls, step_dt)
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
