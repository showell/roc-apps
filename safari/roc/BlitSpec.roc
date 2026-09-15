# BlitSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Blit
import Grade
import Paint
import Text

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

chan_got : List(I64)
chan_got = [Blit.chan_r(8405024), Blit.chan_g(8405024), Blit.chan_b(8405024), Blit.pack_rgb(Blit.chan_r(8405024), Blit.chan_g(8405024), Blit.chan_b(8405024)), Blit.chan_r(16777215), Blit.chan_g(16777215), Blit.chan_b(16777215), Blit.chan_r(0), Blit.pack_rgb(0, 0, 0), Blit.pack_rgb(255, 255, 255)]

chan_want : List(I64)
chan_want = [128, 64, 32, 8405024, 255, 255, 255, 0, 0, 16777215]

shade_got : List(I64)
shade_got = [Blit.shade_chan(128, 0.6), Blit.shade_chan(64, 0.6), Blit.shade_chan(32, 0.6), Blit.shade_chan(250, 1.25), Blit.shade_chan(255, 1.0), Blit.shade_chan(255, 2.0), Blit.shade_chan(0, 1.25), Blit.shade_color(8405024, 0.6)]

shade_want : List(I64)
shade_want = [77, 38, 19, 255, 255, 255, 0, 5056019]

stops_got : List(I64)
stops_got = List.concat(List.concat(Blit.width_shade_stops(8405024, 1.0), Blit.width_shade_stops(8405024, 0.5)), [Blit.width_shade_edge(8405024, 1.0), Blit.width_shade_middle(8405024, 1.0)])

stops_want : List(I64)
stops_want = [5056019, 10506280, 5056019, 6697754, 9455652, 6697754, 5056019, 10506280]

zero_got : List(I64)
zero_got = Blit.width_shade_stops(8405024, 0.0)

zero_want : List(I64)
zero_want = [8405024, 8405024, 8405024]

glow_got : List(I64)
glow_got = [Blit.shade_chan(250, 1.25), Blit.width_shade_middle(16448250, 1.0)]

glow_want : List(I64)
glow_want = [255, 16777215]

visible_got : List(Bool)
visible_got = [Blit.disc_visible(0.5, 0.02), Blit.disc_visible(0.49, 0.02), Blit.disc_visible(0.5, 0.019), Blit.disc_visible(10.0, 1.0), Blit.radial_visible(0.5), Blit.radial_visible(0.49), Blit.too_narrow_to_shade(10.0, 10.5), Blit.too_narrow_to_shade(10.0, 11.0), Blit.too_narrow_to_shade(10.0, 30.0)]

visible_want : List(Bool)
visible_want = [True, False, False, True, True, False, True, False, False]

limits_got : List(F64)
limits_got = [Blit.min_disc_radius, Blit.min_disc_alpha, Blit.min_gradient_radius, Blit.min_shade_width, Blit.shade_edge_darken, Blit.shade_middle_lift]

limits_want : List(F64)
limits_want = [0.5, 0.02, 0.5, 1.0, 0.4, 0.25]

poly : List(F64)
poly = [10.0, 1.0, 30.0, 2.0, 20.0, 3.0]

span_got : List(F64)
span_got = [Blit.span_lo(poly, 0, (List.get(poly, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))), Blit.span_hi(poly, 0, (List.get(poly, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))), Blit.span_lo([5.0, 99.0], 0, 5.0), Blit.span_hi([5.0, 99.0], 0, 5.0)]

span_want : List(F64)
span_want = [10.0, 30.0, 5.0, 5.0]

cmd : I64, I64, F64, List(F64), List(F64) -> Paint.DrawCmd
cmd = |tag, color, strength, geom, pts| { tag: tag, color: color, color2: 0, strength: strength, geom: geom, pts: pts }

wide : Paint.DrawCmd
wide = Blit.expand_shade(cmd(1, 8405024, 1.0, [], poly))

wide_got : List(I64)
wide_got = [wide.tag, wide.color, wide.color2, U64.to_i64_wrap(List.len(wide.geom)), U64.to_i64_wrap(List.len(wide.pts))]

wide_want : List(I64)
wide_want = [2, 5056019, 10506280, 2, 6]

wide_geom_got : List(F64)
wide_geom_got = List.concat(List.concat(wide.geom, wide.pts), [wide.strength])

wide_geom_want : List(F64)
wide_geom_want = [10.0, 30.0, 10.0, 1.0, 30.0, 2.0, 20.0, 3.0, 0.0]

