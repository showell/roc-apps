## These are Mountains' checks: its colours by day and at dusk, where each
## range rises and ends, the snowline, the bearing across the screen, and when
## the skyline hides the sun.
app [main!] {
	lib: "../lib/main.roc",
}

import Angle
import Grade
import Mountains
import Sky

## The bearing `radians` to the right of north.
at : F64 -> Angle.Bearing
at = |radians| Angle.Bearing.radians(radians)

## The west range's middle, `radians` to its right.
west_by : F64 -> Angle.Bearing
west_by = |radians| Mountains.west_range_bearing.plus(Angle.Turn.radians(radians))

palette_got : List(I64)
palette_got = [
	Mountains.rock,
	Mountains.rock_west,
	Mountains.land,
]

palette_want : List(I64)
palette_want = [5991055, 3752799, 4886339]

chan_got : List(F64)
chan_got = [
	Mountains.channel(Mountains.rock, 16),
	Mountains.channel(Mountains.rock, 8),
	Mountains.channel(Mountains.rock, 0),
	Mountains.channel(16777215, 16),
	Mountains.channel(0, 0),
]

chan_want : List(F64)
chan_want = [91.0, 106.0, 143.0, 255.0, 0.0]

dim_got : List(I64)
dim_got = [
	Mountains.color_at_dusk(Mountains.rock, 0.0),
	Mountains.color_at_dusk(Mountains.rock_west, 0.0),
	Mountains.color_at_dusk(Mountains.land, 0.0),
	Mountains.color_at_dusk(Mountains.rock, 1.0),
	Mountains.color_at_dusk(Mountains.rock_west, 1.0),
	Mountains.color_at_dusk(Mountains.land, 1.0),
	Mountains.color_at_dusk(Mountains.rock, 0.5),
]

dim_want : List(I64)
dim_want = [5991055, 3752799, 4886339, 3028296, 1909296, 2443298, 4477035]

snow_got : List(I64)
snow_got = [
	Mountains.snow_color(0.0),
	Mountains.snow_color(1.0),
	Mountains.snow_color(0.5),
	Sky.pack(Mountains.snow_day),
	Sky.pack(Mountains.snow_night),
]

snow_want : List(I64)
snow_want = [15660024, 4609128, 10134704, 15660024, 4609128]

night_order_got : List(Bool)
night_order_got = [
	(Mountains.snow_color(1.0) > Mountains.color_at_dusk(Mountains.rock, 1.0)),
	(Mountains.snow_color(0.0) > Mountains.color_at_dusk(Mountains.rock, 0.0)),
]

night_order_want : List(Bool)
night_order_want = [True, True]

north_edge_got : List(F64)
north_edge_got = [
	Mountains.north_range(at(0.95)),
	Mountains.north_range(at(1.0)),
	Mountains.north_range(at(2.0)),
	Mountains.north_range(at(-0.95)),
	Mountains.north_range(at(-3.0)),
]

north_edge_want : List(F64)
north_edge_want = [0.0, 0.0, 0.0, 0.0, 0.0]

west_edge_got : List(F64)
west_edge_got = [
	Mountains.west_range(west_by(0.8)),
	Mountains.west_range(west_by(-0.8)),
	Mountains.west_range(at(0.0)),
	Mountains.west_range(at(1.5)),
]

west_edge_want : List(F64)
west_edge_want = [0.0, 0.0, 0.0, 0.0]

inside_got : List(Bool)
inside_got = [
	(Mountains.north_range(at(0.0)) > 0.0),
	(Mountains.north_range(at(0.94)) > 0.0),
	(Mountains.north_range(at(0.0)) > Mountains.snow_threshold),
	(Mountains.north_range(at(0.9)) > Mountains.snow_threshold),
	(Mountains.west_range(Mountains.west_range_bearing) > 0.0),
]

inside_want : List(Bool)
inside_want = [True, True, True, False, True]

shape_got : List(F64)
shape_got = [
	Mountains.west_range_bearing.to_radians(),
	Mountains.snow_threshold,
	Mountains.snow_dip,
	Mountains.col_step,
	Mountains.roll_margin,
	Mountains.rock_night_dim,
]

shape_want : List(F64)
shape_want = [
	(-2.0416),
	124.0,
	10.0,
	2.0,
	200.0,
	0.5,
]

snowline_got : List(F64)
snowline_got = [Mountains.snowline(at(0.9)), Mountains.snowline(at(2.0))]

snowline_want : List(F64)
snowline_want = [124.0, 124.0]

