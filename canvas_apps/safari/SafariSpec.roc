# SafariSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Grade
import Paint
import Rider
import Safari
import Text
import Truck
import World

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

segs : List(World.Segment)
segs = seg_list(0)

# seg_list builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
seg_list : I64 -> List(World.Segment)
seg_list = |i| seg_list_acc(i, [])

seg_list_acc : I64, List(World.Segment) -> List(World.Segment)
seg_list_acc = |i, acc| (if (i >= U64.to_i64_wrap(List.len(World.route))) { acc } else { seg_list_acc((i + 1), List.append(acc, World.segment_at(i))) })

start_got : List(F64)
start_got = [Safari.ride_initial.clock, Safari.ride_initial.rider.along, Safari.ride_initial.rider.across, Safari.ride_initial.rider.v, Safari.ride_initial.truck.pos, Safari.ride_initial.truck.v]

start_want : List(F64)
start_want = [0.0, 0.0, 0.0, 0.3, 500.0, 0.3]

start_index_got : List(I64)
start_index_got = [Safari.ride_initial.rider.segment]

start_index_want : List(I64)
start_index_want = [0]

start_flag_got : List(Bool)
start_flag_got = [Safari.ride_initial.truck.braking, Rider.is_finished(Safari.ride_initial.rider, segs)]

start_flag_want : List(Bool)
start_flag_want = [False, False]

one : Safari.Ride
one = Safari.ride_next(segs, Safari.ride_initial)

two : Safari.Ride
two = Safari.ride_next(segs, one)

step_got : List(F64)
step_got = [one.clock, two.clock, (two.clock - one.clock)]

step_want : List(F64)
step_want = [1.0, 2.0, 1.0]

moved_got : List(Bool)
moved_got = [(one.rider.along > Safari.ride_initial.rider.along), (one.truck.pos > Safari.ride_initial.truck.pos), (two.rider.along > one.rider.along)]

moved_want : List(Bool)
moved_want = [True, True, True]

order_got : List(Bool)
order_got = ({
	old_dist = World.route_distance(segs, Safari.ride_initial.rider.segment, Safari.ride_initial.rider.along)
	new_dist = World.route_distance(segs, one.rider.segment, one.rider.along)
	against_new = Truck.truck_next(Safari.ride_initial.truck, new_dist, segs, World.course_length(segs))
	against_old = Truck.truck_next(Safari.ride_initial.truck, old_dist, segs, World.course_length(segs))
	[(F64.to_bits(one.truck.pos) == F64.to_bits(against_new.pos)), (new_dist > old_dist), ((F64.to_bits(against_new.pos) == F64.to_bits(against_old.pos)) == False)]
})

order_want : List(Bool)
order_want = [True, True, True]

done : Safari.Ride
done = { rider: { segment: 18, along: 400.0, across: 0.0, yaw: 0.0, v: 0.0, tilt: 0.0, heading: 0.0, gaze_yaw: 0.0, focus: 0.9 }, truck: { pos: 9000.0, v: 2.0, braking: True }, clock: 12345.0 }

restart_got : List(F64)
restart_got = ({
	r = Safari.ride_next(segs, done)
	[r.clock, r.rider.along, r.rider.v, r.truck.pos, r.rider.focus]
})

restart_want : List(F64)
restart_want = [0.0, 0.0, 0.3, 500.0, 0.0]

restart_flag_got : List(Bool)
restart_flag_got = [Rider.is_finished(done.rider, segs), Safari.ride_next(segs, done).truck.braking]

restart_flag_want : List(Bool)
restart_flag_want = [True, False]

not_done_got : List(Bool)
not_done_got = [(one.clock > 0.0), (Rider.is_finished(one.rider, segs) == False)]

not_done_want : List(Bool)
not_done_want = [True, True]

frame : List(Paint.DrawCmd)
frame = Safari.ride_frame(segs, Safari.ride_initial)

frame_got : List(Bool)
frame_got = [(U64.to_i64_wrap(List.len(frame)) > 0), (U64.to_i64_wrap(List.len(Safari.ride_frame(segs, one))) > 0), ((List.get(frame, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).tag >= 0), ((List.get(frame, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).tag <= 6)]

frame_want : List(Bool)
frame_want = [True, True, True, True]

sun_got : List(Bool)
sun_got = ({
	s = Safari.ride_sun(segs, Safari.ride_initial)
	[(s.visible == False), (s.scale >= 0.0)]
})

sun_want : List(Bool)
sun_want = [True, True]

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Grade.grade_reals([19, 28, 73, 19, 14, 15, 21, 14, 2], start_got, start_want, 0.0)))
	line!(Text.printed(Grade.grade_ints([19, 28, 73, 19, 17, 18, 22, 13, 36], start_index_got, start_index_want)))
	line!(Text.printed(Grade.grade_bools([19, 28, 73, 19, 28, 23, 15, 29, 2], start_flag_got, start_flag_want)))
	line!(Text.printed(Grade.grade_reals([19, 28, 73, 19, 14, 13, 31, 2, 2], step_got, step_want, 0.0)))
	line!(Text.printed(Grade.grade_bools([19, 28, 73, 26, 16, 33, 13, 22, 2], moved_got, moved_want)))
	line!(Text.printed(Grade.grade_bools([19, 28, 73, 16, 21, 22, 13, 21, 2], order_got, order_want)))
	line!(Text.printed(Grade.grade_reals([19, 28, 73, 21, 13, 19, 14, 21, 14], restart_got, restart_want, 0.0)))
	line!(Text.printed(Grade.grade_bools([19, 28, 73, 21, 28, 23, 15, 29, 2], restart_flag_got, restart_flag_want)))
	line!(Text.printed(Grade.grade_bools([19, 28, 73, 18, 16, 14, 22, 16, 18], not_done_got, not_done_want)))
	line!(Text.printed(Grade.grade_bools([19, 28, 73, 28, 21, 15, 26, 13, 2], frame_got, frame_want)))
	line!(Text.printed(Grade.grade_bools([19, 28, 73, 19, 25, 18, 2, 2, 2], sun_got, sun_want)))
	Ok({})
}
