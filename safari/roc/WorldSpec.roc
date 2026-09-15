# WorldSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Grade
import Text
import Trig
import World

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

route_shape_got : List(I64)
route_shape_got = [U64.to_i64_wrap(List.len(World.route)), World.pig_count_to(0, 0), World.pig_count_to(3, 0), World.pig_count_to(11, 0), World.pig_count_to(12, 0), World.pig_count_to(19, 0)]

route_shape_want : List(I64)
route_shape_want = [19, 0, 1, 2, 3, 9]

headings_got : List(F64)
headings_got = [(World.heading_at(0) / Trig.deg), (World.heading_at(1) / Trig.deg), (World.heading_at(2) / Trig.deg), (World.heading_at(3) / Trig.deg), (World.heading_at(4) / Trig.deg), (World.heading_at(5) / Trig.deg), (World.heading_at(6) / Trig.deg), (World.heading_at(7) / Trig.deg), (World.heading_at(8) / Trig.deg), (World.heading_at(9) / Trig.deg), (World.heading_at(10) / Trig.deg), (World.heading_at(11) / Trig.deg), (World.heading_at(12) / Trig.deg), (World.heading_at(13) / Trig.deg), (World.heading_at(14) / Trig.deg), (World.heading_at(15) / Trig.deg), (World.heading_at(16) / Trig.deg), (World.heading_at(17) / Trig.deg), (World.heading_at(18) / Trig.deg)]

headings_want : List(F64)
headings_want = [0.0, 50.0, (-20.0), 0.0, 20.0, (-50.0), (-120.0), (-40.0), (-25.0), (-95.0), (-80.0), (-65.0), (-50.0), (-35.0), (-85.0), (-35.0), (-85.0), (-35.0), (-85.0)]

steps_got : List(F64)
steps_got = [(World.heading_step(0) / Trig.deg), (World.heading_step(1) / Trig.deg), (World.heading_step(6) / Trig.deg), (World.heading_step(18) / Trig.deg)]

steps_want : List(F64)
steps_want = [50.0, (-70.0), 80.0, 0.0]

seg : I64 -> World.Segment
seg = |i| World.segment_at(i)

length_got : List(F64)
length_got = [seg(0).length, seg(1).length, seg(6).length, seg(9).length, seg(18).length, seg(0).width, seg(18).width]

length_want : List(F64)
length_want = [500.0, 320.0, 1200.0, 800.0, 300.0, 4.0, 4.0]

exit_got : List(I64)
exit_got = [seg(0).exit_to, seg(1).exit_to, seg(17).exit_to, seg(18).exit_to]

exit_want : List(I64)
exit_want = [1, 2, 18, 18]

flags_got : List(Bool)
flags_got = [seg(0).terminates, seg(18).terminates, seg(0).exit_right, seg(1).exit_right, seg(6).exit_right, seg(18).exit_right, seg(0).has_mid_tower, seg(6).has_mid_tower, seg(9).has_mid_tower, seg(0).has_cat, seg(1).has_cat, seg(12).has_cat, seg(18).has_cat]

flags_want : List(Bool)
flags_want = [False, True, True, False, True, True, False, True, False, False, True, True, True]

angle_got : List(F64)
angle_got = [(seg(0).exit_angle / Trig.deg), (seg(1).exit_angle / Trig.deg), (seg(6).exit_angle / Trig.deg), (seg(18).exit_angle / Trig.deg), seg(18).commit_along]

angle_want : List(F64)
angle_want = [50.0, 70.0, 80.0, 0.0, 300.0]

commit_got : List(F64)
commit_got = [seg(0).commit_along, seg(1).commit_along, seg(6).commit_along]

commit_want : List(F64)
commit_want = [498.32180073764545, 319.2720595314676, 1199.647346038583]

pigs_got : List(I64)
pigs_got = [U64.to_i64_wrap(List.len(seg(0).pigs)), U64.to_i64_wrap(List.len(seg(2).pigs)), U64.to_i64_wrap(List.len(seg(10).pigs)), U64.to_i64_wrap(List.len(seg(11).pigs)), U64.to_i64_wrap(List.len(seg(13).pigs)), U64.to_i64_wrap(List.len(seg(18).pigs))]

pigs_want : List(I64)
pigs_want = [0, 49, 49, 10, 10, 10]

distract_got : List(Bool)
distract_got = [seg(0).pigs_distract, seg(2).pigs_distract, seg(10).pigs_distract, seg(11).pigs_distract, seg(18).pigs_distract]

distract_want : List(Bool)
distract_want = [False, True, True, False, False]

cows_got : List(I64)
cows_got = [U64.to_i64_wrap(List.len(seg(0).cows)), U64.to_i64_wrap(List.len(seg(3).cows)), U64.to_i64_wrap(List.len(seg(4).cows)), U64.to_i64_wrap(List.len(seg(18).cows))]

cows_want : List(I64)
cows_want = [14, 14, 15, 15]

trees_got : List(I64)
trees_got = [U64.to_i64_wrap(List.len(seg(0).trees)), U64.to_i64_wrap(List.len(seg(1).trees)), U64.to_i64_wrap(List.len(seg(6).trees)), U64.to_i64_wrap(List.len(seg(18).trees))]

trees_want : List(I64)
trees_want = [28, 16, 74, 14]

cat_got : List(F64)
cat_got = [seg(0).cat.mid_across, seg(18).cat.mid_across, seg(0).cat.height, seg(18).cat.height]

cat_want : List(F64)
cat_want = [0.816, 0.816, 1.7, 1.7]

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Grade.grade_ints([27, 16, 73, 19, 20, 15, 31, 13, 2], route_shape_got, route_shape_want)))
	line!(Text.printed(Grade.grade_reals([27, 16, 73, 20, 13, 15, 22, 2, 2], headings_got, headings_want, F64.from_bits(4427486594234968593))))
	line!(Text.printed(Grade.grade_reals([27, 16, 73, 19, 14, 13, 31, 2, 2], steps_got, steps_want, F64.from_bits(4427486594234968593))))
	line!(Text.printed(Grade.grade_reals([27, 16, 73, 23, 13, 18, 29, 14, 20], length_got, length_want, 0.0)))
	line!(Text.printed(Grade.grade_ints([27, 16, 73, 13, 36, 17, 14, 2, 2], exit_got, exit_want)))
	line!(Text.printed(Grade.grade_bools([27, 16, 73, 28, 23, 15, 29, 19, 2], flags_got, flags_want)))
	line!(Text.printed(Grade.grade_reals([27, 16, 73, 15, 18, 29, 23, 13, 2], angle_got, angle_want, F64.from_bits(4427486594234968593))))
	line!(Text.printed(Grade.grade_reals([27, 16, 73, 24, 16, 26, 26, 17, 14], commit_got, commit_want, F64.from_bits(4487126258331716666))))
	line!(Text.printed(Grade.grade_ints([27, 16, 73, 31, 17, 29, 19, 2, 2], pigs_got, pigs_want)))
	line!(Text.printed(Grade.grade_bools([27, 16, 73, 22, 17, 19, 14, 21, 2], distract_got, distract_want)))
	line!(Text.printed(Grade.grade_ints([27, 16, 73, 24, 16, 27, 19, 2, 2], cows_got, cows_want)))
	line!(Text.printed(Grade.grade_ints([27, 16, 73, 14, 21, 13, 13, 19, 2], trees_got, trees_want)))
	line!(Text.printed(Grade.grade_reals([27, 16, 73, 24, 15, 14, 2, 2, 2], cat_got, cat_want, 0.0)))
	Ok({})
}
