# Rules -- roc-ray's examples/generated_assets, the Pixel Workshop editor.
#
# Upstream's `palette_color`, `initial_pixels`, `palette_from_input`, `cell_at`
# and the body of `update_editor` are here with their import lines changed, and
# its expects came across word for word.
#
# **WHAT DID NOT COME ACROSS IS THE INTERESTING PART.** Upstream's editor
# answers `Edited : { model, edits }`, where an edit is `Upload(pixels)`,
# `UploadRegion(region)` or `Play(playback)`: the canvas lives twice, once in
# the model and once on the GPU, so every branch that changes one has to
# remember to emit the upload that changes the other. Its own comment says as
# much -- "returning both together is what keeps the two from drifting apart".
#
# Here a frame is a VALUE computed from the model, so there is no second copy
# to drift, nothing to keep in step, and no upload to forget. Two of the three
# edits are gone and the type with them; what is left is the sound, which is a
# thing that HAPPENED and which this seam already carries as a bit per tone.
import lib.Color
import lib.Input
import lib.Math
import lib.Mouse

Rules :: [].{
	## Whether the last step painted, and which cell, so that holding the
	## button across one cell paints it once and sounds once.
	PaintState := [Idle, Painted(U64)].{
		is_eq : _
	}

	World : {
		pixels : List(Color.Rgba),
		palette : U64,
		last_cell : Rules.PaintState,
		mouse : Math.Vec2,
	}

	grid_side : U64
	grid_side = 16

	canvas_x : F32
	canvas_x = 72

	canvas_y : F32
	canvas_y = 72

	cell_size : F32
	cell_size = 28

	canvas_size : F32
	canvas_size = side(grid_side) * cell_size

	canvas_bounds : Math.Rect
	canvas_bounds = Math.rect(canvas_x, canvas_y, canvas_size, canvas_size)

	palette_color : U64 -> Color.Rgba
	palette_color = |index|
		match index {
			0 => Color.from_hex_rgb(0x17202a)
			1 => Color.from_hex_rgb(0x2f80ed)
			2 => Color.from_hex_rgb(0xf9c74f)
			_ => Color.from_hex_rgb(0xf94144)
		}

	## The design the canvas starts as and that C restores: two diagonals and a
	## square in the middle.
	initial_pixels : List(Color.Rgba)
	initial_pixels = List.map_with_index(
		List.repeat(Color.from_hex_rgb(0xf3f0e8), grid_side * grid_side),
		|_color, index| {
			row = index // grid_side
			col = index % grid_side
			if row == col or row + col == grid_side - 1 {
				Color.from_hex_rgb(0x2f80ed)
			} else if row >= 6 and row <= 9 and col >= 6 and col <= 9 {
				Color.from_hex_rgb(0xf9c74f)
			} else {
				Color.from_hex_rgb(0xf3f0e8)
			}
		},
	)

	start : Rules.World
	start = { pixels: initial_pixels, palette: 1, last_cell: Idle, mouse: { x: 0, y: 0 } }

	palette_from_input : U64, Input.Snapshot -> U64
	palette_from_input = |current, input|
		if input.key_pressed(Key1) {
			0
		} else if input.key_pressed(Key2) {
			1
		} else if input.key_pressed(Key3) {
			2
		} else if input.key_pressed(Key4) {
			3
		} else {
			current
		}

	## Which cell of the canvas a point is in, if it is on the canvas at all.
	## `Outside` is also what stops a drag off the edge from painting the row
	## it would have wrapped onto.
	cell_at : Math.Vec2 -> Try(U64, [Outside])
	cell_at = |point|
		if Math.contains(canvas_bounds, point) {
			column = F32.to_u64_try((point.x - canvas_x) / cell_size)
			row = F32.to_u64_try((point.y - canvas_y) / cell_size)
			match (column, row) {
				(Ok(col), Ok(line)) =>
					if col < grid_side and line < grid_side {
						Ok(line * grid_side + col)
					} else {
						Err(Outside)
					}
				_ => Err(Outside)
			}
		} else {
			Err(Outside)
		}

	## One step of the editor: the canvas it produced, and which tones it set
	## off. Upstream's `update_editor`, with the two upload edits gone.
	step : Rules.World, Input.Snapshot -> { world : Rules.World, sounds : U32 }
	step = |world, input| {
		palette = palette_from_input(world.palette, input)
		base = { ..world, palette, mouse: input.mouse.position() }

		if input.key_pressed(KeyC) {
			{ world: { ..base, pixels: initial_pixels, last_cell: Idle }, sounds: tone_reset }
		} else if input.mouse.button_down(Left) {
			match cell_at(input.mouse.position()) {
				Err(_) => { world: { ..base, last_cell: Idle }, sounds: 0 }
				Ok(index) =>
					if base.last_cell == Painted(index) {
						{ world: base, sounds: 0 }
					} else {
						match List.set(base.pixels, index, palette_color(palette)) {
							Err(_) => { world: base, sounds: 0 }
							Ok(pixels) => {
								world: { ..base, pixels, last_cell: Painted(index) },
								sounds: tone_paint(palette),
							}
						}
					}
			}
		} else {
			{ world: { ..base, last_cell: Idle }, sounds: 0 }
		}
	}

	# **A PITCH IS A TONE HERE.** Upstream generates ONE 520 Hz tone and plays
	# it back at five pitches -- 0.7 to restore the design, and 0.8 plus 0.18 a
	# palette to paint. This seam carries a bit per tone, so the five pitches
	# are five tones at the frequencies those pitches produce, which is the
	# same five sounds by a different route.
	tone_reset : U32
	tone_reset = 1

	tone_paint : U64 -> U32
	tone_paint = |palette| U32.shl_wrap(1, U64.to_u8_wrap(palette) + 1)

	side : U64 -> F32
	side = |n| I32.to_f32(I64.to_i32_wrap(U64.to_i64_wrap(n)))
}

