## These are Blit's checks: colour channels and shading, what is too small
## or too narrow to draw, the span of a polygon, and a frame expanded.
app [main!] {
	lib: "../lib/main.roc",
}

import Blit
import Grade
import Paint

color : I64
color = 8405024

chan_got : List(I64)
chan_got = [
	Blit.red_of(color),
	Blit.green_of(color),
	Blit.blue_of(color),
	Blit.pack_rgb({ red: Blit.red_of(color), green: Blit.green_of(color), blue: Blit.blue_of(color) }),
	Blit.red_of(16777215),
	Blit.green_of(16777215),
	Blit.blue_of(16777215),
	Blit.red_of(0),
	Blit.pack_rgb({ red: 0, green: 0, blue: 0 }),
	Blit.pack_rgb({ red: 255, green: 255, blue: 255 }),
]

chan_want : List(I64)
chan_want = [128, 64, 32, 8405024, 255, 255, 255, 0, 0, 16777215]

shade_got : List(I64)
shade_got = [
	Blit.shade_channel(128, 0.6),
	Blit.shade_channel(64, 0.6),
	Blit.shade_channel(32, 0.6),
	Blit.shade_channel(250, 1.25),
	Blit.shade_channel(255, 1.0),
	Blit.shade_channel(255, 2.0),
	Blit.shade_channel(0, 1.25),
	Blit.shade_color(color, 0.6),
]

shade_want : List(I64)
shade_want = [77, 38, 19, 255, 255, 255, 0, 5056019]

stops_got : List(I64)
stops_got = List.join([Blit.width_shade_stops(color, 1.0), Blit.width_shade_stops(color, 0.5), [Blit.width_shade_edge(color, 1.0), Blit.width_shade_middle(color, 1.0)]])

stops_want : List(I64)
stops_want = [5056019, 10506280, 5056019, 6697754, 9455652, 6697754, 5056019, 10506280]

zero_got : List(I64)
zero_got = Blit.width_shade_stops(color, 0.0)

zero_want : List(I64)
zero_want = [8405024, 8405024, 8405024]

glow_got : List(I64)
glow_got = [Blit.shade_channel(250, 1.25), Blit.width_shade_middle(16448250, 1.0)]

glow_want : List(I64)
glow_want = [255, 16777215]

visible_got : List(Bool)
visible_got = [
	Blit.is_disc_visible({ radius: 0.5, alpha: 0.02 }),
	Blit.is_disc_visible({ radius: 0.49, alpha: 0.02 }),
	Blit.is_disc_visible({ radius: 0.5, alpha: 0.019 }),
	Blit.is_disc_visible({ radius: 10.0, alpha: 1.0 }),
	Blit.is_radial_visible(0.5),
	Blit.is_radial_visible(0.49),
	Blit.is_too_narrow_to_shade({ min_x: 10.0, max_x: 10.5 }),
	Blit.is_too_narrow_to_shade({ min_x: 10.0, max_x: 11.0 }),
	Blit.is_too_narrow_to_shade({ min_x: 10.0, max_x: 30.0 }),
]

visible_want : List(Bool)
visible_want = [True, False, False, True, True, False, True, False, False]

limits_got : List(F64)
limits_got = [Blit.min_disc_radius, Blit.min_disc_alpha, Blit.min_gradient_radius, Blit.min_shade_width, Blit.shade_edge_darken, Blit.shade_middle_lift]

limits_want : List(F64)
limits_want = [0.5, 0.02, 0.5, 1.0, 0.4, 0.25]

# Three points, flat: (10, 1), (30, 2) and (20, 3).
poly : List(F64)
poly = [10.0, 1.0, 30.0, 2.0, 20.0, 3.0]

span_got : List(F64)
span_got = {
	wide_span = Blit.x_span(poly)
	one_point = Blit.x_span([5.0, 99.0])
	[wide_span.min_x, wide_span.max_x, one_point.min_x, one_point.max_x]
}

span_want : List(F64)
span_want = [10.0, 30.0, 5.0, 5.0]

# A command with nothing set, for the checks to fill in.
blank : Paint.DrawCmd
blank = { tag: 0, color: 0, color2: 0, strength: 0.0, geom: [], pts: [] }

wide : Paint.DrawCmd
wide = Blit.expand_shade({ ..blank, tag: 1, color, strength: 1.0, pts: poly })

