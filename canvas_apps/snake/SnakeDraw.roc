# SnakeDraw -- the Snake board as shapes.
#
# Ported from roc-ray's examples/snake Render.roc, which draws imperatively
# into a Draw.Frame. Here a frame is a VALUE -- a list of shapes -- so this
# answers one instead, and the same list is filled by a canvas in a browser and
# by roc-ray in a window.
#
# The halos are additive, as upstream's are: they are a run of added light.
import lib.Pixels
import lib.Point
import lib.Shapes
import lib.ArgbColor
import lib.Brush
import lib.RgbColor
import lib.Font
import Board
import Rules
import Snake
import lib.Trig

SnakeDraw :: [].{
	w : F64
	w = 800.0
	h : F64
	h = 600.0

	field_top : Brush.Rgba
	field_top = Brush.opaque_rgba(RgbColor.of(0x151d3a))
	field_bottom : Brush.Rgba
	field_bottom = Brush.opaque_rgba(RgbColor.of(0x060810))
	board_fill : Brush.Rgba
	board_fill = Brush.opaque_rgba(RgbColor.of(0x0b1226))
	board_edge : Brush.Rgba
	board_edge = Brush.opaque_rgba(RgbColor.of(0x2a3566))
	grid_line : Brush.Rgba
	grid_line = Brush.opaque_rgba(RgbColor.of(0x16203f))
	snake_head : Brush.Rgba
	snake_head = Brush.opaque_rgba(RgbColor.of(0x7ef7d1))
	snake_tail : Brush.Rgba
	snake_tail = Brush.opaque_rgba(RgbColor.of(0x1d7fb8))
	food_neon : Brush.Rgba
	food_neon = Brush.opaque_rgba(RgbColor.of(0xff6b8b))
	hud_color : Brush.Rgba
	hud_color = Brush.opaque_rgba(RgbColor.of(0xd7e3ff))
	hint_color : RgbColor
	hint_color = RgbColor.of(0x6d7aa8)

	cell : F64
	cell = 26.0
	left : F64
	left = 75.0
	top : F64
	top = 80.0
	board_w : F64
	board_w = 25.0 * cell
	board_h : F64
	board_h = 18.0 * cell

	## One complete Snake frame, back to front.
	frame : Rules.World, F64 -> List(Shapes.Shape)
	frame = |world, elapsed| {
		var $out = List.with_capacity(220)
		# The field, a dark vertical gradient rather than flat black.
		$out = List.append($out, Shapes.rectangle({ top_left: Point.at(0.0, 0.0), width: Pixels.of(w), height: Pixels.of(h), fill: Linear({ stops: { start_color: field_top, end_color: field_bottom, start_offset: 0.0, end_offset: 1.0 }, start_point: Point.at(0.0, 0.0), end_point: Point.at(0.0, h) }) }))
		$out = List.concat($out, hud(world))
		$out = List.concat($out, board({}))
		$out = List.concat($out, glow(world, elapsed))
		$out = List.concat($out, body(world.snake))
		$out = List.concat($out, food(world.food, elapsed))
		List.concat($out, game_over(world, elapsed))
	}

	## The title, the score, and the keys.
	hud : Rules.World -> List(Shapes.Shape)
	hud = |world| {
		score = Str.concat("SCORE ", U64.to_str(world.score))

		hint = "ARROWS / WASD TURN    SPACE RESTART"
		var $out = Font.text_shapes("SNAKE", { top_left: Point.at(left, 26.0), size: 30.0, color: snake_head })
		$out = List.concat($out, Font.text_shapes(score, { top_left: Point.at(w - left - Font.width_of(score, 24.0), 30.0), size: 24.0, color: hud_color }))
		List.concat($out, Font.centered_text_shapes(hint, { top_center: Point.at(w / 2.0, 572.0), size: 17.0, color: Brush.opaque_rgba(hint_color) }))
	}

	## The bordered playfield and its faint lattice.
	board : {} -> List(Shapes.Shape)
	board = |{}| {
		var $out = [
			Shapes.rounded_rect({ top_left: Point.at(left - 10.0, top - 10.0), width: Pixels.of(board_w + 20.0), height: Pixels.of(board_h + 20.0), corner_radius: Pixels.of(8.0), corner_steps: 8 }, Flat(board_edge)),
			Shapes.rounded_rect({ top_left: Point.at(left - 8.0, top - 8.0), width: Pixels.of(board_w + 16.0), height: Pixels.of(board_h + 16.0), corner_radius: Pixels.of(7.0), corner_steps: 8 }, Flat(board_fill)),
		]
		var $c = 0
		while $c <= 25 {
			x = left + I64.to_f64($c) * cell
			$out = List.append($out, Shapes.line({ from: Point.at(x, top), to: Point.at(x, top + board_h), width: Pixels.of(1.0) }, Flat(grid_line)))
			$c = $c + 1
		}
		var $r = 0
		while $r <= 18 {
			y = top + I64.to_f64($r) * cell
			$out = List.append($out, Shapes.line({ from: Point.at(left, y), to: Point.at(left + board_w, y), width: Pixels.of(1.0) }, Flat(grid_line)))
			$r = $r + 1
		}
		$out
	}

	## Where a cell sits on the screen.
	cell_at : Board.Cell -> { x : F64, y : F64 }
	cell_at = |c| { x: left + I32.to_f64(c.x) * cell, y: top + I32.to_f64(c.y) * cell }

	middle_of : Board.Cell -> { x : F64, y : F64 }
	middle_of = |c| {
		p = cell_at(c)
		{ x: p.x + cell / 2.0, y: p.y + cell / 2.0 }
	}

	## Every segment, bright at the head and blue at the tail.
	body : Snake -> List(Shapes.Shape)
	body = |snake| {
		cells = snake.cells
		n = List.len(cells)
		var $out = List.with_capacity(n)
		var $i = 0
		while $i < n {
			c = List.get(cells, $i) ?? { x: 0, y: 0 }
			t = if n <= 1 {
				0.0
			} else {
				U64.to_f64($i) / U64.to_f64(n - 1)
			}
			p = cell_at(c)
			$out = List.append($out, Shapes.rounded_rect({ top_left: Point.at(p.x + 2.0, p.y + 2.0), width: Pixels.of(cell - 4.0), height: Pixels.of(cell - 4.0), corner_radius: Pixels.of(5.0), corner_steps: 6 }, Flat(Brush.mix({ from: snake_head, to: snake_tail, fraction: t }))))
			$i = $i + 1
		}
		$out
	}

	## Halos behind the food and the head, which were additive.
	glow : Rules.World, F64 -> List(Shapes.Shape)
	glow = |world, elapsed| {
		beat = Trig.pulse(elapsed)
		food_spot = middle_of(world.food)
		head_spot = middle_of(world.snake.head())
		food_center = Point.at(food_spot.x, food_spot.y)
		head_center = Point.at(head_spot.x, head_spot.y)
		food_r = cell * (1.0 + 0.5 * beat)
		head_r = cell * 1.5
		Shapes.added_light_shapes([
			Shapes.halo({ center: food_center, radius: Pixels.of(food_r) }, Brush.translucent(ArgbColor.of(0x50ff6b8b))),
			Shapes.halo({ center: head_center, radius: Pixels.of(head_r) }, Brush.translucent(ArgbColor.of(0x407ef7d1))),
		])
	}

	## The apple and its highlight.
	food : Board.Cell, F64 -> List(Shapes.Shape)
	food = |at, elapsed| {
		m = middle_of(at)
		r = cell * (0.3 + 0.04 * Trig.pulse(elapsed))
		[
			Disc({ center: Point.at(m.x, m.y), radius: Pixels.of(r), fill: Flat(food_neon) }),
			Disc({ center: Point.at(m.x - r * 0.3, m.y - r * 0.35), radius: Pixels.of(r * 0.32), fill: Flat(Brush.translucent(ArgbColor.of(0xbeffffff))) }),
		]
	}

	## The panel and the breathing prompt, after a crash.
	game_over : Rules.World, F64 -> List(Shapes.Shape)
	game_over = |world, elapsed|
		match world.state {
			Playing => []
			GameOver => {
				over = "GAME OVER"
				again = "PRESS SPACE TO PLAY AGAIN"
				alpha = 0.59 + 0.41 * Trig.pulse(elapsed)
				var $out = [Shapes.rectangle({ top_left: Point.at(left - 8.0, 236.0), width: Pixels.of(board_w + 16.0), height: Pixels.of(140.0), fill: Flat(Brush.translucent(ArgbColor.of(0xe1060810))) })]
				$out = List.concat($out, Font.centered_text_shapes(over, { top_center: Point.at(w / 2.0, 262.0), size: 40.0, color: food_neon }))
				List.concat($out, Font.centered_text_shapes(again, { top_center: Point.at(w / 2.0, 326.0), size: 19.0, color: Brush.with_alpha(hint_color, alpha) }))
			}
		}
}
