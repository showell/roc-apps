# Halloween -- walking up to the house, past the skeletons, until the door opens.
#
# **THE FIRST MOVIE HERE WITH A WORLD IN IT.** capture_plot and particles draw
# in screen coordinates; the skeletons dance on a flat black rectangle. This
# one puts things in metres -- right, forward, height -- and asks View where
# they land, so walking forward is one number going up and everything else
# follows: the house grows, the path widens, the skeletons pass by and are
# lost behind you.
#
# The eye is a metre off the ground, which is a small child's, and it bobs as
# one walks. That is the same trick Safari plays with its rider: the whole
# scene is told from a height, and the height is the character.
#
# Six skeletons, three a side, dancing, each a quarter-loop out of step with
# the last so the walkway ripples rather than pulsing. They are Skeleton's own
# figure, at whatever size the distance makes them, turned forty-five degrees:
# half toward the road and half toward the path, so they crowd it.
#
# **THE WALK ENDS BECAUSE SOMETHING ENDS IT.** The door opens from the inside,
# a witch fills the entrance, and the child stops -- the brake is on her
# arrival, not on a frame number, which is why it reads as fright rather than
# as an animation running out.
import Movie
import Shapes
import Brush
import Trig
import View
import Skeleton

Halloween :: [].{
	width : F64
	width = 640.0
	height : F64
	height = 480.0

	view_at : F64 -> View.View
	# A wide-ish lens: a child looking up at a house sees a lot of it, and a
	# long lens put the roof above the frame long before the doorstep.
	view_at = |eye| { width: width, height: height, eye: eye, focal: 380.0 }

	# A skeleton is this tall, and Skeleton's own figure is this many pixels
	# tall at size one.
	bone_metres : F64
	bone_metres = 1.35
	bone_pixels : F64
	bone_pixels = 238.0

	# ── the clock ───────────────────────────────────────────────────────────
	#
	# Sixty frames a second. The whole walk is fifteen of them, which is a
	# child's pace rather than a march; the door starts to open at eight, she
	# is there at ten, and the child is stopped a second later.
	walk_frames : I64
	walk_frames = 900
	door_tick : I64
	door_tick = 470
	open_frames : I64
	open_frames = 130
	witch_tick : I64
	witch_tick = 600
	loom_frames : I64
	loom_frames = 170
	brake_frames : I64
	brake_frames = 70

	# A skeleton's jig takes a second and a half here. Skeleton's own dance is
	# a second, which is jaunty; slower is worse company.
	dance_frames : F64
	dance_frames = 90.0

	# From the pavement to the doorstep.
	walk_from : F64
	walk_from = 0.0
	# **NOT ALL THE WAY TO THE DOOR.** Walking the whole path put the house
	# across the whole frame and left every skeleton behind the eye, which is
	# true of a real walk and no good to look at.
	walk_to : F64
	walk_to = 9.0

	house_at : F64
	house_at = 12.5

	# Half the walkway, in metres. Narrow enough that a skeleton standing
	# beside it is standing over the child.
	path_half : F64
	path_half = 0.76

	# How far off the middle a skeleton stands. Its arms reach about a third of
	# a metre, so at this distance they come over the path.
	flank : F64
	flank = 1.5

	Model : { tick : I64 }

	movie : Movie.Movie(Halloween.Model)
	movie = {
		size: { width: width, height: height },
		init: { tick: 0 },
		advance: |m| { tick: m.tick + 1 },
		# Every frame is a function of the tick, so back is a step the other
		# way and costs nothing to remember.
		back: |m| { tick: if m.tick > 0 { m.tick - 1 } else { 0 } },
		skip: |m| { tick: m.tick + 60 },
		frame: |m| { shapes: shapes(m), roll: 0.0 },
		clock: |m| I64.to_f64(m.tick),
		title: "Trick or Treat",
		stem: "halloween",
	}

	tau : F64
	tau = 6.283185307179586

	# ── the night ───────────────────────────────────────────────────────────
	sky_high : Brush.Rgba
	sky_high = Brush.opaque(0x090c1c)
	sky_low : Brush.Rgba
	sky_low = Brush.opaque(0x2a2144)
	lawn : Brush.Rgba
	lawn = Brush.opaque(0x121a14)
	path_c : Brush.Rgba
	path_c = Brush.opaque(0x3a3630)
	house_c : Brush.Rgba
	house_c = Brush.opaque(0x14121c)
	roof_c : Brush.Rgba
	roof_c = Brush.opaque(0x0c0a12)
	lit : Brush.Rgba
	lit = Brush.opaque(0xffb642)
	door_c : Brush.Rgba
	door_c = Brush.opaque(0x2a1c14)
	moon_c : Brush.Rgba
	moon_c = Brush.opaque(0xf4f0dc)
	spill : Brush.Rgba
	spill = Brush.opaque(0xe89a2c)
	# She is between the child and the hall light, so she has no colour of her
	# own beyond the little there is to catch.
	witch_c : Brush.Rgba
	witch_c = Brush.opaque(0x090608)
	eye_c : Brush.Rgba
	eye_c = Brush.opaque(0xc8f05a)

	# ── how far along, and how the head moves doing it ──────────────────────
	#
	# **THE CHILD BRAKES WHEN SHE APPEARS.** Until then the walk is the tick;
	# after it the pace falls linearly to nothing over `brake_frames`, and the
	# distance covered while it does is the area under that -- half of it.
	paced : I64 -> F64
	paced = |tick|
		if tick <= witch_tick {
			I64.to_f64(tick)
		} else {
			u = ramp(tick - witch_tick, brake_frames)
			I64.to_f64(witch_tick) + I64.to_f64(brake_frames) * (u - u * u / 2.0)
		}

	walked : I64 -> F64
	walked = |tick| {
		t = F64.min(1.0, paced(tick) / I64.to_f64(walk_frames))
		# Ease out, so the child slows at the door rather than stopping dead.
		walk_from + (walk_to - walk_from) * (1.0 - (1.0 - t) * (1.0 - t))
	}

	# What fraction of a walking pace is left, which is how much the head bobs.
	pace_of : I64 -> F64
	pace_of = |tick|
		if tick >= walk_frames {
			0.0
		} else if tick <= witch_tick {
			1.0
		} else {
			1.0 - ramp(tick - witch_tick, brake_frames)
		}

	eye_of : I64 -> F64
	eye_of = |tick|
		# **A BOB, NOT A SHAKE.** A centimetre either way at a step and a half
		# a second says "walking"; three centimetres at twice that said
		# "handheld camera".
		1.05 + pace_of(tick) * Trig.r_sin(I64.to_f64(tick) * 0.26) * 0.009

	# How much of the way through something that starts at `tick` and takes
	# `len`, held at each end.
	ramp : I64, I64 -> F64
	ramp = |since, len|
		if since <= 0 {
			0.0
		} else if since >= len {
			1.0
		} else {
			I64.to_f64(since) / I64.to_f64(len)
		}

	# ── drawing on a plane in the world ─────────────────────────────────────

	# A polygon given as metres on one plane `fwd` away: right, height, right,
	# height. Everything on the house's face is one of these.
	face : View.View, F64, List(F64), Brush.Fill -> Shapes.Shape
	face = |v, fwd, pts, fill| {
		n = List.len(pts)
		var $out = List.with_capacity(n)
		var $i = 0
		while $i + 1 < n {
			p = View.project(v, { right: List.get(pts, $i) ?? 0.0, forward: fwd, height: List.get(pts, $i + 1) ?? 0.0 })
			$out = List.append($out, p.x)
			$out = List.append($out, p.y)
			$i = $i + 2
		}
		Poly({ pts: $out, fill })
	}

	# A rectangle on that plane, by its two opposite corners.
	panel : View.View, F64, F64, F64, F64, F64, Brush.Fill -> Shapes.Shape
	panel = |v, fwd, x0, y0, x1, y1, fill| face(v, fwd, [x0, y1, x1, y1, x1, y0, x0, y0], fill)

	# A strip of ground between two distances, `half` metres either side of the
	# path's middle: the walkway, which is wider the nearer it is.
	strip : View.View, F64, F64, F64, Brush.Fill -> Shapes.Shape
	strip = |v, half, near_f, far_f, fill| {
		a = View.project(v, { right: 0.0 - half, forward: near_f, height: 0.0 })
		b = View.project(v, { right: half, forward: near_f, height: 0.0 })
		c = View.project(v, { right: half, forward: far_f, height: 0.0 })
		d = View.project(v, { right: 0.0 - half, forward: far_f, height: 0.0 })
		Poly({ pts: [a.x, a.y, b.x, b.y, c.x, c.y, d.x, d.y], fill })
	}

	# ── the frame ───────────────────────────────────────────────────────────
	shapes : Halloween.Model -> List(Shapes.Shape)
	shapes = |m| {
		here = walked(m.tick)
		v = view_at(eye_of(m.tick))
		horizon = height / 2.0
		hf = house_at - here

		var $out = List.with_capacity(160)

		# The sky down to the horizon, and the ground below it. A flat world
		# puts the horizon at eye level whatever the eye is doing.
		$out = List.append($out, Rect({ x: 0.0, y: 0.0, w: width, h: horizon + 1.0, fill: Linear({ c0: sky_high, c1: sky_low, o0: 0.0, o1: 1.0, ax: 0.0, ay: 0.0, dx: 0.0, dy: horizon, len2: horizon * horizon }) }))
		$out = List.append($out, Rect({ x: 0.0, y: horizon, w: width, h: height - horizon, fill: Flat(lawn) }))

		# A moon, off to one side and well up.
		$out = List.append($out, Disc({ x: width * 0.78, y: horizon - 132.0, r: 34.0, fill: Flat(moon_c), clip: Anywhere }))

		# The house, at the end of the path.
		$out = if hf > View.near { List.concat($out, house(v, hf, m.tick)) } else { $out }

		# The walkway, from under the feet to the doorstep.
		$out = List.append($out, strip(v, path_half, 0.4, F64.max(View.near * 2.0, hf), Flat(path_c)))

		# Six skeletons, three a side, each a quarter-loop behind the last, and
		# each turned to face across the path. Farthest first, so a nearer one
		# paints over it.
		beat = I64.to_f64(m.tick) / dance_frames * tau
		var $k = 2
		while $k >= 0 {
			z = 4.5 + I64.to_f64($k) * 3.6
			phase = I64.to_f64($k) * tau / 4.0
			$out = List.concat($out, guard(v, 0.0 - flank, z - here, beat + phase, yaw))
			$out = List.concat($out, guard(v, flank, z - here, beat + phase + tau / 2.0, 0.0 - yaw))
			$k = $k - 1
		}
		$out
	}

	# Forty-five degrees: cos of it is how wide a turned figure still is, and
	# the sign of it is which way it faces.
	yaw : F64
	yaw = 0.7071067811865476

	# One skeleton standing at (right, forward), as big as that distance makes
	# it, turned by `k`. Nothing is drawn for one that has been walked past.
	guard : View.View, F64, F64, F64, F64 -> List(Shapes.Shape)
	guard = |v, right, fwd, t, k|
		if fwd <= View.near {
			[]
		} else {
			feet = View.project(v, { right: right, forward: fwd, height: 0.0 })
			s = View.pixels_per_metre(v, fwd) * bone_metres / bone_pixels
			if s < 0.04 { [] } else { Shapes.squash_x(Skeleton.figure(t, feet.x, feet.y, s), feet.x, k) }
		}

	# ── the house, and what comes out of it ─────────────────────────────────
	#
	# Its face is one distance away, so every panel on it is a flat quad.
	house : View.View, F64, I64 -> List(Shapes.Shape)
	house = |v, hf, tick| {
		open = ramp(tick - door_tick, open_frames)
		# The leaf is hinged on the left and swings inward: what we see of it
		# narrows against its own jamb while the lit hall grows past it.
		leaf = 0.0 - 0.55 + 1.1 * (1.0 - open)
		roof_l = View.project(v, { right: 0.0 - 3.5, forward: hf, height: 2.6 })
		roof_r = View.project(v, { right: 3.5, forward: hf, height: 2.6 })
		peak = View.project(v, { right: 0.0, forward: hf, height: 4.2 })

		var $out = [
			panel(v, hf, 0.0 - 3.0, 0.0, 3.0, 2.6, Flat(house_c)),
			Poly({ pts: [roof_l.x, roof_l.y, peak.x, peak.y, roof_r.x, roof_r.y], fill: Flat(roof_c) }),
			# Two lit windows.
			panel(v, hf, 0.0 - 2.3, 1.5, 0.0 - 1.3, 2.3, Flat(lit)),
			panel(v, hf, 1.3, 1.5, 2.3, 2.3, Flat(lit)),
			# The hall behind the doorway, and the door across it.
			panel(v, hf, 0.0 - 0.55, 0.0, 0.55, 1.95, Flat(spill)),
		]
		$out = if open < 1.0 { List.append($out, panel(v, hf, 0.0 - 0.55, 0.0, leaf, 1.95, Flat(door_c))) } else { $out }
		# She comes down the hall once the door is on its way open.
		List.concat($out, witch(v, hf, ramp(tick - witch_tick, loom_frames)))
	}

	# **SHE ARRIVES BY GROWING.** There is no clipping in the vocabulary, so
	# she cannot walk in from the side of a doorway; coming up the hall from
	# the back of it keeps her inside the one lit rectangle the whole way, and
	# is what someone answering a door actually does.
	witch : View.View, F64, F64 -> List(Shapes.Shape)
	witch = |v, fwd, u|
		if u <= 0.0 {
			[]
		} else {
			# Two thirds of her height at the back of the hall, all of it at
			# the threshold.
			s = 0.66 + 0.34 * u
			ppm = View.pixels_per_metre(v, fwd)
			shoulder_l = View.project(v, { right: 0.0 - 0.19 * s, forward: fwd, height: 1.10 * s })
			shoulder_r = View.project(v, { right: 0.19 * s, forward: fwd, height: 1.10 * s })
			hand_l = View.project(v, { right: 0.0 - 0.52 * s, forward: fwd, height: 0.70 * s })
			hand_r = View.project(v, { right: 0.52 * s, forward: fwd, height: 0.70 * s })
			head = View.project(v, { right: 0.0, forward: fwd, height: 1.24 * s })
			eye_l = View.project(v, { right: 0.0 - 0.045 * s, forward: fwd, height: 1.26 * s })
			eye_r = View.project(v, { right: 0.045 * s, forward: fwd, height: 1.26 * s })
			[
				# The robe, flaring to the floor.
				face(v, fwd, [0.0 - 0.19 * s, 1.10 * s, 0.19 * s, 1.10 * s, 0.30 * s, 0.60 * s, 0.45 * s, 0.0, 0.0 - 0.45 * s, 0.0, 0.0 - 0.30 * s, 0.60 * s], Flat(witch_c)),
				# Two arms, held out from it.
				Shapes.line(shoulder_l.x, shoulder_l.y, hand_l.x, hand_l.y, 0.075 * s * ppm, Flat(witch_c)),
				Shapes.line(shoulder_r.x, shoulder_r.y, hand_r.x, hand_r.y, 0.075 * s * ppm, Flat(witch_c)),
				Disc({ x: head.x, y: head.y, r: 0.115 * s * ppm, fill: Flat(witch_c), clip: Anywhere }),
				# The hat: a brim, and a point that leans.
				face(v, fwd, [0.0 - 0.32 * s, 1.37 * s, 0.32 * s, 1.37 * s, 0.30 * s, 1.31 * s, 0.0 - 0.30 * s, 1.31 * s], Flat(witch_c)),
				face(v, fwd, [0.0 - 0.25 * s, 1.36 * s, 0.25 * s, 1.36 * s, 0.12 * s, 1.86 * s], Flat(witch_c)),
				# **THE ONLY PART OF HER THAT IS NOT DARK.** A silhouette says
				# somebody; two eyes say who.
				Disc({ x: eye_l.x, y: eye_l.y, r: 0.022 * s * ppm, fill: Flat(eye_c), clip: Anywhere }),
				Disc({ x: eye_r.x, y: eye_r.y, r: 0.022 * s * ppm, fill: Flat(eye_c), clip: Anywhere }),
			]
		}
}