wide_got : List(I64)
wide_got = [wide.tag, wide.color, wide.color2, wide.geom.len().to_i64_wrap(), wide.pts.len().to_i64_wrap()]

wide_want : List(I64)
wide_want = [2, 5056019, 10506280, 2, 6]

wide_geom_got : List(F64)
wide_geom_got = List.join([wide.geom, wide.pts, [wide.strength]])

wide_geom_want : List(F64)
wide_geom_want = [10.0, 30.0, 10.0, 1.0, 30.0, 2.0, 20.0, 3.0, 0.0]

flat_of : Paint.DrawCmd -> List(I64)
flat_of = |cmd| {
	expanded = Blit.expand_shade(cmd)
	[expanded.tag, expanded.color, expanded.color2, expanded.geom.len().to_i64_wrap(), expanded.pts.len().to_i64_wrap()]
}

flat_got : List(I64)
flat_got = [
	{ ..blank, tag: 1, color, strength: 0.0, pts: poly },
	{ ..blank, tag: 1, color, strength: 1.0, pts: [5.0] },
	{ ..blank, tag: 1, color, strength: 1.0, pts: [10.0, 1.0, 10.5, 2.0, 10.2, 3.0] },
].join_map(flat_of)

flat_want : List(I64)
flat_want = [0, 8405024, 0, 0, 6, 0, 8405024, 0, 0, 1, 0, 8405024, 0, 0, 6]

frame : List(Paint.DrawCmd)
frame = [
	{ ..blank, tag: 0, color: 111, pts: poly },
	{ ..blank, tag: 1, color, strength: 1.0, pts: poly },
	{ ..blank, tag: 3, color: 222, strength: 0.02, geom: [1.0, 2.0, 0.5] },
	{ ..blank, tag: 3, color: 333, strength: 0.019, geom: [1.0, 2.0, 0.5] },
	{ ..blank, tag: 3, color: 444, strength: 1.0, geom: [1.0, 2.0, 0.49] },
	{ ..blank, tag: 4, color: 555, geom: [1.0, 2.0, 0.5], pts: poly },
	{ ..blank, tag: 4, color: 666, geom: [1.0, 2.0, 0.49], pts: poly },
	{ ..blank, tag: 5, color: 777, pts: poly },
]

frame_got : List(I64)
frame_got = {
	out = Blit.blit_expand(frame)
	List.concat([out.len().to_i64_wrap()], out.join_map(|cmd| [cmd.tag, cmd.color]))
}

frame_want : List(I64)
frame_want = [5, 0, 111, 2, 5056019, 3, 222, 4, 555, 5, 777]

empty_got : List(I64)
empty_got = [Blit.blit_expand([]).len().to_i64_wrap(), Blit.expand_cmd({ ..blank, tag: 3, color: 1, strength: 0.5, geom: [0.0, 0.0, 0.1] }).len().to_i64_wrap()]

empty_want : List(I64)
empty_want = [0, 0]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.ints({
			name: "bl-chan  ",
			got: chan_got,
			want: chan_want,
		}),
		Grade.ints({
			name: "bl-shade ",
			got: shade_got,
			want: shade_want,
		}),
		Grade.ints({
			name: "bl-stops ",
			got: stops_got,
			want: stops_want,
		}),
		Grade.ints({
			name: "bl-zero  ",
			got: zero_got,
			want: zero_want,
		}),
		Grade.ints({
			name: "bl-glow  ",
			got: glow_got,
			want: glow_want,
		}),
		Grade.bools({
			name: "bl-vis   ",
			got: visible_got,
			want: visible_want,
		}),
		Grade.reals({
			name: "bl-limits",
			got: limits_got,
			want: limits_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "bl-span  ",
			got: span_got,
			want: span_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "bl-wide  ",
			got: wide_got,
			want: wide_want,
		}),
		Grade.reals({
			name: "bl-wgeom ",
			got: wide_geom_got,
			want: wide_geom_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "bl-flat  ",
			got: flat_got,
			want: flat_want,
		}),
		Grade.ints({
			name: "bl-frame ",
			got: frame_got,
			want: frame_want,
		}),
		Grade.ints({
			name: "bl-empty ",
			got: empty_got,
			want: empty_want,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
