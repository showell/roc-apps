## Dancer draws the fourth robot, tall and skinny, who does the robot dance
## after the banner comes up. It is told every joint's angle and a few more
## numbers, so the stiff, stepped look of the dance is in the numbers Dinner
## hands it, and this module only stands the figure up from them.
##
## Lengths are metres, up from the feet and across from the middle; an angle
## is from straight down, positive to the screen's right. A turn squashes the
## whole figure toward its middle, which is how a flat figure turns.
import lib.Brush
import lib.Point
import lib.RgbColor
import lib.Shapes
import lib.Squash
import Figure

Dancer :: [].{

	## The dancer's pose. The four arm angles are the upper arms' and the
	## forearms'. `head` turns the head from -1, to the screen's left, to 1,
	## to its right. `pop` lifts the right shoulder when positive and the left
	## when negative. `turn` is the cosine of the body's turn, 1 face on.
	## `bounce` is how far the knees have dropped. `wink` closes the left eye
	## at 1, and `antenna_sway` bends the antenna's tip across, from -1 to 1.
	## `phase` and `stride` are the walk's, as a Robot's are.
	Pose : {
		left_upper : F64,
		left_fore : F64,
		right_upper : F64,
		right_fore : F64,
		head : F64,
		pop : F64,
		turn : F64,
		bounce : F64,
		wink : F64,
		antenna_sway : F64,
		phase : F64,
		stride : F64,
	}

	figure_shapes : {
		pose : Dancer.Pose,
		feet : Point,
		pixels_per_metre : F64,
	} -> List(Shapes.Shape)
	figure_shapes = |{ pose, feet, pixels_per_metre }| {
		place = {
			x: feet.x.to_f64(),
			y: feet.y.to_f64(),
			scale: pixels_per_metre,
		}
		hip = hip_height(pose)
		chest_top = hip + body_height
		head_bottom = chest_top + 0.08
		# A swaying antenna bends across, and dips a little as it does.
		sway = { across: 0.1 * pose.antenna_sway, dip: 0.02 * pose.antenna_sway.abs() }
		antenna_tip = { across: sway.across, up: head_bottom + 0.34 - sway.dip }
		var $out = List.with_capacity(40)
		$out = $out.append(
			Figure.bar(
				place,
				{
					from: { across: 0.0, up: head_bottom + 0.21 },
					to: { across: sway.across, up: head_bottom + 0.33 - sway.dip },
					width: 0.016,
					fill: trim,
				},
			),
		)
		$out = $out.append(
			Figure.dot(
				place,
				{
					at: antenna_tip,
					radius: 0.028,
					fill: Flat(lit_eye),
				},
			),
		)
		$out = List.concat($out, leg_shapes(place, { pose, hip }))
		$out = $out.append(
			Figure.box(
				place,
				{
					left: -0.13,
					bottom: hip,
					width: 0.26,
					height: body_height,
					corner: 0.03,
					fill: paint,
				},
			),
		)
		$out = $out.append(
			Figure.box(
				place,
				{
					left: -0.08,
					bottom: hip + 0.25,
					width: 0.16,
					height: 0.24,
					corner: 0.02,
					fill: trim,
				},
			),
		)
		$out = $out.append(
			Figure.dot(
				place,
				{
					at: { across: 0.0, up: hip + 0.37 },
					radius: 0.025,
					fill: Flat(lit_eye),
				},
			),
		)
		$out = $out.append(
			Figure.bar(
				place,
				{
					from: { across: 0.0, up: chest_top - 0.01 },
					to: { across: 0.0, up: head_bottom + 0.01 },
					width: 0.06,
					fill: trim,
				},
			),
		)
		$out = List.concat(
			$out,
			head_shapes(place, { head_bottom, turn: pose.head, wink: pose.wink }),
		)
		$out = List.concat(
			$out,
			arm_shapes(
				place,
				{
					shoulder: shoulder(pose, Left),
					upper: pose.left_upper,
					fore: pose.left_fore,
				},
			),
		)
		$out = List.concat(
			$out,
			arm_shapes(
				place,
				{
					shoulder: shoulder(pose, Right),
					upper: pose.right_upper,
					fore: pose.right_fore,
				},
			),
		)
		Squash.squashed_shapes($out, { axis: feet.x, cosine: pose.turn })
	}

	## Where the right hand is, in metres across from the middle and up from
	## the feet, for whatever the dancer holds. It is face on: a turn is not
	## in it.
	right_hand_at : Dancer.Pose -> { across : F64, up : F64 }
	right_hand_at = |pose| {
		elbow = Figure.bone_end(
			shoulder(pose, Right),
			{ angle: pose.right_upper, length: upper_arm },
		)
		Figure.bone_end(elbow, { angle: pose.right_fore, length: forearm })
	}
}

