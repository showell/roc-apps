app [main!] { pf: platform "../../../../../../showell_repos/roc-apps/framebuffer/platform/main.roc" }

import pf.Echo

echo! = |msg| Echo.line!(msg)

# Fireworks -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import KeyInput
import Machine
import Wrap64

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

cmd_buf : I64
cmd_buf = 3187671040

sw : I64
sw = 1024

sh : I64
sh = 768

horizon : I64
horizon = 680

max_tri : I64
max_tri = 60000

city_seed : I64
city_seed = 777

num_cities : I64
num_cities = 5

frames_per_city : I64
frames_per_city = 600

finale_len : I64
finale_len = 900

cycle_cities : I64
cycle_cities = (num_cities * frames_per_city)

cycle_total : I64
cycle_total = (cycle_cities + finale_len)

force_city : I64
force_city = (-1)

force_finale : I64
force_finale = 0

part_base : I64
part_base = 2952790016

part_cap : I64
part_cap = 2600

part_stride : I64
part_stride = 32

gravity : I64
gravity = 20

launch_every : I64
launch_every = 9

burst_count : I64
burst_count = 150

sim_substeps : I64
sim_substeps = 3

burst_alt : I64
burst_alt = 170

f_px : I64
f_px = 0

f_py : I64
f_py = 4

f_vx : I64
f_vx = 8

f_vy : I64
f_vy = 12

f_life : I64
f_life = 16

f_max : I64
f_max = 20

f_col : I64
f_col = 24

f_kind : I64
f_kind = 28

sky_top : I64
sky_top = 394774

sky_horizon : I64
sky_horizon = 2758720

fade_sky : I64
fade_sky = 263182

water_top : I64
water_top = 1575976

water_bottom : I64
water_bottom = 328458

building_col : I64
building_col = 1316404

shell_col : I64
shell_col = 16773312

landmark_col : I64
landmark_col = 1843528

antenna_col : I64
antenna_col = 13122090

gg_orange : I64
gg_orange = 12600362

gg_cable : I64
gg_cable = 9056030

needle_col : I64
needle_col = 2764896

monument_col : I64
monument_col = 14209728

dome_col : I64
dome_col = 13157556

trans_col : I64
trans_col = 6975110

burst_color : I64 -> I64
burst_color = |k| ({
	m = (k - (I64.div_trunc_by(k, 6) * 6))
	(if (m == 0) { 16724772 } else { (if (m == 1) { 16777215 } else { (if (m == 2) { 3828735 } else { (if (m == 3) { 16764968 } else { (if (m == 4) { 4644976 } else { 12995583 }) }) }) }) })
})

bump : I64, I64 -> I64
bump = |_written, t| t

put_tri3! : Machine.Machine, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
put_tri3! = |machine, cmd, idx, x0, y0, x1, y1, x2, y2, c0, c1, c2, d| ({
	(machine19, machine__27) = ({
	o = (idx * 72)
	({
		(machine1, machine__9) = Machine.store!(machine, cmd, o, x0, 4)
		(machine2, machine__10) = Machine.store!(machine1, cmd, (o + 4), y0, 4)
		(machine3, machine__11) = Machine.store!(machine2, cmd, (o + 8), x1, 4)
		(machine4, machine__12) = Machine.store!(machine3, cmd, (o + 12), y1, 4)
		(machine5, machine__13) = Machine.store!(machine4, cmd, (o + 16), x2, 4)
		(machine6, machine__14) = Machine.store!(machine5, cmd, (o + 20), y2, 4)
		(machine7, machine__15) = Machine.store!(machine6, cmd, (o + 24), c0, 4)
		(machine8, machine__16) = Machine.store!(machine7, cmd, (o + 28), c1, 4)
		(machine9, machine__17) = Machine.store!(machine8, cmd, (o + 32), c2, 4)
		(machine10, machine__18) = Machine.store!(machine9, cmd, (o + 36), d, 4)
		(machine11, machine__19) = Machine.store!(machine10, cmd, (o + 40), d, 4)
		(machine12, machine__20) = Machine.store!(machine11, cmd, (o + 44), d, 4)
		(machine13, machine__21) = Machine.store!(machine12, cmd, (o + 48), 0, 4)
		(machine14, machine__22) = Machine.store!(machine13, cmd, (o + 52), 0, 4)
		(machine15, machine__23) = Machine.store!(machine14, cmd, (o + 56), 0, 4)
		(machine16, machine__24) = Machine.store!(machine15, cmd, (o + 60), 0, 4)
		(machine17, machine__25) = Machine.store!(machine16, cmd, (o + 64), 0, 4)
		(machine18, machine__26) = Machine.store!(machine17, cmd, (o + 68), 0, 4)
		(machine18, bump((((((((((((((((((machine__9 + machine__10) + machine__11) + machine__12) + machine__13) + machine__14) + machine__15) + machine__16) + machine__17) + machine__18) + machine__19) + machine__20) + machine__21) + machine__22) + machine__23) + machine__24) + machine__25) + machine__26), (idx + 1)))
	})
})
	(machine19, machine__27)
})

put_rect! : Machine.Machine, I64, I64, I64, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
put_rect! = |machine, cmd, idx, x, y, w, h, col, d| (if (idx >= max_tri) { (machine, idx) } else { ({
	(machine1, machine__28) = put_tri3!(machine, cmd, idx, x, y, x, (y + h), (x + w), y, col, col, col, d)
	put_tri3!(machine1, cmd, machine__28, (x + w), y, x, (y + h), (x + w), (y + h), col, col, col, d)
}) })

put_quad_c! : Machine.Machine, I64, I64, I64, I64, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
put_quad_c! = |machine, cmd, idx, x, y, w, h, ctop, cbot, d| (if (idx >= max_tri) { (machine, idx) } else { ({
	(machine1, machine__29) = put_tri3!(machine, cmd, idx, x, y, x, (y + h), (x + w), y, ctop, cbot, ctop, d)
	put_tri3!(machine1, cmd, machine__29, (x + w), y, x, (y + h), (x + w), (y + h), ctop, cbot, cbot, d)
}) })

put_tri3_add! : Machine.Machine, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
put_tri3_add! = |machine, cmd, idx, x0, y0, x1, y1, x2, y2, c0, c1, c2, d| ({
	(machine19, machine__48) = ({
	o = (idx * 72)
	({
		(machine1, machine__30) = Machine.store!(machine, cmd, o, x0, 4)
		(machine2, machine__31) = Machine.store!(machine1, cmd, (o + 4), y0, 4)
		(machine3, machine__32) = Machine.store!(machine2, cmd, (o + 8), x1, 4)
		(machine4, machine__33) = Machine.store!(machine3, cmd, (o + 12), y1, 4)
		(machine5, machine__34) = Machine.store!(machine4, cmd, (o + 16), x2, 4)
		(machine6, machine__35) = Machine.store!(machine5, cmd, (o + 20), y2, 4)
		(machine7, machine__36) = Machine.store!(machine6, cmd, (o + 24), c0, 4)
		(machine8, machine__37) = Machine.store!(machine7, cmd, (o + 28), c1, 4)
		(machine9, machine__38) = Machine.store!(machine8, cmd, (o + 32), c2, 4)
		(machine10, machine__39) = Machine.store!(machine9, cmd, (o + 36), d, 4)
		(machine11, machine__40) = Machine.store!(machine10, cmd, (o + 40), d, 4)
		(machine12, machine__41) = Machine.store!(machine11, cmd, (o + 44), d, 4)
		(machine13, machine__42) = Machine.store!(machine12, cmd, (o + 48), 1, 4)
		(machine14, machine__43) = Machine.store!(machine13, cmd, (o + 52), 0, 4)
		(machine15, machine__44) = Machine.store!(machine14, cmd, (o + 56), 0, 4)
		(machine16, machine__45) = Machine.store!(machine15, cmd, (o + 60), 0, 4)
		(machine17, machine__46) = Machine.store!(machine16, cmd, (o + 64), 0, 4)
		(machine18, machine__47) = Machine.store!(machine17, cmd, (o + 68), 0, 4)
		(machine18, bump((((((((((((((((((machine__30 + machine__31) + machine__32) + machine__33) + machine__34) + machine__35) + machine__36) + machine__37) + machine__38) + machine__39) + machine__40) + machine__41) + machine__42) + machine__43) + machine__44) + machine__45) + machine__46) + machine__47), (idx + 1)))
	})
})
	(machine19, machine__48)
})

