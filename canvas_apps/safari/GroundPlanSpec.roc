## These are GroundPlan's checks: how the road along a segment is cut into
## chunks, where a chunk's corners are, and what the road draws.
app [main!] {
	lib: "../lib/main.roc",
}

import Angle
import Frame
import Geom
import Grade
import GroundPlan
import Paint
import World

fixed_got : List(F64)
fixed_got = [GroundPlan.road_chunk_length, GroundPlan.approach_length]

fixed_want : List(F64)
fixed_want = [25.0, 40.0]

colour_got : List(I64)
colour_got = [GroundPlan.road_color]

colour_want : List(I64)
colour_want = [3421500]

chunks_got : List(I64)
chunks_got = [25.0, 25.1, 50.0, 49.9, 1.0, 0.0, 500.0, 320.0, 1200.0].map(
	|length| GroundPlan.chunks_along(length).to_i64(),
)

chunks_want : List(I64)
chunks_want = [1, 2, 2, 2, 1, 1, 20, 13, 48]

# The first three segments, the rider at the start of the first, and a
# camera only the drawing checks read.
view : GroundPlan.View
view = {
	road: {
		world: [
			World.route_segment(0),
			World.route_segment(1),
			World.route_segment(2),
		],
		chain: [0, 1, 2].map(World.SegmentIndex.number),
		pose: {
			along: 0.0,
			across: 0.0,
			yaw: Angle.straight_ahead,
			half_width: 2.0,
		},
	},
	cam_focal: 500.0,
	view_w: 960.0,
}

## Chunk `chunk_number` of the first segment's 20, which is 500 m long.
chunk_of_first : U32 -> List(Geom.RiderPoint)
chunk_of_first = |chunk_number| GroundPlan.chunk_corners(
	view,
	{
		position: Frame.ChainPosition.first,
		segment_length: 500.0,
		chunk_count: 20,
		chunk_number,
	},
)

corner : List(Geom.RiderPoint), U64 -> Geom.RiderPoint
corner = |corners, i| corners.get(i) ?? crash "GroundPlanSpec: a chunk has four corners"

first_chunk : List(Geom.RiderPoint)
first_chunk = chunk_of_first(0)

last_chunk : List(Geom.RiderPoint)
last_chunk = chunk_of_first(19)

quad_shape_got : List(I64)
quad_shape_got = [first_chunk.len().to_i64_wrap(), last_chunk.len().to_i64_wrap()]

quad_shape_want : List(I64)
quad_shape_want = [4, 4]

across_got : List(F64)
across_got = first_chunk.map(|point| point.right)

across_want : List(F64)
across_want = [
	(-2.0),
	2.0,
	2.0,
	(-2.0),
]

along_got : List(F64)
along_got = [
	corner(first_chunk, 0).forward,
	corner(first_chunk, 3).forward,
	corner(last_chunk, 0).forward,
	corner(last_chunk, 3).forward,
]

along_want : List(F64)
along_want = [0.0, 25.0, 475.0, 500.0]

seam_got : List(F64)
seam_got = {
	before = chunk_of_first(3)
	after = chunk_of_first(4)
	[
		(corner(before, 3).forward - corner(after, 0).forward),
		(corner(before, 2).forward - corner(after, 1).forward),
		(corner(before, 3).right - corner(after, 0).right),
	]
}

seam_want : List(F64)
seam_want = [0.0, 0.0, 0.0]

strip : List(Paint.DrawCmd)
strip = GroundPlan.segment_road(view, Frame.ChainPosition.first)

far_ahead : Frame.Pose
far_ahead = {
	along: 5000.0,
	across: 0.0,
	yaw: Angle.straight_ahead,
	half_width: 2.0,
}

strip_got : List(Bool)
strip_got = [
	(strip.len() > 0),
	(strip.len().to_u32_wrap() <= GroundPlan.chunks_along(500.0)),
	(
		GroundPlan.segment_road(
			{ ..view, road: { ..view.road, pose: far_ahead } },
			Frame.ChainPosition.first,
		).len() == 0
	),
]

strip_want : List(Bool)
strip_want = [True, True, True]

last_cmd : Paint.DrawCmd
last_cmd = strip.last() ?? crash "GroundPlanSpec: the road draws"

cmd_got : List(I64)
cmd_got = [
	last_cmd.tag,
	last_cmd.color,
	last_cmd.color2,
	last_cmd.geom.len().to_i64_wrap(),
]

cmd_want : List(I64)
cmd_want = [0, 3421500, 0, 0]

points_got : List(Bool)
points_got = [(last_cmd.pts.len() >= 6), (last_cmd.pts.len() <= 10)]

points_want : List(Bool)
points_want = [True, True]

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "gp-fixed ",
			got: fixed_got,
			want: fixed_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "gp-colour",
			got: colour_got,
			want: colour_want,
		}),
		Grade.ints({
			name: "gp-chunks",
			got: chunks_got,
			want: chunks_want,
		}),
		Grade.ints({
			name: "gp-shape ",
			got: quad_shape_got,
			want: quad_shape_want,
		}),
		Grade.reals({
			name: "gp-across",
			got: across_got,
			want: across_want,
			tol: 0.0001,
		}),
		Grade.reals({
			name: "gp-along ",
			got: along_got,
			want: along_want,
			tol: 0.0001,
		}),
		Grade.reals({
			name: "gp-seam  ",
			got: seam_got,
			want: seam_want,
			tol: 0.0,
		}),
		Grade.bools({
			name: "gp-strip ",
			got: strip_got,
			want: strip_want,
		}),
		Grade.ints({
			name: "gp-cmd   ",
			got: cmd_got,
			want: cmd_want,
		}),
		Grade.bools({
			name: "gp-points",
			got: points_got,
			want: points_want,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
