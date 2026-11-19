## Robot draws one of the three dinner guests, face on, from what it is told:
## which build it is, how it stands, where its feet are on the screen and how
## many pixels a metre is there. A build is proportions and two colors, and a
## pose is numbers, so a robot knows nothing of when it walks, sits or lights
## up.
##
## Lengths are metres, up from the feet and across from the middle. One phase
## number drives the walk, as Walk.roc's stride drives the child's: the feet
## lift in turn, the body bobs twice a stride, and the free arm swings. The
## right hand is the one that carries, and `hand_at` says where it is, so a
## dish can be put in it.
import lib.Brush
import lib.Pixels
import lib.Point
import lib.RgbColor
import lib.Shapes
import lib.CurvedShapes

Robot :: [].{

	## The three guests: a tall thin one, a round one, and a tiny one on a wheel.
	Build : [Tall, Round, Tiny]

	## How a robot stands this frame. `phase` is how far through its walk it
	## is, in radians, and `stride` how much it is walking, from 0 to 1. `sit`
	## goes from 0, standing, to 1, sat on a seat `seat_height` up. `reach` goes
	## from 0, the right arm at its side, to 1, the right hand held up under a
	## dish. `eye_glow` goes from 0, eyes dark, to 1, lit like the string lights.
	## `look` slides the eyes from 0, straight ahead, to 1, to the screen's right.
	Pose : {
		phase : F64,
		stride : F64,
		sit : F64,
		seat_height : F64,
		reach : F64,
		eye_glow : F64,
		look : F64,
	}

	## Where the right hand is, in metres across from the middle and up from
	## the ground under the robot.
	hand_at : Robot.Build, Robot.Pose -> { across : F64, up : F64 }
	hand_at = |build, pose| {
		body = proportions(build)
		shoulder = right_shoulder(body, pose)
		arm = right_arm_angles(pose.reach)
		elbow = bone_end(shoulder, { angle: arm.upper, length: body.upper_arm })
		bone_end(elbow, { angle: arm.fore, length: body.forearm })
	}

	## The robot, back to front: antenna, legs or wheel, body, head, eyes,
	## then the arms in front of the body.
	figure_shapes : {
		build : Robot.Build,
		pose : Robot.Pose,
		feet : Point,
		pixels_per_metre : F64,
	} -> List(Shapes.Shape)
	figure_shapes = |{ build, pose, feet, pixels_per_metre }| {
		body = proportions(build)
		place = {
			x: feet.x.to_f64(),
			y: feet.y.to_f64(),
			scale: pixels_per_metre,
		}
		hip = hip_height(body, pose)
		top = hip + body.body_height
		head_bottom = top + body.neck
		head_top = head_bottom + body.head_height
		paint = Flat(body.paint)
		trim = Flat(body.trim)

		var $out = List.with_capacity(48)
		if body.antenna > 0.0 {
			$out = $out.append(
				bar(
					place,
					{
						from: { across: 0.0, up: head_top },
						to: { across: 0.0, up: head_top + body.antenna },
						width: 0.018,
						fill: trim,
					},
				),
			)
			$out = $out.append(
				dot(
					place,
					{
						at: { across: 0.0, up: head_top + body.antenna },
						radius: 0.03,
						fill: Flat(antenna_tip(pose.eye_glow)),
					},
				),
			)
		}
		$out = $out.concat(
			match body.moves_on {
				Legs => leg_shapes(place, { body, pose, hip })
				Wheel => wheel_shapes(place, { body, pose, hip })
			},
		)
		$out = List.concat($out, torso_shapes(place, { body, hip }))
		$out = $out.append(
			bar(
				place,
				{
					from: { across: 0.0, up: top - 0.01 },
					to: { across: 0.0, up: head_bottom + 0.01 },
					width: body.head_width * 0.3,
					fill: trim,
				},
			),
		)
		$out = $out.append(
			box(
				place,
				{
					left: 0.0 - body.head_width / 2.0,
					bottom: head_bottom,
					width: body.head_width,
					height: body.head_height,
					corner: body.head_height * 0.3,
					fill: paint,
				},
			),
		)
		$out = List.concat(
			$out,
			face_shapes(
				place,
				{
					body,
					head_bottom,
					glow: pose.eye_glow,
					look: pose.look,
				},
			),
		)
		$out = List.concat($out, arm_shapes(place, { body, pose }))
		$out
	}
}

