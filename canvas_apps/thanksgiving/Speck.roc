## Speck draws a robot in the crowd, cheaply enough for hundreds a frame. Near
## the eye it is the whole Robot; farther off, where a robot is a few pixels
## tall, it is one flat outline of legs, body and head in its build's paint,
## a lit band for its eyes, and its two arms only while they are up for the
## wave. A robot off the screen, or too far off to see, is not drawn at all.
import lib.Pixels
import lib.Point
import lib.Shapes
import Crowd
import Robot
import RobotBody
import RobotHead
import View

Speck :: [].{

	member_shapes : View, Crowd.Member -> List(Shapes.Shape)
	member_shapes = |view, member|
		match view.sighting(member.feet) {
			Ok({ point, pixels_per_metre }) =>
				if !is_on_screen(view, { point, pixels_per_metre }) {
					[]
				} else if pixels_per_metre >= whole_robot_scale {
					Robot.figure_shapes({
						build: member.build,
						pose: {
							phase: member.phase,
							stride: member.running.min(1.0),
							sit: 0.0,
							seat_height: 0.4,
							reach: member.arms,
							eye_glow: 1.0,
							look: 0.0,
						},
						feet: point,
						pixels_per_metre,
					})
				} else {
					block_shapes({
						build: member.build,
						arms: member.arms,
						feet: point,
						pixels_per_metre,
					})
				}
			Err(BehindEye) => []
		}
}

# Nearer than this many pixels a metre, a robot is drawn whole.
whole_robot_scale : F64
whole_robot_scale = 40.0

# A robot shorter than a pixel and a half, or wholly off the screen's sides,
# top or bottom, is left out.
is_on_screen : View, { point : Point, pixels_per_metre : F64 } -> Bool
is_on_screen = |view, { point, pixels_per_metre }| {
	x = point.x.to_f64()
	y = point.y.to_f64()
	reach = 2.2 * pixels_per_metre
	pixels_per_metre > 0.7
		and x > 0.0 - reach
		and x < view.screen_width() + reach
		and y > 0.0
		and y < view.screen_height() + reach
}

block_shapes : {
	build : Robot.Build,
	arms : F64,
	feet : Point,
	pixels_per_metre : F64,
} -> List(Shapes.Shape)
block_shapes = |{ build, arms, feet, pixels_per_metre }| {
	body = Robot.proportions(build)
	place = { x: feet.x.to_f64(), y: feet.y.to_f64(), pixels_per_metre }
	eyes =
		if pixels_per_metre < eye_scale {
			[]
		} else {
			[eye_band_shape(place, body)]
		}
	raised_arms =
		if arms < 0.05 {
			[]
		} else {
			[-1.0, 1.0].map(|side| arm_shape(place, { body, side, arms }))
		}
	[[outline_shape(place, body)], eyes, raised_arms].join()
}

# Farther than this many pixels a metre, a robot's eyes are less than a
# pixel and are left out.
eye_scale : F64
eye_scale = 6.0

Place : {
	x : F64,
	y : F64,
	pixels_per_metre : F64,
}

at : Place, F64, F64 -> Point
at = |{ x, y, pixels_per_metre }, across, up| Point.at(
	x + across * pixels_per_metre,
	y - up * pixels_per_metre,
)

# Legs, body and head as one region in the build's paint, its corners in
# order round the edge from the left foot.
outline_shape : Place, RobotBody.Proportions -> Shapes.Shape
outline_shape = |place, body| {
	legs = body.body_width * 0.3
	torso = body.body_width / 2.0
	head = body.head_width / 2.0
	top = body.hip + body.body_height
	crown = top + body.neck + body.head_height
	right_side = [
		(legs, 0.0),
		(legs, body.hip),
		(torso, body.hip),
		(torso, top),
		(head, top),
		(head, crown),
	]
	left_side = [
		(0.0 - head, crown),
		(0.0 - head, top),
		(0.0 - torso, top),
		(0.0 - torso, body.hip),
		(0.0 - legs, body.hip),
		(0.0 - legs, 0.0),
	]
	Shapes.region_from_corners(
		right_side.concat(left_side).map(|(across, up)| at(place, across, up)),
		Flat(body.paint),
	)
}

# A lit band across the head where the eyes are.
eye_band_shape : Place, RobotBody.Proportions -> Shapes.Shape
eye_band_shape = |place, body| {
	band_bottom = body.hip + body.body_height + body.neck + body.head_height * 0.5
	wide = body.head_width * 0.7
	Shapes.rectangle({
		top_left: at(
			place,
			0.0 - wide / 2.0,
			band_bottom + body.head_height * 0.22,
		),
		width: Pixels.of(wide * place.pixels_per_metre),
		height: Pixels.of(body.head_height * 0.22 * place.pixels_per_metre),
		fill: Flat(RobotHead.lit_eye),
	})
}

# An arm swung up from the shoulder on `side`, -1 left and 1 right, as far
# as `arms` says: from hanging at 0 to straight up at 1, drawn thick enough
# to see from far off.
arm_shape : Place,
{
	body : RobotBody.Proportions,
	side : F64,
	arms : F64,
} -> Shapes.Shape
arm_shape = |place, { body, side, arms }| {
	shoulder = {
		across: side * body.body_width / 2.0,
		up: body.hip + body.body_height - body.limb_width,
	}
	angle = side * (0.25 + 2.65 * arms)
	length = body.upper_arm + body.forearm
	Shapes.line(
		{
			from: at(place, shoulder.across, shoulder.up),
			to: at(
				place,
				shoulder.across + angle.sin() * length,
				shoulder.up - angle.cos() * length,
			),
			width: Pixels.of(1.8 * body.limb_width * place.pixels_per_metre),
		},
		Flat(body.trim),
	)
}
