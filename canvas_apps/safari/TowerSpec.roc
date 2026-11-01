# TowerSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
app [main!] {
	lib: "../lib/main.roc",
}

import Geom
import Grade
import Tower

dims_got : List(F64)
dims_got = [Tower.tower_height, Tower.tower_half, Tower.stage_height, Tower.rod_half, Tower.rod_w, Tower.earth_radius, Tower.beacon_radius, Tower.beacon_period]

dims_want : List(F64)
dims_want = [80.0, 6.0, 20.0, 0.12, 0.24, 20000.0, 3.0, 120.0]

fixed_got : List(I64)
fixed_got = [Tower.brace_stages, Tower.tower_metal, Tower.beacon_color]

fixed_want : List(I64)
fixed_want = [2, 10133672, 16723942]

offsets_got : List(F64)
offsets_got = [Tower.beacon_offset_for(0), Tower.beacon_offset_for(1), Tower.beacon_offset_for(2), Tower.beacon_offset_for(3), Tower.beacon_offset_for(4), Tower.beacon_offset_for(5), Tower.beacon_offset_for(10), Tower.beacon_offset_for(120)]

offsets_want : List(F64)
offsets_want = [0.0, 37.0, 74.0, 111.0, 28.0, 65.0, 10.0, 0.0]

bright_got : List(F64)
bright_got = [Tower.beacon_brightness(0.0), Tower.beacon_brightness(60.0), Tower.beacon_brightness(30.0), Tower.beacon_brightness(90.0), Tower.beacon_brightness(120.0), Tower.beacon_brightness(180.0), Tower.beacon_brightness((0.0 - 60.0)), Tower.beacon_brightness((0.0 - 120.0))]

bright_want : List(F64)
bright_want = [0.0, 1.0, 0.5, 0.5, 0.0, 1.0, 1.0, 0.0]

corner_got : List(F64)
corner_got = [Tower.corner_u(0), Tower.corner_u(1), Tower.corner_u(2), Tower.corner_u(3), Tower.corner_v(0), Tower.corner_v(1), Tower.corner_v(2), Tower.corner_v(3)]

corner_want : List(F64)
corner_want = [(-1.0), 1.0, 1.0, (-1.0), (-1.0), (-1.0), 1.0, 1.0]

ax_of : I64 -> List(F64)
ax_of = |k| (
	{
		p = Tower.base_corner_ax(k, 100.0, 0.0, 0.0)
		[p.a, p.x]
	}
)

ax_got : List(F64)
ax_got = List.join([ax_of(0), ax_of(1), ax_of(2), ax_of(3)])

ax_want : List(F64)
ax_want = [94.0, (-6.0), 94.0, 6.0, 106.0, 6.0, 106.0, (-6.0)]

base4 : List(Geom.RiderPt)
base4 = [{ right: (-6.0), forward: 94.0 }, { right: 6.0, forward: 94.0 }, { right: 6.0, forward: 106.0 }, { right: (-6.0), forward: 106.0 }]

centre : Geom.RiderPt
centre = { right: 0.0, forward: 100.0 }

at_h : I64, F64 -> List(F64)
at_h = |k, h| (
	{
		v = Tower.corner_at(base4, centre, k, h, 1.0)
		[v.right, v.forward, v.height]
	}
)

taper_got : List(F64)
taper_got = List.join([at_h(0, 0.0), at_h(0, 40.0), at_h(0, 80.0), at_h(2, 40.0), at_h(2, 80.0)])

taper_want : List(F64)
taper_want = [(-6.0), 94.0, (-1.0), (-3.0), 97.0, 39.0, 0.0, 100.0, 79.0, 3.0, 103.0, 39.0, 0.0, 100.0, 79.0]

drop_got : List(F64)
drop_got = [Tower.tower_ground_drop({ right: 0.0, forward: 200.0 }), Tower.tower_ground_drop({ right: 100.0, forward: 100.0 }), Tower.tower_ground_drop({ right: 0.0, forward: 0.0 })]

drop_want : List(F64)
drop_want = [1.0, 0.5, 0.0]