put_rect_add! : Machine.Machine, I64, I64, I64, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
put_rect_add! = |machine, cmd, idx, x, y, w, h, col, d| (if (idx >= max_tri) { (machine, idx) } else { ({
	(machine1, machine__49) = put_tri3_add!(machine, cmd, idx, x, y, x, (y + h), (x + w), y, col, col, col, d)
	put_tri3_add!(machine1, cmd, machine__49, (x + w), y, x, (y + h), (x + w), (y + h), col, col, col, d)
}) })

put_tri3_soft! : Machine.Machine, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
put_tri3_soft! = |machine, cmd, idx, x0, y0, x1, y1, x2, y2, col, cx, cy, r| ({
	(machine19, machine__68) = ({
	o = (idx * 72)
	({
		(machine1, machine__50) = Machine.store!(machine, cmd, o, x0, 4)
		(machine2, machine__51) = Machine.store!(machine1, cmd, (o + 4), y0, 4)
		(machine3, machine__52) = Machine.store!(machine2, cmd, (o + 8), x1, 4)
		(machine4, machine__53) = Machine.store!(machine3, cmd, (o + 12), y1, 4)
		(machine5, machine__54) = Machine.store!(machine4, cmd, (o + 16), x2, 4)
		(machine6, machine__55) = Machine.store!(machine5, cmd, (o + 20), y2, 4)
		(machine7, machine__56) = Machine.store!(machine6, cmd, (o + 24), col, 4)
		(machine8, machine__57) = Machine.store!(machine7, cmd, (o + 28), col, 4)
		(machine9, machine__58) = Machine.store!(machine8, cmd, (o + 32), col, 4)
		(machine10, machine__59) = Machine.store!(machine9, cmd, (o + 36), 300, 4)
		(machine11, machine__60) = Machine.store!(machine10, cmd, (o + 40), 300, 4)
		(machine12, machine__61) = Machine.store!(machine11, cmd, (o + 44), 300, 4)
		(machine13, machine__62) = Machine.store!(machine12, cmd, (o + 48), 2, 4)
		(machine14, machine__63) = Machine.store!(machine13, cmd, (o + 52), 0, 4)
		(machine15, machine__64) = Machine.store!(machine14, cmd, (o + 56), cx, 4)
		(machine16, machine__65) = Machine.store!(machine15, cmd, (o + 60), cy, 4)
		(machine17, machine__66) = Machine.store!(machine16, cmd, (o + 64), r, 4)
		(machine18, machine__67) = Machine.store!(machine17, cmd, (o + 68), 0, 4)
		(machine18, bump((((((((((((((((((machine__50 + machine__51) + machine__52) + machine__53) + machine__54) + machine__55) + machine__56) + machine__57) + machine__58) + machine__59) + machine__60) + machine__61) + machine__62) + machine__63) + machine__64) + machine__65) + machine__66) + machine__67), (idx + 1)))
	})
})
	(machine19, machine__68)
})

put_sprite! : Machine.Machine, I64, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
put_sprite! = |machine, cmd, idx, sx, sy, r, col| (if (idx >= max_tri) { (machine, idx) } else { ({
	x0 = (sx - r)
	y0 = (sy - r)
	x1 = (sx + r)
	y1 = (sy + r)
	({
		(machine1, machine__69) = put_tri3_soft!(machine, cmd, idx, x0, y0, x0, y1, x1, y0, col, sx, sy, r)
		put_tri3_soft!(machine1, cmd, machine__69, x1, y0, x0, y1, x1, y1, col, sx, sy, r)
	})
}) })

draw_sky! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
draw_sky! = |machine, cmd, idx| put_quad_c!(machine, cmd, idx, 0, 0, sw, horizon, sky_top, sky_horizon, 9000)

draw_water! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
draw_water! = |machine, cmd, idx| put_quad_c!(machine, cmd, idx, 0, horizon, sw, (sh - horizon), water_top, water_bottom, 8600)

hsh : I64 -> I64
hsh = |n| I64.bitwise_and(I64.shr_zf_wrap(I64.plus_wrap(I64.times_wrap(n, 1103515245), 12345), I64.to_u8_wrap(16)), 1023)

draw_city! : Machine.Machine, I64, I64, I64, I64 => (Machine.Machine, I64)
draw_city! = |machine, cmd, idx, bx, seed| (if (bx >= sw) { (machine, idx) } else { (if (idx >= max_tri) { (machine, idx) } else { ({
	bw = (44 + I64.div_trunc_by((hsh((bx + seed)) * 46), 1024))
	bh = (90 + I64.div_trunc_by((hsh((((bx * 3) + seed) + 11)) * 340), 1024))
	top = (horizon - bh)
	cols = I64.div_trunc_by((bw - 12), 12)
	rows = I64.div_trunc_by((bh - 18), 14)
	({
		(machine1, machine__70) = put_rect!(machine, cmd, idx, bx, top, bw, bh, building_col, 700)
		(machine2, machine__71) = draw_windows!(machine1, cmd, machine__70, bx, top, bw, bh, (bx + seed), 0, cols, rows)
		draw_city!(machine2, cmd, machine__71, ((bx + bw) + 7), seed)
	})
}) }) })

draw_windows! : Machine.Machine, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
draw_windows! = |machine, cmd, idx, bx, top, bw, bh, seed, k, cols, rows| (if (cols <= 0) { (machine, idx) } else { (if (rows <= 0) { (machine, idx) } else { (if (k >= (cols * rows)) { (machine, idx) } else { (if (idx >= max_tri) { (machine, idx) } else { ({
	cc = (k - (I64.div_trunc_by(k, cols) * cols))
	rr = I64.div_trunc_by(k, cols)
	lit = I64.bitwise_and(hsh(((bx + (k * 31)) + seed)), 7)
	(if (lit >= 3) { draw_windows!(machine, cmd, idx, bx, top, bw, bh, seed, (k + 1), cols, rows) } else { ({
		wx = ((bx + 6) + (cc * 12))
		wy = ((top + 10) + (rr * 14))
		wcol = (if (I64.bitwise_and(hsh(((bx + (k * 7)) + seed)), 1) == 0) { 16765040 } else { 12572927 })
		({
			(machine1, machine__72) = put_rect!(machine, cmd, idx, wx, wy, 6, 8, wcol, 650)
			draw_windows!(machine1, cmd, machine__72, bx, top, bw, bh, seed, (k + 1), cols, rows)
		})
	}) })
}) }) }) }) })

draw_skyline! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
draw_skyline! = |machine, cmd, idx, city| (if (city == 0) { draw_nyc!(machine, cmd, idx) } else { (if (city == 1) { draw_chicago!(machine, cmd, idx) } else { (if (city == 2) { draw_sf!(machine, cmd, idx) } else { (if (city == 3) { draw_seattle!(machine, cmd, idx) } else { draw_dc!(machine, cmd, idx) }) }) }) })

