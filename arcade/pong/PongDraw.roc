# PongDraw -- the neon court as shapes.
#
# Ported from roc-ray's examples/pong, whose render! draws into a Draw.Frame.
# Here a frame is a value, so this answers a list of shapes and the same list
# is filled by a canvas in a browser and by roc-ray in a window.
#
# The comet, the halos and the flash are additive, as upstream's are: one
# `Blend(Add)` run covers all three.
import lib.Shapes
import lib.Brush
import lib.Color
import lib.Font
import lib.Math
import Rules

PongDraw :: [].{
	w : F64
	w = 800.0
	h : F64
	h = 600.0

	dash : Brush.Rgba
	dash = Brush.opaque(0x2a3566)

	## One complete Pong frame, back to front.
	frame : Rules.World -> List(Shapes.Shape)
	frame = |world| {
		var $out = List.with_capacity(140)
		# The field, a dark vertical gradient rather than flat black.
		$out = List.append($out, Rect({ x: 0.0, y: 0.0, w: w, h: h, fill: Linear({ c0: Color.brush(Rules.field_top), c1: Color.brush(Rules.field_bottom), o0: 0.0, o1: 1.0, ax: 0.0, ay: 0.0, dx: 0.0, dy: h }) }))
		$out = List.concat($out, center_line({}))
		$out = List.concat($out, scores(world))
		$out = List.append($out, Blend(Add))
		$out = List.concat($out, trail(world))
		$out = List.concat($out, glow(world))
		$out = List.concat($out, wash(world))
		$out = List.append($out, Blend(Over))
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
			$out = List.append($out, Shapes.rounded_rect(w * 0.5 - 2.0, y, 4.0, 22.0, 1.0, 4, Flat(dash)))
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
			c = Color.brush(Rules.ball_neon)
			$out = List.append($out, Disc({ x: F32.to_f64(p.x), y: F32.to_f64(p.y), r: r, fill: Flat({ ..c, a: fade * fade * 0.51 }), clip: Anywhere }))
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

	halo : F64, F64, F64, Color.Rgba -> Shapes.Shape
	halo = |x, y, r, col| Shapes.halo(x, y, r, Color.brush(col), 0.39)

	## The full-field tint after a hit or a point, which decays to nothing.
	wash : Rules.World -> List(Shapes.Shape)
	wash = |world|
		if world.flash.intensity <= 0.0 {
			[]
		} else {
			c = Color.brush(world.flash.color)
			[Rect({ x: 0.0, y: 0.0, w: w, h: h, fill: Flat({ ..c, a: F32.to_f64(world.flash.intensity) * 0.27 }) })]
		}

	## The solid bodies, over their own glow so the edges stay crisp.
	bodies : Rules.World -> List(Shapes.Shape)
	bodies = |world| {
		l = Rules.left_paddle(world.left.paddle_y)
		r = Rules.right_paddle(world.right.paddle_y)
		bx = F32.to_f64(world.ball.pos.x)
		by = F32.to_f64(world.ball.pos.y)
		[
			Shapes.rounded_rect(F32.to_f64(l.x), F32.to_f64(l.y), F32.to_f64(l.width), F32.to_f64(l.height), 7.0, 8, Flat(Color.brush(Rules.left_neon))),
			Shapes.rounded_rect(F32.to_f64(r.x), F32.to_f64(r.y), F32.to_f64(r.width), F32.to_f64(r.height), 7.0, 8, Flat(Color.brush(Rules.right_neon))),
			Disc({ x: bx, y: by, r: 10.0, fill: Flat(Color.brush(Rules.ball_neon)), clip: Anywhere }),
			Disc({ x: bx - 2.0, y: by - 3.0, r: 4.2, fill: Flat(Color.brush(Color.white)), clip: Anywhere }),
		]
	}

	## The two scores, in each player's colour.
	scores : Rules.World -> List(Shapes.Shape)
	scores = |world| {
		left = U64.to_str(world.left.score)
		right = U64.to_str(world.right.score)
		List.concat(
			Font.centered(left, w * 0.32, 30.0, 44.0, Color.brush(Rules.left_neon)),
			Font.centered(right, w * 0.68, 30.0, 44.0, Color.brush(Rules.right_neon)),
		)
	}

	## The hint, always; the winner and the prompt once a match is over.
	banner : Rules.World -> List(Shapes.Shape)
	banner = |world| {
		hint = "W / S MOVE    SPACE NEW MATCH"
		var $out = Font.centered(hint, w / 2.0, h - 34.0, 17.0, Color.brush(Rules.hint_color))
		if Rules.is_over(world) {
			left_won = world.left.score >= 5
			won = if left_won { "LEFT WINS" } else { "RIGHT WINS" }
			again = "PRESS SPACE FOR A NEW MATCH"
			tint = if left_won { Rules.left_neon } else { Rules.right_neon }
			dim = Color.brush(Rules.field_bottom)
			$out = List.concat([Rect({ x: 0.0, y: 0.0, w: w, h: h, fill: Flat({ ..dim, a: 0.75 }) })], $out)
			$out = List.concat($out, Font.centered(won, w / 2.0, 248.0, 40.0, Color.brush(tint)))
			List.concat($out, Font.centered(again, w / 2.0, 316.0, 19.0, Color.brush(Rules.hint_color)))
		} else {
			$out
		}
	}
}
