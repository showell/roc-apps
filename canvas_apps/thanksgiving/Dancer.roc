## Dancer draws the fourth robot, tall and skinny, who does the robot dance
## after the banner comes up. It is told every joint's angle and a few more
## numbers, so the stiff, stepped look of the dance is in the numbers Dinner
## hands it, and this module only stands the figure up from them.
##
## Lengths are metres, up from the feet and across from the middle; an angle
## is from straight down, positive to the screen's right. A turn squashes the
## whole figure toward its middle, which is how a flat figure turns.
import lib.Brush
import lib.Pixels
import lib.Point
import lib.RgbColor
import lib.Shapes
import lib.CurvedShapes
import lib.Squash

Dancer :: [].{

	## The dancer's pose. The four arm angles are the upper arms' and the
	## forearms'. `head` turns the head from -1, to the screen's left, to 1,
	## to its right. `pop` lifts the right shoulder when positive and the left
	## when negative. `turn` is the cosine of the body's turn, 1 face on.
	## `bounce` is how far the knees have dropped. `phase` and `stride` are
	## the walk's, as a Robot's are.
	Pose : {
		left_upper : F64,
		left_fore : F64,
		right_upper : F64,
		right_fore : F64,
		head : F64,
		pop : F64,
		turn : F64,
		bounce : F64,
		phase : F64,
		stride : F64,
	}

	figure_shapes : { pose : Dancer.Pose, feet : Point, pixels_per_metre : F64 } -> List(Shapes.Shape)
	figure_shapes = |{ pose, feet, pixels_per_metre }| {
		place = { x: feet.x.to_f64(), y: feet.y.to_f64(), scale: pixels_per_metre }
		walk_bob = 0.015 * pose.stride * (pose.phase * 2.0).cos()
		hip = leg_length - pose.bounce + walk_bob
		chest_top = hip + body_height
		head_bottom = chest_top + 0.08
		shoulder_up = hip + body_height * 0.93
		var $out = List.with_capacity(40)
		$out = $out.append(bar(place, { from: { across: 0.0, up: head_bottom + 0.21 }, to: { across: 0.0, up: head_bottom + 0.33 }, width: 0.016, fill: trim }))
		$out = $out.append(dot(place, { at: { across: 0.0, up: head_bottom + 0.34 }, radius: 0.028, fill: Flat(lit_eye) }))
		$out = List.concat($out, leg_shapes(place, { pose, hip }))
		$out = $out.append(box(place, { left: -0.13, bottom: hip, width: 0.26, height: body_height, corner: 0.03, fill: paint }))
		$out = $out.append(box(place, { left: -0.08, bottom: hip + 0.25, width: 0.16, height: 0.24, corner: 0.02, fill: trim }))
		$out = $out.append(dot(place, { at: { across: 0.0, up: hip + 0.37 }, radius: 0.025, fill: Flat(lit_eye) }))
		$out = $out.append(bar(place, { from: { across: 0.0, up: chest_top - 0.01 }, to: { across: 0.0, up: head_bottom + 0.01 }, width: 0.06, fill: trim }))
		$out = List.concat($out, head_shapes(place, { head_bottom, turn: pose.head }))
		$out = List.concat($out, arm_shapes(place, { shoulder: { across: -0.16, up: shoulder_up + (-pose.pop).max(0.0) }, upper: pose.left_upper, fore: pose.left_fore }))
		$out = List.concat($out, arm_shapes(place, { shoulder: { across: 0.16, up: shoulder_up + F64.max(pose.pop, 0.0) }, upper: pose.right_upper, fore: pose.right_fore }))
		Squash.squashed_shapes($out, { axis: feet.x, cosine: pose.turn })
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

Place : { x : F64, y : F64, scale : F64 }

Spot : { across : F64, up : F64 }

screen_point : Place, Spot -> Point
screen_point = |place, spot| Point.at(place.x + spot.across * place.scale, place.y - spot.up * place.scale)

bar : Place, { from : Spot, to : Spot, width : F64, fill : Brush.Fill } -> Shapes.Shape
bar = |place, { from, to, width, fill }|
	Shapes.line({ from: screen_point(place, from), to: screen_point(place, to), width: Pixels.of(width * place.scale) }, fill)

dot : Place, { at : Spot, radius : F64, fill : Brush.Fill } -> Shapes.Shape
dot = |place, { at, radius, fill }| Disc({ center: screen_point(place, at), radius: Pixels.of(radius * place.scale), fill })

box : Place, { left : F64, bottom : F64, width : F64, height : F64, corner : F64, fill : Brush.Fill } -> Shapes.Shape
box = |place, { left, bottom, width, height, corner, fill }|
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

bone_end : Spot, { angle : F64, length : F64 } -> Spot
bone_end = |start, { angle, length }| { across: start.across + angle.sin() * length, up: start.up - angle.cos() * length }

# The legs bend outward as the knees drop, and a walking foot lifts while the
# other is down.
leg_shapes : Place, { pose : Dancer.Pose, hip : F64 } -> List(Shapes.Shape)
leg_shapes = |place, { pose, hip }| {
	swing = pose.phase.sin()
	var $out = List.with_capacity(8)
	for leg in [{ side: -1.0, lift: (-swing).max(0.0) * 0.08 * pose.stride }, { side: 1.0, lift: F64.max(swing, 0.0) * 0.08 * pose.stride }] {
		hip_spot = { across: leg.side * 0.07, up: hip }
		knee = { across: leg.side * (0.08 + pose.bounce * 1.6), up: hip / 2.0 + leg.lift }
		foot = { across: leg.side * 0.09, up: leg.lift }
		$out = $out.append(bar(place, { from: hip_spot, to: knee, width: 0.05, fill: trim }))
		$out = $out.append(bar(place, { from: knee, to: foot, width: 0.05, fill: trim }))
		$out = $out.append(dot(place, { at: knee, radius: 0.035, fill: paint }))
		$out = $out.append(box(place, { left: foot.across - 0.065, bottom: foot.up, width: 0.13, height: 0.045, corner: 0.02, fill: trim }))
	}
	$out
}

# The head turns in clicks: the eyes and mouth slide across the face, and
# the bolt on the far side hides behind it.
head_shapes : Place, { head_bottom : F64, turn : F64 } -> List(Shapes.Shape)
head_shapes = |place, { head_bottom, turn }| {
	slide = turn * 0.06
	bolts = [-1.0, 1.0].keep_if(|side| side * turn > -0.4).map(|side| dot(place, { at: { across: side * 0.13, up: head_bottom + 0.11 }, radius: 0.025, fill: trim }))
	face = [
		box(place, { left: -0.12, bottom: head_bottom, width: 0.24, height: 0.22, corner: 0.05, fill: paint }),
		dot(place, { at: { across: slide - 0.05, up: head_bottom + 0.13 }, radius: 0.028, fill: Flat(lit_eye) }),
		dot(place, { at: { across: slide + 0.05, up: head_bottom + 0.13 }, radius: 0.028, fill: Flat(lit_eye) }),
		bar(place, { from: { across: slide - 0.045, up: head_bottom + 0.055 }, to: { across: slide + 0.045, up: head_bottom + 0.055 }, width: 0.018, fill: trim }),
	]
	List.concat(bolts, face)
}

arm_shapes : Place, { shoulder : Spot, upper : F64, fore : F64 } -> List(Shapes.Shape)
arm_shapes = |place, { shoulder, upper, fore }| {
	elbow = bone_end(shoulder, { angle: upper, length: 0.36 })
	hand = bone_end(elbow, { angle: fore, length: 0.34 })
	[
		bar(place, { from: shoulder, to: elbow, width: 0.05, fill: trim }),
		bar(place, { from: elbow, to: hand, width: 0.045, fill: trim }),
		dot(place, { at: shoulder, radius: 0.04, fill: paint }),
		dot(place, { at: elbow, radius: 0.032, fill: paint }),
		dot(place, { at: hand, radius: 0.036, fill: paint }),
	]
}
