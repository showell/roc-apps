# BreakoutDraw -- the cabinet as shapes.
#
# Ported from roc-ray's examples/breakout Render.roc, which draws into a
# Draw.Frame. Here a frame is a value, so this answers a list of shapes.
#
# The halos are additive, as upstream's are: they are a run of added light.
import lib.Shapes
import lib.Brush
import lib.RgbColor
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

	field_top : RgbColor
	field_top = RgbColor.of(0x161d3c)
	field_bottom : RgbColor
	field_bottom = RgbColor.of(0x05070f)
	paddle_neon : RgbColor
	paddle_neon = RgbColor.of(0x38e8ff)
	ball_neon : RgbColor
	ball_neon = RgbColor.of(0xffe08a)
	hud_color : RgbColor
	hud_color = RgbColor.of(0xd7e3ff)
	hint_color : RgbColor
	hint_color = RgbColor.of(0x6d7aa8)
	rule_color : RgbColor
	rule_color = RgbColor.of(0x2a3566)
	white : RgbColor
	white = RgbColor.of(0xffffff)

	## One complete Breakout frame, back to front.
	frame : Rules.World, F64 -> List(Shapes.Shape)
	frame = |world, elapsed| {
		var $out = [Rect({ x: 0.0, y: 0.0, width: w, height: h, fill: Linear({ stops: { start_color: Brush.opaque(field_top), end_color: Brush.opaque(field_bottom), start_offset: 0.0, end_offset: 1.0 }, start_point: { x: 0.0, y: 0.0 }, end_point: { x: 0.0, y: h } }) })]
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
		var $out = Font.text_shapes("BREAKOUT", { top_left: { x: 44.0, y: 22.0 }, size: 26.0, color: Brush.opaque(paddle_neon) })
		$out = List.concat($out, Font.text_shapes(score, { top_left: { x: 330.0, y: 26.0 }, size: 22.0, color: Brush.opaque(hud_color) }))
		$out = List.concat($out, Font.text_shapes(lives, { top_left: { x: 560.0, y: 26.0 }, size: 22.0, color: Brush.opaque(hud_color) }))
		$out = List.append($out, Shapes.line({ from: { x: 44.0, y: 58.0 }, to: { x: 756.0, y: 58.0 }, width: 2.0 }, Brush.flat(rule_color)))
		List.concat($out, Font.centered(hint, { top_center: { x: w / 2.0, y: 572.0 }, size: 17.0, color: Brush.opaque(hint_color) }))
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
			$out = List.append($out, Shapes.rounded_rect({ x, y, width: bw, height: bh, corner_radius: 5.0, corner_steps: 6 }, Flat(Brush.with_alpha(b.color, 0.92))))
			$out = List.append($out, Rect({ x: x + 5.0, y: y + 3.0, width: bw - 10.0, height: 3.0, fill: Flat(Brush.with_alpha(white, 0.43)) }))
			$i = $i + 1
		}
		$out
	}

	## A halo on the paddle and one on the ball.
	glow : Rules.World -> List(Shapes.Shape)
	glow = |world| {
		p = Math.center(world.paddle.rect())
		Shapes.added_light([
			halo(F32.to_f64(p.x), F32.to_f64(p.y), 90.0, paddle_neon),
			halo(F32.to_f64(world.ball.pos.x), F32.to_f64(world.ball.pos.y), 46.0, ball_neon),
		])
	}

	halo : F64, F64, F64, RgbColor -> Shapes.Shape
	halo = |x, y, radius, color| Shapes.halo({ center: { x, y }, radius }, Brush.with_alpha(color, 0.37))

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
			Shapes.rounded_rect({ x: px, y: py, width: pw, height: ph, corner_radius: ph / 2.0, corner_steps: 8 }, Brush.flat(paddle_neon)),
			Rect({ x: px + 8.0, y: py + 3.0, width: pw - 16.0, height: 3.0, fill: Flat(Brush.with_alpha(white, 0.59)) }),
			Disc({ x: bx, y: by, radius: r, fill: Brush.flat(ball_neon) }),
			Disc({ x: bx - 2.0, y: by - 2.0, radius: r * 0.4, fill: Flat(Brush.with_alpha(white, 0.82)) }),
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
				Font.centered(line, { top_center: { x: w / 2.0, y: 340.0 }, size: 22.0, color: Brush.with_alpha(hud_color, prompt_alpha(elapsed)) })
			}
			Playing => []
			Won => banner("WALL CLEARED", RgbColor.of(0x4ce0b3), elapsed)
			GameOver => banner("GAME OVER", RgbColor.of(0xff4f7d), elapsed)
		}

	banner : Str, RgbColor, F64 -> List(Shapes.Shape)
	banner = |line, accent, elapsed| {
		again = "PRESS SPACE TO PLAY AGAIN"
		var $out = [
			Shapes.rounded_rect({ x: 188.0, y: 274.0, width: 424.0, height: 128.0, corner_radius: 18.0, corner_steps: 8 }, Flat(Brush.with_alpha(accent, 0.47))),
			Shapes.rounded_rect({ x: 190.0, y: 276.0, width: 420.0, height: 124.0, corner_radius: 17.0, corner_steps: 8 }, Flat(Brush.with_alpha(field_bottom, 0.91))),
		]
		$out = List.concat($out, Font.centered(line, { top_center: { x: w / 2.0, y: 304.0 }, size: 30.0, color: Brush.opaque(accent) }))
		List.concat($out, Font.centered(again, { top_center: { x: w / 2.0, y: 356.0 }, size: 17.0, color: Brush.with_alpha(hint_color, prompt_alpha(elapsed)) }))
	}
}
