# Fence -- what the yard is enclosed by.
#
# Hand-written. **THE YARD IS FENCED, NOT JUST FRONTED.** Across the kerb it is
# behind the eye for the whole walk up and waiting when the child turns round;
# up each side it is there from the first frame, at the edges of the frame,
# which is what says the path goes somewhere enclosed. Pointed pickets on two
# rails, with two posts and a gap where the path comes through.
#
# A side picket stands in the plane of its own side, so its corners are at two
# distances rather than one; a front one is flat.
import Shapes
import Brush
import View
import Panels

Fence :: [].{
	fence_c : Brush.Rgba
	fence_c = Brush.opaque(0x272430)

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

	shapes : View.View, F64 -> List(Shapes.Shape)
	shapes = |v, now| {
		fwd = fence_at - now
		var $out = List.with_capacity(160)
		# The two gate posts, taller and square-topped.
		$out = List.concat($out, Panels.face(v, fwd, [gate_half, 0.0, gate_half + 0.18, 0.0, gate_half + 0.18, 2.35, gate_half, 2.35], Flat(fence_c)))
		$out = List.concat($out, Panels.face(v, fwd, [0.0 - gate_half - 0.18, 0.0, 0.0 - gate_half, 0.0, 0.0 - gate_half, 2.35, 0.0 - gate_half - 0.18, 2.35], Flat(fence_c)))
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
		Panels.face(v, fwd, [x, 0.0, x + picket_wide, 0.0, x + picket_wide, fence_high - 0.16, x + picket_wide / 2.0, fence_high, x, fence_high - 0.16], Flat(fence_c))

	front_rail : View.View, F64, F64 -> List(Shapes.Shape)
	front_rail = |v, fwd, y|
		List.concat(
			Panels.face(v, fwd, [gate_half, y, yard_half, y, yard_half, y + 0.1, gate_half, y + 0.1], Flat(fence_c)),
			Panels.face(v, fwd, [0.0 - yard_half, y, 0.0 - gate_half, y, 0.0 - gate_half, y + 0.1, 0.0 - yard_half, y + 0.1], Flat(fence_c)),
		)

	side_picket : View.View, F64, F64 -> List(Shapes.Shape)
	side_picket = |v, x, f|
		Panels.world(v, [
			{ right: x, forward: f, height: 0.0 },
			{ right: x, forward: f + picket_wide, height: 0.0 },
			{ right: x, forward: f + picket_wide, height: fence_high - 0.16 },
			{ right: x, forward: f + picket_wide / 2.0, height: fence_high },
			{ right: x, forward: f, height: fence_high - 0.16 },
		], Flat(fence_c))

	side_rail : View.View, F64, F64, F64 -> List(Shapes.Shape)
	side_rail = |v, now, x, y|
		Panels.world(v, [
			{ right: x, forward: fence_at - now, height: y },
			{ right: x, forward: yard_deep - now, height: y },
			{ right: x, forward: yard_deep - now, height: y + 0.1 },
			{ right: x, forward: fence_at - now, height: y + 0.1 },
		], Flat(fence_c))
}
