## Speck draws a robot in the crowd, cheaply enough for hundreds a frame. Near
## the eye it is the whole Robot; farther off, where a robot is a few pixels
## tall, it is one flat outline in its build's paint with the marks that
## still say robot at a few pixels: a box of a head on a neck, an antenna
## with a red light, square shoulders, and, nearer, a lit visor. Its two arms show only while they are up for
## the wave. A robot off the screen, or too far off to see, is not drawn at
## all.
import lib.Brush
import lib.Pixels
import lib.Point
import lib.RgbColor
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
	shape = silhouette(body)
	visor =
		if pixels_per_metre < visor_scale {
			[]
		} else {
			[visor_shape(place, shape)]
		}
	raised_arms =
		if arms < 0.05 {
			[]
		} else {
			[-1.0, 1.0].map(|side| arm_shape(place, { body, side, arms }))
		}
	[
		[outline_shape(place, { body, shape })],
		visor,
		[beacon_shape(place, shape)],
		raised_arms,
	].join()
}

# Farther than this many pixels a metre, a robot in a block is too small
# for its visor to show, so only the outline and the antenna's light are
# drawn.
visor_scale : F64
visor_scale = 3.0

antenna_length : F64
antenna_length = 0.16

stalk_half : F64
stalk_half = 0.016

# A red light on every antenna, which shows as a speck over the head however
# far off the robot is.
beacon : Brush.Rgba
beacon = Brush.opaque_rgba(RgbColor.of(0xFF5A48))

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

# How big the head is drawn in a block, bigger and squarer than the build's
# own, with a neck to set it off, so it reads as a box on a stick from far
# off: how wide and high the head is, where its bottom and top are, and how
# wide the neck is.
Silhouette : {
	head_half : F64,
	head_bottom : F64,
	crown : F64,
	neck_half : F64,
}

silhouette : RobotBody.Proportions -> Silhouette
silhouette = |body| {
	head_half = 0.6 * body.head_width.max(0.7 * body.body_width)
	head_bottom = body.hip + body.body_height + body.neck.max(0.06)
	{
		head_half,
		head_bottom,
		crown: head_bottom + 1.2 * body.head_height.max(0.2),
		neck_half: 0.25 * head_half,
	}
}

# Legs or a wheel's post, a square-shouldered body, a neck, a box of a head
# and the antenna's stalk as one region in the build's paint, its corners
# in order round the edge from the right foot.
outline_shape : Place, { body : RobotBody.Proportions, shape : Silhouette } -> Shapes.Shape
outline_shape = |place, { body, shape }| {
	torso = body.body_width / 2.0
	top = body.hip + body.body_height
	below =
		match body.moves_on {
			Legs => {
				legs = body.body_width * 0.32
				[(legs, 0.0), (legs, body.hip)]
			}
			Wheel => [(0.04, 0.0), (0.04, body.hip)]
		}
	above = [
		(torso, body.hip),
		(torso, top),
		(shape.neck_half, top),
		(shape.neck_half, shape.head_bottom),
		(shape.head_half, shape.head_bottom),
		(shape.head_half, shape.crown),
		(stalk_half, shape.crown),
		(stalk_half, shape.crown + antenna_length),
	]
	right_side = List.concat(below, above)
	# The left side is the right one mirrored, walked back from the crown.
	var $left_side = List.with_capacity(right_side.len())
	var $k = right_side.len()
	while $k > 0 {
		$k = $k - 1
		(across, up) = right_side.get($k) ?? crash "Speck.outline_shape: a corner on each side"
		$left_side = $left_side.append((0.0 - across, up))
	}
	Shapes.region_from_corners(
		right_side.concat($left_side).map(|(across, up)| at(place, across, up)),
		Flat(body.paint),
	)
}

# A lit visor across the face, never thinner than a pixel, so the eyes show
# as a bright band at any distance.
visor_shape : Place, Silhouette -> Shapes.Shape
visor_shape = |place, shape| {
	high = shape.crown - shape.head_bottom
	band = (0.34 * high * place.pixels_per_metre).max(1.0)
	wide = 1.6 * shape.head_half
	Shapes.rectangle({
		top_left: at(place, 0.0 - wide / 2.0, shape.head_bottom + 0.7 * high),
		width: Pixels.of(wide * place.pixels_per_metre),
		height: Pixels.of(band),
		fill: Flat(RobotHead.lit_eye),
	})
}

# The antenna's light, a square that is never less than a pixel and a
# half across, which costs a canvas less than a round dot and looks the
# same at a few pixels.
beacon_shape : Place, Silhouette -> Shapes.Shape
beacon_shape = |place, shape| {
	side = (0.1 * place.pixels_per_metre).max(1.5)
	middle = at(place, 0.0, shape.crown + antenna_length)
	Shapes.rectangle({
		top_left: Point.at(middle.x.to_f64() - side / 2.0, middle.y.to_f64() - side / 2.0),
		width: Pixels.of(side),
		height: Pixels.of(side),
		fill: Flat(beacon),
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
