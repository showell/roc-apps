# MountainsSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Grade
import Mountains
import Sky
import Text

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

palette_got : List(I64)
palette_got = [Mountains.rock, Mountains.rock_west, Mountains.land]

palette_want : List(I64)
palette_want = [5991055, 3752799, 4886339]

chan_got : List(F64)
chan_got = [Mountains.chan(Mountains.rock, 16), Mountains.chan(Mountains.rock, 8), Mountains.chan(Mountains.rock, 0), Mountains.chan(16777215, 16), Mountains.chan(0, 0)]

chan_want : List(F64)
chan_want = [91.0, 106.0, 143.0, 255.0, 0.0]

dim_got : List(I64)
dim_got = [Mountains.dimmed(Mountains.rock, 0.0), Mountains.dimmed(Mountains.rock_west, 0.0), Mountains.dimmed(Mountains.land, 0.0), Mountains.dimmed(Mountains.rock, 1.0), Mountains.dimmed(Mountains.rock_west, 1.0), Mountains.dimmed(Mountains.land, 1.0), Mountains.dimmed(Mountains.rock, 0.5)]

dim_want : List(I64)
dim_want = [5991055, 3752799, 4886339, 3028296, 1909296, 2443298, 4477035]

snow_got : List(I64)
snow_got = [Mountains.snow_color(0.0), Mountains.snow_color(1.0), Mountains.snow_color(0.5), Sky.pack(Mountains.snow_day), Sky.pack(Mountains.snow_night)]

snow_want : List(I64)
snow_want = [15660024, 4609128, 10134704, 15660024, 4609128]

night_order_got : List(Bool)
night_order_got = [(Mountains.snow_color(1.0) > Mountains.dimmed(Mountains.rock, 1.0)), (Mountains.snow_color(0.0) > Mountains.dimmed(Mountains.rock, 0.0))]

night_order_want : List(Bool)
night_order_want = [True, True]

north_edge_got : List(F64)
north_edge_got = [Mountains.north_range(0.95), Mountains.north_range(1.0), Mountains.north_range(2.0), Mountains.north_range((0.0 - 0.95)), Mountains.north_range((0.0 - 3.0))]

north_edge_want : List(F64)
north_edge_want = [0.0, 0.0, 0.0, 0.0, 0.0]

west_edge_got : List(F64)
west_edge_got = [Mountains.west_range((Mountains.west_range_bearing + 0.8)), Mountains.west_range((Mountains.west_range_bearing - 0.8)), Mountains.west_range(0.0), Mountains.west_range(1.5)]

west_edge_want : List(F64)
west_edge_want = [0.0, 0.0, 0.0, 0.0]

inside_got : List(Bool)
inside_got = [(Mountains.north_range(0.0) > 0.0), (Mountains.north_range(0.94) > 0.0), (Mountains.north_range(0.0) > Mountains.snow_threshold), (Mountains.north_range(0.9) > Mountains.snow_threshold), (Mountains.west_range(Mountains.west_range_bearing) > 0.0)]

inside_want : List(Bool)
inside_want = [True, True, True, False, True]

shape_got : List(F64)
shape_got = [Mountains.west_range_bearing, Mountains.snow_threshold, Mountains.snow_dip, Mountains.col_step, Mountains.roll_margin, Mountains.rock_night_dim]

shape_want : List(F64)
shape_want = [(-2.0416), 124.0, 10.0, 2.0, 200.0, 0.5]

snowline_got : List(F64)
snowline_got = [Mountains.snowline_at(0.9, Mountains.snow_peak_height), Mountains.snowline_at(2.0, Mountains.snow_peak_height)]

snowline_want : List(F64)
snowline_want = [124.0, 124.0]

band_got : List(Bool)
band_got = [(Mountains.snowline_at(0.0, Mountains.snow_peak_height) < Mountains.snow_threshold), (Mountains.snowline_at(0.0, Mountains.snow_peak_height) > (Mountains.snow_threshold - Mountains.snow_dip)), (Mountains.snowline_at(0.5, Mountains.snow_peak_height) <= Mountains.snow_threshold), (Mountains.snowline_at(0.5, Mountains.snow_peak_height) >= (Mountains.snow_threshold - Mountains.snow_dip))]

