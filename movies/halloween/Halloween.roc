# Halloween -- walking up to the house, past the skeletons.
#
# **THE FIRST MOVIE HERE WITH A WORLD IN IT.** capture_plot and particles draw
# in screen coordinates; the skeletons dance on a flat black rectangle. This
# one puts things in metres -- right, forward, height -- and asks View where
# they land, so walking forward is one number going up and everything else
# follows: the house grows, the path widens, the skeletons pass by and are
# lost behind you.
#
# The eye is a metre and five centimetres off the ground, which is a small
# child's, and it bobs as one walks. That is the same trick Safari plays with
# its rider: the whole scene is told from a height, and the height is the
# character.
#
# Six skeletons, three a side, each a quarter-loop out of step with the last so
# the walkway ripples rather than pulsing. They are Skeleton's own figure, at
# whatever size the distance makes them.
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

	# Sixty frames a second of walking, and the walk is done in eight.
	period : I64
	period = 60
	walk_frames : I64
	walk_frames = 8 * 60

	# From the pavement to the doorstep.
	walk_from : F64
	walk_from = 0.0
	# **NOT ALL THE WAY TO THE DOOR.** Walking the whole path put the house
	# across the whole frame and left every skeleton behind the eye, which is
	# true of a real walk and no good to look at. It stops a few paces short,
	# with the last pair of skeletons still flanking the door.
	walk_to : F64
	walk_to = 9.0

	house_at : F64
	house_at = 14.0

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

	# How far along the walk, and how the head bobs doing it.
	walked : I64 -> F64
	walked = |tick| {
		t = if tick >= walk_frames { 1.0 } else { I64.to_f64(tick) / I64.to_f64(walk_frames) }
		# Ease out, so the child slows at the door rather than stopping dead.
		walk_from + (walk_to - walk_from) * (1.0 - (1.0 - t) * (1.0 - t))
	}

	eye_of : I64 -> F64
	eye_of = |tick| {
		# Still at the door; bobbing while there is ground to cover.
		moving = if tick >= walk_frames { 0.0 } else { 1.0 }
		1.05 + moving * Trig.r_sin(I64.to_f64(tick) * 0.42) * 0.022
	}

	# A quad in the world, as a polygon on the screen.
	quad : View.View, F64, F64, F64, F64, F64, F64, F64, F64, Brush.Fill -> List(Shapes.Shape)
	quad = |v, x0, f0, h0, x1, f1, h1, x2, f2, fill| {
		# Four corners given as two edges: (x0,f0)..(x1,f1) at heights h0 and h1.
		_ = x2
		_ = f2
		a = View.project(v, { right: x0, forward: f0, height: h0 })
		b = View.project(v, { right: x1, forward: f0, height: h0 })
		c = View.project(v, { right: x1, forward: f1, height: h1 })
		d = View.project(v, { right: x0, forward: f1, height: h1 })
		[Poly({ pts: [a.x, a.y, b.x, b.y, c.x, c.y, d.x, d.y], fill })]
	}

	# A flat panel on the house's face: it all sits at one distance.
	panel : View.View, F64, F64, F64, F64, F64, Brush.Fill -> Shapes.Shape
	panel = |v, fwd, x0, y0, x1, y1, fill| {
		a = View.project(v, { right: x0, forward: fwd, height: y1 })
		b = View.project(v, { right: x1, forward: fwd, height: y1 })
		c = View.project(v, { right: x1, forward: fwd, height: y0 })
		d = View.project(v, { right: x0, forward: fwd, height: y0 })
		Poly({ pts: [a.x, a.y, b.x, b.y, c.x, c.y, d.x, d.y], fill })
	}

	shapes : Halloween.Model -> List(Shapes.Shape)
	shapes = |m| {
		here = walked(m.tick)
		v = view_at(eye_of(m.tick))
		horizon = height / 2.0

		var $out = List.with_capacity(120)

		# The sky down to the horizon, and the ground below it. A flat world
		# puts the horizon at eye level whatever the eye is doing.
		$out = List.append($out, Rect({ x: 0.0, y: 0.0, w: width, h: horizon + 1.0, fill: Linear({ c0: sky_high, c1: sky_low, o0: 0.0, o1: 1.0, ax: 0.0, ay: 0.0, dx: 0.0, dy: horizon, len2: horizon * horizon }) }))
		$out = List.append($out, Rect({ x: 0.0, y: horizon, w: width, h: height - horizon, fill: Flat(lawn) }))

		# A moon, off to one side and well up.
		$out = List.append($out, Disc({ x: width * 0.78, y: horizon - 132.0, r: 34.0, fill: Flat(moon_c), clip: Anywhere }))

		# The house, at the end of the path. Its face is one distance away, so
		# every panel on it is a flat quad.
		hf = house_at - here
		$out = if hf > View.near {
			roof_l = View.project(v, { right: -3.5, forward: hf, height: 2.6 })
			roof_r = View.project(v, { right: 3.5, forward: hf, height: 2.6 })
			peak = View.project(v, { right: 0.0, forward: hf, height: 4.2 })
			List.concat($out, [
				panel(v, hf, -3.0, 0.0, 3.0, 2.6, Flat(house_c)),
				Poly({ pts: [roof_l.x, roof_l.y, peak.x, peak.y, roof_r.x, roof_r.y], fill: Flat(roof_c) }),
				# Two lit windows and a door, with the porch light over it.
				panel(v, hf, -2.3, 1.5, -1.3, 2.3, Flat(lit)),
				panel(v, hf, 1.3, 1.5, 2.3, 2.3, Flat(lit)),
				# The door stands open, with the hall light behind it: the one
				# warm thing at the end of the walk.
				panel(v, hf, -0.55, 0.0, 0.55, 1.95, Flat(door_c)),
				panel(v, hf, -0.34, 0.0, 0.34, 1.78, Flat(spill)),
			])
		} else {
			$out
		}

		# The path: a strip of lighter ground from under the feet to the door.
		$out = List.concat($out, quad(v, -0.95, 0.4, 0.0, 0.95, hf, 0.0, 0.0, 0.0, Flat(path_c)))

		# Six skeletons, three a side, each a quarter-loop behind the last.
		# Farthest first, so a nearer one paints over it.
		var $k = 2
		while $k >= 0 {
			z = 4.5 + I64.to_f64($k) * 3.6
			phase = I64.to_f64($k) * tau / 4.0
			$out = List.concat($out, guard(v, -2.1, z - here, phase))
			$out = List.concat($out, guard(v, 2.1, z - here, phase + tau / 2.0))
			$k = $k - 1
		}
		$out
	}

	# One skeleton standing at (right, forward), as big as that distance makes
	# it. Nothing is drawn for one that has been walked past.
	guard : View.View, F64, F64, F64 -> List(Shapes.Shape)
	guard = |v, right, fwd, phase|
		if fwd <= View.near {
			[]
		} else {
			feet = View.project(v, { right: right, forward: fwd, height: 0.0 })
			s = View.pixels_per_metre(v, fwd) * bone_metres / bone_pixels
			if s < 0.04 { [] } else { Skeleton.figure(phase, feet.x, feet.y, s) }
		}
}
