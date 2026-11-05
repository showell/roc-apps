## These are Sky's checks: the sun's height, the dusk and the warmth from
## start to end, the colours, and where the sun stands when the rider faces
## it and when they face away.
app [main!] {
	lib: "../lib/main.roc",
}

import Angle
import Camera
import Grade
import Lens
import Sky

height_got : List(F64)
height_got = [
	Sky.sun_height_px(0.0),
	Sky.sun_start_px,
	Sky.sun_radius_px,
	Sky.sun_fully_set_px,
	Sky.warmth_falloff_px,
	Sky.visible_turn_limit.to_radians(),
]

height_want : List(F64)
height_want = [
	244.0,
	244.0,
	46.0,
	(-46.0),
	110.0,
	1.4,
]

ends_got : List(F64)
ends_got = [
	Sky.sun_set_fraction(0.0),
	Sky.sunset_warmth(0.0),
	Sky.sun_set_fraction(6000.0),
	Sky.sunset_warmth(6000.0),
	Sky.sunset_glow,
]

ends_want : List(F64)
ends_want = [0.0, 0.0, 1.0, 0.0, 0.85]

sky_got : List(I64)
sky_got = [
	Sky.sky_color(0.0),
	Sky.sky_color(1000.0),
	Sky.sky_color(2000.0),
	Sky.sky_color(3000.0),
	Sky.sky_color(4000.0),
	Sky.sky_color(5000.0),
	Sky.sky_color(6000.0),
]

sky_want : List(I64)
sky_want = [9358054, 9160418, 8633304, 7710918, 6393260, 4219010, 2374238]

horizon_got : List(I64)
horizon_got = [
	Sky.horizon_color(0.0),
	Sky.horizon_color(1000.0),
	Sky.horizon_color(2000.0),
	Sky.horizon_color(3000.0),
	Sky.horizon_color(4000.0),
	Sky.horizon_color(5000.0),
	Sky.horizon_color(6000.0),
]

horizon_want : List(I64)
horizon_want = [9358054, 9160418, 8633304, 10324366, 13262919, 8019301, 2374238]

packed_got : List(I64)
packed_got = [
	Sky.pack(Sky.day_sky),
	Sky.pack(Sky.dusk_sky),
	Sky.pack(Sky.sunset_red),
]

packed_want : List(I64)
packed_want = [9358054, 2374238, 14571572]

mix_got : List(F64)
mix_got = (
	{
		a = Sky.color_between({
			from: Sky.day_sky,
			to: Sky.dusk_sky,
			fraction: 0.0,
		})
		b = Sky.color_between({
			from: Sky.day_sky,
			to: Sky.dusk_sky,
			fraction: 1.0,
		})
		m = Sky.color_between({
			from: Sky.day_sky,
			to: Sky.dusk_sky,
			fraction: 0.5,
		})
		[
			a.r,
			a.g,
			a.b,
			b.r,
			b.g,
			b.b,
			m.r,
			m.g,
			m.b,
		]
	}
)

mix_want : List(F64)
mix_want = [142.0, 202.0, 230.0, 36.0, 58.0, 94.0, 89.0, 130.0, 162.0]

view : Camera.View
view = { cam_focal: Lens.focal, view_w: 960.0 }

facing : Sky.SunPos
facing = Sky.sun_pos({
	heading: Angle.Bearing.radians(0.0 - 2.2176),
	clock: 0.0,
	view,
})

away : Sky.SunPos
away = Sky.sun_pos({
	heading: Angle.north,
	clock: 0.0,
	view,
})

is_in_view : Sky.SunPos -> Bool
is_in_view = |sun|
	match sun {
		InView(_) => True
		OutOfView => False
	}

visible_got : List(Bool)
visible_got = [is_in_view(facing), is_in_view(away)]

visible_want : List(Bool)
visible_want = [True, False]

place_got : List(F64)
place_got = place_numbers(facing).concat(place_numbers(away))

## Where the sun stands, or nothing when it is out of view.
place_numbers : Sky.SunPos -> List(F64)
place_numbers = |sun|
	match sun {
		InView(place) => [
			place.x,
			place.y,
			place.scale,
		]
		OutOfView => []
	}

# The rider faces the sun, then away from it.
place_want : List(F64)
place_want = [480.0, 56.0, 1.0]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "sk-height",
			got: height_got,
			want: height_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "sk-ends  ",
			got: ends_got,
			want: ends_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "sk-sky   ",
			got: sky_got,
			want: sky_want,
		}),
		Grade.ints({
			name: "sk-horiz ",
			got: horizon_got,
			want: horizon_want,
		}),
		Grade.ints({
			name: "sk-packed",
			got: packed_got,
			want: packed_want,
		}),
		Grade.reals({
			name: "sk-mix   ",
			got: mix_got,
			want: mix_want,
			tol: 0.0,
		}),
		Grade.bools({
			name: "sk-vis   ",
			got: visible_got,
			want: visible_want,
		}),
		Grade.reals({
			name: "sk-place ",
			got: place_got,
			want: place_want,
			tol: 0.0,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
