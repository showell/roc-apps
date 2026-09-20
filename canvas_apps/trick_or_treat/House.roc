# House -- the house at the end of the path, and the door on its hinge.
#
# Hand-written. Its face is one distance away, so every panel on it is a flat
# quad; only the door leaf leaves that plane. **IT DOES NOT KNOW WHAT TIME IT
# IS**: it is handed how far open the door is, between nothing and all the way,
# and what comes out of it is somebody else's business.
import lib.Shapes
import lib.Brush
import lib.View
import Panels
import lib.Trig

House :: [].{
	house_c : Brush.Rgba
	house_c = Brush.opaque(0x14121c)
	roof_c : Brush.Rgba
	roof_c = Brush.opaque(0x0c0a12)
	lit : Brush.Rgba
	lit = Brush.opaque(0xffb642)
	door_c : Brush.Rgba
	door_c = Brush.opaque(0x2a1c14)
	spill : Brush.Rgba
	spill = Brush.opaque(0xe89a2c)
	# The hall floor, which is the same light landing on boards rather than
	# coming straight at you.
	floor_c : Brush.Rgba
	floor_c = Brush.opaque(0xb0701c)

	# How far back the lit floor goes, which is as far as anyone coming to the
	# door is ever seen from.
	hall_deep : F64
	hall_deep = 2.4

	shapes : View.View, F64, F64 -> List(Shapes.Shape)
	shapes = |v, hf, open| {
		var $out = List.with_capacity(24)
		$out = List.concat($out, Panels.panel(v, hf, 0.0 - 3.0, 0.0, 3.0, 2.6, Flat(house_c)))
		$out = List.concat($out, Panels.face(v, hf, [0.0 - 3.5, 2.6, 0.0, 4.2, 3.5, 2.6], Flat(roof_c)))
		# Two lit windows.
		$out = List.concat($out, Panels.panel(v, hf, 0.0 - 2.3, 1.5, 0.0 - 1.3, 2.3, Flat(lit)))
		$out = List.concat($out, Panels.panel(v, hf, 1.3, 1.5, 2.3, 2.3, Flat(lit)))
		# **THE HALL IS NOT THERE UNTIL THE DOOR IS OPEN.** It used to be drawn
		# under a shut door at exactly the door's own rectangle, and a canvas
		# antialiases both edges: the bright one bled through the dark one by a
		# fraction of a pixel, and as the child walked, that shared edge
		# drifted across the pixel grid and the light pulsed.
		$out = if open > 0.0 {
			List.concat(
				List.concat($out, Panels.panel(v, hf, 0.0 - 0.53, 0.0, 0.53, 1.93, Flat(spill))),
				# The floor of the hall, which is what the door sweeps over
				# and what she stands on.
				Panels.world(v, [
					{ right: 0.0 - 0.53, forward: hf, height: 0.0 },
					{ right: 0.53, forward: hf, height: 0.0 },
					{ right: 0.53, forward: hf + hall_deep, height: 0.0 },
					{ right: 0.0 - 0.53, forward: hf + hall_deep, height: 0.0 },
				], Flat(floor_c)),
			)
		} else {
			$out
		}
		List.concat($out, leaf(v, hf, open))
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
		Panels.world(v, [
			{ right: hinge_at, forward: hf, height: 1.95 },
			{ right: fx, forward: ff, height: 1.95 },
			{ right: fx, forward: ff, height: 0.0 },
			{ right: hinge_at, forward: hf, height: 0.0 },
		], Flat(door_c))
	}
}