draw_nyc! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
draw_nyc! = |machine, cmd, idx| ({
	(machine1, machine__73) = draw_city!(machine, cmd, idx, 0, 101)
	draw_empire!(machine1, cmd, machine__73, 512)
})

draw_empire! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
draw_empire! = |machine, cmd, idx, cx| ({
	(machine1, machine__74) = put_rect!(machine, cmd, idx, (cx - 60), (horizon - 300), 120, 300, landmark_col, 500)
	(machine2, machine__75) = put_rect!(machine1, cmd, machine__74, (cx - 44), (horizon - 372), 88, 72, landmark_col, 490)
	(machine3, machine__76) = put_rect!(machine2, cmd, machine__75, (cx - 28), (horizon - 430), 56, 58, landmark_col, 480)
	(machine4, machine__77) = put_rect!(machine3, cmd, machine__76, (cx - 8), (horizon - 500), 16, 70, landmark_col, 470)
	put_tri3!(machine4, cmd, machine__77, (cx - 5), (horizon - 500), (cx + 5), (horizon - 500), cx, (horizon - 542), antenna_col, antenna_col, antenna_col, 460)
})

draw_chicago! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
draw_chicago! = |machine, cmd, idx| ({
	(machine1, machine__78) = draw_city!(machine, cmd, idx, 0, 203)
	draw_willis!(machine1, cmd, machine__78, 512)
})

draw_willis! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
draw_willis! = |machine, cmd, idx, cx| ({
	(machine1, machine__79) = put_rect!(machine, cmd, idx, (cx - 80), (horizon - 300), 160, 300, landmark_col, 500)
	(machine2, machine__80) = put_rect!(machine1, cmd, machine__79, (cx - 80), (horizon - 372), 104, 72, landmark_col, 495)
	(machine3, machine__81) = put_rect!(machine2, cmd, machine__80, (cx - 40), (horizon - 420), 80, 48, landmark_col, 490)
	(machine4, machine__82) = put_rect!(machine3, cmd, machine__81, (cx - 30), (horizon - 470), 24, 50, landmark_col, 485)
	(machine5, machine__83) = put_rect!(machine4, cmd, machine__82, (cx + 6), (horizon - 470), 24, 50, landmark_col, 485)
	(machine6, machine__84) = put_rect!(machine5, cmd, machine__83, (cx - 20), (horizon - 512), 4, 42, antenna_col, 480)
	put_rect!(machine6, cmd, machine__84, (cx + 14), (horizon - 512), 4, 42, antenna_col, 480)
})

draw_sf! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
draw_sf! = |machine, cmd, idx| ({
	(machine1, machine__85) = draw_city!(machine, cmd, idx, 0, 307)
	(machine2, machine__86) = draw_transamerica!(machine1, cmd, machine__85, 800)
	draw_goldengate!(machine2, cmd, machine__86, 380, 644)
})

draw_transamerica! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
draw_transamerica! = |machine, cmd, idx, cx| ({
	(machine1, machine__87) = put_rect!(machine, cmd, idx, (cx - 6), (horizon - 120), 12, 120, trans_col, 505)
	put_tri3!(machine1, cmd, machine__87, (cx - 30), (horizon - 120), (cx + 30), (horizon - 120), cx, (horizon - 400), trans_col, trans_col, trans_col, 505)
})

draw_goldengate! : Machine.Machine, I64, I64, I64, I64 => (Machine.Machine, I64)
draw_goldengate! = |machine, cmd, idx, lx, rx| ({
	ttop = (horizon - 340)
	({
		(machine1, machine__88) = put_rect!(machine, cmd, idx, (lx - 12), ttop, 24, (horizon - ttop), gg_orange, 450)
		(machine2, machine__89) = put_rect!(machine1, cmd, machine__88, (rx - 12), ttop, 24, (horizon - ttop), gg_orange, 450)
		(machine3, machine__90) = put_rect!(machine2, cmd, machine__89, (lx - 12), (ttop + 40), 24, 14, gg_orange, 445)
		(machine4, machine__91) = put_rect!(machine3, cmd, machine__90, (rx - 12), (ttop + 40), 24, 14, gg_orange, 445)
		(machine5, machine__92) = put_rect!(machine4, cmd, machine__91, lx, (horizon - 150), (rx - lx), 8, gg_orange, 448)
		draw_cable!(machine5, cmd, machine__92, lx, ttop, (rx - lx), 130, 0)
	})
})

draw_cable! : Machine.Machine, I64, I64, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
draw_cable! = |machine, cmd, idx, x0, topy, span, sag, i| (if (i > 24) { (machine, idx) } else { ({
	u = ((i * 2) - 24)
	px = (x0 + I64.div_trunc_by((i * span), 24))
	yy = ((topy + sag) - I64.div_trunc_by(((sag * u) * u), 576))
	({
		(machine1, machine__93) = put_rect!(machine, cmd, idx, (px - 1), yy, 3, 3, gg_cable, 440)
		draw_cable!(machine1, cmd, machine__93, x0, topy, span, sag, (i + 1))
	})
}) })

draw_seattle! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
draw_seattle! = |machine, cmd, idx| ({
	(machine1, machine__94) = draw_city!(machine, cmd, idx, 0, 411)
	draw_needle!(machine1, cmd, machine__94, 512)
})

draw_needle! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
draw_needle! = |machine, cmd, idx, cx| ({
	(machine1, machine__95) = put_tri3!(machine, cmd, idx, (cx - 60), horizon, (cx - 30), horizon, (cx - 6), (horizon - 280), needle_col, needle_col, needle_col, 500)
	(machine2, machine__96) = put_tri3!(machine1, cmd, machine__95, (cx + 30), horizon, (cx + 60), horizon, (cx + 6), (horizon - 280), needle_col, needle_col, needle_col, 500)
	(machine3, machine__97) = put_rect!(machine2, cmd, machine__96, (cx - 6), (horizon - 280), 12, 280, needle_col, 498)
	(machine4, machine__98) = put_rect!(machine3, cmd, machine__97, (cx - 48), (horizon - 306), 96, 20, needle_col, 490)
	(machine5, machine__99) = put_tri3!(machine4, cmd, machine__98, (cx + 48), (horizon - 286), (cx - 48), (horizon - 286), cx, (horizon - 274), needle_col, needle_col, needle_col, 490)
	(machine6, machine__100) = put_rect!(machine5, cmd, machine__99, (cx - 4), (horizon - 344), 8, 38, needle_col, 488)
	put_tri3!(machine6, cmd, machine__100, (cx - 4), (horizon - 344), (cx + 4), (horizon - 344), cx, (horizon - 362), antenna_col, antenna_col, antenna_col, 486)
})

draw_dc! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
draw_dc! = |machine, cmd, idx| ({
	(machine1, machine__101) = draw_city!(machine, cmd, idx, 0, 523)
	(machine2, machine__102) = draw_monument!(machine1, cmd, machine__101, 400)
	draw_capitol!(machine2, cmd, machine__102, 660)
})

draw_monument! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
draw_monument! = |machine, cmd, idx, cx| ({
	(machine1, machine__103) = put_rect!(machine, cmd, idx, (cx - 13), (horizon - 430), 26, 430, monument_col, 500)
	put_tri3!(machine1, cmd, machine__103, (cx - 13), (horizon - 430), (cx + 13), (horizon - 430), cx, (horizon - 462), monument_col, monument_col, monument_col, 498)
})

