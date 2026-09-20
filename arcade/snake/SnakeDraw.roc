# SnakeDraw -- the Snake board as shapes.
#
# Ported from roc-ray's examples/snake Render.roc, which draws imperatively
# into a Draw.Frame. Here a frame is a VALUE -- a list of shapes -- so this
# answers one instead, and the same list is filled by a canvas in a browser and
# by roc-ray in a window.
#
# **THE GLOW IS APPROXIMATED.** The original wraps its halos in an additive
# blend, and a Shape carries a brush but not a blend mode; these are radial
# fills over the background, which reads close enough at these sizes and costs
# nothing new on any wire.
import ../lib/Shapes
import ../lib/Brush
import ../lib/Font
import Board
import Rules
import Snake
import ../lib/Trig

SnakeDraw :: [].{
	screen_w : F64
	screen_w = 800.0
	screen_h : F64
	screen_h = 600.0

	field_top : Brush.Rgba
	field_top = Brush.opaque(0x151d3a)
	field_bottom : Brush.Rgba
	field_bottom = Brush.opaque(0x060810)
	board_fill : Brush.Rgba
	board_fill = Brush.opaque(0x0b1226)
	board_edge : Brush.Rgba
	board_edge = Brush.opaque(0x2a3566)
	grid_line : Brush.Rgba
	grid_line = Brush.opaque(0x16203f)
	snake_head : Brush.Rgba
	snake_head = Brush.opaque(0x7ef7d1)
	snake_tail : Brush.Rgba
	snake_tail = Brush.opaque(0x1d7fb8)
	food_neon : Brush.Rgba
	food_neon = Brush.opaque(0xff6b8b)
	hud_color : Brush.Rgba
	hud_color = Brush.opaque(0xd7e3ff)
	hint_color : Brush.Rgba
	hint_color = Brush.opaque(0x6d7aa8)

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
		$out = List.append($out, Rect({ x: 0.0, y: 0.0, w: screen_w, h: screen_h, fill: Linear({ c0: field_top, c1: field_bottom, o0: 0.0, o1: 1.0, ax: 0.0, ay: 0.0, dx: 0.0, dy: screen_h, len2: screen_h * screen_h }) }))
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
		score_bytes = Str.to_utf8(score)
		hint = Str.to_utf8("ARROWS / WASD TURN    SPACE RESTART")
		var $out = Font.text(Str.to_utf8("SNAKE"), left, 26.0, 30.0, snake_head)
		$out = List.concat($out, Font.text(score_bytes, screen_w - left - Font.width_of(score_bytes, 24.0), 30.0, 24.0, hud_color))
		List.concat($out, Font.text(hint, (screen_w - Font.width_of(hint, 17.0)) / 2.0, 572.0, 17.0, hint_color))
	}

	## The bordered playfield and its faint lattice.
	board : {} -> List(Shapes.Shape)
	board = |{}| {
		var $out = [
			Shapes.rounded_rect(left - 10.0, top - 10.0, board_w + 20.0, board_h + 20.0, 8.0, 8, Flat(board_edge)),
			Shapes.rounded_rect(left - 8.0, top - 8.0, board_w + 16.0, board_h + 16.0, 7.0, 8, Flat(board_fill)),
		]
		var $c = 0
		while $c <= 25 {
			x = left + I64.to_f64($c) * cell
			$out = List.append($out, Shapes.line(x, top, x, top + board_h, 1.0, Flat(grid_line)))
			$c = $c + 1
		}
		var $r = 0
		while $r <= 18 {
			y = top + I64.to_f64($r) * cell
			$out = List.append($out, Shapes.line(left, y, left + board_w, y, 1.0, Flat(grid_line)))
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
			t = if n <= 1 { 0.0 } else { U64.to_f64($i) / U64.to_f64(n - 1) }
			p = cell_at(c)
			$out = List.append($out, Shapes.rounded_rect(p.x + 2.0, p.y + 2.0, cell - 4.0, cell - 4.0, 5.0, 6, Flat(Brush.mix(snake_head, snake_tail, t))))
			$i = $i + 1
		}
		$out
	}

	## The breathing pulse the food and the restart prompt share.
	pulse : F64 -> F64
	pulse = |elapsed| 0.5 + 0.5 * Trig.r_sin(elapsed * 3.4)

	## Halos behind the food and the head, which were additive.
	glow : Rules.World, F64 -> List(Shapes.Shape)
	glow = |world, elapsed| {
		beat = pulse(elapsed)
		f = middle_of(world.food)
		h = middle_of(world.snake.head())
		food_r = cell * (1.0 + 0.5 * beat)
		head_r = cell * 1.5
		[
			Disc({ x: f.x, y: f.y, r: food_r, fill: Radial({ inner: Brush.with_alpha(0x50ff6b8b), outer: Brush.with_alpha(0x00ff6b8b), x: f.x, y: f.y, r0: 0.0, r1: food_r }), clip: Anywhere }),
			Disc({ x: h.x, y: h.y, r: head_r, fill: Radial({ inner: Brush.with_alpha(0x407ef7d1), outer: Brush.with_alpha(0x007ef7d1), x: h.x, y: h.y, r0: 0.0, r1: head_r }), clip: Anywhere }),
		]
	}

	## The apple and its highlight.
	food : Board.Cell, F64 -> List(Shapes.Shape)
	food = |at, elapsed| {
		m = middle_of(at)
		r = cell * (0.3 + 0.04 * pulse(elapsed))
		[
			Disc({ x: m.x, y: m.y, r: r, fill: Flat(food_neon), clip: Anywhere }),
			Disc({ x: m.x - r * 0.3, y: m.y - r * 0.35, r: r * 0.32, fill: Flat(Brush.with_alpha(0xbeffffff)), clip: Anywhere }),
		]
	}

	## The panel and the breathing prompt, after a crash.
	game_over : Rules.World, F64 -> List(Shapes.Shape)
	game_over = |world, elapsed|
		match world.state {
			Playing => []
			GameOver => {
				over = Str.to_utf8("GAME OVER")
				again = Str.to_utf8("PRESS SPACE TO PLAY AGAIN")
				alpha = 0.59 + 0.41 * pulse(elapsed)
				var $out = [Rect({ x: left - 8.0, y: 236.0, w: board_w + 16.0, h: 140.0, fill: Flat(Brush.with_alpha(0xe1060810)) })]
				$out = List.concat($out, Font.text(over, (screen_w - Font.width_of(over, 40.0)) / 2.0, 262.0, 40.0, food_neon))
				List.concat($out, Font.text(again, (screen_w - Font.width_of(again, 19.0)) / 2.0, 326.0, 19.0, { r: hint_color.r, g: hint_color.g, b: hint_color.b, a: alpha }))
			}
		}
}
