## SideBody draws a dinner guest side on, facing the screen's right, as a
## guest walking up the side of the table and sitting at it is seen from the
## near end. Where Robot stands a guest face on and slides its parts about,
## this is a jointed rig: the hips go where the pose puts them, each ankle
## goes where the pose plants it, and Figure finds the knees between, so a
## guest that lowers its hips onto a seat bends its knees forward the way a
## body does. The torso leans from the hips, the head rides on top and can
## turn toward the eye, and the arms hang from the shoulders at their own
## angles. A guest on a wheel has the wheel under its hips instead of legs.
##
## Lengths are metres from the point on the ground the pose is measured
## from, `across` toward the way the guest faces and `up` from the ground. An
## angle is from straight down, positive toward the way it faces; a lean is
## from upright, positive forward.
import lib.Brush
import lib.Point
import lib.RgbColor
import lib.Shapes
import lib.Squash
import Figure
import RobotBody
import RobotHead

SideBody :: [].{

	## Where everything is this frame. `near_foot` and `far_foot` are where
	## the ankles are planted, which the legs reach as far as they are long;
	## `look` turns the head from side on, at 0, to the eye, at 1; `glow`
	## lights the eyes; `wheel_turn` is how far a wheel has rolled, in
	## radians. `facing` is the cosine of the guest's turn about its upright
	## axis: 1 faces the screen's right, -1 its left, and between it is
	## turning, squashed as a flat figure turns.
	Pose : {
		hip : Figure.Spot,
		near_foot : Figure.Spot,
		far_foot : Figure.Spot,
		lean : F64,
		head_tilt : F64,
		near_arm : SideBody.Arm,
		far_arm : SideBody.Arm,
		wheel_turn : F64,
		look : F64,
		glow : F64,
		facing : F64,
	}

	## An arm's two angles: the upper arm's and the forearm's.
	Arm : { upper : F64, fore : F64 }

	## How long a guest's thigh and shin are, each: half its leg, from the hip
	## to the ankle.
	bone_length : RobotBody.Proportions -> F64
	bone_length = |body| (body.hip - ankle_height) / 2.0

	## How high the hips stand, the knees a little soft, and the ankle's own
	## height off the ground.
	standing_hip : RobotBody.Proportions -> F64
	standing_hip = |body|
		match body.moves_on {
			Legs => ankle_height + 0.985 * 2.0 * bone_length(body)
			Wheel => body.hip
		}

	ankle_height : F64
	ankle_height = 0.045

	## Where the near hand is, before any turn.
	near_hand_at : RobotBody.Proportions, SideBody.Pose -> Figure.Spot
	near_hand_at = |body, pose| hand_at(
		body,
		{ shoulder: shoulder_at(body, pose), arm: pose.near_arm },
	)

	## Where the shoulders are, at the top of the leaning torso.
	shoulder : RobotBody.Proportions, { hip : Figure.Spot, lean : F64, .. } -> Figure.Spot
	shoulder = |body, pose| shoulder_at(body, pose)

	## The arm that puts the hand at `hand`, the elbow bent down, or as near
	## as it reaches.
	arm_toward : RobotBody.Proportions, { pose : SideBody.Pose, hand : Figure.Spot } -> SideBody.Arm
	arm_toward = |body, { pose, hand }| {
		from = shoulder_at(body, pose)
		arm = Figure.elbow_between({
			shoulder: from,
			hand,
			upper: body.upper_arm,
			fore: body.forearm,
		})
		{
			upper: Figure.angle_from_down(from, arm.elbow),
			fore: Figure.angle_from_down(arm.elbow, arm.hand),
		}
	}

	## The guest, back to front: the far leg and arm, the body, the head, then
	## the near leg and arm.
	figure_shapes : {
		body : RobotBody.Proportions,
		pose : SideBody.Pose,
		feet : Point,
		pixels_per_metre : F64,
	} -> List(Shapes.Shape)
	figure_shapes = |{ body, pose, feet, pixels_per_metre }| {
		place = {
			x: feet.x.to_f64(),
			y: feet.y.to_f64(),
			scale: pixels_per_metre,
		}
		far_trim = Flat(
			Brush.mix({
				from: body.trim,
				to: shadow,
				fraction: 0.35,
			}),
		)
		near_trim = Flat(body.trim)
		shoulder_spot = shoulder_at(body, pose)
		under =
			match body.moves_on {
				Legs => leg_shapes(
					place,
					{
						body,
						hip: pose.hip,
						ankle: pose.far_foot,
						fill: far_trim,
					},
				)
				Wheel => wheel_shapes(place, { body, pose })
			}
		over =
			match body.moves_on {
				Legs => leg_shapes(
					place,
					{
						body,
						hip: pose.hip,
						ankle: pose.near_foot,
						fill: near_trim,
					},
				)
				Wheel => []
			}
		[
			under,
			arm_shapes(
				place,
				{
					body,
					shoulder: shoulder_spot,
					arm: pose.far_arm,
					fill: far_trim,
				},
			),
			torso_shapes(place, { body, pose }),
			head_shapes(place, { body, pose }),
			over,
			arm_shapes(
				place,
				{
					body,
					shoulder: shoulder_spot,
					arm: pose.near_arm,
					fill: near_trim,
				},
			),
		]
			.join()
			|> Squash.squashed_shapes({ axis: feet.x, cosine: pose.facing })
	}
}

