# GroundPlanSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Frame
import Geom
import Grade
import GroundPlan
import Paint
import World

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

fixed_got : List(F64)
fixed_got = [GroundPlan.road_chunk, GroundPlan.entry_road_dist]

fixed_want : List(F64)
fixed_want = [25.0, 40.0]

colour_got : List(I64)
colour_got = [GroundPlan.road_color]

colour_want : List(I64)
colour_want = [3421500]

chunks_got : List(I64)
chunks_got = [GroundPlan.chunks_for(25.0), GroundPlan.chunks_for(25.1), GroundPlan.chunks_for(50.0), GroundPlan.chunks_for(49.9), GroundPlan.chunks_for(1.0), GroundPlan.chunks_for(0.0), GroundPlan.chunks_for(500.0), GroundPlan.chunks_for(320.0), GroundPlan.chunks_for(1200.0)]

chunks_want : List(I64)
chunks_want = [1, 2, 2, 2, 1, 1, 20, 13, 48]

segs : List(World.Segment)
segs = [World.segment_at(0), World.segment_at(1), World.segment_at(2)]

chain : List(I64)
chain = [0, 1, 2]

origin : Frame.Pose
origin = { along: 0.0, across: 0.0, yaw: 0.0, hw: 2.0 }

quad : List(Geom.RiderPt)
quad = GroundPlan.slice_quad(segs, chain, origin, 0, 0, 20, 500.0, 4.0)

quad_shape_got : List(I64)
quad_shape_got = [U64.to_i64_wrap(List.len(quad)), U64.to_i64_wrap(List.len(GroundPlan.slice_quad(segs, chain, origin, 0, 19, 20, 500.0, 4.0)))]

quad_shape_want : List(I64)
quad_shape_want = [4, 4]

across_got : List(F64)
across_got = [(List.get(quad, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).right, (List.get(quad, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).right, (List.get(quad, I64.to_u64_wrap(2)) ?? crash("list-at out of range")).right, (List.get(quad, I64.to_u64_wrap(3)) ?? crash("list-at out of range")).right]

across_want : List(F64)
across_want = [(-2.0), 2.0, 2.0, (-2.0)]

along_got : List(F64)
along_got = ({
	last = GroundPlan.slice_quad(segs, chain, origin, 0, 19, 20, 500.0, 4.0)
	[(List.get(quad, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).forward, (List.get(quad, I64.to_u64_wrap(3)) ?? crash("list-at out of range")).forward, (List.get(last, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).forward, (List.get(last, I64.to_u64_wrap(3)) ?? crash("list-at out of range")).forward]
})

along_want : List(F64)
along_want = [0.0, 25.0, 475.0, 500.0]

seam_got : List(F64)
seam_got = ({
	a = GroundPlan.slice_quad(segs, chain, origin, 0, 3, 20, 500.0, 4.0)
	b = GroundPlan.slice_quad(segs, chain, origin, 0, 4, 20, 500.0, 4.0)
	[((List.get(a, I64.to_u64_wrap(3)) ?? crash("list-at out of range")).forward - (List.get(b, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).forward), ((List.get(a, I64.to_u64_wrap(2)) ?? crash("list-at out of range")).forward - (List.get(b, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).forward), ((List.get(a, I64.to_u64_wrap(3)) ?? crash("list-at out of range")).right - (List.get(b, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).right)]
})

seam_want : List(F64)
seam_want = [0.0, 0.0, 0.0]

strip : List(Paint.DrawCmd)
strip = GroundPlan.seg_road(segs, chain, origin, 0, 500.0, 960.0)

strip_got : List(Bool)
strip_got = [(U64.to_i64_wrap(List.len(strip)) > 0), (U64.to_i64_wrap(List.len(strip)) <= GroundPlan.chunks_for(500.0)), (U64.to_i64_wrap(List.len(GroundPlan.seg_road(segs, chain, { along: 5000.0, across: 0.0, yaw: 0.0, hw: 2.0 }, 0, 500.0, 960.0))) == 0)]

strip_want : List(Bool)
strip_want = [True, True, True]

cmd_got : List(I64)
cmd_got = ({
	c = (List.get(strip, I64.to_u64_wrap((U64.to_i64_wrap(List.len(strip)) - 1))) ?? crash("list-at out of range"))
	[c.tag, c.color, c.color2, U64.to_i64_wrap(List.len(c.geom))]
})

cmd_want : List(I64)
cmd_want = [0, 3421500, 0, 0]

points_got : List(Bool)
points_got = ({
	c = (List.get(strip, I64.to_u64_wrap((U64.to_i64_wrap(List.len(strip)) - 1))) ?? crash("list-at out of range"))
	[(U64.to_i64_wrap(List.len(c.pts)) >= 6), (U64.to_i64_wrap(List.len(c.pts)) <= 10)]
})

points_want : List(Bool)
points_want = [True, True]

# --- Entry ---

main! = |_args| {
	line!(Grade.grade_reals("gp-fixed ", fixed_got, fixed_want, 0.0))
	line!(Grade.grade_ints("gp-colour", colour_got, colour_want))
	line!(Grade.grade_ints("gp-chunks", chunks_got, chunks_want))
	line!(Grade.grade_ints("gp-shape ", quad_shape_got, quad_shape_want))
	line!(Grade.grade_reals("gp-across", across_got, across_want, 0.0001))
	line!(Grade.grade_reals("gp-along ", along_got, along_want, 0.0001))
	line!(Grade.grade_reals("gp-seam  ", seam_got, seam_want, 0.0))
	line!(Grade.grade_bools("gp-strip ", strip_got, strip_want))
	line!(Grade.grade_ints("gp-cmd   ", cmd_got, cmd_want))
	line!(Grade.grade_bools("gp-points", points_got, points_want))
	Ok({})
}