# A build's proportions, in metres, and its two colors.
Proportions : {
	hip : F64,
	body_width : F64,
	body_height : F64,
	torso : [Blocky, Barrel],
	neck : F64,
	head_width : F64,
	head_height : F64,
	upper_arm : F64,
	forearm : F64,
	limb_width : F64,
	moves_on : [Legs, Wheel],
	antenna : F64,
	paint : Brush.Rgba,
	trim : Brush.Rgba,
}

proportions : Robot.Build -> Proportions
proportions = |build|
	match build {
		Tall => {
			hip: 0.86,
			body_width: 0.3,
			body_height: 0.6,
			torso: Blocky,
			neck: 0.07,
			head_width: 0.24,
			head_height: 0.21,
			upper_arm: 0.3,
			forearm: 0.28,
			limb_width: 0.055,
			moves_on: Legs,
			antenna: 0.12,
			paint: Brush.opaque_rgba(RgbColor.of(0x8FA9C4)),
			trim: Brush.opaque_rgba(RgbColor.of(0x3E536B)),
		}
		Round => {
			hip: 0.36,
			body_width: 0.62,
			body_height: 0.58,
			torso: Barrel,
			neck: 0.03,
			head_width: 0.34,
			head_height: 0.22,
			upper_arm: 0.22,
			forearm: 0.2,
			limb_width: 0.075,
			moves_on: Legs,
			antenna: 0.0,
			paint: Brush.opaque_rgba(RgbColor.of(0xD5884A)),
			trim: Brush.opaque_rgba(RgbColor.of(0x7D4622)),
		}
		Tiny => {
			hip: 0.22,
			body_width: 0.24,
			body_height: 0.2,
			torso: Blocky,
			neck: 0.03,
			head_width: 0.3,
			head_height: 0.22,
			upper_arm: 0.13,
			forearm: 0.13,
			limb_width: 0.045,
			moves_on: Wheel,
			antenna: 0.09,
			paint: Brush.opaque_rgba(RgbColor.of(0x63C29E)),
			trim: Brush.opaque_rgba(RgbColor.of(0x2D6B55)),
		}
	}

# Where the screen is for one figure: its feet, and pixels a metre.
Place : {
	x : F64,
	y : F64,
	scale : F64,
}

# A spot on the figure, in metres from its feet.
Spot : { across : F64, up : F64 }

screen_point : Place, Spot -> Point
screen_point = |place, spot| Point.at(
	place.x + spot.across * place.scale,
	place.y - spot.up * place.scale,
)

bar : Place,
{
	from : Spot,
	to : Spot,
	width : F64,
	fill : Brush.Fill,
} -> Shapes.Shape
bar = |place, { from, to, width, fill }|
	Shapes.line(
		{
			from: screen_point(place, from),
			to: screen_point(place, to),
			width: Pixels.of(width * place.scale),
		},
		fill,
	)

dot : Place,
{
	at : Spot,
	radius : F64,
	fill : Brush.Fill,
} -> Shapes.Shape
dot = |place, { at, radius, fill }| Disc({
	center: screen_point(place, at),
	radius: Pixels.of(radius * place.scale),
	fill,
})

# A rounded box, `left` and `bottom` its lower left corner in metres.
box : Place,
{
	left : F64,
	bottom : F64,
	width : F64,
	height : F64,
	corner : F64,
	fill : Brush.Fill,
} -> Shapes.Shape
box = |
	place,
	{
		left,
		bottom,
		width,
		height,
		corner,
		fill,
	},