upper_arm : F64
upper_arm = 0.36

forearm : F64
forearm = 0.34

# The hips ride down as the knees drop, and bob as the dancer walks.
hip_height : Dancer.Pose -> F64
hip_height = |pose| leg_length - pose.bounce + 0.015 * pose.stride * (pose.phase * 2.0).cos()

# A shoulder, lifted when `pop` pops it.
shoulder : Dancer.Pose, [Left, Right] -> Figure.Spot
shoulder = |pose, side| {
	up = hip_height(pose) + body_height * 0.93
	match side {
		Left => { across: -0.16, up: up + (-pose.pop).max(0.0) }
		Right => { across: 0.16, up: up + F64.max(pose.pop, 0.0) }
	}
}

leg_length : F64
leg_length = 1.0

body_height : F64
body_height = 0.62

paint : Brush.Fill
paint = Brush.flat(RgbColor.of(0xB9B3D6))

trim : Brush.Fill
trim = Brush.flat(RgbColor.of(0x4B4470))

lit_eye : Brush.Rgba
lit_eye = Brush.opaque_rgba(RgbColor.of(0x7FF0FF))

# The legs bend outward as the knees drop, and a walking foot lifts while the
# other is down.
leg_shapes : Figure.Place, { pose : Dancer.Pose, hip : F64 } -> List(Shapes.Shape)
leg_shapes = |place, { pose, hip }| {
	swing = pose.phase.sin()
	# Knees bend outward as they drop a little; dropped far, the robot is
	# sitting, and seen face on its thighs point at the eye, so the knees
	# come up toward the hips instead of out.
	bent = pose.bounce.min(0.12)
	sitting = ((pose.bounce - 0.15) / 0.3).max(0.0).min(1.0)
	var $out = List.with_capacity(8)
	for leg in [
		{ side: -1.0, lift: (-swing).max(0.0) * 0.08 * pose.stride },
		{ side: 1.0, lift: F64.max(swing, 0.0) * 0.08 * pose.stride },
	] {
		hip_spot = { across: leg.side * 0.07, up: hip }
		knee = {
			across: leg.side * (0.08 + bent * 1.6 + 0.04 * sitting),
			up: hip / 2.0 + (hip / 2.0 - 0.06) * sitting + leg.lift,
		}
		foot = { across: leg.side * 0.09, up: leg.lift }
		$out = $out.append(
			Figure.bar(
				place,
				{
					from: hip_spot,
					to: knee,
					width: 0.05,
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
					width: 0.05,
					fill: trim,
				},
			),
		)
		$out = $out.append(
			Figure.dot(
				place,
				{
					at: knee,
					radius: 0.035,
					fill: paint,
				},
			),
		)
		$out = $out.append(
			Figure.box(
				place,
				{
					left: foot.across - 0.065,
					bottom: foot.up,
					width: 0.13,
					height: 0.045,
					corner: 0.02,
					fill: trim,
				},
			),
		)
	}
	$out
}

