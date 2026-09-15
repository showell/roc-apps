# SkySpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Grade
import Lens
import Sky
import Text

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

height_got : List(F64)
height_got = [Sky.sun_height_px(0.0), Sky.sun_start_px, Sky.sun_radius_px, Sky.sun_fully_set_px, Sky.warmth_falloff_px, Sky.visible_bearing_limit]

height_want : List(F64)
height_want = [244.0, 244.0, 46.0, (-46.0), 110.0, 1.4]

ends_got : List(F64)
ends_got = [Sky.sun_set_fraction(0.0), Sky.sunset_warmth(0.0), Sky.sun_set_fraction(6000.0), Sky.sunset_warmth(6000.0), Sky.sunset_glow]

ends_want : List(F64)
ends_want = [0.0, 0.0, 1.0, 0.0, 0.85]

sky_got : List(I64)
sky_got = [Sky.sky_color(0.0), Sky.sky_color(1000.0), Sky.sky_color(2000.0), Sky.sky_color(3000.0), Sky.sky_color(4000.0), Sky.sky_color(5000.0), Sky.sky_color(6000.0)]

sky_want : List(I64)
sky_want = [9358054, 9160418, 8633304, 7710918, 6393260, 4219010, 2374238]

horizon_got : List(I64)
horizon_got = [Sky.horizon_color(0.0), Sky.horizon_color(1000.0), Sky.horizon_color(2000.0), Sky.horizon_color(3000.0), Sky.horizon_color(4000.0), Sky.horizon_color(5000.0), Sky.horizon_color(6000.0)]

horizon_want : List(I64)
horizon_want = [9358054, 9160418, 8633304, 10324366, 13262919, 8019301, 2374238]

packed_got : List(I64)
packed_got = [Sky.pack(Sky.day_sky), Sky.pack(Sky.dusk_sky), Sky.pack(Sky.sunset_red)]

packed_want : List(I64)
packed_want = [9358054, 2374238, 14571572]

mix_got : List(F64)
mix_got = ({
	a = Sky.lerp3(Sky.day_sky, Sky.dusk_sky, 0.0)
	b = Sky.lerp3(Sky.day_sky, Sky.dusk_sky, 1.0)
	m = Sky.lerp3(Sky.day_sky, Sky.dusk_sky, 0.5)
	[a.r, a.g, a.b, b.r, b.g, b.b, m.r, m.g, m.b]
})

mix_want : List(F64)
mix_want = [142.0, 202.0, 230.0, 36.0, 58.0, 94.0, 89.0, 130.0, 162.0]

facing : Sky.SunPos
facing = Sky.sun_pos((0.0 - 2.2176), 0.0, Lens.focal, 960.0)

away : Sky.SunPos
away = Sky.sun_pos(0.0, 0.0, Lens.focal, 960.0)

visible_got : List(Bool)
visible_got = [facing.visible, away.visible]

visible_want : List(Bool)
visible_want = [True, False]

place_got : List(F64)
place_got = [facing.x, facing.y, facing.scale, away.x, away.y, away.scale]

place_want : List(F64)
place_want = [480.0, 56.0, 1.0, 0.0, 0.0, 0.0]

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Grade.grade_reals([19, 34, 73, 20, 13, 17, 29, 20, 14], height_got, height_want, 0.0)))
	line!(Text.printed(Grade.grade_reals([19, 34, 73, 13, 18, 22, 19, 2, 2], ends_got, ends_want, 0.0)))
	line!(Text.printed(Grade.grade_ints([19, 34, 73, 19, 34, 30, 2, 2, 2], sky_got, sky_want)))
	line!(Text.printed(Grade.grade_ints([19, 34, 73, 20, 16, 21, 17, 38, 2], horizon_got, horizon_want)))
	line!(Text.printed(Grade.grade_ints([19, 34, 73, 31, 15, 24, 34, 13, 22], packed_got, packed_want)))
	line!(Text.printed(Grade.grade_reals([19, 34, 73, 26, 17, 36, 2, 2, 2], mix_got, mix_want, 0.0)))
	line!(Text.printed(Grade.grade_bools([19, 34, 73, 33, 17, 19, 2, 2, 2], visible_got, visible_want)))
	line!(Text.printed(Grade.grade_reals([19, 34, 73, 31, 23, 15, 24, 13, 2], place_got, place_want, 0.0)))
	Ok({})
}
