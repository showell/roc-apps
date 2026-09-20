# Camera -- a 2D camera as a value, under roc-ray's own name and surface.
#
# Hand-written, the same trick as Keys, Math, Color and Random: a game ported
# from an example says `import lib.Camera` instead of `import rr.Camera` and
# every `Camera.` in it is left alone. Only what a game here asks for is
# implemented; roc-ray's is larger.
#
# **A CAMERA IS TWO THINGS AND THEY ARE BOTH HERE.** It is arithmetic the game
# itself needs -- `screen_to_world` is how a pointer in pixels becomes a point
# in the world, and no runner can answer that for it -- and it is a mark in a
# frame saying where the shapes after it are. `view` is the second; everything
# else is the first, and none of it is an effect.
#
# Pixels in F32, because that is what the examples are written in. `view`
# widens to the F64 a frame is made of.
import Math
import Shapes

Camera :: [].{
	## Target, screen offset, clockwise rotation in degrees, and zoom factor.
	Settings : {
		target : Math.Vec2,
		offset : Math.Vec2,
		rotation : F32,
		zoom : F32,
	}

	## What a frame is looked at through. roc-ray names this type too.
	Camera2D :: {
		target : Math.Vec2,
		offset : Math.Vec2,
		rotation : F32,
		zoom : F32,
	}.{
		## World-space point placed at the camera offset.
		target : Camera2D -> Math.Vec2
		target = |camera| camera.target

		## Screen-space offset the target is placed at.
		offset : Camera2D -> Math.Vec2
		offset = |camera| camera.offset

		## Clockwise rotation, in degrees.
		rotation : Camera2D -> F32
		rotation = |camera| camera.rotation

		## Zoom factor. Negative mirrors both axes; zero cannot occur.
		zoom : Camera2D -> F32
		zoom = |camera| camera.zoom

		with_target : Camera2D, Math.Vec2 -> Camera2D
		with_target = |camera, new_target| { ..camera, target: sane_vec(new_target) }

		with_offset : Camera2D, Math.Vec2 -> Camera2D
		with_offset = |camera, new_offset| { ..camera, offset: sane_vec(new_offset) }

		with_rotation : Camera2D, F32 -> Camera2D
		with_rotation = |camera, new_rotation| { ..camera, rotation: sane_scalar(new_rotation) }

		with_zoom : Camera2D, F32 -> Camera2D
		with_zoom = |camera, new_zoom| { ..camera, zoom: sane_zoom(new_zoom) }

		## Hold the zoom between two limits, as a wheel wants.
		clamp_zoom : Camera2D, { min : F32, max : F32 } -> Camera2D
		clamp_zoom = |camera, limits| camera.with_zoom(Math.clamp(camera.zoom, limits.min, limits.max))

		## A world point, in screen pixels. Rotation is in degrees, as raylib
		## and the canvas both take it.
		world_to_screen : Camera2D, Math.Vec2 -> Math.Vec2
		world_to_screen = |camera, world| {
			radians = camera.rotation * degree
			cosine = F32.cos(radians)
			sine = F32.sin(radians)
			dx = world.x - camera.target.x
			dy = world.y - camera.target.y
			{
				x: (dx * cosine - dy * sine) * camera.zoom + camera.offset.x,
				y: (dx * sine + dy * cosine) * camera.zoom + camera.offset.y,
			}
		}

		## A screen point, in the world. **THIS IS WHY A CAMERA IS A VALUE THE
		## GAME HOLDS** rather than a scope a runner opens: the pointer arrives
		## in pixels and the rules are written in the world, so somebody has to
		## do this arithmetic, and only the game knows which camera to do it
		## with. Every camera here is invertible, because no constructor lets a
		## zoom of zero through.
		screen_to_world : Camera2D, Math.Vec2 -> Math.Vec2
		screen_to_world = |camera, screen| {
			radians = 0 - camera.rotation * degree
			cosine = F32.cos(radians)
			sine = F32.sin(radians)
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
			left = F32.min(F32.min(top_left.x, top_right.x), F32.min(bottom_left.x, bottom_right.x))
			right = F32.max(F32.max(top_left.x, top_right.x), F32.max(bottom_left.x, bottom_right.x))
			top = F32.min(F32.min(top_left.y, top_right.y), F32.min(bottom_left.y, bottom_right.y))
			bottom = F32.max(F32.max(top_left.y, top_right.y), F32.max(bottom_left.y, bottom_right.y))
			Math.rect(left, top, right - left, bottom - top)
		}

		## The mark that puts the shapes after it in this camera's world.
		## `Shapes.screen` is how a frame comes back out again.
		view : Camera2D -> Shapes.Shape
		view = |camera|
			View(
				World({
					target: { x: F32.to_f64(camera.target.x), y: F32.to_f64(camera.target.y) },
					offset: { x: F32.to_f64(camera.offset.x), y: F32.to_f64(camera.offset.y) },
					rotation: F32.to_f64(camera.rotation),
					zoom: F32.to_f64(camera.zoom),
				}),
			)
	}

	## Identity: no offset, no rotation, unit zoom.
	default : Camera.Camera2D
	default = { target: Math.zero, offset: Math.zero, rotation: 0, zoom: 1 }

	new : Camera.Settings -> Camera.Camera2D
	new = |settings|
		{
			target: sane_vec(settings.target),
			offset: sane_vec(settings.offset),
			rotation: sane_scalar(settings.rotation),
			zoom: sane_zoom(settings.zoom),
		}

	## Put `target` in the middle of a screen of that size, at unit zoom.
	centered : Math.Vec2, Math.Vec2 -> Camera.Camera2D
	centered = |target, screen|
		new({ target, offset: { x: screen.x / 2, y: screen.y / 2 }, rotation: 0, zoom: 1 })

	## The player-follow camera: the same, with a zoom.
	follow : Math.Vec2, { screen : Math.Vec2, zoom : F32 } -> Camera.Camera2D
	follow = |target, cfg|
		new({ target, offset: { x: cfg.screen.x / 2, y: cfg.screen.y / 2 }, rotation: 0, zoom: cfg.zoom })

	## Radians per degree.
	degree : F32
	degree = 0.017453292519943295

	# **A ZOOM OF ZERO HAS NO INVERSE**, and one that is not finite has no
	# meaning, so neither is allowed to reach a transform. roc-ray substitutes
	# a tiny zoom rather than 1, which collapses the world to a dot at the
	# offset: a camera that had to be rescued should read on screen as the
	# mistake it is, not as something plausible. The same reasoning as throwing
	# on an unknown brush mode rather than painting half a frame.
	fallback_zoom : F32
	fallback_zoom = 0.000001

	sane_scalar : F32 -> F32
	sane_scalar = |value| if F32.is_finite(value) { value } else { 0 }

	sane_vec : Math.Vec2 -> Math.Vec2
	sane_vec = |v| { x: sane_scalar(v.x), y: sane_scalar(v.y) }

	sane_zoom : F32 -> F32
	sane_zoom = |zoom|
		if F32.is_finite(zoom) and zoom != 0 {
			zoom
		} else if zoom < 0 {
			0 - fallback_zoom
		} else {
			fallback_zoom
		}
}

# A point taken into the world and back is the point it started as.
expect {
	camera = Camera.new({ target: { x: 120, y: -40 }, offset: { x: 400, y: 300 }, rotation: 37, zoom: 2.5 })
	there = camera.screen_to_world({ x: 210, y: 160 })
	back = camera.world_to_screen(there)
	F32.abs(back.x - 210) < 0.01 and F32.abs(back.y - 160) < 0.01
}

# A follow camera puts its target under the middle of the screen.
expect Camera.follow({ x: 900, y: 700 }, { screen: { x: 800, y: 600 }, zoom: 2 }).world_to_screen({ x: 900, y: 700 })
    == { x: 400, y: 300 }

# Zoom cannot be zero, whatever it is asked for.
expect Camera.default.with_zoom(0).zoom() == Camera.fallback_zoom