# The head turns in clicks: the eyes and mouth slide across the face, and
# the bolt on the far side hides behind it. A wink shuts the left eye to a
# line.
head_shapes : Figure.Place,
{
	head_bottom : F64,
	turn : F64,
	wink : F64,
} -> List(Shapes.Shape)
head_shapes = |place, { head_bottom, turn, wink }| {
	slide = turn * 0.06
	bolt = |side| Figure.dot(
		place,
		{
			at: { across: side * 0.13, up: head_bottom + 0.11 },
			radius: 0.025,
			fill: trim,
		},
	)
	bolts = [-1.0, 1.0].keep_if(|side| side * turn > -0.4).map(bolt)
	face = [
		Figure.box(
			place,
			{
				left: -0.12,
				bottom: head_bottom,
				width: 0.24,
				height: 0.22,
				corner: 0.05,
				fill: paint,
			},
		),
		left_eye(place, { at: { across: slide - 0.05, up: head_bottom + 0.13 }, wink }),
		Figure.dot(
			place,
			{
				at: { across: slide + 0.05, up: head_bottom + 0.13 },
				radius: 0.028,
				fill: Flat(lit_eye),
			},
		),
		Figure.bar(
			place,
			{
				from: { across: slide - 0.045, up: head_bottom + 0.055 },
				to: { across: slide + 0.045, up: head_bottom + 0.055 },
				width: 0.018,
				fill: trim,
			},
		),
	]
	List.concat(bolts, face).concat(wink_sparkle_shapes(place, { head_bottom, wink }))
}

# A wink gives off a little four-pointed twinkle at the corner of the eye.
wink_sparkle_shapes : Figure.Place, { head_bottom : F64, wink : F64 } -> List(Shapes.Shape)
wink_sparkle_shapes = |place, { head_bottom, wink }|
	if wink < 0.5 {
		[]
	} else {
		center = { across: -0.17, up: head_bottom + 0.2 }
		arm = 0.045 * wink
		[
			Figure.bar(
				place,
				{
					from: { ..center, across: center.across - arm },
					to: { ..center, across: center.across + arm },
					width: 0.012,
					fill: twinkle,
				},
			),
			Figure.bar(
				place,
				{
					from: { ..center, up: center.up - arm },
					to: { ..center, up: center.up + arm },
					width: 0.012,
					fill: twinkle,
				},
			),
			Figure.dot(
				place,
				{
					at: center,
					radius: 0.012,
					fill: twinkle,
				},
			),
		]
	}

twinkle : Brush.Fill
twinkle = Brush.flat(RgbColor.of(0xFFF3B0))

left_eye : Figure.Place, { at : Figure.Spot, wink : F64 } -> Shapes.Shape
left_eye = |place, { at, wink }|
	if wink < 0.5 {
		Figure.dot(
			place,
			{
				at,
				radius: 0.028,
				fill: Flat(lit_eye),
			},
		)
	} else {
		Figure.bar(
			place,
			{
				from: { ..at, across: at.across - 0.03 },
				to: { ..at, across: at.across + 0.03 },
				width: 0.014,
				fill: trim,
			},
		)
	}

arm_shapes : Figure.Place,
{
	shoulder : Figure.Spot,
	upper : F64,
	fore : F64,
} -> List(Shapes.Shape)
arm_shapes = |place, { shoulder: top, upper, fore }| {
	elbow = Figure.bone_end(top, { angle: upper, length: upper_arm })
	hand = Figure.bone_end(elbow, { angle: fore, length: forearm })
	[
		Figure.bar(
			place,
			{
				from: top,
				to: elbow,
				width: 0.05,
				fill: trim,
			},
		),
		Figure.bar(
			place,
			{
				from: elbow,
				to: hand,
				width: 0.045,
				fill: trim,
			},
		),
		Figure.dot(
			place,
			{
				at: top,
				radius: 0.04,
				fill: paint,
			},
		),
		Figure.dot(
			place,
			{
				at: elbow,
				radius: 0.032,
				fill: paint,
			},
		),
		Figure.dot(
			place,
			{
				at: hand,
				radius: 0.036,
				fill: paint,
			},
		),
	]
}
