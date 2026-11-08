# PongDraw -- the neon court as shapes.
#
# Ported from roc-ray's examples/pong, whose render! draws into a Draw.Frame.
# Here a frame is a value, so this answers a list of shapes and the same list
# is filled by a canvas in a browser and by roc-ray in a window.
#
# The comet, the halos and the flash are additive, as upstream's are: one run
# of added light covers all three.
import lib.Shapes
import lib.Brush
import lib.RgbColor
import lib.Font
import lib.Math
import Rules

PongDraw :: [].{
	w : F64
	w = 800.0
	h : F64
	h = 600.0

	dash : Brush.Rgba
	dash = Brush.opaque_rgba(RgbColor.of(0x2a3566))

	## One complete Pong frame, back to front.
	frame : Rules.World -> List(Shapes.Shape)
	frame = |world| {
		var $out = List.with_capacity(140)
		# The field, a dark vertical gradient rather than flat black.
		$out = List.append($out, Rect({ x: 0.0, y: 0.0, width: w, height: h, fill: Linear({ stops: { start_color: Brush.opaque_rgba(Rules.field_top), end_color: Brush.opaque_rgba(Rules.field_bottom), start_offset: 0.0, end_offset: 1.0 }, start_point: { x: 0.0, y: 0.0 }, end_point: { x: 0.0, y: h } }) }))
		$out = List.concat($out, center_line({}))
		$out = List.concat($out, scores(world))
		$out = List.concat($out, Shapes.added_light_shapes([trail(world), glow(world), wash(world)].join()))
		$out = List.concat($out, bodies(world))
		List.concat($out, banner(world))
	}

	## Soft dashes rather than one hard rule.
	center_line : {} -> List(Shapes.Shape)
	center_line = |{}| {
		var $out = List.with_capacity(15)
		var $i = 0
		while $i < 15 {
			y = 12.0 + I64.to_f64($i) * 40.0
			$out = List.append($out, Shapes.rounded_rect({ x: w * 0.5 - 2.0, y, width: 4.0, height: 22.0, corner_radius: 1.0, corner_steps: 4 }, Flat(dash)))
			$i = $i + 1
		}
		$out
	}

	## Newest first, so the index is the age of the sample.
	trail : Rules.World -> List(Shapes.Shape)
	trail = |world| {
		n = List.len(world.trail)
		var $out = List.with_capacity(n)
		var $i = 0
		while $i < n {
			p = List.get(world.trail, $i) ?? { x: 0, y: 0 }
			fade = 1.0 - U64.to_f64($i) / 14.0
			r = 10.0 * (0.35 + 0.55 * fade)
			$out = List.append($out, Disc({ x: F32.to_f64(p.x), y: F32.to_f64(p.y), radius: r, fill: Flat(Brush.with_alpha(Rules.ball_neon, fade * fade * 0.51)) }))
			$i = $i + 1
		}
		$out
	}

	## A halo on each paddle and one on the ball.
	glow : Rules.World -> List(Shapes.Shape)
	glow = |world| {
		l = Math.center(Rules.left_paddle(world.left.paddle_y))
		r = Math.center(Rules.right_paddle(world.right.paddle_y))
		[
			halo(F32.to_f64(l.x), F32.to_f64(l.y), 68.0, Rules.left_neon),
			halo(F32.to_f64(r.x), F32.to_f64(r.y), 68.0, Rules.right_neon),
			halo(F32.to_f64(world.ball.pos.x), F32.to_f64(world.ball.pos.y), 46.0, Rules.ball_neon),
		]
	}

	halo : F64, F64, F64, RgbColor -> Shapes.Shape
	halo = |x, y, radius, color| Shapes.halo({ center: { x, y }, radius }, Brush.with_alpha(color, 0.39))

	## The full-field tint after a hit or a point, which decays to nothing.
	wash : Rules.World -> List(Shapes.Shape)
	wash = |world|
		if world.flash.intensity <= 0.0 {
			[]
		} else {
			[Rect({ x: 0.0, y: 0.0, width: w, height: h, fill: Flat(Brush.with_alpha(world.flash.color, F32.to_f64(world.flash.intensity) * 0.27)) })]
		}

	## The solid bodies, over their own glow so the edges stay crisp.
	bodies : Rules.World -> List(Shapes.Shape)
	bodies = |world| {
		l = Rules.left_paddle(world.left.paddle_y)
		r = Rules.right_paddle(world.right.paddle_y)
		bx = F32.to_f64(world.ball.pos.x)
		by = F32.to_f64(world.ball.pos.y)
		[
			Shapes.rounded_rect({ x: F32.to_f64(l.x), y: F32.to_f64(l.y), width: F32.to_f64(l.width), height: F32.to_f64(l.height), corner_radius: 7.0, corner_steps: 8 }, Brush.flat(Rules.left_neon)),
			Shapes.rounded_rect({ x: F32.to_f64(r.x), y: F32.to_f64(r.y), width: F32.to_f64(r.width), height: F32.to_f64(r.height), corner_radius: 7.0, corner_steps: 8 }, Brush.flat(Rules.right_neon)),
			Disc({ x: bx, y: by, radius: 10.0, fill: Brush.flat(Rules.ball_neon) }),
			Disc({ x: bx - 2.0, y: by - 3.0, radius: 4.2, fill: Brush.flat(RgbColor.of(0xffffff)) }),
		]
	}

	## The two scores, in each player's colour.
	scores : Rules.World -> List(Shapes.Shape)
	scores = |world| {
		left = U64.to_str(world.left.score)
		right = U64.to_str(world.right.score)
		List.concat(
			Font.centered_text_shapes(left, { top_center: { x: w * 0.32, y: 30.0 }, size: 44.0, color: Brush.opaque_rgba(Rules.left_neon) }),
			Font.centered_text_shapes(right, { top_center: { x: w * 0.68, y: 30.0 }, size: 44.0, color: Brush.opaque_rgba(Rules.right_neon) }),
		)
	}

	## The hint, always; the winner and the prompt once a match is over.
	banner : Rules.World -> List(Shapes.Shape)
	banner = |world| {
		hint = "W / S MOVE    SPACE NEW MATCH"
		var $out = Font.centered_text_shapes(hint, { top_center: { x: w / 2.0, y: h - 34.0 }, size: 17.0, color: Brush.opaque_rgba(Rules.hint_color) })
		if Rules.is_over(world) {
			left_won = world.left.score >= 5
			won = if left_won {
				"LEFT WINS"
			} else {
				"RIGHT WINS"
			}
			again = "PRESS SPACE FOR A NEW MATCH"
			tint = if left_won {
				Rules.left_neon
			} else {
				Rules.right_neon
			}
			$out = List.concat([Rect({ x: 0.0, y: 0.0, width: w, height: h, fill: Flat(Brush.with_alpha(Rules.field_bottom, 0.75)) })], $out)
			$out = List.concat($out, Font.centered_text_shapes(won, { top_center: { x: w / 2.0, y: 248.0 }, size: 40.0, color: Brush.opaque_rgba(tint) }))
			List.concat($out, Font.centered_text_shapes(again, { top_center: { x: w / 2.0, y: 316.0 }, size: 19.0, color: Brush.opaque_rgba(Rules.hint_color) }))
		} else {
			$out
		}
	}
}
