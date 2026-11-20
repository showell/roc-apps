## RobotBody is a dinner guest's body, from its proportions: where its joints
## are for a stance, and the shapes of its legs or wheel, its torso and its
## arms. RobotHead draws the head. Robot says which build has which
## proportions and puts the parts together, back to front.
##
## Lengths are metres, up from the feet and across from the middle. One phase
## number drives the walk: the feet lift in turn, the body bobs twice a
## stride, and the free arm swings. The right arm is the one that carries.
import lib.Brush
import lib.RgbColor
import lib.Shapes
import Figure

RobotBody :: [].{

	## A build's proportions, in metres, and its two colors.
	Proportions : {
		hip : F64,
		body_width : F64,
		body_height : F64,
		torso : [Boxy, Barrel],
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

	## The part of a robot's pose the body reads: the walk's `phase` and
	## `stride`, how far it has sat on a seat `seat_height` up, and how far
	## its right arm has reached up.
	Stance(others) : {
		phase : F64,
		stride : F64,
		sit : F64,
		seat_height : F64,
		reach : F64,
		..others,
	}

	## How high the hips are. Legs fold onto the seat; a wheel hops up onto it,
	## with an arc on the way that is highest halfway.
	hip_height : RobotBody.Proportions, RobotBody.Stance(others) -> F64
	hip_height = |body, pose|
		match body.moves_on {
			Legs => body.hip + (pose.seat_height + 0.05 - body.hip) * pose.sit + bob(body, pose)
			Wheel => {
				hop = 0.12 * (F64.pi * pose.sit).sin()
				body.hip + pose.seat_height * pose.sit + hop + bob(body, pose)
			}
		}

	right_shoulder : RobotBody.Proportions, RobotBody.Stance(others) -> Figure.Spot
	right_shoulder = |body, pose| {
		hip = hip_height(body, pose)
		match body.torso {
			Boxy => { across: body.body_width / 2.0 + 0.02, up: hip + body.body_height * 0.88 }
			Barrel => { across: body.body_width * 0.44, up: hip + body.body_height * 0.72 }
		}
	}

	## Where the right hand is, from the feet.
	right_hand_at : RobotBody.Proportions, RobotBody.Stance(others) -> Figure.Spot
	right_hand_at = |body, pose| {
		shoulder = right_shoulder(body, pose)
		arm = right_arm_angles(pose.reach)
		elbow = Figure.bone_end(shoulder, { angle: arm.upper, length: body.upper_arm })
		Figure.bone_end(elbow, { angle: arm.fore, length: body.forearm })
	}

	leg_shapes : Figure.Place,
	{
		body : RobotBody.Proportions,
		pose : RobotBody.Stance(others),
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
				Figure.bar(
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
				Figure.bar(
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
				Figure.dot(
					place,
					{
						at: knee,
						radius: body.limb_width * 0.7,
						fill: Flat(body.paint),
					},
				),
			)
			$out = $out.append(
				Figure.box(
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

	wheel_shapes : Figure.Place,
	{
		body : RobotBody.Proportions,
		pose : RobotBody.Stance(others),
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
			Figure.bar(
				place,
				{
					from: axle,
					to: { across: 0.0, up: hip + 0.01 },
					width: 0.04,
					fill: trim,
				},
			),
			Figure.dot(place, { at: axle, radius, fill: trim }),
			Figure.dot(
				place,
				{
					at: axle,
					radius: radius * 0.62,
					fill: Flat(body.paint),
				},
			),
			Figure.bar(
				place,
				{
					from: { across: axle.across - spoke.across, up: axle.up - spoke.up },
					to: { across: axle.across + spoke.across, up: axle.up + spoke.up },
					width: 0.015,
					fill: trim,
				},
			),
			Figure.dot(
				place,
				{
					at: axle,
					radius: 0.02,
					fill: trim,
				},
			),
		]
	}

	torso_shapes : Figure.Place, { body : RobotBody.Proportions, hip : F64 } -> List(Shapes.Shape)
	torso_shapes = |place, { body, hip }| {
		paint = Flat(body.paint)
		trim = Flat(body.trim)
		match body.torso {
			Boxy => [
				Figure.box(
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
				Figure.box(
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
				Figure.dot(
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
					Figure.dot(place, { at: middle, radius, fill: paint }),
					Figure.dot(
						place,
						{
							at: middle,
							radius: radius * 0.55,
							fill: trim,
						},
					),
					Figure.dot(
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

	## The left arm swings with the walk; the right one carries, so it goes
	## where `reach` puts it.
	arm_shapes : Figure.Place,
	{
		body : RobotBody.Proportions,
		pose : RobotBody.Stance(others),
	} -> List(Shapes.Shape)
	arm_shapes = |place, { body, pose }| {
		trim = Flat(body.trim)
		right = right_shoulder(body, pose)
		left = { across: 0.0 - right.across, up: right.up }
		swing = 0.32 * pose.stride * pose.phase.sin()
		free = { upper: 0.0 - 0.2 - swing, fore: 0.0 - 0.08 - swing * 1.3 }
		held = right_arm_angles(pose.reach)
		var $out = List.with_capacity(10)
		for arm in [{ shoulder: left, angles: free }, { shoulder: right, angles: held }] {
			elbow = Figure.bone_end(
				arm.shoulder,
				{ angle: arm.angles.upper, length: body.upper_arm },
			)
			hand = Figure.bone_end(elbow, { angle: arm.angles.fore, length: body.forearm })
			$out = $out.append(
				Figure.bar(
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
				Figure.bar(
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
				Figure.dot(
					place,
					{
						at: arm.shoulder,
						radius: body.limb_width * 0.75,
						fill: Flat(body.paint),
					},
				),
			)
			$out = $out.append(
				Figure.dot(
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
}

# The bob of a stride: up twice a stride, as each foot comes down and the
# other passes it.
bob : RobotBody.Proportions, RobotBody.Stance(others) -> F64
bob = |body, pose| {
	depth =
		match body.moves_on {
			Legs => 0.02
			Wheel => 0.012
		}
	depth * pose.stride * (2.0 * pose.phase).cos()
}

# An arm's two angles from straight down, positive to the screen's right:
# at its side when `reach` is 0, and up under a dish when it is 1.
right_arm_angles : F64 -> { upper : F64, fore : F64 }
right_arm_angles = |reach| { upper: 0.2 + 2.05 * reach, fore: 0.08 + 2.87 * reach }

dial : Brush.Rgba
dial = Brush.opaque_rgba(RgbColor.of(0xF2E2B8))