draw_capitol! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
draw_capitol! = |machine, cmd, idx, cx| ({
	(machine1, machine__104) = put_rect!(machine, cmd, idx, (cx - 90), (horizon - 70), 180, 70, dome_col, 500)
	(machine2, machine__105) = put_rect!(machine1, cmd, machine__104, (cx - 52), (horizon - 112), 104, 42, dome_col, 498)
	(machine3, machine__106) = put_rect!(machine2, cmd, machine__105, (cx - 34), (horizon - 150), 68, 38, dome_col, 496)
	(machine4, machine__107) = put_tri3!(machine3, cmd, machine__106, (cx - 34), (horizon - 150), (cx + 34), (horizon - 150), cx, (horizon - 188), dome_col, dome_col, dome_col, 494)
	put_rect!(machine4, cmd, machine__107, (cx - 2), (horizon - 204), 4, 16, dome_col, 492)
})

g_a : I64
g_a = 11245

g_c : I64
g_c = 14627

g_d : I64
g_d = 27502

g_e : I64
g_e = 31143

g_f : I64
g_f = 31140

g_g : I64
g_g = 14699

g_h : I64
g_h = 23533

g_i : I64
g_i = 29847

g_k : I64
g_k = 23469

g_l : I64
g_l = 18727

g_n : I64
g_n = 24573

g_o : I64
g_o = 11114

g_r : I64
g_r = 27565

g_s : I64
g_s = 14478

g_t : I64
g_t = 29842

g_u : I64
g_u = 23407

g_w : I64
g_w = 23549

g_y : I64
g_y = 23186

g_d0 : I64
g_d0 = 31599

g_d1 : I64
g_d1 = 11415

g_d2 : I64
g_d2 = 29671

g_d5 : I64
g_d5 = 31183

g_d6 : I64
g_d6 = 31215

g_d7 : I64
g_d7 = 29330

g_m : I64
g_m = 24557

g_p : I64
g_p = 27556

g_b : I64
g_b = 27566

g_bang : I64
g_bang = 9346

g_dash : I64
g_dash = 448

g_dot : I64
g_dot = 128

draw_glyph! : Machine.Machine, I64, I64, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
draw_glyph! = |machine, cmd, idx, x, y, sz, col, bits| draw_glyph_px!(machine, cmd, idx, x, y, sz, col, bits, 0)

draw_glyph_px! : Machine.Machine, I64, I64, I64, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
draw_glyph_px! = |machine, cmd, idx, x, y, sz, col, bits, i| (if (i >= 15) { (machine, idx) } else { ({
	row = I64.div_trunc_by(i, 3)
	cp = (i - (row * 3))
	mask = I64.shl_wrap(1, I64.to_u8_wrap((14 - i)))
	(if (I64.bitwise_and(bits, mask) == 0) { draw_glyph_px!(machine, cmd, idx, x, y, sz, col, bits, (i + 1)) } else { ({
		(machine1, machine__108) = put_rect!(machine, cmd, idx, (x + (cp * sz)), (y + (row * sz)), sz, sz, col, 150)
		draw_glyph_px!(machine1, cmd, machine__108, x, y, sz, col, bits, (i + 1))
	}) })
}) })

gc! : Machine.Machine, I64, I64, I64, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
gc! = |machine, cmd, idx, x0, y, sz, col, k, bits| draw_glyph!(machine, cmd, idx, (x0 + ((k * sz) * 4)), y, sz, col, bits)

banner_col : I64
banner_col = 16764968

name_col : I64
name_col = 16777215

seahawks_col : I64
seahawks_col = 6929960

band_y : I64
band_y = 36

name_y : I64
name_y = 84

txt_sz : I64
txt_sz = 5

draw_banner! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
draw_banner! = |machine, cmd, idx| ({
	x0 = 322
	b = band_y
	s = txt_sz
	({
		(machine1, machine__109) = gc!(machine, cmd, idx, x0, b, s, banner_col, 0, g_u)
		(machine2, machine__110) = gc!(machine1, cmd, machine__109, x0, b, s, banner_col, 1, g_s)
		(machine3, machine__111) = gc!(machine2, cmd, machine__110, x0, b, s, banner_col, 2, g_a)
		(machine4, machine__112) = gc!(machine3, cmd, machine__111, x0, b, s, banner_col, 4, g_d2)
		(machine5, machine__113) = gc!(machine4, cmd, machine__112, x0, b, s, banner_col, 5, g_d5)
		(machine6, machine__114) = gc!(machine5, cmd, machine__113, x0, b, s, banner_col, 6, g_d0)
		(machine7, machine__115) = gc!(machine6, cmd, machine__114, x0, b, s, banner_col, 8, g_dot)
		(machine8, machine__116) = gc!(machine7, cmd, machine__115, x0, b, s, banner_col, 10, g_d1)
		(machine9, machine__117) = gc!(machine8, cmd, machine__116, x0, b, s, banner_col, 11, g_d7)
		(machine10, machine__118) = gc!(machine9, cmd, machine__117, x0, b, s, banner_col, 12, g_d7)
		(machine11, machine__119) = gc!(machine10, cmd, machine__118, x0, b, s, banner_col, 13, g_d6)
		(machine12, machine__120) = gc!(machine11, cmd, machine__119, x0, b, s, banner_col, 14, g_dash)
		(machine13, machine__121) = gc!(machine12, cmd, machine__120, x0, b, s, banner_col, 15, g_d2)
		(machine14, machine__122) = gc!(machine13, cmd, machine__121, x0, b, s, banner_col, 16, g_d0)
		(machine15, machine__123) = gc!(machine14, cmd, machine__122, x0, b, s, banner_col, 17, g_d2)
		gc!(machine15, cmd, machine__123, x0, b, s, banner_col, 18, g_d6)
	})
})

draw_city_name! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
draw_city_name! = |machine, cmd, idx, city| (if (city == 0) { draw_name_nyc!(machine, cmd, idx) } else { (if (city == 1) { draw_name_chicago!(machine, cmd, idx) } else { (if (city == 2) { draw_name_sf!(machine, cmd, idx) } else { (if (city == 3) { draw_name_seattle!(machine, cmd, idx) } else { draw_name_dc!(machine, cmd, idx) }) }) }) })

draw_name_nyc! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
draw_name_nyc! = |machine, cmd, idx| ({
	x0 = 432
	y = name_y
	s = txt_sz
	({
		(machine1, machine__124) = gc!(machine, cmd, idx, x0, y, s, name_col, 0, g_n)
		(machine2, machine__125) = gc!(machine1, cmd, machine__124, x0, y, s, name_col, 1, g_e)
		(machine3, machine__126) = gc!(machine2, cmd, machine__125, x0, y, s, name_col, 2, g_w)
		(machine4, machine__127) = gc!(machine3, cmd, machine__126, x0, y, s, name_col, 4, g_y)
		(machine5, machine__128) = gc!(machine4, cmd, machine__127, x0, y, s, name_col, 5, g_o)
		(machine6, machine__129) = gc!(machine5, cmd, machine__128, x0, y, s, name_col, 6, g_r)
		gc!(machine6, cmd, machine__129, x0, y, s, name_col, 7, g_k)
	})
})

draw_name_chicago! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
draw_name_chicago! = |machine, cmd, idx| ({
	x0 = 442
	y = name_y
	s = txt_sz
	({
		(machine1, machine__130) = gc!(machine, cmd, idx, x0, y, s, name_col, 0, g_c)
		(machine2, machine__131) = gc!(machine1, cmd, machine__130, x0, y, s, name_col, 1, g_h)
		(machine3, machine__132) = gc!(machine2, cmd, machine__131, x0, y, s, name_col, 2, g_i)
		(machine4, machine__133) = gc!(machine3, cmd, machine__132, x0, y, s, name_col, 3, g_c)
		(machine5, machine__134) = gc!(machine4, cmd, machine__133, x0, y, s, name_col, 4, g_a)
		(machine6, machine__135) = gc!(machine5, cmd, machine__134, x0, y, s, name_col, 5, g_g)
		gc!(machine6, cmd, machine__135, x0, y, s, name_col, 6, g_o)
	})
})

