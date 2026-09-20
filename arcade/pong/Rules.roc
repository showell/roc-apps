## Pong's pure rules: the ball, the paddles, the scores, and the events a step
## reports.
##
## Ported from roc-ray's examples/pong, which keeps all of this in main.roc
## beside its drawing and its driver. The rules are lifted verbatim, tests and
## all; only the two import lines differ, because `lib.Math` and `lib.Random`
## offer what `rr.Math` and `rr.Random` offer, under the same names.
import lib.Color
import lib.Math
import lib.Random

# Upstream is one flat app file, so its definitions are wrapped here in the
# module block this dialect wants. That is an indent and nothing else.
Rules :: [].{

	## Dynamic game and presentation state advanced by the pure game step.
	Ball : {
		pos : Math.Vec2,
		velocity : Math.Vec2,
	}

	Player : {
		paddle_y : F32,
		score : U64,
	}

	World : {
		ball : Ball,
		left : Player,
		right : Player,

		## Presentation state, advanced by the same pure step as the rules.
		## `trail` is the ball's recent positions, newest first; `flash` decays from
		## 1 to 0 after a hit or a point and tints a full-screen additive wash.
		trail : List(Math.Vec2),
		flash : {
			intensity : F32,
			color : Color.Rgba,
		},

		## Simulation randomness lives in the model, so a serve is drawn on the
		## frame that needs it and a run replays exactly from its seed.
		rng : Random.State,
	}

	## Gameplay sees intentions, not the keys currently bound to them.
	Controls : {
		move : F32,
		new_match_pressed : Bool,
		quit_pressed : Bool,
	}

	## The match ends as soon as either score reaches the winning score.
	is_over : World -> Bool
	is_over = |world| world.left.score >= win_score or world.right.score >= win_score

	# --- Constants (screen is 800x600; speeds in pixels/second) ---
	screen_w = 800.F32

	screen_h = 600.F32

	paddle_w = 15.F32

	paddle_h = 100.F32

	paddle_margin = 30.F32

	ball_r = 10.F32

	paddle_speed = 360.F32

	ai_speed = 270.F32

	init_vx = 260.F32

	# vy gained per pixel of offset between ball and paddle centre on a hit
	bounce_factor = 6.F32

	# First player to this many points wins.
	win_score = 5.U64

	# The ball's comet: how many past positions to keep, and how far apart to
	# sample them.
	trail_length = 14.U64

	trail_spacing = 11.F32


	# --- Palette: one dark field, two rival neons, one warm ball ---
	field_top = Color.from_hex_rgb(0x141a35)

	field_bottom = Color.from_hex_rgb(0x05060f)

	left_neon = Color.from_hex_rgb(0x38e8ff)

	right_neon = Color.from_hex_rgb(0xff4fa3)

	ball_neon = Color.from_hex_rgb(0xffe7a3)

	hint_color = Color.from_hex_rgb(0x6d7aa8)

	# A random vertical serve speed in px/second, so each serve leaves at a
	# different angle instead of the same predictable line.
	# Drawing from the model's own generator rather than an effect keeps the serve
	# immediate: the ball leaves on the frame that scored, not the frame after.
	random_serve_vy : Random.State -> Random.Generation(F32)
	random_serve_vy = |state| {
		drawn = Random.step(state, Random.bounded_i32(-160, 160))
		{ value: I32.to_f32(drawn.value), state: drawn.state }
	}

	left_paddle : F32 -> Math.Rect
	left_paddle = |y| Math.rect(paddle_margin, y, paddle_w, paddle_h)

	right_paddle : F32 -> Math.Rect
	right_paddle = |y| Math.rect(screen_w - paddle_margin - paddle_w, y, paddle_w, paddle_h)

	ball_circle : F32, F32 -> Math.Circle
	ball_circle = |x, y| Math.circle({ x, y }, ball_r)

	## A world to start from, which upstream builds inside init! beside its
	## assets. Only new_match ever reads these values; it replaces all of them.
	opening : Random.State -> World
	opening = |rng| {
		ball: { pos: { x: screen_w * 0.5, y: screen_h * 0.5 }, velocity: { x: init_vx, y: 0 } },
		left: { paddle_y: 250, score: 0 },
		right: { paddle_y: 250, score: 0 },
		trail: [],
		flash: { intensity: 0, color: ball_neon },
		rng,
	}

	# A fresh match: ball centred, scores zeroed, served in a random direction.
	new_match : World -> World
	new_match = |world| {
		# Direction then speed, drawn in that order from one generator, so the
		# sequence is the same every time a given seed replays.
		direction = Random.step(world.rng, Random.bounded_i32(0, 1))
		serve = random_serve_vy(direction.state)
		{
			..world,
			ball: {
				pos: { x: screen_w * 0.5, y: screen_h * 0.5 },
				velocity: {
					x: if direction.value == 0 (init_vx * -1) else init_vx,
					y: serve.value,
				},
			},
			rng: serve.state,
			left: { paddle_y: 250, score: 0 },
			right: { paddle_y: 250, score: 0 },
			trail: [],
			flash: { intensity: 0, color: ball_neon },
		}
	}

	# The trail is sampled by distance, not by frame: at 240 frames a second a
	# per-frame trail would sit entirely inside the ball, and at 30 it would be a
	# dashed line. Recording only once the ball has moved `trail_spacing` pixels
	# gives the same comet at any frame rate.
	push_trail : List(Math.Vec2), Math.Vec2 -> List(Math.Vec2)
	push_trail = |trail, pos|
		match List.first(trail) {
			Ok(head) if Math.distance_squared(head, pos) < trail_spacing * trail_spacing => trail
			_ => List.take_first(List.prepend(trail, pos), trail_length)
		}

	## Significant gameplay occurrences interpreted by the application boundary.
	GameEvent := [PaddleHit, WallHit, PointScored]

	# --- Win screen: freeze the field and wait for SPACE to start a new game ---
	step_game_over : World, Controls -> (World, List(GameEvent))
	step_game_over = |world, controls| {
		next_world = if controls.new_match_pressed new_match(world) else { ..world, flash: { ..world.flash, intensity: F32.max(world.flash.intensity - 0.02, 0) } }
		(next_world, [])
	}

	# --- Active play ---
	## Play is a function of the sampled input and how much time to advance by, so
	## the caller passes both rather than a whole frame the stepper would only take
	## one field from.
	step_playing : World, Controls, F32 -> (World, List(GameEvent))
	step_playing = |world, controls, dt| {

		# --- Left paddle: semantic player movement ---
		left_y = Math.clamp(world.left.paddle_y + controls.move * paddle_speed * dt, 0, screen_h - paddle_h)

		# --- Right paddle: simple AI tracks the ball's vertical position ---
		right_center = world.right.paddle_y + paddle_h * 0.5
		right_dir = if world.ball.pos.y < right_center - 4 (ai_speed * -1) else if world.ball.pos.y > right_center + 4 ai_speed else 0
		right_y = Math.clamp(world.right.paddle_y + right_dir * dt, 0, screen_h - paddle_h)

		# --- Move ball ---
		nx0 = world.ball.pos.x + world.ball.velocity.x * dt
		ny0 = world.ball.pos.y + world.ball.velocity.y * dt

		# Bounce off top / bottom walls
		hit_top = ny0 - ball_r < 0
		hit_bottom = ny0 + ball_r > screen_h
		ny = if hit_top ball_r else if hit_bottom (screen_h - ball_r) else ny0
		vy_wall = if hit_top (world.ball.velocity.y * -1) else if hit_bottom (world.ball.velocity.y * -1) else world.ball.velocity.y

		# Paddle geometry
		left_rect = left_paddle(left_y)
		right_rect = right_paddle(right_y)
		ball_shape = ball_circle(nx0, ny)

		# Paddle collisions (reflect horizontally; set vy from where the ball struck)
		hit_left = world.ball.velocity.x < 0 and nx0 >= Math.left(left_rect) and Math.circle_rect(ball_shape, left_rect)
		hit_right = world.ball.velocity.x > 0 and nx0 <= Math.right(right_rect) and Math.circle_rect(ball_shape, right_rect)

		left_paddle_center = Math.center(left_rect).y
		right_paddle_center = Math.center(right_rect).y

		nx = if hit_left (Math.right(left_rect) + ball_r) else if hit_right (Math.left(right_rect) - ball_r) else nx0
		vx = if hit_left (world.ball.velocity.x * -1) else if hit_right (world.ball.velocity.x * -1) else world.ball.velocity.x
		vy = if hit_left ((ny - left_paddle_center) * bounce_factor) else if hit_right ((ny - right_paddle_center) * bounce_factor) else vy_wall

		# --- Scoring: ball left the field on the left or right edge ---
		out_left = nx - ball_r < 0
		out_right = nx + ball_r > screen_w
		# Draw randomness only when a new serve is actually needed.
		# The generator only advances when a serve is actually needed, so an idle
		# rally does not consume draws.
		serve = if out_left or out_right random_serve_vy(world.rng) else { value: vy, state: world.rng }

		final_ball = {
			pos: {
				x: if out_left or out_right (screen_w * 0.5) else nx,
				y: if out_left or out_right (screen_h * 0.5) else ny,
			},
			velocity: {
				x: if out_left (init_vx * -1) else if out_right init_vx else vx,
				y: if out_left or out_right serve.value else vy,
			},
		}

		left = { paddle_y: left_y, score: if out_right world.left.score + 1 else world.left.score }
		right = { paddle_y: right_y, score: if out_left world.right.score + 1 else world.right.score }

		scored = out_left or out_right
		paddled = hit_left or hit_right

		# Presentation, derived from the events this frame already computed: a point
		# flashes hard in the scorer's colour, a hit gently, and otherwise the
		# previous flash decays.
		flash_intensity =
			if scored 1.0
			else if paddled 0.45
			else if hit_top or hit_bottom 0.22
			else F32.max(world.flash.intensity - dt * 2.4, 0)
		flash_color =
			if out_right left_neon
			else if out_left right_neon
			else if hit_left left_neon
			else if hit_right right_neon
			else world.flash.color

		# A serve teleports the ball, so the trail is cleared rather than stretched
		# across the field as one long streak.
		trail = if scored [] else push_trail(world.trail, final_ball.pos)

		next = {
			..world,
			ball: final_ball,
			left: left,
			right: right,
			rng: serve.state,
			trail: trail,
			flash: { intensity: flash_intensity, color: flash_color },
		}

		# Gameplay events for this frame, in the order the boundary handles them.
		(
			next,
			List.concat(
				if hit_left or hit_right [PaddleHit] else [],
				List.concat(
					if hit_top or hit_bottom [WallHit] else [],
					if out_left or out_right [PointScored] else [],
				),
			),
		)
	}
}

