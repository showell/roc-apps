# Geom -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Trig

Geom :: [].{
	RiderPt : { right : F64, forward : F64 }
	Vec3 : { right : F64, forward : F64, height : F64 }
	AX : { a : F64, x : F64 }

	ground_radius : F64
	ground_radius = 100000.0

	ground_drop : F64, F64 -> F64
	ground_drop = |right, forward| (((right * right) + (forward * forward)) / (2.0 * ground_radius))

	to_rider : F64, F64, F64, F64, F64, F64 -> Geom.RiderPt
	to_rider = |a, x, cam_along, cam_across, yaw, hw| ({
		d_a = (a - cam_along)
		d_x = (x - (cam_across + hw))
		c = Trig.r_cos(yaw)
		s = Trig.r_sin(yaw)
		{ forward: ((d_a * c) + (d_x * s)), right: (((0.0 - d_a) * s) + (d_x * c)) }
	})

	next_to_cur : F64, F64, F64, F64, Bool, F64 -> Geom.AX
	next_to_cur = |a_b, x_b, seg_len, theta, turns_right, width| ({
		c = Trig.r_cos(theta)
		s = Trig.r_sin(theta)
		(if turns_right { { a: ((((a_b * c) - (x_b * s)) + (width * s)) + seg_len), x: (((x_b * c) + (a_b * s)) + (width * (1.0 - c))) } } else { { a: (((a_b * c) + (x_b * s)) + seg_len), x: ((x_b * c) - (a_b * s)) } })
	})

	cur_to_next : F64, F64, F64, F64, Bool, F64 -> Geom.AX
	cur_to_next = |a, x, seg_len, theta, turns_right, width| ({
		c = Trig.r_cos(theta)
		s = Trig.r_sin(theta)
		(if turns_right { ({
			a0 = ((a - seg_len) - (width * s))
			x0 = (x - (width * (1.0 - c)))
			{ a: ((a0 * c) + (x0 * s)), x: (((0.0 - a0) * s) + (x0 * c)) }
		}) } else { ({
			a0 = (a - seg_len)
			{ a: ((a0 * c) - (x * s)), x: ((a0 * s) + (x * c)) }
		}) })
	})

	line_meet : Geom.RiderPt, Geom.RiderPt, Geom.RiderPt, Geom.RiderPt -> Geom.RiderPt
	line_meet = |a0, a1, b0, b1| ({
		dax = (a1.right - a0.right)
		daf = (a1.forward - a0.forward)
		dbx = (b1.right - b0.right)
		dbf = (b1.forward - b0.forward)
		t = ((((b0.right - a0.right) * dbf) - ((b0.forward - a0.forward) * dbx)) / ((dax * dbf) - (daf * dbx)))
		{ right: (a0.right + (t * dax)), forward: (a0.forward + (t * daf)) }
	})

	near : F64
	near = 0.4

	clip_cross : Geom.Vec3, Geom.Vec3, F64 -> List(Geom.Vec3)
	clip_cross = |a, b, near_| ({
		f = ((near_ - a.forward) / (b.forward - a.forward))
		[{ right: (a.right + (f * (b.right - a.right))), forward: near_, height: (a.height + (f * (b.height - a.height))) }]
	})

	both_sides : Bool, Bool -> Bool
	both_sides = |a_in, b_in| (if a_in { b_in } else { (if b_in { False } else { True }) })

	clip_near_edge : List(Geom.Vec3), F64, I64 -> List(Geom.Vec3)
	clip_near_edge = |poly, near_, i| ({
		n = U64.to_i64_wrap(List.len(poly))
		(if (i >= n) { [] } else { ({
			a = (List.get(poly, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
			b = (List.get(poly, I64.to_u64_wrap(((i + 1) - (I64.div_trunc_by((i + 1), n) * n)))) ?? crash("list-at out of range"))
			a_in = (a.forward >= near_)
			b_in = (b.forward >= near_)
			kept = (if a_in { [a] } else { [] })
			crossed = (if both_sides(a_in, b_in) { [] } else { clip_cross(a, b, near_) })
			List.concat(List.concat(kept, crossed), clip_near_edge(poly, near_, (i + 1)))
		}) })
	})

	clip_near : List(Geom.Vec3), F64 -> List(Geom.Vec3)
	clip_near = |poly, near_| clip_near_edge(poly, near_, 0)
}