draw_name_sf! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
draw_name_sf! = |machine, cmd, idx| ({
	x0 = 382
	y = name_y
	s = txt_sz
	({
		(machine1, machine__136) = gc!(machine, cmd, idx, x0, y, s, name_col, 0, g_s)
		(machine2, machine__137) = gc!(machine1, cmd, machine__136, x0, y, s, name_col, 1, g_a)
		(machine3, machine__138) = gc!(machine2, cmd, machine__137, x0, y, s, name_col, 2, g_n)
		(machine4, machine__139) = gc!(machine3, cmd, machine__138, x0, y, s, name_col, 4, g_f)
		(machine5, machine__140) = gc!(machine4, cmd, machine__139, x0, y, s, name_col, 5, g_r)
		(machine6, machine__141) = gc!(machine5, cmd, machine__140, x0, y, s, name_col, 6, g_a)
		(machine7, machine__142) = gc!(machine6, cmd, machine__141, x0, y, s, name_col, 7, g_n)
		(machine8, machine__143) = gc!(machine7, cmd, machine__142, x0, y, s, name_col, 8, g_c)
		(machine9, machine__144) = gc!(machine8, cmd, machine__143, x0, y, s, name_col, 9, g_i)
		(machine10, machine__145) = gc!(machine9, cmd, machine__144, x0, y, s, name_col, 10, g_s)
		(machine11, machine__146) = gc!(machine10, cmd, machine__145, x0, y, s, name_col, 11, g_c)
		gc!(machine11, cmd, machine__146, x0, y, s, name_col, 12, g_o)
	})
})

draw_name_seattle! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
draw_name_seattle! = |machine, cmd, idx| ({
	x0 = 442
	y = name_y
	s = txt_sz
	({
		(machine1, machine__147) = gc!(machine, cmd, idx, x0, y, s, name_col, 0, g_s)
		(machine2, machine__148) = gc!(machine1, cmd, machine__147, x0, y, s, name_col, 1, g_e)
		(machine3, machine__149) = gc!(machine2, cmd, machine__148, x0, y, s, name_col, 2, g_a)
		(machine4, machine__150) = gc!(machine3, cmd, machine__149, x0, y, s, name_col, 3, g_t)
		(machine5, machine__151) = gc!(machine4, cmd, machine__150, x0, y, s, name_col, 4, g_t)
		(machine6, machine__152) = gc!(machine5, cmd, machine__151, x0, y, s, name_col, 5, g_l)
		(machine7, machine__153) = gc!(machine6, cmd, machine__152, x0, y, s, name_col, 6, g_e)
		draw_seahawks_line!(machine7, cmd, machine__153)
	})
})

draw_seahawks_line! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
draw_seahawks_line! = |machine, cmd, idx| ({
	x0 = 218
	y = 118
	s = 3
	c = seahawks_col
	({
		(machine1, machine__154) = gc!(machine, cmd, idx, x0, y, s, c, 0, g_h)
		(machine2, machine__155) = gc!(machine1, cmd, machine__154, x0, y, s, c, 1, g_o)
		(machine3, machine__156) = gc!(machine2, cmd, machine__155, x0, y, s, c, 2, g_m)
		(machine4, machine__157) = gc!(machine3, cmd, machine__156, x0, y, s, c, 3, g_e)
		(machine5, machine__158) = gc!(machine4, cmd, machine__157, x0, y, s, c, 5, g_o)
		(machine6, machine__159) = gc!(machine5, cmd, machine__158, x0, y, s, c, 6, g_f)
		(machine7, machine__160) = gc!(machine6, cmd, machine__159, x0, y, s, c, 8, g_t)
		(machine8, machine__161) = gc!(machine7, cmd, machine__160, x0, y, s, c, 9, g_h)
		(machine9, machine__162) = gc!(machine8, cmd, machine__161, x0, y, s, c, 10, g_e)
		(machine10, machine__163) = gc!(machine9, cmd, machine__162, x0, y, s, c, 12, g_r)
		(machine11, machine__164) = gc!(machine10, cmd, machine__163, x0, y, s, c, 13, g_e)
		(machine12, machine__165) = gc!(machine11, cmd, machine__164, x0, y, s, c, 14, g_i)
		(machine13, machine__166) = gc!(machine12, cmd, machine__165, x0, y, s, c, 15, g_g)
		(machine14, machine__167) = gc!(machine13, cmd, machine__166, x0, y, s, c, 16, g_n)
		(machine15, machine__168) = gc!(machine14, cmd, machine__167, x0, y, s, c, 17, g_i)
		(machine16, machine__169) = gc!(machine15, cmd, machine__168, x0, y, s, c, 18, g_n)
		(machine17, machine__170) = gc!(machine16, cmd, machine__169, x0, y, s, c, 19, g_g)
		(machine18, machine__171) = gc!(machine17, cmd, machine__170, x0, y, s, c, 21, g_s)
		(machine19, machine__172) = gc!(machine18, cmd, machine__171, x0, y, s, c, 22, g_u)
		(machine20, machine__173) = gc!(machine19, cmd, machine__172, x0, y, s, c, 23, g_p)
		(machine21, machine__174) = gc!(machine20, cmd, machine__173, x0, y, s, c, 24, g_e)
		(machine22, machine__175) = gc!(machine21, cmd, machine__174, x0, y, s, c, 25, g_r)
		(machine23, machine__176) = gc!(machine22, cmd, machine__175, x0, y, s, c, 26, g_b)
		(machine24, machine__177) = gc!(machine23, cmd, machine__176, x0, y, s, c, 27, g_o)
		(machine25, machine__178) = gc!(machine24, cmd, machine__177, x0, y, s, c, 28, g_w)
		(machine26, machine__179) = gc!(machine25, cmd, machine__178, x0, y, s, c, 29, g_l)
		(machine27, machine__180) = gc!(machine26, cmd, machine__179, x0, y, s, c, 31, g_c)
		(machine28, machine__181) = gc!(machine27, cmd, machine__180, x0, y, s, c, 32, g_h)
		(machine29, machine__182) = gc!(machine28, cmd, machine__181, x0, y, s, c, 33, g_a)
		(machine30, machine__183) = gc!(machine29, cmd, machine__182, x0, y, s, c, 34, g_m)
		(machine31, machine__184) = gc!(machine30, cmd, machine__183, x0, y, s, c, 35, g_p)
		(machine32, machine__185) = gc!(machine31, cmd, machine__184, x0, y, s, c, 36, g_i)
		(machine33, machine__186) = gc!(machine32, cmd, machine__185, x0, y, s, c, 37, g_o)
		(machine34, machine__187) = gc!(machine33, cmd, machine__186, x0, y, s, c, 38, g_n)
		(machine35, machine__188) = gc!(machine34, cmd, machine__187, x0, y, s, c, 40, g_s)
		(machine36, machine__189) = gc!(machine35, cmd, machine__188, x0, y, s, c, 41, g_e)
		(machine37, machine__190) = gc!(machine36, cmd, machine__189, x0, y, s, c, 42, g_a)
		(machine38, machine__191) = gc!(machine37, cmd, machine__190, x0, y, s, c, 43, g_h)
		(machine39, machine__192) = gc!(machine38, cmd, machine__191, x0, y, s, c, 44, g_a)
		(machine40, machine__193) = gc!(machine39, cmd, machine__192, x0, y, s, c, 45, g_w)
		(machine41, machine__194) = gc!(machine40, cmd, machine__193, x0, y, s, c, 46, g_k)
		(machine42, machine__195) = gc!(machine41, cmd, machine__194, x0, y, s, c, 47, g_s)
		gc!(machine42, cmd, machine__195, x0, y, s, c, 48, g_bang)
	})
})