|
	CurvedShapes.rounded_rect(
		{
			top_left: screen_point(place, { across: left, up: bottom + height }),
			width: Pixels.of(width * place.scale),
			height: Pixels.of(height * place.scale),
			corner_radius: Pixels.of(corner * place.scale),
			corner_steps: 3,
		},
		fill,
	)

# The bob of a stride: up twice a stride, as each foot comes down and the
# other passes it.
bob : Proportions, Robot.Pose -> F64
bob = |body, pose| {
	depth =
		match body.moves_on {
			Legs => 0.02
			Wheel => 0.012
		}
	depth * pose.stride * (2.0 * pose.phase).cos()
}

# How high the hips are. Legs fold onto the seat; a wheel hops up onto it,
# with an arc on the way that is highest halfway.
hip_height : Proportions, Robot.Pose -> F64
hip_height = |body, pose|
	match body.moves_on {
		Legs => body.hip + (pose.seat_height + 0.05 - body.hip) * pose.sit + bob(body, pose)
		Wheel => body.hip + pose.seat_height * pose.sit + 0.12 * (F64.pi * pose.sit).sin() + bob(
			body,
			pose,
		)
	}

right_shoulder : Proportions, Robot.Pose -> Spot
right_shoulder = |body, pose| {
	hip = hip_height(body, pose)
	match body.torso {
		Blocky => { across: body.body_width / 2.0 + 0.02, up: hip + body.body_height * 0.88 }
		Barrel => { across: body.body_width * 0.44, up: hip + body.body_height * 0.72 }
	}
}

# An arm's two angles from straight down, positive to the screen's right:
# at its side when `reach` is 0, and up under a dish when it is 1.
right_arm_angles : F64 -> { upper : F64, fore : F64 }
right_arm_angles = |reach| { upper: 0.2 + 2.05 * reach, fore: 0.08 + 2.87 * reach }

bone_end : Spot, { angle : F64, length : F64 } -> Spot
bone_end = |start, { angle, length }| {
	across: start.across + angle.sin() * length,
	up: start.up - angle.cos() * length,
}

leg_shapes : Place,
{
	body : Proportions,
	pose : Robot.Pose,
	hip : F64,
} -> List(Shapes.Shape)
leg_shapes = |place, { body, pose, hip }| {
	spread = body.body_width * 0.28
	trim = Flat(body.trim)
	# A walking foot lifts while the other is down; a seated knee comes up to
	# the seat, its thigh pointing at the camera.
	swing = pose.phase.sin()
	lifts = [
		{ side: -1.0, lift: (-swing).max(0.0) * 0.07 * pose.stride },
		{ side: 1.0, lift: F64.max(swing, 0.0) * 0.07 * pose.stride },
	]
	var $out = List.with_capacity(8)
	for leg in lifts {
		hip_spot = { across: leg.side * spread, up: hip }
		knee_up = body.hip * 0.5 + (pose.seat_height - body.hip * 0.5) * pose.sit + leg.lift
		knee = { across: leg.side * (spread + 0.04 * pose.sit), up: knee_up }
		foot = { across: leg.side * (spread + 0.04 * pose.sit), up: leg.lift }
		$out = $out.append(
			bar(
				place,
				{
					from: hip_spot,
					to: knee,
					width: body.limb_width,
					fill: trim,
				},
			),
		)
		$out = $out.append(
			bar(
				place,
				{
					from: knee,
					to: foot,
					width: body.limb_width,
					fill: trim,
				},
			),
		)
		$out = $out.append(
			dot(
				place,
				{
					at: knee,
					radius: body.limb_width * 0.7,
					fill: Flat(body.paint),
				},
			),
		)
		$out = $out.append(
			box(
				place,
				{
					left: foot.across - 0.06,
					bottom: foot.up,
					width: 0.12,
					height: 0.045,
					corner: 0.02,
					fill: trim,
				},
			),
		)
	}
	$out
}

