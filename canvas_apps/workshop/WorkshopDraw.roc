# WorkshopDraw -- roc-ray's Pixel Workshop as a frame value.
#
# Upstream's `render!` draws the canvas with `frame.texture!`, from a texture
# it made at startup and has been uploading to ever since. Here the canvas is
# `Shapes.Image`, which carries the pixels themselves, so the picture on screen
# is a function of the model and cannot be stale.
#
# The chrome is upstream's, laid out at upstream's coordinates. Only the text
# sizes differ: a plotter alphabet is about twice as wide per character as a
# typeface, so a label that must fit a panel is smaller here.
import lib.ArgbColor
import lib.Brush
import lib.Font
import lib.Math
import lib.RgbColor
import lib.Pixels
import lib.Point
import lib.Shapes
import Rules

WorkshopDraw :: [].{

	## The shared surface palette for the workshop's chrome. The four paint
	## colours are the artwork; everything around them stays quiet.
	theme : { bg : Brush.Rgba, panel : Brush.Rgba, edge : Brush.Rgba, ink : Brush.Rgba, muted : Brush.Rgba, faint : Brush.Rgba, accent : Brush.Rgba }
	theme = {
		bg: hex(0x0e1420),
		panel: hex(0x161f31),
		edge: hex(0x25314b),
		ink: hex(0xe6ecf5),
		muted: hex(0x8fa0bd),
		faint: hex(0x5c6b87),
		accent: hex(0x4c8dff),
	}

	frame : Rules.World -> List(Shapes.Shape)
	frame = |world| {
		var $out = [Shapes.rectangle({ top_left: Point.at(0.0, 0.0), width: Pixels.of(800.0), height: Pixels.of(600.0), fill: Flat(theme.bg) })]
		$out = List.concat($out, Font.text_shapes("Pixel Workshop", { top_left: Point.at(72.0, 12.0), size: 20.0, color: theme.ink }))
		$out = List.concat($out, Font.text_shapes("Canvas, palette and brush sound all generated at startup", { top_left: Point.at(72.0, 44.0), size: 12.0, color: theme.muted }))
		$out = List.concat($out, canvas(world))
		$out = List.concat($out, palette(world))
		List.concat($out, Font.text_shapes("Drag to paint  |  1-4 pick a colour  |  C restores the design", { top_left: Point.at(72.0, 562.0), size: 11.0, color: theme.faint }))
	}

	# ── the canvas ─────────────────────────────────────────────────────────

	canvas : Rules.World -> List(Shapes.Shape)
	canvas = |world| {
		x = f(Rules.canvas_x)
		y = f(Rules.canvas_y)
		side = f(Rules.canvas_size)

		# A card under the canvas, so the pixel art sits on a surface instead
		# of floating on the background.
		var $out = card({ x: x - 14.0, y: y - 14.0, width: side + 28.0, height: side + 28.0, corner_radius: 12.0 })
		# **THE PICTURE ITSELF, PIXELS AND ALL.** Upstream's texture handle and
		# its uploads are what this one shape replaces.
		$out = List.append(
			$out,
			Shapes.image({
				x,
				y,
				width: side,
				height: side,
				cols: Rules.grid_side,
				rows: Rules.grid_side,
				pixels: List.map(world.pixels, Brush.opaque_rgba),
			}),
		)
		$out = List.concat($out, outline({ x: x - 2.0, y: y - 2.0, width: side + 4.0, height: side + 4.0, thickness: 2.0 }, theme.edge))
		List.concat($out, hovered(world.mouse))
	}

	## The cell under the pointer, ringed, or nothing when the pointer is off
	## the canvas -- the same `cell_at` the painting uses, so the ring never
	## sits on a cell a click would miss.
	hovered : Math.Vec2 -> List(Shapes.Shape)
	hovered = |mouse|
		match Rules.cell_at(mouse) {
			Err(_) => []
			Ok(index) => {
				col = count(index % Rules.grid_side)
				row = count(index // Rules.grid_side)
				size = f(Rules.cell_size)
				outline({ x: f(Rules.canvas_x) + col * size, y: f(Rules.canvas_y) + row * size, width: size, height: size, thickness: 2.0 }, white)
			}
		}

	# ── the palette ────────────────────────────────────────────────────────

	palette : Rules.World -> List(Shapes.Shape)
	palette = |world| {
		var $out = card({ x: 594.0, y: 108.0, width: 150.0, height: 348.0, corner_radius: 12.0 })
		$out = List.concat($out, Font.text_shapes("Palette", { top_left: Point.at(610.0, 126.0), size: 16.0, color: theme.ink }))
		var $i = 0
		while $i < 4 {
			$out = List.concat($out, swatch($i, world.palette, world.mouse))
			$i = $i + 1
		}
		$out
	}

	swatch : U64, U64, Math.Vec2 -> List(Shapes.Shape)
	swatch = |index, selected, mouse| {
		bounds = Rules.swatch_bounds(index)
		x = f(bounds.x)
		y = f(bounds.y)
		w = f(bounds.width)
		h = f(bounds.height)
		chosen = index == selected
		edge =
			if chosen {
				white
			} else if Math.contains(bounds, mouse) {
				Brush.translucent(ArgbColor.of(0x96ffffff))
			} else {
				theme.edge
			}

		# The selected swatch gets a lit ring outside it as well as a bright
		# edge, so which colour the brush carries survives a glance. A ring is
		# the larger shape with the smaller one punched out of it, which is
		# exact because what it sits on is the panel's flat colour.
		var $out = []
		if chosen {
			$out = List.append($out, Shapes.rounded_rect({ top_left: Point.at(x - 5.0, y - 5.0), width: Pixels.of(w + 10.0), height: Pixels.of(h + 10.0), corner_radius: Pixels.of(11.0), corner_steps: 8 }, Flat(theme.accent)))
			$out = List.append($out, Shapes.rounded_rect({ top_left: Point.at(x - 3.0, y - 3.0), width: Pixels.of(w + 6.0), height: Pixels.of(h + 6.0), corner_radius: Pixels.of(9.0), corner_steps: 8 }, Flat(theme.panel)))
		} else {
			{}
		}
		lip = if chosen {
			3.0
		} else {
			2.0
		}
		$out = List.append($out, Shapes.rounded_rect({ top_left: Point.at(x - lip, y - lip), width: Pixels.of(w + lip * 2.0), height: Pixels.of(h + lip * 2.0), corner_radius: Pixels.of(8.0 + lip), corner_steps: 8 }, Flat(edge)))
		$out = List.append($out, Shapes.rounded_rect({ top_left: Point.at(x, y), width: Pixels.of(w), height: Pixels.of(h), corner_radius: Pixels.of(8.0), corner_steps: 8 }, Brush.flat(Rules.palette_color(index))))

		# The number beside the swatch, centred on upstream's anchor.
		digit = U64.to_str(index + 1)
		ink = if chosen {
			theme.ink
		} else {
			theme.faint
		}
		List.concat($out, Font.text_shapes(digit, { top_left: Point.at(752.0 - Font.width_of(digit, 18.0) / 2.0, y + 25.0 - 9.0), size: 18.0, color: ink }))
	}

	# ── the small arithmetic ───────────────────────────────────────────────

	# A panel: its edge, then its face, which is the outline trick again.
	card : { x : F64, y : F64, width : F64, height : F64, corner_radius : F64 } -> List(Shapes.Shape)
	card = |{ x, y, width, height, corner_radius }|
		[
			Shapes.rounded_rect({ top_left: Point.at(x - 1.0, y - 1.0), width: Pixels.of(width + 2.0), height: Pixels.of(height + 2.0), corner_radius: Pixels.of(corner_radius + 1.0), corner_steps: 8 }, Flat(theme.edge)),
			Shapes.rounded_rect({ top_left: Point.at(x, y), width: Pixels.of(width), height: Pixels.of(height), corner_radius: Pixels.of(corner_radius), corner_steps: 8 }, Flat(theme.panel)),
		]

	# A rectangle's outline, as the four lines it is, drawn on the edge itself.
	outline : { x : F64, y : F64, width : F64, height : F64, thickness : F64 }, Brush.Rgba -> List(Shapes.Shape)
	outline = |{ x, y, width, height, thickness }, colour| {
		fill = Flat(colour)
		top_left = Point.at(x, y)
		top_right = Point.at(x + width, y)
		bottom_right = Point.at(x + width, y + height)
		bottom_left = Point.at(x, y + height)
		[
			Shapes.line({ from: top_left, to: top_right, width: Pixels.of(thickness) }, fill),
			Shapes.line({ from: top_right, to: bottom_right, width: Pixels.of(thickness) }, fill),
			Shapes.line({ from: bottom_right, to: bottom_left, width: Pixels.of(thickness) }, fill),
			Shapes.line({ from: bottom_left, to: top_left, width: Pixels.of(thickness) }, fill),
		]
	}

	white : Brush.Rgba
	white = hex(0xffffff)

	hex : I64 -> Brush.Rgba
	hex = |rgb| Brush.opaque_rgba(RgbColor.of(rgb))

	count : U64 -> F64
	count = |n| I64.to_f64(U64.to_i64_wrap(n))

	f : F32 -> F64
	f = |value| F32.to_f64(value)
}