band_got : List(Bool)
band_got = [
	(Mountains.snowline(at(0.0)) < Mountains.snow_threshold),
	(Mountains.snowline(at(0.0)) > (Mountains.snow_threshold - Mountains.snow_dip)),
	(Mountains.snowline(at(0.5)) <= Mountains.snow_threshold),
	(Mountains.snowline(at(0.5)) >= (Mountains.snow_threshold - Mountains.snow_dip)),
]

band_want : List(Bool)
band_want = [True, True, True, True]

peak_got : List(Bool)
peak_got = [
	(Mountains.snow_peak_height > Mountains.snow_threshold),
	(Mountains.snow_peak_height < 150.0),
]

peak_want : List(Bool)
peak_want = [True, True]

## The bearing seen at `x` across a 960-pixel screen.
bearing : {
	heading : F64,
	cam_focal : F64,
	x : F64,
} -> F64
bearing = |
	{
		heading,
		cam_focal,
		x,
	},
| Mountains.bearing_at(
	{
		heading: at(heading),
		cam_focal,
		view_w: 960.0,
	},
	x,
).to_radians()

bearing_got : List(F64)
bearing_got = [
	bearing({
		heading: 0.0,
		cam_focal: 500.0,
		x: 480.0,
	}),
	bearing({
		heading: 1.25,
		cam_focal: 500.0,
		x: 480.0,
	}),
	bearing({
		heading: 1.25,
		cam_focal: 100.0,
		x: 480.0,
	}),
]

bearing_want : List(F64)
bearing_want = [0.0, 1.25, 1.25]

spread_got : List(Bool)
spread_got = [
	bearing({
		heading: 0.0,
		cam_focal: 500.0,
		x: 0.0,
	}) < bearing({
		heading: 0.0,
		cam_focal: 500.0,
		x: 480.0,
	}),
	bearing({
		heading: 0.0,
		cam_focal: 500.0,
		x: 480.0,
	}) < bearing({
		heading: 0.0,
		cam_focal: 500.0,
		x: 960.0,
	}),
	bearing({
		heading: 0.0,
		cam_focal: 100.0,
		x: 960.0,
	}) > bearing({
		heading: 0.0,
		cam_focal: 500.0,
		x: 960.0,
	}),
]

spread_want : List(Bool)
spread_want = [True, True, True]

crest_got : List(Bool)
crest_got = [
	(Mountains.horizon_crest_px(at(0.0)) >= Mountains.ground_base(at(0.0))),
	(Mountains.horizon_crest_px(at(2.0)) >= Mountains.ground_base(at(2.0))),
	(Mountains.horizon_crest_px(at(0.0)) >= Mountains.north_range(at(0.0))),
	Mountains.is_sun_behind_mountains(0.0),
	Mountains.is_sun_behind_mountains(6000.0),
]

crest_want : List(Bool)
crest_want = [True, True, True, False, True]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.ints({
			name: "mt-pal   ",
			got: palette_got,
			want: palette_want,
		}),
		Grade.reals({
			name: "mt-chan  ",
			got: chan_got,
			want: chan_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "mt-dim   ",
			got: dim_got,
			want: dim_want,
		}),
		Grade.ints({
			name: "mt-snow  ",
			got: snow_got,
			want: snow_want,
		}),
		Grade.bools({
			name: "mt-order ",
			got: night_order_got,
			want: night_order_want,
		}),
		Grade.reals({
			name: "mt-north ",
			got: north_edge_got,
			want: north_edge_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "mt-west  ",
			got: west_edge_got,
			want: west_edge_want,
			tol: 0.0,
		}),
		Grade.bools({
			name: "mt-inside",
			got: inside_got,
			want: inside_want,
		}),
		Grade.reals({
			name: "mt-shape ",
			got: shape_got,
			want: shape_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "mt-snowln",
			got: snowline_got,
			want: snowline_want,
			tol: 0.0,
		}),
		Grade.bools({
			name: "mt-band  ",
			got: band_got,
			want: band_want,
		}),
		Grade.bools({
			name: "mt-peak  ",
			got: peak_got,
			want: peak_want,
		}),
		Grade.reals({
			name: "mt-bear  ",
			got: bearing_got,
			want: bearing_want,
			tol: 0.0,
		}),
		Grade.bools({
			name: "mt-spread",
			got: spread_got,
			want: spread_want,
		}),
		Grade.bools({
			name: "mt-crest ",
			got: crest_got,
			want: crest_want,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
