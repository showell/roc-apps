# CameraDraw -- roc-ray's examples/camera as a frame value.
#
# Upstream's `render!` opens a camera scope and draws into it; this answers a
# list, and the scope is a pair of marks in that list. **THE MARKS ARE THE
# WHOLE DIFFERENCE**: `Shapes.shapes_in_space(eye.space(), ...)` puts the shapes it
# holds in the world, and the window takes the ones after it. What it holds is
# upstream's `draw_world!`, point for point.
#
# The text is bigger than upstream's per character -- a plotter alphabet is
# wider than a typeface -- so the panel is wider and the sizes are smaller.
# The words are upstream's, with `+` spelled as a comma because a stroke font
# with no plus sign draws nothing at all and says nothing about it.
import lib.Brush
import lib.ArgbColor
import lib.Font
import lib.Math
import lib.RgbColor
import lib.Pixels
import lib.Point
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
		$out = List.concat($out, Shapes.shapes_in_space(eye.space(), world_shapes(world.player, mouse_world, seen)))
		$out = List.concat($out, pointer_mark(mouse_screen))
		List.concat($out, hud(world, mouse_world))
	}

	backdrop : Shapes.Shape
	backdrop =
		Rectangle({
			top_left: Point.at(0.0, 0.0),
			width: Pixels.of(800.0),
			height: Pixels.of(600.0),
			fill: Linear({ stops: { start_color: hex(0x101a24), end_color: hex(0x060a0f), start_offset: 0.0, end_offset: 1.0 }, start_point: Point.at(0.0, 0.0), end_point: Point.at(0.0, 600.0) }),
		})

	# ── the world ──────────────────────────────────────────────────────────

	world_shapes : Math.Vec2, Math.Vec2, Math.Rect -> List(Shapes.Shape)
	world_shapes = |player, mouse_world, seen| {
		left = f(Rules.world_left)
		top = f(Rules.world_top)
		right = f(Rules.world_right)
		bottom = f(Rules.world_bottom)

		var $out = [Rectangle({ top_left: Point.at(left, top), width: Pixels.of(right - left), height: Pixels.of(bottom - top), fill: Flat(hex(0x16222b)) })]
		$out = List.concat($out, box({ left, top, right, bottom, line_width: 3.0 }, dim(0x5a5fa8d3)))
		$out = List.concat($out, grid(seen))

		$out = List.concat($out, landmark(-320.0, -160.0, 360.0, 260.0, hex(0x3b6f8f)))
		$out = List.concat($out, landmark(280.0, 120.0, 520.0, 340.0, hex(0x4c8f5f)))
		$out = List.concat($out, landmark(860.0, -280.0, 420.0, 460.0, hex(0x8f6540)))

		axis_color = dim(0xc8ffd166)
		$out = List.append($out, Shapes.line({ from: Point.at(left, 0.0), to: Point.at(right, 0.0), width: Pixels.of(3.0) }, Flat(axis_color)))
		$out = List.append($out, Shapes.line({ from: Point.at(0.0, top), to: Point.at(0.0, bottom), width: Pixels.of(3.0) }, Flat(axis_color)))

		$out = List.concat($out, marker(f(player.x), f(player.y)))
		# The pointer, where it actually is in the world.
		List.concat($out, Shapes.ring_shapes({ center: Point.at(f(mouse_world.x), f(mouse_world.y)), radius: Pixels.of(10.0), line_width: Pixels.of(2.0), sides: 20 }, Flat(hex(0xffd166))))
	}

	# A world landmark: a soft shadow, the slab, and a lighter cap so the world
	# reads as depth rather than as three flat swatches.
	landmark : F64, F64, F64, F64, Brush.Rgba -> List(Shapes.Shape)
	landmark = |x, y, w, h, color|
		[
			Rectangle({ top_left: Point.at(x + 10.0, y + 14.0), width: Pixels.of(w), height: Pixels.of(h), fill: Flat(dim(0x5A000000)) }),
			Rectangle({ top_left: Point.at(x, y), width: Pixels.of(w), height: Pixels.of(h), fill: Flat(color) }),
			Rectangle({ top_left: Point.at(x, y), width: Pixels.of(w), height: Pixels.of(10.0), fill: Flat(dim(0x2Dffffff)) }),
		]

	# The player: a shadow, the disc, its white rim, and the cross that shows
	# which way the world is turned.
	marker : F64, F64 -> List(Shapes.Shape)
	marker = |x, y| {
		white = hex(0xffffff)
		var $out = [
			Disc({ center: Point.at(x, y + 6.0), radius: Pixels.of(26.0), fill: Flat(dim(0x6E000000)) }),
			Disc({ center: Point.at(x, y), radius: Pixels.of(26.0), fill: Flat(hex(0xef476f)) }),
		]
		$out = List.concat($out, Shapes.ring_shapes({ center: Point.at(x, y), radius: Pixels.of(26.0), line_width: Pixels.of(4.0), sides: 28 }, Flat(white)))
		$out = List.append($out, Shapes.line({ from: Point.at(x - 42.0, y), to: Point.at(x + 42.0, y), width: Pixels.of(3.0) }, Flat(white)))
		List.append($out, Shapes.line({ from: Point.at(x, y - 42.0), to: Point.at(x, y + 42.0), width: Pixels.of(3.0) }, Flat(white)))
	}

	# **THE GRID IS WHY THE CAMERA HAS TO BE A VALUE THE GAME HOLDS.** Every
	# eightieth line of a world three screens wide is thirty-one lines, and
	# drawing them all at every zoom is most of the frame; `viewport` says
	# which of them can be seen, and only the camera knows.
	grid : Math.Rect -> List(Shapes.Shape)
	grid = |seen| {
		faint = Flat(dim(0x37ffffff))
		top = f(Rules.world_top)
		bottom = f(Rules.world_bottom)
		left = f(Rules.world_left)
		right = f(Rules.world_right)

		var $out = []
		var $x = left
		while $x <= right {
			if $x >= f(seen.x) and $x <= f(seen.x) + f(seen.width) {
				$out = List.append($out, Shapes.line({ from: Point.at($x, top), to: Point.at($x, bottom), width: Pixels.of(1.0) }, faint))
			} else {
				{}
			}
			$x = $x + 80.0
		}
		var $y = top
		while $y <= bottom {
			if $y >= f(seen.y) and $y <= f(seen.y) + f(seen.height) {
				$out = List.append($out, Shapes.line({ from: Point.at(left, $y), to: Point.at(right, $y), width: Pixels.of(1.0) }, faint))
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
		arm = Flat(dim(0x8Cffd166))
		var $out = Shapes.ring_shapes({ center: Point.at(x, y), radius: Pixels.of(7.0), line_width: Pixels.of(2.0), sides: 16 }, Flat(hex(0xffd166)))
		$out = List.append($out, Shapes.line({ from: Point.at(x - 14.0, y), to: Point.at(x + 14.0, y), width: Pixels.of(1.0) }, arm))
		List.append($out, Shapes.line({ from: Point.at(x, y - 14.0), to: Point.at(x, y + 14.0), width: Pixels.of(1.0) }, arm))
	}

	hud : Rules.World, Math.Vec2 -> List(Shapes.Shape)
	hud = |world, mouse_world| {
		var $out = [
			Shapes.rounded_rect({ top_left: Point.at(15.0, 15.0), width: Pixels.of(462.0), height: Pixels.of(128.0), corner_radius: Pixels.of(13.0), corner_steps: 8 }, Flat(dim(0x28ffffff))),
			Shapes.rounded_rect({ top_left: Point.at(16.0, 16.0), width: Pixels.of(460.0), height: Pixels.of(126.0), corner_radius: Pixels.of(12.0), corner_steps: 8 }, Flat(dim(0xD70b1219))),
		]
		$out = List.concat($out, Font.text_shapes("Camera world", { top_left: Point.at(32.0, 28.0), size: 20.0, color: hex(0xffffff) }))
		$out = List.concat($out, Font.text_shapes("world-space draw, screen-space HUD", { top_left: Point.at(32.0, 58.0), size: 12.0, color: hex(0x8fa3b8) }))
		$out = List.append($out, Shapes.line({ from: Point.at(32.0, 80.0), to: Point.at(460.0, 80.0), width: Pixels.of(1.0) }, Flat(dim(0x1Effffff))))
		# The pointer in both spaces at once, which is the whole demonstration.
		$out = List.concat($out, Font.text_shapes(readout(world, mouse_world), { top_left: Point.at(32.0, 88.0), size: 13.0, color: hex(0xffd166) }))
		List.concat($out, Font.text_shapes("WASD move, wheel zoom, Q/E rotate, R reset", { top_left: Point.at(32.0, 112.0), size: 10.0, color: hex(0x8fa3b8) }))
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
	box : { left : F64, top : F64, right : F64, bottom : F64, line_width : F64 }, Brush.Rgba -> List(Shapes.Shape)
	box = |{ left, top, right, bottom, line_width }, color| {
		fill = Flat(color)
		top_left = Point.at(left, top)
		top_right = Point.at(right, top)
		bottom_right = Point.at(right, bottom)
		bottom_left = Point.at(left, bottom)
		[
			Shapes.line({ from: top_left, to: top_right, width: Pixels.of(line_width) }, fill),
			Shapes.line({ from: top_right, to: bottom_right, width: Pixels.of(line_width) }, fill),
			Shapes.line({ from: bottom_right, to: bottom_left, width: Pixels.of(line_width) }, fill),
			Shapes.line({ from: bottom_left, to: top_left, width: Pixels.of(line_width) }, fill),
		]
	}

	hex : I64 -> Brush.Rgba
	hex = |rgb| Brush.opaque_rgba(RgbColor.of(rgb))

	# A colour with its alpha byte, 0xAARRGGBB.
	dim : I64 -> Brush.Rgba
	dim = |argb| Brush.translucent(ArgbColor.of(argb))

	# The world is written in F32, as roc-ray's examples are; a frame is F64.
	f : F32 -> F64
	f = |value| F32.to_f64(value)
}