wheel_shapes : Place,
{
	body : Proportions,
	pose : Robot.Pose,
	hip : F64,
} -> List(Shapes.Shape)
wheel_shapes = |place, { body, pose, hip }| {
	radius = 0.09
	axle = { across: 0.0, up: hip - body.hip + radius }
	trim = Flat(body.trim)
	# The spokes turn with the walk's own phase, so the wheel rolls as far as
	# the robot goes.
	spoke = { across: pose.phase.sin() * radius * 0.8, up: pose.phase.cos() * radius * 0.8 }
	[
		bar(
			place,
			{
				from: axle,
				to: { across: 0.0, up: hip + 0.01 },
				width: 0.04,
				fill: trim,
			},
		),
		dot(place, { at: axle, radius, fill: trim }),
		dot(
			place,
			{
				at: axle,
				radius: radius * 0.62,
				fill: Flat(body.paint),
			},
		),
		bar(
			place,
			{
				from: { across: axle.across - spoke.across, up: axle.up - spoke.up },
				to: { across: axle.across + spoke.across, up: axle.up + spoke.up },
				width: 0.015,
				fill: trim,
			},
		),
		dot(
			place,
			{
				at: axle,
				radius: 0.02,
				fill: trim,
			},
		),
	]
}

torso_shapes : Place, { body : Proportions, hip : F64 } -> List(Shapes.Shape)
torso_shapes = |place, { body, hip }| {
	paint = Flat(body.paint)
	trim = Flat(body.trim)
	match body.torso {
		Blocky => [
			box(
				place,
				{
					left: 0.0 - body.body_width / 2.0,
					bottom: hip,
					width: body.body_width,
					height: body.body_height,
					corner: body.body_width * 0.12,
					fill: paint,
				},
			),
			box(
				place,
				{
					left: 0.0 - body.body_width * 0.3,
					bottom: hip + body.body_height * 0.35,
					width: body.body_width * 0.6,
					height: body.body_height * 0.4,
					corner: body.body_width * 0.06,
					fill: trim,
				},
			),
			dot(
				place,
				{
					at: { across: 0.0, up: hip + body.body_height * 0.55 },
					radius: body.body_width * 0.08,
					fill: Flat(dial),
				},
			),
		]
		Barrel => {
			radius = body.body_width / 2.0
			middle = { across: 0.0, up: hip + body.body_height / 2.0 }
			[
				dot(place, { at: middle, radius, fill: paint }),
				dot(
					place,
					{
						at: middle,
						radius: radius * 0.55,
						fill: trim,
					},
				),
				dot(
					place,
					{
						at: middle,
						radius: radius * 0.18,
						fill: Flat(dial),
					},
				),
			]
		}
	}
}

# Two eyes and a mouth. Lit eyes add a glow around them, the color of the
# string lights.
face_shapes : Place,
{
	body : Proportions,
	head_bottom : F64,
	glow : F64,
	look : F64,
} -> List(Shapes.Shape)
face_shapes = |place, { body, head_bottom, glow, look }| {
	slide = look * body.head_width * 0.14
	eye_up = head_bottom + body.head_height * 0.58
	eye_apart = body.head_width * 0.24
	eye_radius = body.head_height * 0.14
	color = Brush.mix({
		from: dark_eye,
		to: lit_eye,
		fraction: glow,
	})
	eye_fill = Flat(color)
	eyes = [-1.0, 1.0].map(
		|side|
			dot(
				place,
				{
					at: { across: slide + side * eye_apart, up: eye_up },
					radius: eye_radius,
					fill: eye_fill,
				},
			),
	)
	mouth = bar(
		place,
		{
			from: {
				across: 0.0 - body.head_width * 0.18,
				up: head_bottom + body.head_height * 0.24,
			},
			to: { across: body.head_width * 0.18, up: head_bottom + body.head_height * 0.24 },
			width: body.head_height * 0.07,
			fill: Flat(body.trim),
		},
	)
	halos =
		if glow > 0.0 {
			Shapes.added_light_shapes(
				[-1.0, 1.0].map(
					|side|
						Shapes.halo(
							{
								center: screen_point(
									place,
									{ across: slide + side * eye_apart, up: eye_up },
								),
								radius: Pixels.of(eye_radius * 2.6 * place.scale),
							},
							{ ..lit_eye, a: 0.55 * glow },
						),
				),
			)
		} else {
			[]
		}
	List.concat(eyes.append(mouth), halos)
}

