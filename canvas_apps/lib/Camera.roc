## Camera is a 2D camera as a value, with roc-ray's own name and surface. A game
## ported from a roc-ray example says `import lib.Camera` in place of
## `import rr.Camera`, as it does for Keys, Math and Random, and every `Camera.`
## in it stays as it is. Only what a game here asks for is written; roc-ray's
## camera does more.
##
## A camera does two jobs, and both are here. It is arithmetic the game itself
## needs: `screen_to_world` turns a pointer in pixels into a point in the world,
## which no runner can answer for the game. It is also the space a frame's
## shapes can be put in, which is `space`. None of it is an effect.
##
## Pixels are F32, because the examples are written in F32. `space` widens them
## to the F64 a frame is made of.
import Math
import Point
import Shapes
import Trig

Camera :: [].{

	## What a frame is looked at through: the world point `target`, placed at
	## the screen point `offset`, turned clockwise by `rotation` degrees and
	## scaled by `zoom`. roc-ray names this type too. Every value is finite
	## and the zoom is never zero, which `new` and `with_rotation` check.
	Camera2D :: {
		target : Math.Vec2,
		offset : Math.Vec2,
		rotation : F32,
		zoom : F32,
	}.{

		with_rotation : Camera2D, F32 -> Camera2D
		with_rotation = |camera, new_rotation| { ..camera, rotation: finite_scalar(new_rotation) }

		## A world point, in screen pixels. Rotation is in degrees, as raylib
		## and the canvas both take it.
		world_to_screen : Camera2D, Math.Vec2 -> Math.Vec2
		world_to_screen = |camera, world| {
			radians = camera.rotation * Trig.degree.to_f32_wrap()
			cosine = radians.cos()
			sine = radians.sin()
			dx = world.x - camera.target.x
			dy = world.y - camera.target.y
			{
				x: (dx * cosine - dy * sine) * camera.zoom + camera.offset.x,
				y: (dx * sine + dy * cosine) * camera.zoom + camera.offset.y,
			}
		}

		## A screen point, in the world. This is why a camera is a value the
		## game holds rather than a scope a runner opens: the pointer arrives
		## in pixels and the rules are written in the world, so somebody has to
		## do this arithmetic, and only the game knows which camera to do it
		## with. Every camera here is invertible, because no constructor lets a
		## zoom of zero through.
		screen_to_world : Camera2D, Math.Vec2 -> Math.Vec2
		screen_to_world = |camera, screen| {
			radians = 0 - camera.rotation * Trig.degree.to_f32_wrap()
			cosine = radians.cos()
			sine = radians.sin()
			dx = (screen.x - camera.offset.x) / camera.zoom
			dy = (screen.y - camera.offset.y) / camera.zoom
			{
				x: camera.target.x + dx * cosine - dy * sine,
				y: camera.target.y + dx * sine + dy * cosine,
			}
		}

		## The world this camera can see on a screen of that size, as an
		## upright rectangle. All four corners, because a rotated camera's
		## bounds are not either diagonal.
		viewport : Camera2D, Math.Vec2 -> Math.Rect
		viewport = |camera, screen| {
			top_left = camera.screen_to_world(Math.zero)
			top_right = camera.screen_to_world({ x: screen.x, y: 0 })
			bottom_left = camera.screen_to_world({ x: 0, y: screen.y })
			bottom_right = camera.screen_to_world(screen)
			left = top_left.x.min(top_right.x).min(bottom_left.x.min(bottom_right.x))
			right = top_left.x.max(top_right.x).max(bottom_left.x.max(bottom_right.x))
			top = top_left.y.min(top_right.y).min(bottom_left.y.min(bottom_right.y))
			bottom = top_left.y.max(top_right.y).max(bottom_left.y.max(bottom_right.y))
			Math.rect(left, top, right - left, bottom - top)
		}

		## This camera's world, as the space `Shapes.shapes_in_space` puts shapes in.
		space : Camera2D -> Shapes.Space
		space = |camera|
			Shapes.world_space({
				target: point_of_vec2(camera.target),
				offset: point_of_vec2(camera.offset),
				rotation: camera.rotation.to_f64(),
				zoom: camera.zoom.to_f64(),
			})
	}

	## A camera, its numbers checked: a value that is not finite, or a zoom of
	## zero, crashes.
	new : { target : Math.Vec2, offset : Math.Vec2, rotation : F32, zoom : F32 } -> Camera.Camera2D
	new = |{ target, offset, rotation, zoom }|
		{
			target: finite_vec(target),
			offset: finite_vec(offset),
			rotation: finite_scalar(rotation),
			zoom: invertible_zoom(zoom),
		}

	## The player-follow camera: `target` in the middle of a screen of that
	## size, at a zoom.
	follow : Math.Vec2, { screen : Math.Vec2, zoom : F32 } -> Camera.Camera2D
	follow = |target, { screen, zoom }|
		new({ target, offset: { x: screen.x / 2, y: screen.y / 2 }, rotation: 0, zoom })
}

## `v`, widened to the F64 a frame is made of.
point_of_vec2 : Math.Vec2 -> Point.Point
point_of_vec2 = |v| { x: v.x.to_f64(), y: v.y.to_f64() }

# A number that is not finite has no place on a camera, and comes only from a
# bug in the game.
finite_scalar : F32 -> F32
finite_scalar = |value|
	if value.is_finite() {
		value
	} else {
		crash "Camera: a camera's number is not finite"
	}

finite_vec : Math.Vec2 -> Math.Vec2
finite_vec = |v| { x: finite_scalar(v.x), y: finite_scalar(v.y) }

# A zoom of zero has no inverse, so screen_to_world could not undo it.
invertible_zoom : F32 -> F32
invertible_zoom = |zoom|
	if zoom == 0 {
		crash "Camera: a zoom of zero has no inverse"
	} else {
		finite_scalar(zoom)
	}

# A point taken into the world and back is the point it started as.
expect {
	camera = Camera.new({ target: { x: 120, y: -40 }, offset: { x: 400, y: 300 }, rotation: 37, zoom: 2.5 })
	there = camera.screen_to_world({ x: 210, y: 160 })
	back = camera.world_to_screen(there)
	(back.x - 210).abs() < 0.01 and (back.y - 160).abs() < 0.01
}

# A follow camera puts its target under the middle of the screen.
expect Camera.follow({ x: 900, y: 700 }, { screen: { x: 800, y: 600 }, zoom: 2 }).world_to_screen({ x: 900, y: 700 })
	== { x: 400, y: 300 }
