# BreakoutDraw -- the cabinet as shapes.
#
# Ported from roc-ray's examples/breakout Render.roc, which draws into a
# Draw.Frame. Here a frame is a value, so this answers a list of shapes.
#
# The halos are additive, as upstream's are: `Blend(Add)` marks the run.
import lib.Shapes
import lib.Brush
import lib.Color
import lib.Font
import lib.Math
import lib.Trig
import Ball
import Bricks
import Paddle
import Rules

BreakoutDraw :: [].{
	w : F64
	w = 800.0
	h : F64
	h = 600.0

	field_top : Color.Rgba
	field_top = Color.from_hex_rgb(0x161d3c)
	field_bottom : Color.Rgba
	field_bottom = Color.from_hex_rgb(0x05070f)
	paddle_neon : Color.Rgba
	paddle_neon = Color.from_hex_rgb(0x38e8ff)
	ball_neon : Color.Rgba
	ball_neon = Color.from_hex_rgb(0xffe08a)
	hud_color : Color.Rgba
	hud_color = Color.from_hex_rgb(0xd7e3ff)
	hint_color : Color.Rgba
	hint_color = Color.from_hex_rgb(0x6d7aa8)
	rule_color : Color.Rgba
	rule_color = Color.from_hex_rgb(0x2a3566)

	## One complete Breakout frame, back to front.
	frame : Rules.World, F64 -> List(Shapes.Shape)
	frame = |world, elapsed| {
		var $out = [Rect({ x: 0.0, y: 0.0, w: w, h: h, fill: Linear({ c0: Color.brush(field_top), c1: Color.brush(field_bottom), o0: 0.0, o1: 1.0, ax: 0.0, ay: 0.0, dx: 0.0, dy: h }) })]
		$out = List.concat($out, hud(world))
		$out = List.concat($out, bricks(world.bricks))
		$out = List.concat($out, glow(world))
		$out = List.concat($out, bodies(world))
		List.concat($out, overlay(world, elapsed))
	}

	## The title, the score, the lives, the rule under them, and the keys.
	hud : Rules.World -> List(Shapes.Shape)
	hud = |world| {
		score = Str.concat("SCORE ", U64.to_str(world.score))
		lives = Str.concat("LIVES ", U64.to_str(world.lives))
		hint = "LEFT / RIGHT MOVE    SPACE LAUNCH"
		var $out = Font.text("BREAKOUT", 44.0, 22.0, 26.0, Color.brush(paddle_neon))
		$out = List.concat($out, Font.text(score, 330.0, 26.0, 22.0, Color.brush(hud_color)))
		$out = List.concat($out, Font.text(lives, 560.0, 26.0, 22.0, Color.brush(hud_color)))
		$out = List.append($out, Shapes.line(44.0, 58.0, 756.0, 58.0, 2.0, Flat(Color.brush(rule_color))))
		List.concat($out, Font.centered(hint, w / 2.0, 572.0, 17.0, Color.brush(hint_color)))
	}

	## Every brick still standing, each with a bright top-edge sheen.
	bricks : List(Bricks.Brick) -> List(Shapes.Shape)
	bricks = |wall| {
		n = List.len(wall)
		var $out = List.with_capacity(2 * n)
		var $i = 0
		while $i < n {
			b = List.get(wall, $i) ?? { id: 0, rect: { x: 0, y: 0, width: 0, height: 0 }, color: paddle_neon }
			x = F32.to_f64(b.rect.x)
			y = F32.to_f64(b.rect.y)
			bw = F32.to_f64(b.rect.width)
			bh = F32.to_f64(b.rect.height)
			face = Color.brush(b.color)
			$out = List.append($out, Shapes.rounded_rect(x, y, bw, bh, 5.0, 6, Flat({ ..face, a: 0.92 })))
			$out = List.append($out, Rect({ x: x + 5.0, y: y + 3.0, w: bw - 10.0, h: 3.0, fill: Flat({ r: 255.0, g: 255.0, b: 255.0, a: 0.43 }) }))
			$i = $i + 1
		}
		$out
	}

	## A halo on the paddle and one on the ball.
	glow : Rules.World -> List(Shapes.Shape)
	glow = |world| {
		p = Math.center(world.paddle.rect())
		[
			Blend(Add),
			halo(F32.to_f64(p.x), F32.to_f64(p.y), 90.0, paddle_neon),
			halo(F32.to_f64(world.ball.pos.x), F32.to_f64(world.ball.pos.y), 46.0, ball_neon),
			Blend(Over),
		]
	}

	halo : F64, F64, F64, Color.Rgba -> Shapes.Shape
	halo = |x, y, r, col| Shapes.halo(x, y, r, Color.brush(col), 0.37)

	## The solid paddle and ball, over their glows.
	bodies : Rules.World -> List(Shapes.Shape)
	bodies = |world| {
		p = world.paddle.rect()
		px = F32.to_f64(p.x)
		py = F32.to_f64(p.y)
		pw = F32.to_f64(p.width)
		ph = F32.to_f64(p.height)
		bx = F32.to_f64(world.ball.pos.x)
		by = F32.to_f64(world.ball.pos.y)
		r = F32.to_f64(Ball.radius)
		[
			Shapes.rounded_rect(px, py, pw, ph, ph / 2.0, 8, Flat(Color.brush(paddle_neon))),
			Rect({ x: px + 8.0, y: py + 3.0, w: pw - 16.0, h: 3.0, fill: Flat({ r: 255.0, g: 255.0, b: 255.0, a: 0.59 }) }),
			Disc({ x: bx, y: by, r: r, fill: Flat(Color.brush(ball_neon)), clip: Anywhere }),
			Disc({ x: bx - 2.0, y: by - 2.0, r: r * 0.4, fill: Flat({ r: 255.0, g: 255.0, b: 255.0, a: 0.82 }), clip: Anywhere }),
		]
	}

	## Waiting text pulses between translucent and opaque.
	prompt_alpha : F64 -> F64
	prompt_alpha = |elapsed| 0.59 + 0.41 * Trig.pulse(elapsed)

	## The launch prompt, or the banner a finished match earns.
	overlay : Rules.World, F64 -> List(Shapes.Shape)
	overlay = |world, elapsed|
		match world.state {
			Ready => {
				line = "PRESS SPACE TO LAUNCH"
				c = Color.brush(hud_color)
				Font.centered(line, w / 2.0, 340.0, 22.0, { ..c, a: prompt_alpha(elapsed) })
			}
			Playing => []
			Won => banner("WALL CLEARED", Color.from_hex_rgb(0x4ce0b3), elapsed)
			GameOver => banner("GAME OVER", Color.from_hex_rgb(0xff4f7d), elapsed)
		}

	banner : Str, Color.Rgba, F64 -> List(Shapes.Shape)
	banner = |line, accent, elapsed| {
		dim = Color.brush(field_bottom)
		edge = Color.brush(accent)
		again = "PRESS SPACE TO PLAY AGAIN"
		hint = Color.brush(hint_color)
		var $out = [
			Shapes.rounded_rect(188.0, 274.0, 424.0, 128.0, 18.0, 8, Flat({ ..edge, a: 0.47 })),
			Shapes.rounded_rect(190.0, 276.0, 420.0, 124.0, 17.0, 8, Flat({ ..dim, a: 0.91 })),
		]
		$out = List.concat($out, Font.centered(line, w / 2.0, 304.0, 30.0, Color.brush(accent)))
		List.concat($out, Font.centered(again, w / 2.0, 356.0, 17.0, { ..hint, a: prompt_alpha(elapsed) }))
	}
}
