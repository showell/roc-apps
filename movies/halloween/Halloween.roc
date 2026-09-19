# Halloween -- up the path, and back down it rather faster.
#
# **THE FIRST MOVIE HERE WITH A WORLD IN IT.** capture_plot and particles draw
# in screen coordinates; the skeletons dance on a flat black rectangle. This
# one puts things in metres -- right, forward, height -- and asks View where
# they land, so walking is one number changing and everything else follows:
# the house grows, the path widens, the skeletons pass by.
#
# The eye is a metre off the ground, which is a small child's, and it bobs
# four times a metre walked rather than so many times a second, so the bob is
# a stride and dies when the walking does. That is the same trick Safari plays
# with its rider: the whole scene is told from a height, and the height is the
# character.
#
# Six skeletons, three a side, dancing, each a quarter-loop out of step with
# the last. They face wherever the child was half a second ago, turned toward
# the path, so they track whoever is on it -- and while the child stands still
# they square up and face them head on.
#
# **THE WALK ENDS BECAUSE SOMETHING ENDS IT.** The door opens from the inside,
# a witch fills the entrance, the child stands frozen for half a second, turns
# on the spot and goes back down the path half again as fast. Every brake and
# every turn hangs off her arrival, not off a frame number.
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

	# A wide-ish lens: a child looking up at a house sees a lot of it, and a
	# long lens put the roof above the frame long before the doorstep.
	focal : F64
	focal = 380.0

	view_of : I64 -> View.View
	view_of = |tick| { width: width, height: height, eye: eye_of(tick), focal: focal, heading: heading_of(tick) }

	# A skeleton is this tall, and Skeleton's own figure is this many pixels
	# tall at size one.
	bone_metres : F64
	bone_metres = 1.35
	bone_pixels : F64
	bone_pixels = 238.0

	# ── the clock ───────────────────────────────────────────────────────────
	#
	# Sixty frames a second. The approach is fifteen of them, which is a
	# child's pace rather than a march.
	walk_frames : I64
	walk_frames = 900
	walk_to : F64
	walk_to = 9.0

	# The door starts to open at eight seconds and she is all the way down the
	# hall at twelve; the child brakes from the moment she appears.
	door_tick : I64
	door_tick = 470
	open_frames : I64
	open_frames = 130
	witch_tick : I64
	witch_tick = 600
	loom_frames : I64
	loom_frames = 120
	brake_frames : I64
	brake_frames = 100

	# Half a second of nothing at all, and then a turn that takes better than
	# two seconds: a child looking over both shoulders on the way round, not a
	# gun turret.
	spin_tick : I64
	spin_tick = 750
	spin_frames : I64
	spin_frames = 132

	# **THE WAY BACK IS HALF AGAIN AS FAST.** The approach averaged about
	# twelve millimetres a frame; this is sixteen, reached over three quarters
	# of a second.
	back_tick : I64
	back_tick = 882
	back_speed : F64
	back_speed = 0.0154
	back_ramp : I64
	back_ramp = 45

	# A skeleton's jig takes a second and a half here. Skeleton's own dance is
	# a second, which is jauntier than this wants.
	dance_frames : F64
	dance_frames = 90.0

	# Where the skeletons stand: far enough apart to be passed one pair at a
	# time, and the last pair still short of the door, so they flank it.
	flank : F64
	flank = 1.5
	first_at : F64
	first_at = 3.4
	spacing : F64
	spacing = 3.5

	# Half the walkway, in metres. Narrow enough that a skeleton standing
	# beside it is standing over the child.
	path_half : F64
	path_half = 0.76

	house_at : F64
	house_at = 12.5

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
	street_c : Brush.Rgba
	street_c = Brush.opaque(0x24232a)
	lamp_c : Brush.Rgba
	lamp_c = Brush.opaque(0xffe9a8)
	pole_c : Brush.Rgba
	pole_c = Brush.opaque(0x101014)
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
	# The hall floor, which is the same light landing on boards rather than
	# coming straight at you.
	floor_c : Brush.Rgba
	floor_c = Brush.opaque(0xb0701c)
	fence_c : Brush.Rgba
	fence_c = Brush.opaque(0x272430)
	# She is between the child and the hall light, so she has no colour of her
	# own beyond the little there is to catch.
	witch_c : Brush.Rgba
	witch_c = Brush.opaque(0x090608)
	eye_c : Brush.Rgba
	eye_c = Brush.opaque(0xc8f05a)

	# ── where the child is, and which way they are looking ──────────────────
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

	approach : I64 -> F64
	approach = |tick| {
		t = F64.min(1.0, paced(tick) / I64.to_f64(walk_frames))
		# Ease out, so the child slows up the path rather than stopping dead.
		walk_to * (1.0 - (1.0 - t) * (1.0 - t))
	}

	# As far up the path as the child ever gets.
	arrived : F64
	arrived = approach(back_tick)

	# How far back down it they have come, which stops at the pavement.
	retreated : I64 -> F64
	retreated = |tick| {
		s = tick - back_tick
		if s <= 0 {
			0.0
		} else {
			u = I64.to_f64(s)
			r = I64.to_f64(back_ramp)
			# The area under a pace that ramps up and then holds.
			d = if u < r { back_speed * u * u / (2.0 * r) } else { back_speed * (u - r / 2.0) }
			F64.min(d, arrived)
		}
	}

	here : I64 -> F64
	here = |tick| approach(tick) - retreated(tick)

	# Every metre of it, whichever way it was walked: what the stride counts.
	travelled : I64 -> F64
	travelled = |tick| approach(tick) + retreated(tick)

	# The turn, quick and eased at both ends.
	heading_of : I64 -> F64
	heading_of = |tick| Trig.pi * smooth(ramp(tick - spin_tick, spin_frames))

	# **A STRIDE, NOT A SHAKE.** Four bobs to the metre of nine millimetres
	# each: it is the walking that makes it, so it quickens on the way back
	# and stops dead when the child does.
	bobs_per_metre : F64
	bobs_per_metre = 4.0

	eye_of : I64 -> F64
	eye_of = |tick| 1.05 + stride(tick) * Trig.r_sin(travelled(tick) * bobs_per_metre * tau) * 0.009

	# How much walking is going on, from the walking itself.
	stride : I64 -> F64
	stride = |tick| {
		d = here(tick) - here(tick - 5)
		F64.min(1.0, (if d < 0.0 { 0.0 - d } else { d }) * 20.0)
	}

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

	smooth : F64 -> F64
	smooth = |u| u * u * (3.0 - 2.0 * u)

	# ── drawing on a plane in the world ─────────────────────────────────────

	# A polygon of points in the world, however they are placed: the door
	# leaf turns out of its own plane on its hinge, and a floor lies flat.
	world : View.View, List(View.At), Brush.Fill -> List(Shapes.Shape)
	world = |v, ats, fill| Shapes.polygon(View.seen(v, ats), fill)

	# A polygon given as metres on one plane `fwd` away: right, height, right,
	# height. Everything on the house's face is one of these.
	face : View.View, F64, List(F64), Brush.Fill -> List(Shapes.Shape)
	face = |v, fwd, pts, fill| {
		n = List.len(pts)
		var $ats = List.with_capacity(n // 2)
		var $i = 0
		while $i + 1 < n {
			$ats = List.append($ats, { right: List.get(pts, $i) ?? 0.0, forward: fwd, height: List.get(pts, $i + 1) ?? 0.0 })
			$i = $i + 2
		}
		world(v, $ats, fill)
	}

	# A rectangle on that plane, by its two opposite corners.
	panel : View.View, F64, F64, F64, F64, F64, Brush.Fill -> List(Shapes.Shape)
	panel = |v, fwd, x0, y0, x1, y1, fill| face(v, fwd, [x0, y1, x1, y1, x1, y0, x0, y0], fill)

	# A strip of ground between two distances, `half` metres either side of
	# the path's middle: the walkway, which is wider the nearer it is.
	strip : View.View, F64, F64, F64, Brush.Fill -> List(Shapes.Shape)
	strip = |v, half, near_f, far_f, fill|
		Shapes.polygon(
			View.seen(v, [
				{ right: 0.0 - half, forward: near_f, height: 0.0 },
				{ right: half, forward: near_f, height: 0.0 },
				{ right: half, forward: far_f, height: 0.0 },
				{ right: 0.0 - half, forward: far_f, height: 0.0 },
			]),
			fill,
		)

	# ── the frame ───────────────────────────────────────────────────────────
	shapes : Halloween.Model -> List(Shapes.Shape)
	shapes = |m| {
		now = here(m.tick)
		v = view_of(m.tick)
		horizon = height / 2.0

		var $out = List.with_capacity(200)

		# The sky down to the horizon, and the ground below it. A flat world
		# puts the horizon at eye level whatever the eye is doing.
		$out = List.append($out, Rect({ x: 0.0, y: 0.0, w: width, h: horizon + 1.0, fill: Linear({ c0: sky_high, c1: sky_low, o0: 0.0, o1: 1.0, ax: 0.0, ay: 0.0, dx: 0.0, dy: horizon, len2: horizon * horizon }) }))
		$out = List.append($out, Rect({ x: 0.0, y: horizon, w: width, h: height - horizon, fill: Flat(lawn) }))

		# The moon, which is a long way off and so goes behind you when you
		# turn round, the same as everything else does.
		moon = { right: 150.0, forward: 360.0, height: 160.0 }
		$out = if View.ahead(v, moon) {
			c = View.turn(v, moon)
			p = View.flat(v, c)
			List.append($out, Disc({ x: p.x, y: p.y, r: 32.0 * View.pixels_per_metre(v, c.forward), fill: Flat(moon_c), clip: Anywhere }))
		} else {
			$out
		}

		# The street the child came from, the walkway, and the house.
		$out = List.concat($out, strip(v, 14.0, 0.0 - 9.0 - now, 0.0 - 0.6 - now, Flat(street_c)))
		$out = List.concat($out, fence(v, now))
		# **SOMETHING TO WALK BACK TOWARD.** The way down the path is four
		# seconds of nothing once the house is behind you; a light at the kerb
		# is where the child is going.
		$out = List.concat($out, streetlight(v, now))
		$out = List.concat($out, house(v, house_at - now, m.tick))
		$out = List.concat($out, strip(v, path_half, 0.0 - now, house_at - now, Flat(path_c)))

		# Six skeletons, three a side, each a quarter-loop behind the last.
		# Farthest first, so a nearer one paints over it.
		beat = I64.to_f64(m.tick) / dance_frames * tau
		lag = here(m.tick - lag_frames)
		tilt = (1.0 - attend(m.tick)) * Trig.pi / 4.0
		var $k = 2
		while $k >= 0 {
			z = first_at + I64.to_f64($k) * spacing
			phase = I64.to_f64($k) * tau / 4.0
			$out = List.concat($out, guard(v, 0.0 - flank, z, now, lag, beat + phase, tilt, 1.0))
			$out = List.concat($out, guard(v, flank, z, now, lag, beat + phase + tau / 2.0, tilt, 0.0 - 1.0))
			$k = $k - 1
		}
		$out
	}

	# A light at the kerb: a pole on the plane it stands in, the lamp, and the
	# glow around it, which is the one warm thing on the way out.
	streetlight : View.View, F64 -> List(Shapes.Shape)
	streetlight = |v, now| {
		fwd = 0.0 - 1.1 - now
		lamp = { right: 1.9, forward: fwd, height: 4.1 }
		if View.ahead(v, lamp) {
			c = View.turn(v, lamp)
			p = View.flat(v, c)
			ppm = View.pixels_per_metre(v, c.forward)
			List.concat(
				face(v, fwd, [1.84, 0.0, 1.96, 0.0, 1.96, 4.1, 1.84, 4.1], Flat(pole_c)),
				[
					Disc({ x: p.x, y: p.y, r: 1.4 * ppm, fill: Radial({ inner: Brush.with_alpha(0x80ffe9a8), outer: Brush.with_alpha(0x00ffe9a8), x: p.x, y: p.y, r0: 0.0, r1: 1.4 * ppm }), clip: Anywhere }),
					Disc({ x: p.x, y: p.y, r: 0.24 * ppm, fill: Flat(lamp_c), clip: Anywhere }),
				],
			)
		} else {
			[]
		}
	}

	# ── the skeletons ───────────────────────────────────────────────────────
	#
	# How far behind the child's own movements they are.
	lag_frames : I64
	lag_frames = 30

	# **THEY SQUARE UP WHEN THE CHILD STOPS.** Off the path they stand at
	# forty-five degrees, half toward the road and half over the walkway; the
	# moment the child freezes in front of the witch they all turn and face
	# them, and they go back to the angle once the child is running.
	attend : I64 -> F64
	attend = |tick| smooth(ramp(tick - (witch_tick + 60), 90)) * (1.0 - smooth(ramp(tick - (back_tick + 40), 100)))

	# One skeleton standing at (right, forward) in the world, as big as that
	# distance makes it and as wide as the way it is facing leaves it.
	guard : View.View, F64, F64, F64, F64, F64, F64, F64 -> List(Shapes.Shape)
	guard = |v, sx, sz, now, lag, t, tilt, side| {
		spot = { right: sx, forward: sz - now, height: 0.0 }
		if View.ahead(v, spot) {
			c = View.turn(v, spot)
			feet = View.flat(v, c)
			s = View.pixels_per_metre(v, c.forward) * bone_metres / bone_pixels
			# Too small to read, or entirely off one side of the frame.
			if s < 0.04 or feet.x + 120.0 * s < 0.0 or feet.x - 120.0 * s > width {
				[]
			} else {
				k = facing(sx, sz, now, lag, tilt, side)
				Shapes.squash_x(Skeleton.figure(t, feet.x, feet.y, s), feet.x, k)
			}
		} else {
			[]
		}
	}

	# How wide a skeleton is from here: the cosine of the angle between the
	# way it faces and the way the child is, which is all a flat figure can
	# say about being turned. It faces where the child WAS, tilted toward the
	# path, so it is always coming round to them and never quite there.
	facing : F64, F64, F64, F64, F64, F64 -> F64
	facing = |sx, sz, now, lag, tilt, side| {
		u = unit(0.0 - sx, now - sz)
		was = unit(0.0 - sx, lag - sz)
		c = Trig.r_cos(tilt * side)
		s = Trig.r_sin(tilt * side)
		nx = was.x * c - was.z * s
		nz = was.x * s + was.z * c
		side * (nx * u.x + nz * u.z)
	}

	unit : F64, F64 -> { x : F64, z : F64 }
	unit = |x, z| {
		d = F64.sqrt(x * x + z * z)
		if d <= 0.000001 { { x: 0.0, z: 1.0 } } else { { x: x / d, z: z / d } }
	}

	# ── the house, and what comes out of it ─────────────────────────────────
	#
	# Its face is one distance away, so every panel on it is a flat quad.
	house : View.View, F64, I64 -> List(Shapes.Shape)
	house = |v, hf, tick| {
		open = ramp(tick - door_tick, open_frames)

		var $out = List.with_capacity(24)
		$out = List.concat($out, panel(v, hf, 0.0 - 3.0, 0.0, 3.0, 2.6, Flat(house_c)))
		$out = List.concat($out, face(v, hf, [0.0 - 3.5, 2.6, 0.0, 4.2, 3.5, 2.6], Flat(roof_c)))
		# Two lit windows.
		$out = List.concat($out, panel(v, hf, 0.0 - 2.3, 1.5, 0.0 - 1.3, 2.3, Flat(lit)))
		$out = List.concat($out, panel(v, hf, 1.3, 1.5, 2.3, 2.3, Flat(lit)))
		# **THE HALL IS NOT THERE UNTIL THE DOOR IS OPEN.** It used to be drawn
		# under a shut door at exactly the door's own rectangle, and a canvas
		# antialiases both edges: the bright one bled through the dark one by
		# a fraction of a pixel, and as the child walked, that shared edge
		# drifted across the pixel grid and the light pulsed.
		$out = if open > 0.0 {
			List.concat(
				List.concat($out, panel(v, hf, 0.0 - 0.53, 0.0, 0.53, 1.93, Flat(spill))),
				# The floor of the hall, which is what the door sweeps over
				# and what she stands on.
				world(v, [
					{ right: 0.0 - 0.53, forward: hf, height: 0.0 },
					{ right: 0.53, forward: hf, height: 0.0 },
					{ right: 0.53, forward: hf + 2.4, height: 0.0 },
					{ right: 0.0 - 0.53, forward: hf + 2.4, height: 0.0 },
				], Flat(floor_c)),
			)
		} else {
			$out
		}
		$out = List.concat($out, leaf(v, hf, open))
		# She comes up the hall once the door is on its way open.
		List.concat($out, witch(v, hf, ramp(tick - witch_tick, loom_frames)))
	}

	# **A DOOR IS ON A HINGE.** It was a rectangle that got narrower, which is
	# what a door looks like only if you are standing on its hinge; this one
	# turns about the jamb, so its free edge swings back into the hall and its
	# foot draws that arc across the floor.
	hinge_at : F64
	hinge_at = 0.0 - 0.55
	leaf_wide : F64
	leaf_wide = 1.1
	# Ninety-five degrees: far enough back to be edge-on, not so far that it
	# swings out past its own jamb.
	leaf_swing : F64
	leaf_swing = 1.658

	leaf : View.View, F64, F64 -> List(Shapes.Shape)
	leaf = |v, hf, open| {
		a = open * leaf_swing
		fx = hinge_at + leaf_wide * Trig.r_cos(a)
		ff = hf + leaf_wide * Trig.r_sin(a)
		world(v, [
			{ right: hinge_at, forward: hf, height: 1.95 },
			{ right: fx, forward: ff, height: 1.95 },
			{ right: fx, forward: ff, height: 0.0 },
			{ right: hinge_at, forward: hf, height: 0.0 },
		], Flat(door_c))
	}

	# **SHE ARRIVES BY WALKING.** There is no clipping of one shape to another
	# in the vocabulary, so she cannot walk in from the side of a doorway;
	# coming up the hall from the back of it keeps her inside the one lit
	# rectangle the whole way, and is what someone answering a door does.
	# She is drawn at her own size at her own distance, so the projection
	# shrinks her and stands her feet on the part of the floor she is on --
	# scaling a figure pinned to the doorway put her feet on the threshold
	# whatever it was pretending about how far back she was.
	hall_deep : F64
	hall_deep = 2.2

	witch : View.View, F64, F64 -> List(Shapes.Shape)
	witch = |v, door_f, u|
		if u <= 0.0 {
			[]
		} else {
			fwd = door_f + hall_deep * (1.0 - u)
			here_she = { right: 0.0, forward: fwd, height: 1.0 }
			if View.ahead(v, here_she) {
				c = View.turn(v, here_she)
				ppm = View.pixels_per_metre(v, c.forward)
				shoulder_l = View.project(v, { right: 0.0 - 0.19, forward: fwd, height: 1.10 })
				shoulder_r = View.project(v, { right: 0.19, forward: fwd, height: 1.10 })
				hand_l = View.project(v, { right: 0.0 - 0.52, forward: fwd, height: 0.70 })
				hand_r = View.project(v, { right: 0.52, forward: fwd, height: 0.70 })
				head = View.project(v, { right: 0.0, forward: fwd, height: 1.24 })
				eye_l = View.project(v, { right: 0.0 - 0.045, forward: fwd, height: 1.26 })
				eye_r = View.project(v, { right: 0.045, forward: fwd, height: 1.26 })
				var $out = List.with_capacity(14)
				# Two legs and two long pointed shoes, under a hem that stops
				# short of the floor.
				$out = List.concat($out, face(v, fwd, [0.0 - 0.15, 0.26, 0.0 - 0.07, 0.26, 0.0 - 0.07, 0.05, 0.0 - 0.15, 0.05], Flat(witch_c)))
				$out = List.concat($out, face(v, fwd, [0.07, 0.26, 0.15, 0.26, 0.15, 0.05, 0.07, 0.05], Flat(witch_c)))
				$out = List.concat($out, face(v, fwd, [0.0 - 0.15, 0.08, 0.0 - 0.06, 0.08, 0.0 - 0.32, 0.0], Flat(witch_c)))
				$out = List.concat($out, face(v, fwd, [0.15, 0.08, 0.06, 0.08, 0.32, 0.0], Flat(witch_c)))
				# The robe, flaring to the hem.
				$out = List.concat($out, face(v, fwd, [0.0 - 0.19, 1.10, 0.19, 1.10, 0.30, 0.66, 0.42, 0.24, 0.0 - 0.42, 0.24, 0.0 - 0.30, 0.66], Flat(witch_c)))
				# Two arms, held out from it.
				$out = List.append($out, Shapes.line(shoulder_l.x, shoulder_l.y, hand_l.x, hand_l.y, 0.075 * ppm, Flat(witch_c)))
				$out = List.append($out, Shapes.line(shoulder_r.x, shoulder_r.y, hand_r.x, hand_r.y, 0.075 * ppm, Flat(witch_c)))
				$out = List.append($out, Disc({ x: head.x, y: head.y, r: 0.115 * ppm, fill: Flat(witch_c), clip: Anywhere }))
				# The hat: a brim, and a point that leans.
				$out = List.concat($out, face(v, fwd, [0.0 - 0.32, 1.37, 0.32, 1.37, 0.30, 1.31, 0.0 - 0.30, 1.31], Flat(witch_c)))
				$out = List.concat($out, face(v, fwd, [0.0 - 0.25, 1.36, 0.25, 1.36, 0.12, 1.86], Flat(witch_c)))
				# **THE ONLY PART OF HER THAT IS NOT DARK.** A silhouette says
				# somebody; two eyes say who.
				$out = List.append($out, Disc({ x: eye_l.x, y: eye_l.y, r: 0.022 * ppm, fill: Flat(eye_c), clip: Anywhere }))
				List.append($out, Disc({ x: eye_r.x, y: eye_r.y, r: 0.022 * ppm, fill: Flat(eye_c), clip: Anywhere }))
			} else {
				[]
			}
		}

	# ── the fence ───────────────────────────────────────────────────────────
	#
	# **THE YARD IS FENCED, NOT JUST FRONTED.** Across the kerb it is behind
	# the eye for the whole walk up and waiting when the child turns round;
	# up each side it is there from the first frame, at the edges of the
	# frame, which is what says the path goes somewhere enclosed. Pointed
	# pickets on two rails, with two posts and a gap where the path comes
	# through.
	fence_at : F64
	fence_at = 0.2
	fence_high : F64
	fence_high = 2.0
	gate_half : F64
	gate_half = 1.0
	yard_half : F64
	yard_half = 5.5
	yard_deep : F64
	yard_deep = 13.0
	# Along the front, out from the gate; up each side, back from the kerb.
	front_pickets : I64
	front_pickets = 21
	side_pickets : I64
	side_pickets = 42
	picket_wide : F64
	picket_wide = 0.13
	rail_at_low : F64
	rail_at_low = 0.52
	rail_at_high : F64
	rail_at_high = 1.34

	fence : View.View, F64 -> List(Shapes.Shape)
	fence = |v, now| {
		fwd = fence_at - now
		var $out = List.with_capacity(160)
		# The two gate posts, taller and square-topped.
		$out = List.concat($out, face(v, fwd, [gate_half, 0.0, gate_half + 0.18, 0.0, gate_half + 0.18, 2.35, gate_half, 2.35], Flat(fence_c)))
		$out = List.concat($out, face(v, fwd, [0.0 - gate_half - 0.18, 0.0, 0.0 - gate_half, 0.0, 0.0 - gate_half, 2.35, 0.0 - gate_half - 0.18, 2.35], Flat(fence_c)))
		$out = List.concat($out, front_rail(v, fwd, rail_at_low))
		$out = List.concat($out, front_rail(v, fwd, rail_at_high))
		var $i = 0
		while $i < front_pickets {
			x = gate_half + 0.24 + I64.to_f64($i) * 0.2
			$out = List.concat($out, picket(v, fwd, x))
			$out = List.concat($out, picket(v, fwd, 0.0 - x - picket_wide))
			$i = $i + 1
		}
		# Up both sides of the yard, from the kerb to past the house.
		$out = List.concat($out, side_rail(v, now, yard_half, rail_at_low))
		$out = List.concat($out, side_rail(v, now, yard_half, rail_at_high))
		$out = List.concat($out, side_rail(v, now, 0.0 - yard_half, rail_at_low))
		$out = List.concat($out, side_rail(v, now, 0.0 - yard_half, rail_at_high))
		var $j = 0
		while $j < side_pickets {
			f = fence_at + 0.2 + I64.to_f64($j) * 0.3 - now
			$out = List.concat($out, side_picket(v, yard_half, f))
			$out = List.concat($out, side_picket(v, 0.0 - yard_half, f))
			$j = $j + 1
		}
		$out
	}

	picket : View.View, F64, F64 -> List(Shapes.Shape)
	picket = |v, fwd, x|
		face(v, fwd, [x, 0.0, x + picket_wide, 0.0, x + picket_wide, fence_high - 0.16, x + picket_wide / 2.0, fence_high, x, fence_high - 0.16], Flat(fence_c))

	front_rail : View.View, F64, F64 -> List(Shapes.Shape)
	front_rail = |v, fwd, y|
		List.concat(
			face(v, fwd, [gate_half, y, yard_half, y, yard_half, y + 0.1, gate_half, y + 0.1], Flat(fence_c)),
			face(v, fwd, [0.0 - yard_half, y, 0.0 - gate_half, y, 0.0 - gate_half, y + 0.1, 0.0 - yard_half, y + 0.1], Flat(fence_c)),
		)

	# A side picket stands in the plane of its own side, so its corners are at
	# two distances rather than one.
	side_picket : View.View, F64, F64 -> List(Shapes.Shape)
	side_picket = |v, x, f|
		world(v, [
			{ right: x, forward: f, height: 0.0 },
			{ right: x, forward: f + picket_wide, height: 0.0 },
			{ right: x, forward: f + picket_wide, height: fence_high - 0.16 },
			{ right: x, forward: f + picket_wide / 2.0, height: fence_high },
			{ right: x, forward: f, height: fence_high - 0.16 },
		], Flat(fence_c))

	side_rail : View.View, F64, F64, F64 -> List(Shapes.Shape)
	side_rail = |v, now, x, y|
		world(v, [
			{ right: x, forward: fence_at - now, height: y },
			{ right: x, forward: yard_deep - now, height: y },
			{ right: x, forward: yard_deep - now, height: y + 0.1 },
			{ right: x, forward: fence_at - now, height: y + 0.1 },
		], Flat(fence_c))
}
