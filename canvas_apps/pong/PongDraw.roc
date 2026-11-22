## PongDraw draws the neon court as shapes.
##
## A frame is a value, so this module answers a list of shapes, which a canvas
## fills in a browser.
##
## The comet, the halos and the flash are additive: one run of added light
## covers all three.
import lib.Pixels
import lib.Point
import lib.Shapes
import lib.CurvedShapes
import lib.Brush
import lib.RgbColor
import lib.Font
import lib.Math
import Rules

PongDraw :: [].{
	court_width : F64
	court_width = 800.0
	court_height : F64
	court_height = 600.0

	dash : Brush.Rgba
	dash = Brush.opaque_rgba(RgbColor.of(0x2a3566))

	## One complete Pong frame, back to front.
	frame_shapes : Rules.World -> List(Shapes.Shape)
	frame_shapes = |world| {
		var $out = List.with_capacity(140)
		# The field, a dark vertical gradient rather than flat black.
		$out = List.append($out, Shapes.rectangle({ top_left: Point.at(0.0, 0.0), width: Pixels.of(court_width), height: Pixels.of(court_height), fill: Linear({ stops: { start_color: Brush.opaque_rgba(Rules.field_top), end_color: Brush.opaque_rgba(Rules.field_bottom), start_offset: 0.0, end_offset: 1.0 }, start_point: Point.at(0.0, 0.0), end_point: Point.at(0.0, court_height) }) }))
		$out = List.concat($out, center_line_shapes({}))
		$out = List.concat($out, scores(world))
		$out = List.concat($out, Shapes.added_light_shapes([trail_shapes(world), glow_shapes(world), wash_shapes(world)].join()))
		$out = List.concat($out, bodies(world))
		List.concat($out, banner_shapes(world))
	}

	## Soft dashes rather than one hard rule.
	center_line_shapes : {} -> List(Shapes.Shape)
	center_line_shapes = |{}| {
		var $out = List.with_capacity(15)
		var $i = 0
		while $i < 15 {
			y = 12.0 + I64.to_f64($i) * 40.0
			$out = List.append($out, CurvedShapes.rounded_rect({ top_left: Point.at(court_width * 0.5 - 2.0, y), width: Pixels.of(4.0), height: Pixels.of(22.0), corner_radius: Pixels.of(1.0), corner_steps: 4 }, Flat(dash)))
			$i = $i + 1
		}
		$out
	}

	## Newest first, so the index is the age of the sample.
	trail_shapes : Rules.World -> List(Shapes.Shape)
	trail_shapes = |world| {
		sample_count = List.len(world.trail_positions)
		var $out = List.with_capacity(sample_count)
		var $i = 0
		while $i < sample_count {
			sample = List.get(world.trail_positions, $i) ?? { x: 0, y: 0 }
			fade = 1.0 - U64.to_f64($i) / 14.0
			radius = 10.0 * (0.35 + 0.55 * fade)
			$out = List.append($out, Disc({ center: Point.at(F32.to_f64(sample.x), F32.to_f64(sample.y)), radius: Pixels.of(radius), fill: Flat(Brush.with_alpha(Rules.ball_neon, fade * fade * 0.51)) }))
			$i = $i + 1
		}
		$out
	}

	## A halo on each paddle and one on the ball.
	glow_shapes : Rules.World -> List(Shapes.Shape)
	glow_shapes = |world| {
		left_center = Math.center(Rules.left_paddle(world.left.paddle_y))
		right_center = Math.center(Rules.right_paddle(world.right.paddle_y))
		[
			halo(F32.to_f64(left_center.x), F32.to_f64(left_center.y), 68.0, Rules.left_neon),
			halo(F32.to_f64(right_center.x), F32.to_f64(right_center.y), 68.0, Rules.right_neon),
			halo(F32.to_f64(world.ball.position.x), F32.to_f64(world.ball.position.y), 46.0, Rules.ball_neon),
		]
	}

	halo : F64, F64, F64, RgbColor -> Shapes.Shape
	halo = |x, y, radius, color| Shapes.halo({ center: Point.at(x, y), radius: Pixels.of(radius) }, Brush.with_alpha(color, 0.39))

	## The full-field tint after a hit or a point, which decays to nothing.
	wash_shapes : Rules.World -> List(Shapes.Shape)
	wash_shapes = |world|
		if world.flash.intensity <= 0.0 {
			[]
		} else {
			[Shapes.rectangle({ top_left: Point.at(0.0, 0.0), width: Pixels.of(court_width), height: Pixels.of(court_height), fill: Flat(Brush.with_alpha(world.flash.color, F32.to_f64(world.flash.intensity) * 0.27)) })]
		}

	## The solid bodies, over their own glow so the edges stay crisp.
	bodies : Rules.World -> List(Shapes.Shape)
	bodies = |world| {
		left_rect = Rules.left_paddle(world.left.paddle_y)
		right_rect = Rules.right_paddle(world.right.paddle_y)
		bx = F32.to_f64(world.ball.position.x)
		by = F32.to_f64(world.ball.position.y)
		[
			CurvedShapes.rounded_rect({ top_left: Point.at(F32.to_f64(left_rect.x), F32.to_f64(left_rect.y)), width: Pixels.of(F32.to_f64(left_rect.width)), height: Pixels.of(F32.to_f64(left_rect.height)), corner_radius: Pixels.of(7.0), corner_steps: 8 }, Brush.flat(Rules.left_neon)),
			CurvedShapes.rounded_rect({ top_left: Point.at(F32.to_f64(right_rect.x), F32.to_f64(right_rect.y)), width: Pixels.of(F32.to_f64(right_rect.width)), height: Pixels.of(F32.to_f64(right_rect.height)), corner_radius: Pixels.of(7.0), corner_steps: 8 }, Brush.flat(Rules.right_neon)),
			Disc({ center: Point.at(bx, by), radius: Pixels.of(10.0), fill: Brush.flat(Rules.ball_neon) }),
			Disc({ center: Point.at(bx - 2.0, by - 3.0), radius: Pixels.of(4.2), fill: Brush.flat(RgbColor.of(0xffffff)) }),
		]
	}

	## The two scores, in each player's colour.
	scores : Rules.World -> List(Shapes.Shape)
	scores = |world| {
		left = U64.to_str(world.left.score)
		right = U64.to_str(world.right.score)
		List.concat(
			Font.centered_text_shapes(left, { top_center: Point.at(court_width * 0.32, 30.0), size: 44.0, color: Brush.opaque_rgba(Rules.left_neon) }),
			Font.centered_text_shapes(right, { top_center: Point.at(court_width * 0.68, 30.0), size: 44.0, color: Brush.opaque_rgba(Rules.right_neon) }),
		)
	}

	## The hint, always; the winner and the prompt once a match is over.
	banner_shapes : Rules.World -> List(Shapes.Shape)
	banner_shapes = |world| {
		hint = "W / S MOVE    SPACE NEW MATCH"
		var $out = Font.centered_text_shapes(hint, { top_center: Point.at(court_width / 2.0, court_height - 34.0), size: 17.0, color: Brush.opaque_rgba(Rules.hint_color) })
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
			$out = List.concat([Shapes.rectangle({ top_left: Point.at(0.0, 0.0), width: Pixels.of(court_width), height: Pixels.of(court_height), fill: Flat(Brush.with_alpha(Rules.field_bottom, 0.75)) })], $out)
			$out = List.concat($out, Font.centered_text_shapes(won, { top_center: Point.at(court_width / 2.0, 248.0), size: 40.0, color: Brush.opaque_rgba(tint) }))
			List.concat($out, Font.centered_text_shapes(again, { top_center: Point.at(court_width / 2.0, 316.0), size: 19.0, color: Brush.opaque_rgba(Rules.hint_color) }))
		} else {
			$out
		}
	}
}