flat_of : Paint.DrawCmd -> List(I64)
flat_of = |c| ({
	e = Blit.expand_shade(c)
	[e.tag, e.color, e.color2, U64.to_i64_wrap(List.len(e.geom)), U64.to_i64_wrap(List.len(e.pts))]
})

flat_got : List(I64)
flat_got = List.concat(List.concat(flat_of(cmd(1, 8405024, 0.0, [], poly)), flat_of(cmd(1, 8405024, 1.0, [], [5.0]))), flat_of(cmd(1, 8405024, 1.0, [], [10.0, 1.0, 10.5, 2.0, 10.2, 3.0])))

flat_want : List(I64)
flat_want = [0, 8405024, 0, 0, 6, 0, 8405024, 0, 0, 1, 0, 8405024, 0, 0, 6]

frame : List(Paint.DrawCmd)
frame = [cmd(0, 111, 0.0, [], poly), cmd(1, 8405024, 1.0, [], poly), cmd(3, 222, 0.02, [1.0, 2.0, 0.5], []), cmd(3, 333, 0.019, [1.0, 2.0, 0.5], []), cmd(3, 444, 1.0, [1.0, 2.0, 0.49], []), cmd(4, 555, 0.0, [1.0, 2.0, 0.5], poly), cmd(4, 666, 0.0, [1.0, 2.0, 0.49], poly), cmd(5, 777, 0.0, [], poly)]

frame_got : List(I64)
frame_got = ({
	out = Blit.blit_expand(frame, 0)
	[U64.to_i64_wrap(List.len(out)), (List.get(out, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).tag, (List.get(out, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).color, (List.get(out, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).tag, (List.get(out, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).color, (List.get(out, I64.to_u64_wrap(2)) ?? crash("list-at out of range")).tag, (List.get(out, I64.to_u64_wrap(2)) ?? crash("list-at out of range")).color, (List.get(out, I64.to_u64_wrap(3)) ?? crash("list-at out of range")).tag, (List.get(out, I64.to_u64_wrap(3)) ?? crash("list-at out of range")).color, (List.get(out, I64.to_u64_wrap(4)) ?? crash("list-at out of range")).tag, (List.get(out, I64.to_u64_wrap(4)) ?? crash("list-at out of range")).color]
})

frame_want : List(I64)
frame_want = [5, 0, 111, 2, 5056019, 3, 222, 4, 555, 5, 777]

empty_got : List(I64)
empty_got = [U64.to_i64_wrap(List.len(Blit.blit_expand([], 0))), U64.to_i64_wrap(List.len(Blit.expand_cmd(cmd(3, 1, 0.5, [0.0, 0.0, 0.1], []))))]

empty_want : List(I64)
empty_want = [0, 0]

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Grade.grade_ints([32, 23, 73, 24, 20, 15, 18, 2, 2], chan_got, chan_want)))
	line!(Text.printed(Grade.grade_ints([32, 23, 73, 19, 20, 15, 22, 13, 2], shade_got, shade_want)))
	line!(Text.printed(Grade.grade_ints([32, 23, 73, 19, 14, 16, 31, 19, 2], stops_got, stops_want)))
	line!(Text.printed(Grade.grade_ints([32, 23, 73, 38, 13, 21, 16, 2, 2], zero_got, zero_want)))
	line!(Text.printed(Grade.grade_ints([32, 23, 73, 29, 23, 16, 27, 2, 2], glow_got, glow_want)))
	line!(Text.printed(Grade.grade_bools([32, 23, 73, 33, 17, 19, 2, 2, 2], visible_got, visible_want)))
	line!(Text.printed(Grade.grade_reals([32, 23, 73, 23, 17, 26, 17, 14, 19], limits_got, limits_want, 0.0)))
	line!(Text.printed(Grade.grade_reals([32, 23, 73, 19, 31, 15, 18, 2, 2], span_got, span_want, 0.0)))
	line!(Text.printed(Grade.grade_ints([32, 23, 73, 27, 17, 22, 13, 2, 2], wide_got, wide_want)))
	line!(Text.printed(Grade.grade_reals([32, 23, 73, 27, 29, 13, 16, 26, 2], wide_geom_got, wide_geom_want, 0.0)))
	line!(Text.printed(Grade.grade_ints([32, 23, 73, 28, 23, 15, 14, 2, 2], flat_got, flat_want)))
	line!(Text.printed(Grade.grade_ints([32, 23, 73, 28, 21, 15, 26, 13, 2], frame_got, frame_want)))
	line!(Text.printed(Grade.grade_ints([32, 23, 73, 13, 26, 31, 14, 30, 2], empty_got, empty_want)))
	Ok({})
}
