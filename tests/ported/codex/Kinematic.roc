# Kinematic -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import IntOps

Kinematic :: [].{

	dot_2d : I64, I64, I64, I64 -> I64
	dot_2d = |ax, ay, bx, by| ((ax * bx) + (ay * by))

	dot_3d : I64, I64, I64, I64, I64, I64 -> I64
	dot_3d = |ax, ay, az, bx, by, bz| (((ax * bx) + (ay * by)) + (az * bz))

	cross_2d : I64, I64, I64, I64 -> I64
	cross_2d = |ax, ay, bx, by| ((ax * by) - (ay * bx))

	cross_3d_x : I64, I64, I64, I64, I64, I64 -> I64
	cross_3d_x = |_ax, ay, az, _bx, by, bz| ((ay * bz) - (az * by))

	cross_3d_y : I64, I64, I64, I64, I64, I64 -> I64
	cross_3d_y = |ax, _ay, az, bx, _by, bz| ((az * bx) - (ax * bz))

	cross_3d_z : I64, I64, I64, I64, I64, I64 -> I64
	cross_3d_z = |ax, ay, _az, bx, by, _bz| ((ax * by) - (ay * bx))

	distance_sq_2d : I64, I64, I64, I64 -> I64
	distance_sq_2d = |x1, y1, x2, y2| ({
		dx : I64
		dx = (x2 - x1)
		dy : I64
		dy = (y2 - y1)
		((dx * dx) + (dy * dy))
	})

	distance_sq_3d : I64, I64, I64, I64, I64, I64 -> I64
	distance_sq_3d = |x1, y1, z1, x2, y2, z2| ({
		dx : I64
		dx = (x2 - x1)
		dy : I64
		dy = (y2 - y1)
		dz : I64
		dz = (z2 - z1)
		(((dx * dx) + (dy * dy)) + (dz * dz))
	})

	manhattan_2d : I64, I64, I64, I64 -> I64
	manhattan_2d = |x1, y1, x2, y2| (IntOps.int_abs((x2 - x1)) + IntOps.int_abs((y2 - y1)))

	manhattan_3d : I64, I64, I64, I64, I64, I64 -> I64
	manhattan_3d = |x1, y1, z1, x2, y2, z2| ((IntOps.int_abs((x2 - x1)) + IntOps.int_abs((y2 - y1))) + IntOps.int_abs((z2 - z1)))

	midpoint_x : I64, I64 -> I64
	midpoint_x = |x1, x2| I64.shr_zf_wrap((x1 + x2), I64.to_u8_wrap(1))

	midpoint_y : I64, I64 -> I64
	midpoint_y = |y1, y2| I64.shr_zf_wrap((y1 + y2), I64.to_u8_wrap(1))
}
