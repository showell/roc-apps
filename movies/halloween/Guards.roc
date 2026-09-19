# Guards -- the skeletons flanking the walkway.
#
# Hand-written: where they stand, how fast they dance, and which way they are
# facing. The figure itself is Skeleton.roc, which knows nothing about a
# walkway -- this is the Plan to its Draw.
#
# **A FLAT FIGURE SAYS IT IS TURNED BY BEING NARROWER.** Shapes.squash_x pulls
# every x toward the figure's own middle by the cosine of the angle it is
# turned through, and a negative factor mirrors it as well, so the two files
# flanking the path face each other rather than both facing right.
import Shapes
import View
import Skeleton
import Trig

Guards :: [].{
	# A skeleton is this tall, and Skeleton's own figure is this many pixels
	# tall at size one.
	bone_metres : F64
	bone_metres = 1.35
	bone_pixels : F64
	bone_pixels = 238.0

	# A skeleton's jig takes a second and a half here. Skeleton's own dance is
	# a second, which is jauntier than this wants.
	dance_frames : F64
	dance_frames = 90.0

	# Where they stand: far enough apart to be passed one pair at a time, and
	# the last pair still short of the door, so they flank it.
	flank : F64
	flank = 1.5
	first_at : F64
	first_at = 3.4
	spacing : F64
	spacing = 3.5
	files : I64
	files = 3

	# How far behind the child's own movements they are.
	lag_frames : I64
	lag_frames = 30

	tau : F64
	tau = 6.283185307179586

	# All six, farthest first, so a nearer one paints over it. `now` is where
	# the child is and `lag` is where they were; `tilt` is how far off facing
	# the child each one stands, which goes to nothing while the child is
	# stopped.
	shapes : View.View, I64, F64, F64, F64 -> List(Shapes.Shape)
	shapes = |v, tick, now, lag, tilt| {
		beat = I64.to_f64(tick) / dance_frames * tau
		var $out = List.with_capacity(120)
		var $k = files - 1
		while $k >= 0 {
			z = first_at + I64.to_f64($k) * spacing
			phase = I64.to_f64($k) * tau / 4.0
			$out = List.concat($out, one(v, 0.0 - flank, z, now, lag, beat + phase, tilt, 1.0))
			$out = List.concat($out, one(v, flank, z, now, lag, beat + phase + tau / 2.0, tilt, 0.0 - 1.0))
			$k = $k - 1
		}
		$out
	}

	# One skeleton standing at (right, forward) in the world, as big as that
	# distance makes it and as wide as the way it is facing leaves it. Nothing
	# is drawn for one that has been walked past.
	one : View.View, F64, F64, F64, F64, F64, F64, F64 -> List(Shapes.Shape)
	one = |v, sx, sz, now, lag, t, tilt, side| {
		spot = { right: sx, forward: sz - now, height: 0.0 }
		if View.ahead(v, spot) {
			c = View.turn(v, spot)
			feet = View.flat(v, c)
			s = View.pixels_per_metre(v, c.forward) * bone_metres / bone_pixels
			# Too small to read, or entirely off one side of the frame.
			if s < 0.04 or feet.x + 120.0 * s < 0.0 or feet.x - 120.0 * s > v.width {
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
}
