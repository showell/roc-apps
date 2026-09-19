# Skeleton -- one skeleton, dancing, forever.
#
# After The Skeleton Dance (1929), which is in the public domain: Disney's
# first Silly Symphony, white bones on black, no dialogue, and a figure built
# out of exactly the shapes this vocabulary has -- a skull is a disc, a rib is
# a thick line, a femur is the quad `Shapes.line` builds. Nothing is traced
# from it; this is a skeleton doing a jig, which is what that short is.
#
# **IT IS THE THIRD KIND OF MOVIE.** Safari and particles simulate forwards and
# cannot say what frame 900 looks like without walking there; capture_plot is a
# function of its clock. This one is a function of its PHASE -- the loop is
# sixty frames and frame 900 is frame 60 is frame 0 -- so it can be stepped
# either way, and a movie that loops needs no history to go back.
#
# A pose is angles. Every joint below is an angle from straight down, positive
# to the right, and a bone is where two of them meet; the dance is four sine
# waves on one phase.
import Movie
import Shapes
import Brush
import Trig

Skeleton :: [].{
	width : F64
	width = 640.0
	height : F64
	height = 480.0

	# Sixty frames to the loop, so the phase closes exactly.
	period : I64
	period = 60

	Model : { tick : I64 }

	movie : Movie.Movie(Skeleton.Model)
	movie = {
		size: { width: width, height: height },
		init: { tick: 0 },
		advance: |m| { tick: wrap(m.tick + 1) },
		# **IT LOOPS, SO IT REMEMBERS NOTHING.** Back is a step the other way.
		back: |m| { tick: wrap(m.tick - 1) },
		# A quarter of the way round.
		skip: |m| { tick: wrap(m.tick + period // 4) },
		frame: |m| { shapes: shapes(m), roll: 0.0 },
		clock: |m| I64.to_f64(m.tick),
		title: "The Skeleton Dance",
		stem: "skeleton",
	}

	wrap : I64 -> I64
	wrap = |t| {
		r = t - I64.div_trunc_by(t, period) * period
		if r < 0 { r + period } else { r }
	}

	tau : F64
	tau = 6.283185307179586

	bone : Brush.Rgba
	bone = Brush.opaque(0xf2f0e6)
	night : Brush.Rgba
	night = Brush.opaque(0x0a0a0c)

	# Where a bone of length `len` ends, leaving (x, y) at `angle` from straight
	# down. y is down, so this is the screen's own arithmetic.
	end_of : F64, F64, F64, F64 -> { x : F64, y : F64 }
	end_of = |x, y, angle, len| { x: x + Trig.r_sin(angle) * len, y: y + Trig.r_cos(angle) * len }

	rib : F64, F64, F64, F64, F64 -> Shapes.Shape
	rib = |x0, y0, x1, y1, w| Shapes.line(x0, y0, x1, y1, w, Flat(bone))

	joint : F64, F64, F64 -> Shapes.Shape
	joint = |x, y, r| Disc({ x: x, y: y, r: r, fill: Flat(bone), clip: Anywhere })

	# **TWO OF THEM, HALF A LOOP APART.** One figure is a function of a phase
	# and a place, so a second costs a call: while one is swaying right with
	# its left arm up, the other is doing the opposite, and the pair reads as a
	# dance rather than as one puppet.
	shapes : Skeleton.Model -> List(Shapes.Shape)
	shapes = |m| {
		t = I64.to_f64(m.tick) / I64.to_f64(period) * tau
		var $all = [Rect({ x: 0.0, y: 0.0, w: width, h: height, fill: Flat(night) })]
		$all = List.concat($all, figure(t, width * 0.32, 392.0, 1.0))
		$all = List.concat($all, figure(t + tau / 2.0, width * 0.68, 392.0, 1.0))
		$all
	}

	# **A FIGURE IS A PHASE, A PLACE AND A SIZE.** It was pixels at a fixed
	# spot on a fixed screen until a scene wanted six of them at six distances;
	# `s` is how big one metre of skeleton is in pixels, and `feet_y` is where
	# it stands. A skeleton is about 1.35 metres of bone, which is a child's
	# height and suits the company it keeps.
	figure : F64, F64, F64, F64 -> List(Shapes.Shape)
	figure = |t, base, feet_y, s| {

		# The dance: a bob on the double beat, a sway on the beat, and the
		# limbs alternating about it.
		bob = Trig.r_cos(2.0 * t) * 7.0 * s
		sway = Trig.r_sin(t) * 14.0 * s
		swing = Trig.r_sin(t)

		cx = base + sway
		pelvis_y = feet_y - 92.0 * s + bob

		# The spine, and the skull on top of it.
		shoulder_y = pelvis_y - 78.0 * s
		lean = Trig.r_sin(t) * 0.10
		neck = end_of(cx, shoulder_y, lean, -16.0 * s)
		skull = end_of(neck.x, neck.y, lean, -26.0 * s)

		var $out = List.with_capacity(40)

		# Spine and pelvis.
		$out = List.append($out, rib(cx, pelvis_y, cx, shoulder_y, 9.0 * s))
		$out = List.append($out, rib(cx - 22.0 * s, pelvis_y + 2.0 * s, cx + 22.0 * s, pelvis_y + 2.0 * s, 13.0 * s))

		# Four ribs, narrowing downward, each a bar across the spine.
		var $k = 0
		while $k < 4 {
			ry = shoulder_y + (12.0 + I64.to_f64($k) * 13.0) * s
			half = (30.0 - I64.to_f64($k) * 4.0) * s
			$out = List.append($out, rib(cx - half, ry, cx + half, ry, 6.0 * s))
			$k = $k + 1
		}

		# The skull: a disc, two sockets, and a jaw that opens on the beat.
		$out = List.append($out, joint(skull.x, skull.y, 26.0 * s))
		$out = List.append($out, Disc({ x: skull.x - 9.0 * s, y: skull.y - 4.0 * s, r: 6.0 * s, fill: Flat(night), clip: Anywhere }))
		$out = List.append($out, Disc({ x: skull.x + 9.0 * s, y: skull.y - 4.0 * s, r: 6.0 * s, fill: Flat(night), clip: Anywhere }))
		gape = (3.0 + 3.0 * (1.0 + Trig.r_cos(2.0 * t)) / 2.0) * s
		$out = List.append($out, Rect({ x: skull.x - 11.0 * s, y: skull.y + 12.0 * s, w: 22.0 * s, h: gape, fill: Flat(night) }))

		# The arms, alternating: one up while the other is down.
		$out = arm($out, cx - 26.0 * s, shoulder_y + 4.0 * s, s, 0.0 - 1.9 - swing * 0.9, 0.0 - 0.7 - swing * 0.5)
		$out = arm($out, cx + 26.0 * s, shoulder_y + 4.0 * s, s, 1.9 - swing * 0.9, 0.7 - swing * 0.5)

		# The legs, kicking the other way about.
		$out = leg($out, cx - 15.0 * s, pelvis_y + 6.0 * s, s, 0.0 - 0.18 + swing * 0.55, 0.0 - 0.10 - swing * 0.45)
		$out = leg($out, cx + 15.0 * s, pelvis_y + 6.0 * s, s, 0.18 + swing * 0.55, 0.10 - swing * 0.45)
		$out
	}

	# An upper arm and a forearm, with a shoulder, an elbow and a hand.
	arm : List(Shapes.Shape), F64, F64, F64, F64, F64 -> List(Shapes.Shape)
	arm = |acc, x, y, s, upper, fore| {
		elbow = end_of(x, y, upper, 34.0 * s)
		hand = end_of(elbow.x, elbow.y, upper + fore, 30.0 * s)
		List.concat(acc, [
			rib(x, y, elbow.x, elbow.y, 7.0 * s),
			rib(elbow.x, elbow.y, hand.x, hand.y, 6.0 * s),
			joint(x, y, 6.0 * s),
			joint(elbow.x, elbow.y, 5.0 * s),
			joint(hand.x, hand.y, 5.0 * s),
		])
	}

	# A thigh and a shin, with a hip, a knee and a foot.
	leg : List(Shapes.Shape), F64, F64, F64, F64, F64 -> List(Shapes.Shape)
	leg = |acc, x, y, s, thigh, shin| {
		knee = end_of(x, y, thigh, 44.0 * s)
		foot = end_of(knee.x, knee.y, thigh + shin, 42.0 * s)
		toe = end_of(foot.x, foot.y, thigh + shin + 1.4, 16.0 * s)
		List.concat(acc, [
			rib(x, y, knee.x, knee.y, 9.0 * s),
			rib(knee.x, knee.y, foot.x, foot.y, 7.0 * s),
			rib(foot.x, foot.y, toe.x, toe.y, 6.0 * s),
			joint(x, y, 7.0 * s),
			joint(knee.x, knee.y, 6.0 * s),
		])
	}
}