expect Rules.palette_from_input(0, Input.none.with_key_pressed(Key3)) == 2
expect Rules.palette_from_input(2, Input.none) == 2

## The canvas maps the pointer to a cell index; anything off it is `Outside`.
expect Rules.cell_at({ x: Rules.canvas_x + Rules.cell_size * 1.5, y: Rules.canvas_y + Rules.cell_size * 2.5 }) == Ok(2 * Rules.grid_side + 1)
expect Rules.cell_at({ x: Rules.canvas_x - 1, y: Rules.canvas_y }) == Err(Outside)
expect Rules.cell_at({ x: Rules.canvas_x + Rules.canvas_size, y: Rules.canvas_y }) == Err(Outside)

## Holding the button across ONE cell paints it once and sounds once; the
## second step over the same cell is silent and changes nothing.
expect {
    at = { x: Rules.canvas_x + 10, y: Rules.canvas_y + 10 }
    held = Input.none.with_mouse(Mouse.of(Mouse.bit(Left), 0, at.x, at.y, 0))
    first = Rules.step(Rules.start, held)
    again = Rules.step(first.world, held)
    first.sounds == Rules.tone_paint(1) and again.sounds == 0 and again.world.pixels == first.world.pixels
}

## A stroke paints the colour the digit chose, in the same step.
expect {
    at = { x: Rules.canvas_x + 10, y: Rules.canvas_y + 10 }
    keyed = Input.none.with_key_pressed(Key4).with_mouse(Mouse.of(Mouse.bit(Left), 0, at.x, at.y, 0))
    after = Rules.step(Rules.start, keyed)
    List.get(after.world.pixels, 0) == Ok(Rules.palette_color(3)) and after.sounds == 16
}

## C restores the design and says so.
expect {
    at = { x: Rules.canvas_x + 10, y: Rules.canvas_y + 10 }
    painted = Rules.step(Rules.start, Input.none.with_mouse(Mouse.of(Mouse.bit(Left), 0, at.x, at.y, 0))).world
    restored = Rules.step(painted, Input.none.with_key_pressed(KeyC))
    restored.world.pixels == Rules.initial_pixels and restored.sounds == 1
}