lerp_got : List(F64)
lerp_got = (
	{
		a = { right: 0.0, forward: 10.0, height: 20.0 }
		b = { right: 8.0, forward: 30.0, height: 0.0 }
		m = Tower.lerp3v(a, b, 0.25)
		[m.right, m.forward, m.height]
	}
)

lerp_want : List(F64)
lerp_want = [2.0, 15.0, 15.0]

bar_got : List(F64)
bar_got = (List.get(Tower.bar({ x: 0.0, y: 0.0 }, { x: 30.0, y: 40.0 }, 10.0), I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).pts

bar_want : List(F64)
bar_want = [(-4.0), 3.0, 26.0, 43.0, 34.0, 37.0, 4.0, (-3.0)]

degenerate_got : List(F64)
degenerate_got = (
	{
		d = Tower.bar({ x: 5.0, y: 6.0 }, { x: 5.0, y: 6.0 }, 10.0)
		List.concat([I64.to_f64(d.len().to_i64_wrap())], (List.get(d, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).pts)
	}
)

degenerate_want : List(F64)
degenerate_want = [1.0, 5.0, 6.0, 5.0, 6.0, 5.0, 6.0, 5.0, 6.0]

width_got : List(F64)
width_got = [Tower.rod_px(10.0, 500.0, 960.0), Tower.rod_px(25.0, 500.0, 960.0), Tower.rod_px(50.0, 500.0, 960.0)]

width_want : List(F64)
width_want = [12.0, 4.8, 2.4]

v3 : F64, F64, F64 -> Geom.Vec3
v3 = |r, f, h| { right: r, forward: f, height: h }

clip_count_got : List(I64)
clip_count_got = [Tower.bar3d(v3(0.0, 10.0, 0.0), v3(1.0, 20.0, 0.0), 4.0, 500.0, 960.0).len().to_i64_wrap(), Tower.bar3d(v3(0.0, 0.0, 0.0), v3(0.0, 0.8, 0.0), 4.0, 500.0, 960.0).len().to_i64_wrap(), Tower.bar3d(v3(0.0, 0.8, 0.0), v3(0.0, 0.0, 0.0), 4.0, 500.0, 960.0).len().to_i64_wrap(), Tower.bar3d(v3(0.0, 0.0, 0.0), v3(0.0, 0.2, 0.0), 4.0, 500.0, 960.0).len().to_i64_wrap()]

clip_count_want : List(I64)
clip_count_want = [1, 1, 1, 0]

cut_got : List(F64)
cut_got = (
	{
		c = Tower.bar3d_cut(v3(0.0, 0.0, 10.0), v3(8.0, 0.8, 30.0))
		[c.right, c.forward, c.height]
	}
)

cut_want : List(F64)
cut_want = [4.0, 0.4, 20.0]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "tw-dims  ",
			got: dims_got,
			want: dims_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "tw-fixed ",
			got: fixed_got,
			want: fixed_want,
		}),
		Grade.reals({
			name: "tw-offset",
			got: offsets_got,
			want: offsets_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "tw-bright",
			got: bright_got,
			want: bright_want,
			tol: F64.from_bits(4502148214488346440),
		}),
		Grade.reals({
			name: "tw-corner",
			got: corner_got,
			want: corner_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "tw-ax    ",
			got: ax_got,
			want: ax_want,
			tol: F64.from_bits(4517329193108106637),
		}),
		Grade.reals({
			name: "tw-taper ",
			got: taper_got,
			want: taper_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "tw-drop  ",
			got: drop_got,
			want: drop_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "tw-lerp  ",
			got: lerp_got,
			want: lerp_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "tw-bar   ",
			got: bar_got,
			want: bar_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "tw-degen ",
			got: degenerate_got,
			want: degenerate_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "tw-width ",
			got: width_got,
			want: width_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "tw-clip  ",
			got: clip_count_got,
			want: clip_count_want,
		}),
		Grade.reals({
			name: "tw-cut   ",
			got: cut_got,
			want: cut_want,
			tol: 0.0,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