shadow : Brush.Rgba
shadow = Brush.opaque_rgba(RgbColor.of(0x000000))

# A spot `metres` along the torso from the hips, which lean the torso.
along_torso : { hip : Figure.Spot, lean : F64, .. }, F64 -> Figure.Spot
along_torso = |pose, metres| {
	across: pose.hip.across + pose.lean.sin() * metres,
	up: pose.hip.up + pose.lean.cos() * metres,
}

shoulder_at : RobotBody.Proportions, { hip : Figure.Spot, lean : F64, .. } -> Figure.Spot
shoulder_at = |body, pose|
	match body.torso {
		Boxy => along_torso(pose, body.body_height * 0.88)
		Barrel => along_torso(pose, body.body_height * 0.72)
	}

hand_at : RobotBody.Proportions, { shoulder : Figure.Spot, arm : SideBody.Arm } -> Figure.Spot
hand_at = |body, { shoulder, arm }| {
	elbow = Figure.bone_end(shoulder, { angle: arm.upper, length: body.upper_arm })
	Figure.bone_end(elbow, { angle: arm.fore, length: body.forearm })
}

leg_shapes : Figure.Place,
{
	body : RobotBody.Proportions,
	hip : Figure.Spot,
	ankle : Figure.Spot,
	fill : Brush.Fill,
} -> List(Shapes.Shape)
leg_shapes = |place, { body, hip, ankle, fill }| {
	bone = SideBody.bone_length(body)
	leg = Figure.knee_between({
		hip,
		ankle,
		thigh: bone,
		shin: bone,
	})
	foot_bottom = leg.ankle.up - SideBody.ankle_height
	[
		Figure.bar(
			place,
			{
				from: hip,
				to: leg.knee,
				width: body.limb_width,
				fill,
			},
		),
		Figure.bar(
			place,
			{
				from: leg.knee,
				to: leg.ankle,
				width: body.limb_width,
				fill,
			},
		),
		Figure.dot(
			place,
			{
				at: leg.knee,
				radius: body.limb_width * 0.7,
				fill: Flat(body.paint),
			},
		),
		Figure.box(
			place,
			{
				left: leg.ankle.across - 0.035,
				bottom: foot_bottom,
				width: 0.13,
				height: 0.045,
				corner: 0.02,
				fill,
			},
		),
	]
}