draw_name_dc! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
draw_name_dc! = |machine, cmd, idx| ({
	x0 = 382
	y = name_y
	s = txt_sz
	({
		(machine1, machine__196) = gc!(machine, cmd, idx, x0, y, s, name_col, 0, g_w)
		(machine2, machine__197) = gc!(machine1, cmd, machine__196, x0, y, s, name_col, 1, g_a)
		(machine3, machine__198) = gc!(machine2, cmd, machine__197, x0, y, s, name_col, 2, g_s)
		(machine4, machine__199) = gc!(machine3, cmd, machine__198, x0, y, s, name_col, 3, g_h)
		(machine5, machine__200) = gc!(machine4, cmd, machine__199, x0, y, s, name_col, 4, g_i)
		(machine6, machine__201) = gc!(machine5, cmd, machine__200, x0, y, s, name_col, 5, g_n)
		(machine7, machine__202) = gc!(machine6, cmd, machine__201, x0, y, s, name_col, 6, g_g)
		(machine8, machine__203) = gc!(machine7, cmd, machine__202, x0, y, s, name_col, 7, g_t)
		(machine9, machine__204) = gc!(machine8, cmd, machine__203, x0, y, s, name_col, 8, g_o)
		(machine10, machine__205) = gc!(machine9, cmd, machine__204, x0, y, s, name_col, 9, g_n)
		(machine11, machine__206) = gc!(machine10, cmd, machine__205, x0, y, s, name_col, 11, g_d)
		gc!(machine11, cmd, machine__206, x0, y, s, name_col, 12, g_c)
	})
})

md : I64, I64 -> I64
md = |a, n| (a - (I64.div_trunc_by(a, n) * n))

rnd : I64 -> I64
rnd = |n| ({
	a = I64.plus_wrap(I64.times_wrap(n, 374761393), 668265263)
	b = I64.bitwise_xor(a, I64.shr_zf_wrap(a, I64.to_u8_wrap(13)))
	c = Wrap64.w64_mul(b, 1274126177)
	I64.bitwise_and(I64.bitwise_xor(c, I64.shr_zf_wrap(c, I64.to_u8_wrap(16))), 16777215)
})

write_particle! : Machine.Machine, I64, I64, I64, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
write_particle! = |machine, slot, px, py, vx, vy, life, col, kind| ({
	(machine9, machine__207) = ({
	o = (slot * part_stride)
	(machine1, _a) = Machine.store!(machine, part_base, (o + f_px), px, 4)
	(machine2, _b) = Machine.store!(machine1, part_base, (o + f_py), py, 4)
	(machine3, _c) = Machine.store!(machine2, part_base, (o + f_vx), vx, 4)
	(machine4, _d) = Machine.store!(machine3, part_base, (o + f_vy), vy, 4)
	(machine5, _e) = Machine.store!(machine4, part_base, (o + f_life), life, 4)
	(machine6, _f) = Machine.store!(machine5, part_base, (o + f_max), life, 4)
	(machine7, _g) = Machine.store!(machine6, part_base, (o + f_col), col, 4)
	(machine8, _h) = Machine.store!(machine7, part_base, (o + f_kind), kind, 4)
	(machine8, slot)
})
	(machine9, machine__207)
})

clear_parts! : Machine.Machine, I64 => (Machine.Machine, I64)
clear_parts! = |machine, i| (if (i >= part_cap) { (machine, 0) } else { ({
	(machine1, _w) = Machine.store!(machine, part_base, ((i * part_stride) + f_kind), 0, 4)
	clear_parts!(machine1, (i + 1))
}) })

spawn_burst! : Machine.Machine, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
spawn_burst! = |machine, cx, cy, col, cursor, i| (if (i >= burst_count) { (machine, cursor) } else { ({
	jit = rnd(((cx + (cy * 3)) + (i * 2654435)))
	ang = (I64.div_trunc_by((i * 6283), burst_count) + I64.bitwise_and(jit, 63))
	spd = (240 + I64.bitwise_and(I64.shr_zf_wrap(jit, I64.to_u8_wrap(6)), 640))
	vx = I64.div_trunc_by((fw_cos(ang) * spd), 1000)
	vy = I64.div_trunc_by((fw_sin(ang) * spd), 1000)
	life = (40 + I64.bitwise_and(I64.shr_zf_wrap(jit, I64.to_u8_wrap(16)), 70))
	slot = md(cursor, part_cap)
	(machine1, _w) = write_particle!(machine, slot, cx, cy, vx, vy, life, col, 1)
	spawn_burst!(machine1, cx, cy, col, (cursor + 1), (i + 1))
}) })

maybe_launch! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
maybe_launch! = |machine, frame, cursor| ({
	(machine3, machine__209) = (if (md(frame, launch_every) != 0) { (machine, cursor) } else { ({
	(machine2, machine__208) = ({
	r = rnd(((frame * 17) + 3))
	lx = (70 + I64.div_trunc_by((I64.bitwise_and(r, 1023) * (sw - 140)), 1024))
	vy0 = (0 - (2280 + I64.bitwise_and(I64.shr_zf_wrap(r, I64.to_u8_wrap(10)), 300)))
	vx0 = ((I64.bitwise_and(I64.shr_zf_wrap(r, I64.to_u8_wrap(20)), 255) - 128) * 4)
	col = burst_color(I64.shr_zf_wrap(r, I64.to_u8_wrap(18)))
	slot = md(cursor, part_cap)
	(machine1, _w) = write_particle!(machine, slot, (lx * 256), ((horizon - 30) * 256), vx0, vy0, 240, col, 2)
	(machine1, (cursor + 1))
})
	(machine2, machine__208)
}) })
	(machine3, machine__209)
})

finale_launch! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
finale_launch! = |machine, frame, cursor, i| (if (i >= 3) { (machine, cursor) } else { ({
	r = rnd((((frame * 131) + (i * 977)) + 7))
	lx = (60 + I64.div_trunc_by((I64.bitwise_and(r, 1023) * (sw - 120)), 1024))
	vy0 = (0 - (2250 + I64.bitwise_and(I64.shr_zf_wrap(r, I64.to_u8_wrap(10)), 350)))
	vx0 = ((I64.bitwise_and(I64.shr_zf_wrap(r, I64.to_u8_wrap(20)), 255) - 128) * 5)
	col = burst_color(I64.shr_zf_wrap(r, I64.to_u8_wrap(18)))
	slot = md(cursor, part_cap)
	(machine1, _w) = write_particle!(machine, slot, (lx * 256), ((horizon - 20) * 256), vx0, vy0, 200, col, 2)
	finale_launch!(machine1, frame, (cursor + 1), (i + 1))
}) })

launch_frame! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
launch_frame! = |machine, frame, cursor| (if (is_finale(frame) >= 1) { finale_gate!(machine, frame, cursor) } else { maybe_launch!(machine, frame, cursor) })

finale_gate! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
finale_gate! = |machine, frame, cursor| (if (md(frame, 3) == 0) { finale_launch!(machine, frame, cursor, 0) } else { (machine, cursor) })

update_steps! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
update_steps! = |machine, cursor, n| (if (n <= 0) { (machine, cursor) } else { ({
	(machine1, machine__210) = update_all!(machine, 0, cursor)
	update_steps!(machine1, machine__210, (n - 1))
}) })