# The left arm swings with the walk; the right one carries, so it goes where
# `reach` puts it.
arm_shapes : Place, { body : Proportions, pose : Robot.Pose } -> List(Shapes.Shape)
arm_shapes = |place, { body, pose }| {
	trim = Flat(body.trim)
	right = right_shoulder(body, pose)
	left = { across: 0.0 - right.across, up: right.up }
	swing = 0.32 * pose.stride * pose.phase.sin()
	free = { upper: 0.0 - 0.2 - swing, fore: 0.0 - 0.08 - swing * 1.3 }
	held = right_arm_angles(pose.reach)
	var $out = List.with_capacity(10)
	for arm in [{ shoulder: left, angles: free }, { shoulder: right, angles: held }] {
		elbow = bone_end(arm.shoulder, { angle: arm.angles.upper, length: body.upper_arm })
		hand = bone_end(elbow, { angle: arm.angles.fore, length: body.forearm })
		$out = $out.append(
			bar(
				place,
				{
					from: arm.shoulder,
					to: elbow,
					width: body.limb_width,
					fill: trim,
				},
			),
		)
		$out = $out.append(
			bar(
				place,
				{
					from: elbow,
					to: hand,
					width: body.limb_width * 0.9,
					fill: trim,
				},
			),
		)
		$out = $out.append(
			dot(
				place,
				{
					at: arm.shoulder,
					radius: body.limb_width * 0.75,
					fill: Flat(body.paint),
				},
			),
		)
		$out = $out.append(
			dot(
				place,
				{
					at: hand,
					radius: body.limb_width * 0.8,
					fill: Flat(body.paint),
				},
			),
		)
	}
	$out
}

antenna_tip : F64 -> Brush.Rgba
antenna_tip = |glow| Brush.mix({
	from: Brush.opaque_rgba(RgbColor.of(0xC0504A)),
	to: lit_eye,
	fraction: glow,
})

dark_eye : Brush.Rgba
dark_eye = Brush.opaque_rgba(RgbColor.of(0x1F2830))

lit_eye : Brush.Rgba
lit_eye = Brush.opaque_rgba(RgbColor.of(0xFFD98A))

dial : Brush.Rgba
dial = Brush.opaque_rgba(RgbColor.of(0xF2E2B8))

standing_still : Robot.Pose
standing_still = {
	phase: 0.0,
	stride: 0.0,
	sit: 0.0,
	seat_height: 0.4,
	reach: 0.0,
	eye_glow: 0.0,
	look: 0.0,
}

# A raised hand is above the shoulder, and a lowered one below it, for every
# build.
expect
	[Tall, Round, Tiny].all(
		|build| {
			shoulder = right_shoulder(proportions(build), standing_still)
			raised = Robot.hand_at(build, { ..standing_still, reach: 1.0 })
			lowered = Robot.hand_at(build, standing_still)
			raised.up > shoulder.up and lowered.up < shoulder.up
		},
	)

# The tall robot stands tallest and the tiny one shortest, standing still.
expect {
	tall = Robot.hand_at(Tall, standing_still)
	round = Robot.hand_at(Round, standing_still)
	tiny = Robot.hand_at(Tiny, standing_still)
	tall.up > round.up and round.up > tiny.up
}

# Sitting lowers a legged robot's hips to its seat and lifts a wheeled one
# onto it.
expect hip_height(proportions(Tall), { ..standing_still, sit: 1.0 }) < proportions(Tall).hip
expect hip_height(proportions(Tiny), { ..standing_still, sit: 1.0 }) > proportions(Tiny).hip

# A figure is drawn at all, and dark eyes add no glow.
expect {
	figure = Robot.figure_shapes({
		build: Round,
		pose: standing_still,
		feet: Point.at(100.0, 200.0),
		pixels_per_metre: 80.0,
	})
	figure.len() > 10 and !figure.contains(Blend(Add))
}