## Ordinary game data and neutral controls make the simulation directly
## testable without host resources or platform input.
test_world : Rules.World
test_world = {
	ball: {
		pos: { x: Rules.screen_w * 0.5, y: Rules.screen_h * 0.5 },
		velocity: { x: Rules.init_vx, y: 0 },
	},
	left: { paddle_y: 250, score: 0 },
	right: { paddle_y: 250, score: 0 },
	trail: [],
	flash: { intensity: 0, color: Rules.ball_neon },
	rng: Random.seed(1),
}

no_controls : Rules.Controls
no_controls = { move: 0, new_match_pressed: Bool.False, quit_pressed: Bool.False }

expect !Rules.is_over(test_world)
expect Rules.is_over({ ..test_world, right: { ..test_world.right, score: Rules.win_score } })

## The top wall reflects the ball and reports one event.
expect {
	ball = {
		..test_world.ball,
		pos: { ..test_world.ball.pos, y: Rules.ball_r },
		velocity: { ..test_world.ball.velocity, y: -100 },
	}
	(world, events) = Rules.step_playing({ ..test_world, ball }, no_controls, 0.1)
	world.ball.velocity.y > 0 and List.len(events) == 1
}

## A ball past the right edge scores for the left player and re-serves from the
## centre.
expect {
	ball = { ..test_world.ball, pos: { ..test_world.ball.pos, x: Rules.screen_w - 5 } }
	(world, _) = Rules.step_playing({ ..test_world, ball }, no_controls, 0.1)
	world.left.score == 1 and world.ball.pos.x == Rules.screen_w * 0.5
}

## The win screen holds until SPACE, and SPACE starts a whole new match rather
## than resuming the old one.
expect {
	finished = { ..test_world, left: { ..test_world.left, score: Rules.win_score } }
	new_match_controls = { ..no_controls, new_match_pressed: Bool.True }
	(waiting_world, _) = Rules.step_game_over(finished, no_controls)
	(restarted_world, _) = Rules.step_game_over(finished, new_match_controls)
	waiting_world.left.score == Rules.win_score and restarted_world.left.score == 0
}
