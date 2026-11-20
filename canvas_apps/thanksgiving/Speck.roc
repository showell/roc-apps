## Speck draws a robot in the crowd, cheaply enough for hundreds a frame. Near
## the eye it is the whole Robot; farther off, where a robot is a few pixels
## tall, it is six flat blocks in its build's proportions and colors: legs,
## body, head, a lit band for the eyes, and two arms that go up for the wave.
## A robot off the screen, or too far off to see, is not drawn at all.
import lib.Pixels
import lib.Point
import lib.Shapes
import Crowd
import Robot
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
					block_shapes({ build: member.build, arms: member.arms, feet: point, pixels_per_metre })
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
	x = feet.x.to_f64()
	y = feet.y.to_f64()
	at = |across, up| Point.at(x + across * pixels_per_metre, y - up * pixels_per_metre)
	block = |{ across, up, wide, high }, fill|
		Shapes.rectangle({
			top_left: at(across - wide / 2.0, up + high),
			width: Pixels.of(wide * pixels_per_metre),
			height: Pixels.of(high * pixels_per_metre),
			fill,
		})
	top = body.hip + body.body_height
	head_bottom = top + body.neck
	shoulder_up = top - body.limb_width
	arm_length = body.upper_arm + body.forearm
	arm = |side| {
		angle = side * (0.25 + 2.65 * arms)
		Shapes.line(
			{
				from: at(side * body.body_width / 2.0, shoulder_up),
				to: at(
					side * body.body_width / 2.0 + angle.sin() * arm_length,
					shoulder_up - angle.cos() * arm_length,
				),
				width: Pixels.of(body.limb_width * pixels_per_metre),
			},
			Flat(body.trim),
		)
	}
	[
		block({ across: 0.0, up: 0.0, wide: body.body_width * 0.6, high: body.hip }, Flat(body.trim)),
		block({ across: 0.0, up: body.hip, wide: body.body_width, high: body.body_height }, Flat(body.paint)),
		block({ across: 0.0, up: head_bottom, wide: body.head_width, high: body.head_height }, Flat(body.paint)),
		block(
			{
				across: 0.0,
				up: head_bottom + body.head_height * 0.5,
				wide: body.head_width * 0.7,
				high: body.head_height * 0.22,
			},
			Flat(RobotHead.lit_eye),
		),
		arm(-1.0),
		arm(1.0),
	]
}