update_all! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
update_all! = |machine, i, cursor| (if (i >= part_cap) { (machine, cursor) } else { ({
	o = (i * part_stride)
	(machine1, kind) = Machine.load!(machine, part_base, (o + f_kind), 4)
	(if (kind == 0) { update_all!(machine1, (i + 1), cursor) } else { ({
		(machine2, life) = Machine.load!(machine1, part_base, (o + f_life), 4)
		(if (life <= 0) { ({
			(machine3, _k) = Machine.store!(machine2, part_base, (o + f_kind), 0, 4)
			update_all!(machine3, (i + 1), cursor)
		}) } else { ({
			(machine4, px) = Machine.load!(machine2, part_base, (o + f_px), 4)
			(machine5, py) = Machine.load!(machine4, part_base, (o + f_py), 4)
			(machine6, vx) = Machine.load!(machine5, part_base, (o + f_vx), 4)
			(machine7, vy) = Machine.load!(machine6, part_base, (o + f_vy), 4)
			vy2 = (vy + gravity)
			(machine8, _a) = Machine.store!(machine7, part_base, (o + f_px), (px + vx), 4)
			(machine9, _b) = Machine.store!(machine8, part_base, (o + f_py), (py + vy), 4)
			(machine10, _c) = Machine.store!(machine9, part_base, (o + f_vy), vy2, 4)
			(machine11, _d) = Machine.store!(machine10, part_base, (o + f_life), (life - 1), 4)
			(if (kind == 2) { (if (py <= (burst_alt * 256)) { ({
				(machine12, col) = Machine.load!(machine11, part_base, (o + f_col), 4)
				(machine13, _kill) = Machine.store!(machine12, part_base, (o + f_kind), 0, 4)
				(machine14, cur2) = spawn_burst!(machine13, (px + vx), (py + vy), col, cursor, 0)
				update_all!(machine14, (i + 1), cur2)
			}) } else { ({
				ts = md(cursor, part_cap)
				(machine15, _tw) = write_particle!(machine11, ts, (px + vx), (py + vy), I64.div_trunc_by(vx, 3), (I64.div_trunc_by(vy, 4) + 20), 14, 16762980, 1)
				update_all!(machine15, (i + 1), (cursor + 1))
			}) }) } else { update_all!(machine11, (i + 1), cursor) })
		}) })
	}) })
}) })

reflect_spark! : Machine.Machine, I64, I64, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
reflect_spark! = |machine, cmd, idx, sx, ry, sz, base, fade| (if (ry <= horizon) { (machine, idx) } else { (if (ry >= sh) { (machine, idx) } else { put_rect_add!(machine, cmd, idx, (sx - sz), (ry - sz), (sz * 2), (sz * 2), scale_col(base, I64.div_trunc_by(fade, 3)), 2000) }) })

scale_col : I64, I64 -> I64
scale_col = |packed, f| ({
	r = I64.bitwise_and(I64.shr_zf_wrap(packed, I64.to_u8_wrap(16)), 255)
	g = I64.bitwise_and(I64.shr_zf_wrap(packed, I64.to_u8_wrap(8)), 255)
	b = I64.bitwise_and(packed, 255)
	I64.bitwise_or(I64.shl_wrap(I64.div_trunc_by((r * f), 1000), I64.to_u8_wrap(16)), I64.bitwise_or(I64.shl_wrap(I64.div_trunc_by((g * f), 1000), I64.to_u8_wrap(8)), I64.div_trunc_by((b * f), 1000)))
})

draw_particles! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
draw_particles! = |machine, cmd, idx, i| (if (i >= part_cap) { (machine, idx) } else { (if (idx >= max_tri) { (machine, idx) } else { ({
	o = (i * part_stride)
	(machine1, kind) = Machine.load!(machine, part_base, (o + f_kind), 4)
	(if (kind == 0) { draw_particles!(machine1, cmd, idx, (i + 1)) } else { ({
		(machine2, life) = Machine.load!(machine1, part_base, (o + f_life), 4)
		(machine3, maxl) = Machine.load!(machine2, part_base, (o + f_max), 4)
		(machine4, machine__211) = Machine.load!(machine3, part_base, (o + f_px), 4)
		sx = I64.div_trunc_by(machine__211, 256)
		(machine5, machine__212) = Machine.load!(machine4, part_base, (o + f_py), 4)
		sy = I64.div_trunc_by(machine__212, 256)
		fade = (if (maxl <= 0) { 0 } else { I64.div_trunc_by((life * 1000), maxl) })
		(machine6, base) = Machine.load!(machine5, part_base, (o + f_col), 4)
		(if (kind == 2) { ({
			(machine7, machine__213) = put_rect_add!(machine6, cmd, idx, (sx - 3), (sy - 3), 6, 6, shell_col, 300)
			draw_particles!(machine7, cmd, machine__213, (i + 1))
		}) } else { ({
			col = scale_col(base, fade)
			sz = (if (fade > 600) { 3 } else { 2 })
			ry = ((2 * horizon) - sy)
			({
				(machine8, machine__214) = put_rect_add!(machine6, cmd, idx, (sx - sz), (sy - sz), (sz * 2), (sz * 2), col, 300)
				(machine9, machine__215) = reflect_spark!(machine8, cmd, machine__214, sx, ry, sz, base, fade)
				draw_particles!(machine9, cmd, machine__215, (i + 1))
			})
		}) })
	}) })
}) }) })

cool_col : I64, I64 -> I64
cool_col = |base, fade| (if (fade > 820) { 16774368 } else { (if (fade > 520) { base } else { scale_col(base, ((fade * 2) + 120)) }) })

draw_particles_soft! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
draw_particles_soft! = |machine, cmd, idx, i| (if (i >= part_cap) { (machine, idx) } else { (if (idx >= max_tri) { (machine, idx) } else { ({
	o = (i * part_stride)
	(machine1, kind) = Machine.load!(machine, part_base, (o + f_kind), 4)
	(if (kind == 0) { draw_particles_soft!(machine1, cmd, idx, (i + 1)) } else { ({
		(machine2, life) = Machine.load!(machine1, part_base, (o + f_life), 4)
		(machine3, maxl) = Machine.load!(machine2, part_base, (o + f_max), 4)
		(machine4, machine__216) = Machine.load!(machine3, part_base, (o + f_px), 4)
		sx = I64.div_trunc_by(machine__216, 256)
		(machine5, machine__217) = Machine.load!(machine4, part_base, (o + f_py), 4)
		sy = I64.div_trunc_by(machine__217, 256)
		fade = (if (maxl <= 0) { 0 } else { I64.div_trunc_by((life * 1000), maxl) })
		(machine6, base) = Machine.load!(machine5, part_base, (o + f_col), 4)
		(if (kind == 2) { ({
			(machine7, machine__218) = put_sprite!(machine6, cmd, idx, sx, sy, 5, shell_col)
			draw_particles_soft!(machine7, cmd, machine__218, (i + 1))
		}) } else { ({
			col = cool_col(base, fade)
			sz = (if (fade > 600) { 5 } else { 4 })
			({
				(machine8, machine__219) = put_sprite!(machine6, cmd, idx, sx, sy, sz, col)
				draw_particles_soft!(machine8, cmd, machine__219, (i + 1))
			})
		}) })
	}) })
}) }) })

is_finale : I64 -> I64
is_finale = |frame| (if (force_finale >= 1) { 1 } else { (if (md(frame, cycle_total) >= cycle_cities) { 1 } else { 0 }) })

scene_city : I64 -> I64
scene_city = |frame| (if (force_city >= 0) { force_city } else { md(I64.div_trunc_by(md(frame, cycle_total), frames_per_city), num_cities) })

render_scene! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
render_scene! = |machine, cmd, frame, mode| (if (mode == 1) { render_real!(machine, cmd, frame) } else { (if (is_finale(frame) >= 1) { render_finale!(machine, cmd, frame) } else { render_city_scene!(machine, cmd, frame) }) })

