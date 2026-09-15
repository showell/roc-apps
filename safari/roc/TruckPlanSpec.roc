# TruckPlanSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Frame
import Grade
import Text
import TruckPlan
import World

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

segs : List(World.Segment)
segs = [World.segment_at(0), World.segment_at(1), World.segment_at(2)]

chain : List(I64)
chain = [0, 1, 2]

here : Frame.Pose
here = { along: 0.0, across: 0.0, yaw: 0.0, hw: 2.0 }

lengths_got : List(F64)
lengths_got = [(List.get(segs, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).length, (List.get(segs, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).length, (List.get(segs, I64.to_u64_wrap(2)) ?? crash("list-at out of range")).length]

lengths_want : List(F64)
lengths_want = [500.0, 320.0, 400.0]

lead_of : F64 -> TruckPlan.TruckAt
lead_of = |lead| TruckPlan.truck_at(segs, chain, here, 0.0, lead)

present_got : List(Bool)
present_got = [lead_of(100.0).present, lead_of(499.0).present, lead_of(600.0).present, lead_of(900.0).present, lead_of(2000.0).present, lead_of(0.0).present, lead_of((0.0 - 50.0)).present]

present_want : List(Bool)
present_want = [True, True, True, True, False, False, False]

landed_got : List(I64)
landed_got = [lead_of(100.0).d, lead_of(499.0).d, lead_of(600.0).d, lead_of(900.0).d]

landed_want : List(I64)
landed_want = [0, 0, 1, 2]

along_got : List(F64)
along_got = [lead_of(100.0).along, lead_of(499.0).along, lead_of(600.0).along, lead_of(900.0).along]

along_want : List(F64)
along_want = [100.0, 499.0, 100.0, 80.0]

fwd_got : List(F64)
fwd_got = [lead_of(100.0).fwd, lead_of(499.0).fwd]

fwd_want : List(F64)
fwd_want = [100.0, 499.0]

none_got : List(F64)
none_got = ({
	n = lead_of(2000.0)
	[n.along, n.fwd, I64.to_f64(n.d), TruckPlan.no_truck.along, TruckPlan.no_truck.fwd, I64.to_f64(TruckPlan.no_truck.d)]
})

none_want : List(F64)
none_want = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]

none_flag_got : List(Bool)
none_flag_got = [TruckPlan.no_truck.present, lead_of(2000.0).present]

none_flag_want : List(Bool)
none_flag_want = [False, False]

behind : TruckPlan.TruckAt
behind = TruckPlan.truck_at(segs, chain, { along: 100.0, across: 0.0, yaw: 0.0, hw: 2.0 }, 0.0, 100.0)

behind_got : List(Bool)
behind_got = [behind.present, TruckPlan.truck_at(segs, chain, { along: 99.0, across: 0.0, yaw: 0.0, hw: 2.0 }, 0.0, 100.0).present]

behind_want : List(Bool)
behind_want = [False, True]

items_got : List(I64)
items_got = [U64.to_i64_wrap(List.len(TruckPlan.truck_items(lead_of(100.0)))), U64.to_i64_wrap(List.len(TruckPlan.truck_items(lead_of(2000.0)))), U64.to_i64_wrap(List.len(TruckPlan.truck_items(TruckPlan.no_truck))), (List.get(TruckPlan.truck_items(lead_of(100.0)), I64.to_u64_wrap(0)) ?? crash("list-at out of range")).i]

items_want : List(I64)
items_want = [1, 0, 0, 0]

item_fwd_got : List(F64)
item_fwd_got = [(List.get(TruckPlan.truck_items(lead_of(499.0)), I64.to_u64_wrap(0)) ?? crash("list-at out of range")).fwd]

item_fwd_want : List(F64)
item_fwd_want = [499.0]

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Grade.grade_reals([14, 31, 73, 23, 13, 18, 29, 14, 20], lengths_got, lengths_want, 0.0)))
	line!(Text.printed(Grade.grade_bools([14, 31, 73, 31, 21, 13, 19, 18, 14], present_got, present_want)))
	line!(Text.printed(Grade.grade_ints([14, 31, 73, 23, 15, 18, 22, 13, 22], landed_got, landed_want)))
	line!(Text.printed(Grade.grade_reals([14, 31, 73, 15, 23, 16, 18, 29, 2], along_got, along_want, 0.0)))
	line!(Text.printed(Grade.grade_reals([14, 31, 73, 28, 27, 22, 2, 2, 2], fwd_got, fwd_want, 0.0001)))
	line!(Text.printed(Grade.grade_reals([14, 31, 73, 18, 16, 18, 13, 2, 2], none_got, none_want, 0.0)))
	line!(Text.printed(Grade.grade_bools([14, 31, 73, 18, 28, 23, 15, 29, 2], none_flag_got, none_flag_want)))
	line!(Text.printed(Grade.grade_bools([14, 31, 73, 32, 13, 20, 17, 18, 22], behind_got, behind_want)))
	line!(Text.printed(Grade.grade_ints([14, 31, 73, 17, 14, 13, 26, 19, 2], items_got, items_want)))
	line!(Text.printed(Grade.grade_reals([14, 31, 73, 17, 28, 27, 22, 2, 2], item_fwd_got, item_fwd_want, 0.0001)))
	Ok({})
}
