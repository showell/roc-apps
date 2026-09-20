# Rules -- roc-ray's examples/camera, its world and its update.
#
# Upstream's `axis`, `move_player` and the body of its `update!` are here
# unchanged but for their import lines and the `Exit` that belongs to a runner.
# Its expects came across word for word, which is the point: a snapshot is a
# value on both platforms, so a test that drives a game on one drives it on the
# other.
#
# **THE CAMERA IS BUILT FROM THE WORLD, NOT STORED IN IT.** Upstream says why:
# calculated values kept beside the values they are calculated from can
# disagree with them. Here it earns a second keep -- the drawing wants the
# camera and so does the pointer arithmetic, and both get the same one.
import lib.Camera
import lib.Input
import lib.Math
import lib.Mouse

Rules :: [].{
	World : {
		player : Math.Vec2,
		zoom : F32,
		rotation : F32,
		mouse : Math.Vec2,
	}

	screen : Math.Vec2
	screen = { x: 800, y: 600 }

	# The world is three times the screen each way, and the screen starts in
	# the middle of it. Nothing here is clamped to the screen: that is what
	# makes it a world rather than a board.
	world_left : F32
	world_left = -800
	world_right : F32
	world_right = 1600
	world_top : F32
	world_top = -600
	world_bottom : F32
	world_bottom = 1200

	start : Rules.World
	start = { player: { x: 400, y: 300 }, zoom: 1, rotation: 0, mouse: { x: 0, y: 0 } }

	## What a camera at the world's current settings sees it through.
	eye : Rules.World -> Camera.Camera2D
	eye = |world|
		Camera.follow(world.player, { screen, zoom: world.zoom }).with_rotation(world.rotation)

	axis : Bool, Bool -> F32
	axis = |negative, positive| if negative { -1 } else if positive { 1 } else { 0 }

	## Moves the player from the current keyboard state and elapsed time.
	## Passing only these values keeps the movement rules easy to test
	## separately.
	move_player : Math.Vec2, Input.Snapshot, F32 -> Math.Vec2
	move_player = |player, input, dt| {
		left = input.key_down(KeyLeft) or input.key_down(KeyA)
		right = input.key_down(KeyRight) or input.key_down(KeyD)
		up = input.key_down(KeyUp) or input.key_down(KeyW)
		down = input.key_down(KeyDown) or input.key_down(KeyS)

		speed = 360
		{
			x: Math.clamp(player.x + axis(left, right) * speed * dt, world_left + 40, world_right - 40),
			y: Math.clamp(player.y + axis(up, down) * speed * dt, world_top + 40, world_bottom - 40),
		}
	}

	## One tick: the player moves, the wheel zooms, Q and E turn, R levels.
	##
	## **THE POINTER IS KEPT IN SCREEN PIXELS.** Where it is in the world
	## depends on the camera, and the camera is built from this world, so
	## storing the world position would be storing the answer to a question
	## whose terms change in the same step.
	step : Rules.World, Input.Snapshot, F32 -> Rules.World
	step = |world, input, dt| {
		pointer = input.mouse
		player = move_player(world.player, input, dt)
		zoom = Math.clamp(world.zoom + pointer.wheel * 0.1, 0.5, 2.5)
		turn = axis(input.key_down(KeyQ), input.key_down(KeyE))
		rotation = if input.key_pressed(KeyR) { 0 } else { world.rotation + turn * 90 * dt }
		{ player, zoom, rotation, mouse: pointer.position() }
	}
}

expect Rules.axis(Bool.True, Bool.False) == -1
expect Rules.axis(Bool.False, Bool.False) == 0

# Movement integrates over the seconds it is handed, and stops at the world
# edge rather than running off it.
expect Rules.move_player({ x: 0, y: 0 }, Input.none.with_key_down(KeyD), 0.5) == { x: 180, y: 0 }
expect Rules.move_player({ x: Rules.world_right, y: 0 }, Input.none.with_key_down(KeyD), 1) == { x: Rules.world_right - 40, y: 0 }

# The wheel zooms, and stops at the limits rather than turning the world inside
# out. A snapshot is a value, so saying "the wheel turned" is writing it down.
expect Rules.step(Rules.start, Input.none.with_mouse(Mouse.of(0, 0, 0, 0, 3)), 0).zoom == 1.3
expect Rules.step({ ..Rules.start, zoom: 2.4 }, Input.none.with_mouse(Mouse.of(0, 0, 0, 0, 9)), 0).zoom == 2.5

# R levels a turned camera, which is what upstream's reset does.
expect Rules.step({ ..Rules.start, rotation: 42 }, Input.none.with_key_pressed(KeyR), 0.1).rotation == 0