render_real! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
render_real! = |machine, cmd, frame| ({
	(machine1, machine__220) = draw_water!(machine, cmd, 0)
	(machine2, machine__221) = draw_skyline!(machine1, cmd, machine__220, scene_city(frame))
	draw_particles_soft!(machine2, cmd, machine__221, 0)
})

render_city_scene! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
render_city_scene! = |machine, cmd, frame| ({
	city = scene_city(frame)
	({
		(machine1, machine__222) = draw_sky!(machine, cmd, 0)
		(machine2, machine__223) = draw_water!(machine1, cmd, machine__222)
		(machine3, machine__224) = draw_skyline!(machine2, cmd, machine__223, city)
		(machine4, machine__225) = draw_particles!(machine3, cmd, machine__224, 0)
		(machine5, machine__226) = draw_banner!(machine4, cmd, machine__225)
		draw_city_name!(machine5, cmd, machine__226, city)
	})
})

render_finale! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
render_finale! = |machine, cmd, _frame| ({
	(machine1, machine__227) = draw_sky!(machine, cmd, 0)
	(machine2, machine__228) = draw_water!(machine1, cmd, machine__227)
	(machine3, machine__229) = draw_city!(machine2, cmd, machine__228, 0, 909)
	(machine4, machine__230) = draw_particles!(machine3, cmd, machine__229, 0)
	(machine5, machine__231) = draw_banner!(machine4, cmd, machine__230)
	draw_finale_text!(machine5, cmd, machine__231)
})

draw_finale_text! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
draw_finale_text! = |machine, cmd, idx| ({
	bx = 316
	by = 250
	bs = 14
	({
		(machine1, machine__232) = gc!(machine, cmd, idx, bx, by, bs, banner_col, 0, g_u)
		(machine2, machine__233) = gc!(machine1, cmd, machine__232, bx, by, bs, banner_col, 1, g_s)
		(machine3, machine__234) = gc!(machine2, cmd, machine__233, bx, by, bs, banner_col, 2, g_a)
		(machine4, machine__235) = gc!(machine3, cmd, machine__234, bx, by, bs, banner_col, 4, g_d2)
		(machine5, machine__236) = gc!(machine4, cmd, machine__235, bx, by, bs, banner_col, 5, g_d5)
		(machine6, machine__237) = gc!(machine5, cmd, machine__236, bx, by, bs, banner_col, 6, g_d0)
		draw_finale_sub!(machine6, cmd, machine__237)
	})
})

draw_finale_sub! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
draw_finale_sub! = |machine, cmd, idx| ({
	sx = 368
	sy = 470
	ss = 8
	({
		(machine1, machine__238) = gc!(machine, cmd, idx, sx, sy, ss, name_col, 0, g_d2)
		(machine2, machine__239) = gc!(machine1, cmd, machine__238, sx, sy, ss, name_col, 1, g_d5)
		(machine3, machine__240) = gc!(machine2, cmd, machine__239, sx, sy, ss, name_col, 2, g_d0)
		(machine4, machine__241) = gc!(machine3, cmd, machine__240, sx, sy, ss, name_col, 4, g_y)
		(machine5, machine__242) = gc!(machine4, cmd, machine__241, sx, sy, ss, name_col, 5, g_e)
		(machine6, machine__243) = gc!(machine5, cmd, machine__242, sx, sy, ss, name_col, 6, g_a)
		(machine7, machine__244) = gc!(machine6, cmd, machine__243, sx, sy, ss, name_col, 7, g_r)
		gc!(machine7, cmd, machine__244, sx, sy, ss, name_col, 8, g_s)
	})
})

seed_scene! : Machine.Machine, I64 => (Machine.Machine, I64)
seed_scene! = |machine, _dummy| ({
	(machine1, c0) = clear_parts!(machine, 0)
	(machine2, c1) = spawn_burst!(machine1, (300 * 256), (170 * 256), 16724772, c0, 0)
	spawn_burst!(machine2, (720 * 256), (150 * 256), 3828735, c1, 0)
})

flush_ret! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
flush_ret! = |machine, n, ret| ({
	(machine1, _f) = Machine.port_out_32!(machine, 1024, n)
	(machine1, ret)
})

clear_select! : Machine.Machine, I64 => (Machine.Machine, I64)
clear_select! = |machine, mode| (if (mode == 1) { Machine.port_out_32!(machine, 1038, fade_sky) } else { Machine.port_out_32!(machine, 1025, sky_top) })

clear_frame! : Machine.Machine, I64 => (Machine.Machine, I64)
clear_frame! = |machine, mode| ({
	(machine1, r) = clear_select!(machine, mode)
	(machine2, _d) = Machine.port_out_32!(machine1, 1026, 0)
	(machine2, r)
})

render_frame! : Machine.Machine, I64, I64, I64, I64 => (Machine.Machine, I64)
render_frame! = |machine, cmd, frame, cursor, mode| ({
	(machine1, _a) = clear_frame!(machine, mode)
	({
		(machine2, cur1) = launch_frame!(machine1, frame, cursor)
		(machine3, cur2) = update_steps!(machine2, cur1, sim_substeps)
		({
			(machine4, machine__245) = render_scene!(machine3, cmd, frame, mode)
			flush_ret!(machine4, machine__245, cur2)
		})
	})
})

edge_mode : I64, I64, I64 -> I64
edge_mode = |sc, prev, mode| (if (sc == KeyInput.key_f1) { (if (prev == KeyInput.key_f1) { mode } else { (1 - mode) }) } else { mode })

fw_loop! : Machine.Machine, I64, I64, I64, I64, I64 => (Machine.Machine, Str)
fw_loop! = |machine, cmd, frame, cursor, mode, prev| ({
	(machine1, sc) = KeyInput.poll_key!(machine)
	({
		(machine2, nc) = render_frame!(machine1, cmd, frame, cursor, edge_mode(sc, prev, mode))
		(match (KeyInput.key_upper(sc) == 63) {
			True => (machine2, "done")
			_ => fw_loop!(machine2, cmd, (frame + 1), nc, edge_mode(sc, prev, mode), sc)
		})
	})
})

fw_sin : I64 -> I64
fw_sin = |raw| ({
	a = fw_wrap(raw)
	(if (a <= 1570) { fw_sin_core(a) } else { (if (a <= 3141) { fw_sin_core((3141 - a)) } else { (if (a <= 4712) { (0 - fw_sin_core((a - 3141))) } else { (0 - fw_sin_core((6283 - a))) }) }) })
})

fw_cos : I64 -> I64
fw_cos = |raw| fw_sin((raw + 1570))

fw_sin_core : I64 -> I64
fw_sin_core = |x| ({
	x2 = I64.div_trunc_by((x * x), 1000)
	x3 = I64.div_trunc_by((x2 * x), 1000)
	x5 = I64.div_trunc_by((x3 * x2), 1000)
	((x - I64.div_trunc_by(x3, 6)) + I64.div_trunc_by(x5, 120))
})

fw_wrap : I64 -> I64
fw_wrap = |a| ({
	m = (a - (I64.div_trunc_by(a, 6283) * 6283))
	(if (m < 0) { (m + 6283) } else { m })
})

# --- Entry ---

main! = |args| {
	machine = Machine.boot!(args, ["Console", "Device.Port", "Gpu.Compute", "Gpu.Memory"])
	(machine1, machine__246) = Machine.port_out_32!(machine, 1040, 1)
	_con = machine__246
	(machine2, machine__247) = seed_scene!(machine1, 0)
	(machine3, machine__248) = fw_loop!(machine2, cmd_buf, 0, machine__247, 0, 0)
	result = machine__248
	line!(result)
	Machine.halt!(machine3)
	Ok({})
}
