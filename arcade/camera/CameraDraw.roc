# CameraDraw -- roc-ray's examples/camera as a frame value.
#
# Upstream's `render!` opens a camera scope and draws into it; this answers a
# list, and the scope is two marks in that list. **THE MARKS ARE THE WHOLE
# DIFFERENCE**: `eye.view()` says the shapes after it are in the world, and
# `Shapes.screen` says the ones after that are back in the window. Between
# them is upstream's `draw_world!`, point for point.
#
# The text is bigger than upstream's per character -- a plotter alphabet is
# wider than a typeface -- so the panel is wider and the sizes are smaller.
# The words are upstream's, with `+` spelled as a comma because a stroke font
# with no plus sign draws nothing at all and says nothing about it.
import lib.Brush
import lib.Camera
import lib.Color
import lib.Font
import lib.Math
import lib.Shapes
import Rules

CameraDraw :: [].{
	frame : Rules.World -> List(Shapes.Shape)
	frame = |world| {
		eye = Rules.eye(world)
		mouse_world = eye.screen_to_world(world.mouse)
		mouse_screen = eye.world_to_screen(mouse_world)
		seen = eye.viewport(Rules.screen)

		var $out = [backdrop]
		# Everything after this mark is in the world.
		$out = List.append($out, eye.view())
		$out = List.concat($out, world_shapes(world.player, mouse_world, seen))
		# And everything after this one is back in the window.
		$out = List.append($out, Shapes.screen)
		$out = List.concat($out, pointer_mark(mouse_screen))
		List.concat($out, hud(world, mouse_world))
	}

	backdrop : Shapes.Shape
	backdrop =
		Rect({
			x: 0.0,
			y: 0.0,
			w: 800.0,
			h: 600.0,
			fill: Linear({ c0: hex(0x101a24), c1: hex(0x060a0f), o0: 0.0, o1: 1.0, ax: 0.0, ay: 0.0, dx: 0.0, dy: 600.0 }),
		})

	# ── the world ──────────────────────────────────────────────────────────

	world_shapes : Math.Vec2, Math.Vec2, Math.Rect -> List(Shapes.Shape)
	world_shapes = |player, mouse_world, seen| {
		left = f(Rules.world_left)
		top = f(Rules.world_top)
		right = f(Rules.world_right)
		bottom = f(Rules.world_bottom)

		var $out = [Rect({ x: left, y: top, w: right - left, h: bottom - top, fill: Flat(hex(0x16222b)) })]
		$out = List.concat($out, box(left, top, right, bottom, 3.0, dim(0x5fa8d3, 90)))
		$out = List.concat($out, grid(seen))

		$out = List.concat($out, landmark(-320.0, -160.0, 360.0, 260.0, hex(0x3b6f8f)))
		$out = List.concat($out, landmark(280.0, 120.0, 520.0, 340.0, hex(0x4c8f5f)))
		$out = List.concat($out, landmark(860.0, -280.0, 420.0, 460.0, hex(0x8f6540)))

		axis_color = dim(0xffd166, 200)
		$out = List.append($out, Shapes.line(left, 0.0, right, 0.0, 3.0, Flat(axis_color)))
		$out = List.append($out, Shapes.line(0.0, top, 0.0, bottom, 3.0, Flat(axis_color)))

		$out = List.concat($out, marker(f(player.x), f(player.y)))
		# The pointer, where it actually is in the world.
		List.concat($out, Shapes.ring(f(mouse_world.x), f(mouse_world.y), 10.0, 2.0, 20, Flat(hex(0xffd166))))
	}

	# A world landmark: a soft shadow, the slab, and a lighter cap so the world
	# reads as depth rather than as three flat swatches.
	landmark : F64, F64, F64, F64, Brush.Rgba -> List(Shapes.Shape)
	landmark = |x, y, w, h, color|
		[
			Rect({ x: x + 10.0, y: y + 14.0, w, h, fill: Flat({ r: 0.0, g: 0.0, b: 0.0, a: 90.0 / 255.0 }) }),
			Rect({ x, y, w, h, fill: Flat(color) }),
			Rect({ x, y, w, h: 10.0, fill: Flat({ r: 255.0, g: 255.0, b: 255.0, a: 45.0 / 255.0 }) }),
		]

	# The player: a shadow, the disc, its white rim, and the cross that shows
	# which way the world is turned.
	marker : F64, F64 -> List(Shapes.Shape)
	marker = |x, y| {
		white = { r: 255.0, g: 255.0, b: 255.0, a: 1.0 }
		var $out = [
			Disc({ x, y: y + 6.0, r: 26.0, fill: Flat({ r: 0.0, g: 0.0, b: 0.0, a: 110.0 / 255.0 }), clip: Anywhere }),
			Disc({ x, y, r: 26.0, fill: Flat(hex(0xef476f)), clip: Anywhere }),
		]
		$out = List.concat($out, Shapes.ring(x, y, 26.0, 4.0, 28, Flat(white)))
		$out = List.append($out, Shapes.line(x - 42.0, y, x + 42.0, y, 3.0, Flat(white)))
		List.append($out, Shapes.line(x, y - 42.0, x, y + 42.0, 3.0, Flat(white)))
	}

	# **THE GRID IS WHY THE CAMERA HAS TO BE A VALUE THE GAME HOLDS.** Every
	# eightieth line of a world three screens wide is thirty-one lines, and
	# drawing them all at every zoom is most of the frame; `viewport` says
	# which of them can be seen, and only the camera knows.
	grid : Math.Rect -> List(Shapes.Shape)
	grid = |seen| {
		faint = Flat(dim(0xffffff, 55))
		top = f(Rules.world_top)
		bottom = f(Rules.world_bottom)
		left = f(Rules.world_left)
		right = f(Rules.world_right)

		var $out = []
		var $x = left
		while $x <= right {
			if $x >= f(seen.x) and $x <= f(seen.x) + f(seen.width) {
				$out = List.append($out, Shapes.line($x, top, $x, bottom, 1.0, faint))
			} else {
				{}
			}
			$x = $x + 80.0
		}
		var $y = top
		while $y <= bottom {
			if $y >= f(seen.y) and $y <= f(seen.y) + f(seen.height) {
				$out = List.append($out, Shapes.line(left, $y, right, $y, 1.0, faint))
			} else {
				{}
			}
			$y = $y + 80.0
		}
		$out
	}

	# ── the window ─────────────────────────────────────────────────────────

	# Drawn outside the camera: `world_to_screen` is what puts a screen-space
	# mark back on top of a world-space point.
	pointer_mark : Math.Vec2 -> List(Shapes.Shape)
	pointer_mark = |at| {
		x = f(at.x)
		y = f(at.y)
		arm = Flat(dim(0xffd166, 140))
		var $out = Shapes.ring(x, y, 7.0, 2.0, 16, Flat(hex(0xffd166)))
		$out = List.append($out, Shapes.line(x - 14.0, y, x + 14.0, y, 1.0, arm))
		List.append($out, Shapes.line(x, y - 14.0, x, y + 14.0, 1.0, arm))
	}

	hud : Rules.World, Math.Vec2 -> List(Shapes.Shape)
	hud = |world, mouse_world| {
		var $out = [
			Shapes.rounded_rect(15.0, 15.0, 462.0, 128.0, 13.0, 8, Flat(dim(0xffffff, 40))),
			Shapes.rounded_rect(16.0, 16.0, 460.0, 126.0, 12.0, 8, Flat(dim(0x0b1219, 215))),
		]
		$out = List.concat($out, Font.text("Camera world", 32.0, 28.0, 20.0, hex(0xffffff)))
		$out = List.concat($out, Font.text("world-space draw, screen-space HUD", 32.0, 58.0, 12.0, hex(0x8fa3b8)))
		$out = List.append($out, Shapes.line(32.0, 80.0, 460.0, 80.0, 1.0, Flat(dim(0xffffff, 30))))
		# The pointer in both spaces at once, which is the whole demonstration.
		$out = List.concat($out, Font.text(readout(world, mouse_world), 32.0, 88.0, 13.0, hex(0xffd166)))
		List.concat($out, Font.text("WASD move, wheel zoom, Q/E rotate, R reset", 32.0, 112.0, 10.0, hex(0x8fa3b8)))
	}

	readout : Rules.World, Math.Vec2 -> Str
	readout = |world, mouse_world|
		Str.concat(
			Str.concat(Str.concat("world ", coord(mouse_world.x)), Str.concat(", ", coord(mouse_world.y))),
			Str.concat(Str.concat("   zoom ", coord(world.zoom * 100)), "%"),
		)

	## Whole units, so the readout does not jitter its own width every frame.
	coord : F32 -> Str
	coord = |value| I32.to_str(F32.to_i32_wrap(value))

	# ── the small arithmetic ───────────────────────────────────────────────

	# A rectangle's outline, as the four lines it is.
	box : F64, F64, F64, F64, F64, Brush.Rgba -> List(Shapes.Shape)
	box = |left, top, right, bottom, w, color| {
		fill = Flat(color)
		[
			Shapes.line(left, top, right, top, w, fill),
			Shapes.line(right, top, right, bottom, w, fill),
			Shapes.line(right, bottom, left, bottom, w, fill),
			Shapes.line(left, bottom, left, top, w, fill),
		]
	}

	hex : I64 -> Brush.Rgba
	hex = |value| Color.brush(Color.from_hex_rgb(value))

	dim : I64, U8 -> Brush.Rgba
	dim = |value, alpha| Color.brush(Color.with_alpha(Color.from_hex_rgb(value), alpha))

	# The world is written in F32, as roc-ray's examples are; a frame is F64.
	f : F32 -> F64
	f = |value| F32.to_f64(value)
}