band_want : List(Bool)
band_want = [True, True, True, True]

peak_got : List(Bool)
peak_got = [(Mountains.snow_peak_height > Mountains.snow_threshold), (Mountains.snow_peak_height < 150.0)]

peak_want : List(Bool)
peak_want = [True, True]

bearing_got : List(F64)
bearing_got = [Mountains.bearing_at(480.0, 0.0, 500.0, 960.0), Mountains.bearing_at(480.0, 1.25, 500.0, 960.0), Mountains.bearing_at(480.0, 1.25, 100.0, 960.0)]

bearing_want : List(F64)
bearing_want = [0.0, 1.25, 1.25]

spread_got : List(Bool)
spread_got = [(Mountains.bearing_at(0.0, 0.0, 500.0, 960.0) < Mountains.bearing_at(480.0, 0.0, 500.0, 960.0)), (Mountains.bearing_at(480.0, 0.0, 500.0, 960.0) < Mountains.bearing_at(960.0, 0.0, 500.0, 960.0)), (Mountains.bearing_at(960.0, 0.0, 100.0, 960.0) > Mountains.bearing_at(960.0, 0.0, 500.0, 960.0))]

spread_want : List(Bool)
spread_want = [True, True, True]

crest_got : List(Bool)
crest_got = [(Mountains.horizon_crest_px(0.0) >= Mountains.ground_base(0.0)), (Mountains.horizon_crest_px(2.0) >= Mountains.ground_base(2.0)), (Mountains.horizon_crest_px(0.0) >= Mountains.north_range(0.0)), Mountains.sun_behind_mountains(0.0), Mountains.sun_behind_mountains(6000.0)]

crest_want : List(Bool)
crest_want = [True, True, True, False, True]

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Grade.grade_ints([26, 14, 73, 31, 15, 23, 2, 2, 2], palette_got, palette_want)))
	line!(Text.printed(Grade.grade_reals([26, 14, 73, 24, 20, 15, 18, 2, 2], chan_got, chan_want, 0.0)))
	line!(Text.printed(Grade.grade_ints([26, 14, 73, 22, 17, 26, 2, 2, 2], dim_got, dim_want)))
	line!(Text.printed(Grade.grade_ints([26, 14, 73, 19, 18, 16, 27, 2, 2], snow_got, snow_want)))
	line!(Text.printed(Grade.grade_bools([26, 14, 73, 16, 21, 22, 13, 21, 2], night_order_got, night_order_want)))
	line!(Text.printed(Grade.grade_reals([26, 14, 73, 18, 16, 21, 14, 20, 2], north_edge_got, north_edge_want, 0.0)))
	line!(Text.printed(Grade.grade_reals([26, 14, 73, 27, 13, 19, 14, 2, 2], west_edge_got, west_edge_want, 0.0)))
	line!(Text.printed(Grade.grade_bools([26, 14, 73, 17, 18, 19, 17, 22, 13], inside_got, inside_want)))
	line!(Text.printed(Grade.grade_reals([26, 14, 73, 19, 20, 15, 31, 13, 2], shape_got, shape_want, 0.0)))
	line!(Text.printed(Grade.grade_reals([26, 14, 73, 19, 18, 16, 27, 23, 18], snowline_got, snowline_want, 0.0)))
	line!(Text.printed(Grade.grade_bools([26, 14, 73, 32, 15, 18, 22, 2, 2], band_got, band_want)))
	line!(Text.printed(Grade.grade_bools([26, 14, 73, 31, 13, 15, 34, 2, 2], peak_got, peak_want)))
	line!(Text.printed(Grade.grade_reals([26, 14, 73, 32, 13, 15, 21, 2, 2], bearing_got, bearing_want, 0.0)))
	line!(Text.printed(Grade.grade_bools([26, 14, 73, 19, 31, 21, 13, 15, 22], spread_got, spread_want)))
	line!(Text.printed(Grade.grade_bools([26, 14, 73, 24, 21, 13, 19, 14, 2], crest_got, crest_want)))
	Ok({})
}
