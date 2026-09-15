# CritterPlanSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CritterPlan
import Frame
import Grade
import Text
import World

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

reach_got : List(I64)
reach_got = [CritterPlan.farm_seg_reach, CritterPlan.safari_seg_reach]

reach_want : List(I64)
reach_want = [3, 5]

segs : List(World.Segment)
segs = [World.segment_at(0), World.segment_at(1), World.segment_at(2), World.segment_at(3), World.segment_at(4), World.segment_at(5)]

chain : List(I64)
chain = [0, 1, 2, 3, 4, 5]

origin : Frame.Pose
origin = { along: 0.0, across: 0.0, yaw: 0.0, hw: 2.0 }

farm_at : I64 -> I64
farm_at = |d| U64.to_i64_wrap(List.len(CritterPlan.seg_farm(segs, chain, origin, d, 2.0)))

safari_at : I64 -> I64
safari_at = |d| U64.to_i64_wrap(List.len(CritterPlan.seg_safari(segs, chain, origin, d, 2.0)))

cutoff_got : List(Bool)
cutoff_got = [(farm_at(0) > 0), (farm_at(2) > 0), (farm_at(3) == 0), (farm_at(4) == 0), (farm_at(5) == 0), (safari_at(3) > 0), (safari_at(4) > 0), (safari_at(5) == 0)]

cutoff_want : List(Bool)
cutoff_want = [True, True, True, True, True, True, True, True]

term_got : List(I64)
term_got = [U64.to_i64_wrap(List.len(CritterPlan.seg_safari([World.segment_at(18)], [0], origin, 0, 2.0)))]

term_want : List(I64)
term_want = [0]

term_flag_got : List(Bool)
term_flag_got = [(U64.to_i64_wrap(List.len(CritterPlan.seg_safari([World.segment_at(0)], [0], origin, 0, 2.0))) > 0)]

term_flag_want : List(Bool)
term_flag_want = [True]

duck_count : I64 -> I64
duck_count = |i| U64.to_i64_wrap(List.len(CritterPlan.seg_ducks([World.segment_at(i)], [0], origin, 0)))

duck_got : List(Bool)
duck_got = [(duck_count(12) > 0), (duck_count(0) == 0), (duck_count(4) == 0), (duck_count(18) == 0)]

duck_want : List(Bool)
duck_want = [True, True, True, True]

duck_reach_got : List(I64)
duck_reach_got = [U64.to_i64_wrap(List.len(CritterPlan.seg_ducks(segs, chain, origin, 5))), U64.to_i64_wrap(List.len(CritterPlan.seg_ducks([World.segment_at(12)], [0], origin, 0)))]

duck_reach_want : List(I64)
duck_reach_want = [0, 6]

order_got : List(I64)
order_got = ({
	d0 = U64.to_i64_wrap(List.len(CritterPlan.seg_billboards(segs, chain, origin, 0)))
	f0 = farm_at(0)
	s0 = safari_at(0)
	k0 = U64.to_i64_wrap(List.len(CritterPlan.seg_ducks(segs, chain, origin, 0)))
	[(d0 - ((f0 + s0) + k0))]
})

order_want : List(I64)
order_want = [0]

one_seg : List(World.Segment)
one_seg = [World.segment_at(0)]

walk_got : List(I64)
walk_got = [U64.to_i64_wrap(List.len(CritterPlan.walk_billboards(segs, [], origin, 0))), (U64.to_i64_wrap(List.len(CritterPlan.walk_billboards(one_seg, [0], origin, 0))) - U64.to_i64_wrap(List.len(CritterPlan.seg_billboards(one_seg, [0], origin, 0)))), U64.to_i64_wrap(List.len(CritterPlan.walk_billboards(segs, chain, origin, 6)))]

walk_want : List(I64)
walk_want = [0, 0, 0]

grow_got : List(Bool)
grow_got = ({
	a = U64.to_i64_wrap(List.len(CritterPlan.walk_billboards(segs, chain, origin, 0)))
	b = U64.to_i64_wrap(List.len(CritterPlan.walk_billboards(segs, chain, origin, 1)))
	c = U64.to_i64_wrap(List.len(CritterPlan.walk_billboards(segs, chain, origin, 2)))
	[(a >= b), (b >= c)]
})

grow_want : List(Bool)
grow_want = [True, True]

behind_got : List(Bool)
behind_got = [(U64.to_i64_wrap(List.len(CritterPlan.behind_billboards(segs, chain, origin, 0))) >= 0), (U64.to_i64_wrap(List.len(CritterPlan.behind_ducks(segs, chain, origin, World.segment_at(12)))) > 0), (U64.to_i64_wrap(List.len(CritterPlan.behind_ducks(segs, chain, origin, World.segment_at(0)))) == 0)]

behind_want : List(Bool)
behind_want = [True, True, True]

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Grade.grade_ints([24, 18, 73, 21, 13, 15, 24, 20, 2], reach_got, reach_want)))
	line!(Text.printed(Grade.grade_bools([24, 18, 73, 24, 25, 14, 16, 28, 28], cutoff_got, cutoff_want)))
	line!(Text.printed(Grade.grade_ints([24, 18, 73, 14, 13, 21, 26, 2, 2], term_got, term_want)))
	line!(Text.printed(Grade.grade_bools([24, 18, 73, 14, 28, 23, 15, 29, 2], term_flag_got, term_flag_want)))
	line!(Text.printed(Grade.grade_bools([24, 18, 73, 22, 25, 24, 34, 2, 2], duck_got, duck_want)))
	line!(Text.printed(Grade.grade_ints([24, 18, 73, 22, 21, 13, 15, 24, 20], duck_reach_got, duck_reach_want)))
	line!(Text.printed(Grade.grade_ints([24, 18, 73, 16, 21, 22, 13, 21, 2], order_got, order_want)))
	line!(Text.printed(Grade.grade_ints([24, 18, 73, 27, 15, 23, 34, 2, 2], walk_got, walk_want)))
	line!(Text.printed(Grade.grade_bools([24, 18, 73, 29, 21, 16, 27, 2, 2], grow_got, grow_want)))
	line!(Text.printed(Grade.grade_bools([24, 18, 73, 32, 13, 20, 17, 18, 22], behind_got, behind_want)))
	Ok({})
}