# A wheel under the hips, its post up to them, its spoke turned as far as it
# has rolled.
wheel_shapes : Figure.Place,
{
	body : RobotBody.Proportions,
	pose : SideBody.Pose,
} -> List(Shapes.Shape)
wheel_shapes = |place, { body, pose }| {
	radius = 0.09
	axle = { across: pose.hip.across, up: pose.hip.up - body.hip + radius }
	trim = Flat(body.trim)
	spoke = {
		across: pose.wheel_turn.sin() * radius * 0.8,
		up: pose.wheel_turn.cos() * radius * 0.8,
	}
	[
		Figure.bar(
			place,
			{
				from: axle,
				to: { ..pose.hip, up: pose.hip.up + 0.01 },
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
	]
}

# The torso side on: a slab as deep as three quarters of its width, leaning
# from the hips, or a barrel, which is round from any side.
torso_shapes : Figure.Place,
{
	body : RobotBody.Proportions,
	pose : SideBody.Pose,
} -> List(Shapes.Shape)
torso_shapes = |place, { body, pose }| {
	paint = Flat(body.paint)
	trim = Flat(body.trim)
	match body.torso {
		Boxy => {
			depth = body.body_width * 0.75
			[
				Figure.bar(
					place,
					{
						from: pose.hip,
						to: along_torso(pose, body.body_height),
						width: depth,
						fill: paint,
					},
				),
				Figure.bar(
					place,
					{
						from: along_torso(pose, body.body_height * 0.35),
						to: along_torso(pose, body.body_height * 0.75),
						width: depth * 0.25,
						fill: trim,
					},
				),
			]
		}
		Barrel => {
			radius = body.body_width / 2.0
			middle = along_torso(pose, body.body_height / 2.0)
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
			]
		}
	}
}

# The neck, the head and the antenna. Side on, the head is narrower and has
# one eye at its front; as it turns toward the eye it widens to its full
# width, its face slides to the middle and the second eye comes round.
head_shapes : Figure.Place,
{
	body : RobotBody.Proportions,
	pose : SideBody.Pose,
} -> List(Shapes.Shape)
head_shapes = |place, { body, pose }| {
	top = along_torso(pose, body.body_height)
	tilt = pose.lean + pose.head_tilt
	upward = { across: tilt.sin(), up: tilt.cos() }
	forward = { across: tilt.cos(), up: 0.0 - tilt.sin() }
	at = |from, { ahead, up }| {
		across: from.across + forward.across * ahead + upward.across * up,
		up: from.up + forward.up * ahead + upward.up * up,
	}
	head_bottom = at(top, { ahead: 0.0, up: body.neck })
	head_top = at(head_bottom, { ahead: 0.0, up: body.head_height })
	wide = body.head_width * (0.75 + 0.25 * pose.look)
	face = 0.38 * wide * (1.0 - pose.look)
	eye_apart = body.head_width * 0.24 * pose.look
	eye_up = body.head_height * 0.58
	eye_fill = Flat(RobotHead.eye_color(pose.glow))
	eye = |side| Figure.dot(
		place,
		{
			at: at(head_bottom, { ahead: face + side * eye_apart, up: eye_up }),
			radius: body.head_height * 0.14,
			fill: eye_fill,
		},
	)
	eyes =
		if pose.look < 0.15 {
			[eye(0.0)]
		} else {
			[eye(-1.0), eye(1.0)]
		}
	mouth_y = body.head_height * 0.24
	mouth = Figure.bar(
		place,
		{
			from: at(head_bottom, { ahead: face - body.head_width * 0.12, up: mouth_y }),
			to: at(head_bottom, { ahead: face + body.head_width * 0.12, up: mouth_y }),
			width: body.head_height * 0.07,
			fill: Flat(body.trim),
		},
	)
	antenna_place = {
		x: place.x + head_top.across * place.scale,
		y: place.y,
		scale: place.scale,
	}
	[
		RobotHead.antenna_shapes(antenna_place, { body, head_top: head_top.up, glow: pose.glow }),
		[
			Figure.bar(
				place,
				{
					from: top,
					to: head_bottom,
					width: body.head_width * 0.3,
					fill: Flat(body.trim),
				},
			),
			Figure.bar(
				place,
				{
					from: head_bottom,
					to: head_top,
					width: wide,
					fill: Flat(body.paint),
				},
			),
		],
		eyes,
		[mouth],
	].join()
}

arm_shapes : Figure.Place,
{
	body : RobotBody.Proportions,
	shoulder : Figure.Spot,
	arm : SideBody.Arm,
	fill : Brush.Fill,
} -> List(Shapes.Shape)
arm_shapes = |place, { body, shoulder, arm, fill }| {
	elbow = Figure.bone_end(shoulder, { angle: arm.upper, length: body.upper_arm })
	hand = Figure.bone_end(elbow, { angle: arm.fore, length: body.forearm })
	[
		Figure.bar(
			place,
			{
				from: shoulder,
				to: elbow,
				width: body.limb_width,
				fill,
			},
		),
		Figure.bar(
			place,
			{
				from: elbow,
				to: hand,
				width: body.limb_width * 0.9,
				fill,
			},
		),
		Figure.dot(
			place,
			{
				at: shoulder,
				radius: body.limb_width * 0.75,
				fill: Flat(body.paint),
			},
		),
		Figure.dot(
			place,
			{
				at: hand,
				radius: body.limb_width * 0.8,
				fill: Flat(body.paint),
			},
		),
	]
}
