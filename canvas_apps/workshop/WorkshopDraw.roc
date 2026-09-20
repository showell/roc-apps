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
import lib.Brush
import lib.Color
import lib.Font
import lib.Math
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
		var $out = [Rect({ x: 0.0, y: 0.0, w: 800.0, h: 600.0, fill: Flat(theme.bg) })]
		$out = List.concat($out, Font.text("Pixel Workshop", 72.0, 12.0, 20.0, theme.ink))
		$out = List.concat($out, Font.text("Canvas, palette and brush sound all generated at startup", 72.0, 44.0, 12.0, theme.muted))
		$out = List.concat($out, canvas(world))
		$out = List.concat($out, palette(world))
		List.concat($out, Font.text("Drag to paint  |  1-4 pick a colour  |  C restores the design", 72.0, 562.0, 11.0, theme.faint))
	}

	# ── the canvas ─────────────────────────────────────────────────────────

	canvas : Rules.World -> List(Shapes.Shape)
	canvas = |world| {
		x = f(Rules.canvas_x)
		y = f(Rules.canvas_y)
		side = f(Rules.canvas_size)

		# A card under the canvas, so the pixel art sits on a surface instead
		# of floating on the background.
		var $out = card(x - 14.0, y - 14.0, side + 28.0, side + 28.0, 12.0)
		# **THE PICTURE ITSELF, PIXELS AND ALL.** Upstream's texture handle and
		# its uploads are what this one shape replaces.
		$out = List.append(
			$out,
			Image({
				x,
				y,
				w: side,
				h: side,
				cols: Rules.grid_side,
				rows: Rules.grid_side,
				pixels: List.map(world.pixels, Color.brush),
			}),
		)
		$out = List.concat($out, outline(x - 2.0, y - 2.0, side + 4.0, side + 4.0, 2.0, theme.edge))
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
				outline(f(Rules.canvas_x) + col * size, f(Rules.canvas_y) + row * size, size, size, 2.0, white)
			}
		}

	# ── the palette ────────────────────────────────────────────────────────

	palette : Rules.World -> List(Shapes.Shape)
	palette = |world| {
		var $out = card(594.0, 108.0, 150.0, 348.0, 12.0)
		$out = List.concat($out, Font.text("Palette", 610.0, 126.0, 16.0, theme.ink))
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
				{ ..white, a: 150.0 / 255.0 }
			} else {
				theme.edge
			}

		# The selected swatch gets a lit ring outside it as well as a bright
		# edge, so which colour the brush carries survives a glance. A ring is
		# the larger shape with the smaller one punched out of it, which is
		# exact because what it sits on is the panel's flat colour.
		var $out = []
		if chosen {
			$out = List.append($out, Shapes.rounded_rect(x - 5.0, y - 5.0, w + 10.0, h + 10.0, 11.0, 8, Flat(theme.accent)))
			$out = List.append($out, Shapes.rounded_rect(x - 3.0, y - 3.0, w + 6.0, h + 6.0, 9.0, 8, Flat(theme.panel)))
		} else {
			{}
		}
		lip = if chosen { 3.0 } else { 2.0 }
		$out = List.append($out, Shapes.rounded_rect(x - lip, y - lip, w + lip * 2.0, h + lip * 2.0, 8.0 + lip, 8, Flat(edge)))
		$out = List.append($out, Shapes.rounded_rect(x, y, w, h, 8.0, 8, Flat(Color.brush(Rules.palette_color(index)))))

		# The number beside the swatch, centred on upstream's anchor.
		digit = U64.to_str(index + 1)
		ink = if chosen { theme.ink } else { theme.faint }
		List.concat($out, Font.text(digit, 752.0 - Font.width_of(digit, 18.0) / 2.0, y + 25.0 - 9.0, 18.0, ink))
	}

	# ── the small arithmetic ───────────────────────────────────────────────

	# A panel: its edge, then its face, which is the outline trick again.
	card : F64, F64, F64, F64, F64 -> List(Shapes.Shape)
	card = |x, y, w, h, r|
		[
			Shapes.rounded_rect(x - 1.0, y - 1.0, w + 2.0, h + 2.0, r + 1.0, 8, Flat(theme.edge)),
			Shapes.rounded_rect(x, y, w, h, r, 8, Flat(theme.panel)),
		]

	# A rectangle's outline, as the four lines it is, drawn on the edge itself.
	outline : F64, F64, F64, F64, F64, Brush.Rgba -> List(Shapes.Shape)
	outline = |x, y, w, h, thickness, colour| {
		fill = Flat(colour)
		[
			Shapes.line(x, y, x + w, y, thickness, fill),
			Shapes.line(x + w, y, x + w, y + h, thickness, fill),
			Shapes.line(x + w, y + h, x, y + h, thickness, fill),
			Shapes.line(x, y + h, x, y, thickness, fill),
		]
	}

	white : Brush.Rgba
	white = { r: 255.0, g: 255.0, b: 255.0, a: 1.0 }

	hex : I64 -> Brush.Rgba
	hex = |value| Color.brush(Color.from_hex_rgb(value))

	count : U64 -> F64
	count = |n| I64.to_f64(U64.to_i64_wrap(n))

	f : F32 -> F64
	f = |value| F32.to_f64(value)
}

