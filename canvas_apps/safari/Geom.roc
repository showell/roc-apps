# Geom -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import lib.Trig

Geom :: [].{
	RiderPt : { right : F64, forward : F64 }
	Vec3 : {
		right : F64,
		forward : F64,
		height : F64,
	}
	AX : { a : F64, x : F64 }

	## Where the camera stands on the current segment, and which way it faces.
	Pose : {
		along : F64,
		across : F64,
		yaw : F64,
		hw : F64,
	}

	## The bend from one segment into the next: the length of the segment
	## before it, the angle it turns through, which way, and the lane's width.
	Turn : {
		segment_length : F64,
		turn_angle : F64,
		turns_right : Bool,
		lane_width : F64,
	}

	## A line through two points.
	Line : { start_point : Geom.RiderPt, end_point : Geom.RiderPt }

	ground_radius : F64
	ground_radius = 100000.0

	ground_drop : F64, F64 -> F64
	ground_drop = |right, forward| (((right * right) + (forward * forward)) / (2.0 * ground_radius))

	to_rider : Geom.AX, Geom.Pose -> Geom.RiderPt
	to_rider = |{ a, x }, pose| (
		{
			d_a = (a - pose.along)
			d_x = (x - (pose.across + pose.hw))
			c = Trig.r_cos(pose.yaw)
			s = Trig.r_sin(pose.yaw)
			{ forward: ((d_a * c) + (d_x * s)), right: (((0.0 - d_a) * s) + (d_x * c)) }
		}
	)

	next_to_cur : Geom.AX, Geom.Turn -> Geom.AX
	next_to_cur = |{ a: a_b, x: x_b }, turn| (
		{
			seg_len = turn.segment_length
			width = turn.lane_width
			c = Trig.r_cos(turn.turn_angle)
			s = Trig.r_sin(turn.turn_angle)
			(
				if turn.turns_right {
					{
						a: ((((a_b * c) - (x_b * s)) + (width * s)) + seg_len),
						x: (((x_b * c) + (a_b * s)) + (width * (1.0 - c))),
					}
				} else {
					{ a: (((a_b * c) + (x_b * s)) + seg_len), x: ((x_b * c) - (a_b * s)) }
				}
			)
		}
	)

	cur_to_next : Geom.AX, Geom.Turn -> Geom.AX
	cur_to_next = |{ a, x }, turn| (
		{
			seg_len = turn.segment_length
			width = turn.lane_width
			c = Trig.r_cos(turn.turn_angle)
			s = Trig.r_sin(turn.turn_angle)
			(
				if turn.turns_right {
					(
						{
							a0 = ((a - seg_len) - (width * s))
							x0 = (x - (width * (1.0 - c)))
							{ a: ((a0 * c) + (x0 * s)), x: (((0.0 - a0) * s) + (x0 * c)) }
						}
					)
				} else {
					(
						{
							a0 = (a - seg_len)
							{ a: ((a0 * c) - (x * s)), x: ((a0 * s) + (x * c)) }
						}
					)
				}
			)
		}
	)

	line_meet : { first_line : Geom.Line, second_line : Geom.Line } -> Geom.RiderPt
	line_meet = |{ first_line, second_line }| (
		{
			a0 = first_line.start_point
			a1 = first_line.end_point
			b0 = second_line.start_point
			b1 = second_line.end_point
			dax = (a1.right - a0.right)
			daf = (a1.forward - a0.forward)
			dbx = (b1.right - b0.right)
			dbf = (b1.forward - b0.forward)
			offset_cross = (((b0.right - a0.right) * dbf) - ((b0.forward - a0.forward) * dbx))
			direction_cross = ((dax * dbf) - (daf * dbx))
			t = (offset_cross / direction_cross)
			{ right: (a0.right + (t * dax)), forward: (a0.forward + (t * daf)) }
		}
	)

	near : F64
	near = 0.4

	clip_cross : { edge_start : Geom.Vec3, edge_end : Geom.Vec3 } -> List(Geom.Vec3)
	clip_cross = |{ edge_start: a, edge_end: b }| (
		{
			f = ((near - a.forward) / (b.forward - a.forward))
			[
				{
					right: (a.right + (f * (b.right - a.right))),
					forward: near,
					height: (a.height + (f * (b.height - a.height))),
				},
			]
		}
	)

	both_sides : Bool, Bool -> Bool
	both_sides = |a_in, b_in| (
		if a_in {
			b_in
		} else {
			(
				if b_in {
					False
				} else {
					True
				}
			)
		}
	)

	# An accumulator loop is linear, where appending a recursive call is quadratic.
	clip_near_onto : List(Geom.Vec3),
	{
		corner_index : I64,
		clipped : List(Geom.Vec3),
	} -> List(Geom.Vec3)
	clip_near_onto = |poly, { corner_index: i, clipped: acc }| (
		{
			n = poly.len().to_i64_wrap()
			(
				if i >= n {
					acc
				} else {
					(
						{
							a = (
								List.get(
									poly,
									I64.to_u64_wrap(i),
								) ?? crash ("list-at out of range")
							)
							b = (
								List.get(
									poly,
									I64.to_u64_wrap(((i + 1) - (I64.div_trunc_by((i + 1), n) * n))),
								) ?? crash ("list-at out of range")
							)
							a_in = (a.forward >= near)
							b_in = (b.forward >= near)
							kept = (
								if a_in {
									[a]
								} else {
									[]
								}
							)
							crossed = (
								if both_sides(a_in, b_in) {
									[]
								} else {
									clip_cross({ edge_start: a, edge_end: b })
								}
							)
							clip_near_onto(
								poly,
								{
									corner_index: (i + 1),
									clipped: List.join([
										acc,
										kept,
										crossed,
									]),
								},
							)
						}
					)
				}
			)
		}
	)

	## The polygon cut to what lies at or past the near plane, `near` ahead.
	clip_near : List(Geom.Vec3) -> List(Geom.Vec3)
	clip_near = |poly| clip_near_onto(poly, { corner_index: 0, clipped: [] })
}
