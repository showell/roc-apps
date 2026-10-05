app [main!] { pf: platform "../../../../../../showell_repos/roc-apps/framebuffer/platform/main.roc" }

import pf.Echo

echo! = |msg| Echo.line!(msg)

# Fireworks -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceChar
import CceText
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
	m : I64
	m = (k - (I64.div_trunc_by(k, 6) * 6))
	(if (m == 0) { 16724772 } else { (if (m == 1) { 16777215 } else { (if (m == 2) { 3828735 } else { (if (m == 3) { 16764968 } else { (if (m == 4) { 4644976 } else { 12995583 }) }) }) }) })
})

bump : I64, I64 -> I64
bump = |_written, t| t

put_tri3! : Machine.Machine, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
put_tri3! = |machine, cmd, idx, x0, y0, x1, y1, x2, y2, c0, c1, c2, d| ({
	(machine19, machine__19) = ({
	o : I64
	o = (idx * 72)
	({
		(machine1, machine__1) = Machine.store!(machine, cmd, o, x0, 4)
		(machine2, machine__2) = Machine.store!(machine1, cmd, (o + 4), y0, 4)
		(machine3, machine__3) = Machine.store!(machine2, cmd, (o + 8), x1, 4)
		(machine4, machine__4) = Machine.store!(machine3, cmd, (o + 12), y1, 4)
		(machine5, machine__5) = Machine.store!(machine4, cmd, (o + 16), x2, 4)
		(machine6, machine__6) = Machine.store!(machine5, cmd, (o + 20), y2, 4)
		(machine7, machine__7) = Machine.store!(machine6, cmd, (o + 24), c0, 4)
		(machine8, machine__8) = Machine.store!(machine7, cmd, (o + 28), c1, 4)
		(machine9, machine__9) = Machine.store!(machine8, cmd, (o + 32), c2, 4)
		(machine10, machine__10) = Machine.store!(machine9, cmd, (o + 36), d, 4)
		(machine11, machine__11) = Machine.store!(machine10, cmd, (o + 40), d, 4)
		(machine12, machine__12) = Machine.store!(machine11, cmd, (o + 44), d, 4)
		(machine13, machine__13) = Machine.store!(machine12, cmd, (o + 48), 0, 4)
		(machine14, machine__14) = Machine.store!(machine13, cmd, (o + 52), 0, 4)
		(machine15, machine__15) = Machine.store!(machine14, cmd, (o + 56), 0, 4)
		(machine16, machine__16) = Machine.store!(machine15, cmd, (o + 60), 0, 4)
		(machine17, machine__17) = Machine.store!(machine16, cmd, (o + 64), 0, 4)
		(machine18, machine__18) = Machine.store!(machine17, cmd, (o + 68), 0, 4)
		(machine18, bump((((((((((((((((((machine__1 + machine__2) + machine__3) + machine__4) + machine__5) + machine__6) + machine__7) + machine__8) + machine__9) + machine__10) + machine__11) + machine__12) + machine__13) + machine__14) + machine__15) + machine__16) + machine__17) + machine__18), (idx + 1)))
	})
})
	(machine19, machine__19)
})

put_rect! : Machine.Machine, I64, I64, I64, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
put_rect! = |machine, cmd, idx, x, y, w, h, col, d| (if (idx >= max_tri) { (machine, idx) } else { ({
	(machine1, machine__1) = put_tri3!(machine, cmd, idx, x, y, x, (y + h), (x + w), y, col, col, col, d)
	put_tri3!(machine1, cmd, machine__1, (x + w), y, x, (y + h), (x + w), (y + h), col, col, col, d)
}) })

put_quad_c! : Machine.Machine, I64, I64, I64, I64, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
put_quad_c! = |machine, cmd, idx, x, y, w, h, ctop, cbot, d| (if (idx >= max_tri) { (machine, idx) } else { ({
	(machine1, machine__1) = put_tri3!(machine, cmd, idx, x, y, x, (y + h), (x + w), y, ctop, cbot, ctop, d)
	put_tri3!(machine1, cmd, machine__1, (x + w), y, x, (y + h), (x + w), (y + h), ctop, cbot, cbot, d)
}) })

put_tri3_add! : Machine.Machine, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
put_tri3_add! = |machine, cmd, idx, x0, y0, x1, y1, x2, y2, c0, c1, c2, d| ({
	(machine19, machine__19) = ({
	o : I64
	o = (idx * 72)
	({
		(machine1, machine__1) = Machine.store!(machine, cmd, o, x0, 4)
		(machine2, machine__2) = Machine.store!(machine1, cmd, (o + 4), y0, 4)
		(machine3, machine__3) = Machine.store!(machine2, cmd, (o + 8), x1, 4)
		(machine4, machine__4) = Machine.store!(machine3, cmd, (o + 12), y1, 4)
		(machine5, machine__5) = Machine.store!(machine4, cmd, (o + 16), x2, 4)
		(machine6, machine__6) = Machine.store!(machine5, cmd, (o + 20), y2, 4)
		(machine7, machine__7) = Machine.store!(machine6, cmd, (o + 24), c0, 4)
		(machine8, machine__8) = Machine.store!(machine7, cmd, (o + 28), c1, 4)
		(machine9, machine__9) = Machine.store!(machine8, cmd, (o + 32), c2, 4)
		(machine10, machine__10) = Machine.store!(machine9, cmd, (o + 36), d, 4)
		(machine11, machine__11) = Machine.store!(machine10, cmd, (o + 40), d, 4)
		(machine12, machine__12) = Machine.store!(machine11, cmd, (o + 44), d, 4)
		(machine13, machine__13) = Machine.store!(machine12, cmd, (o + 48), 1, 4)
		(machine14, machine__14) = Machine.store!(machine13, cmd, (o + 52), 0, 4)
		(machine15, machine__15) = Machine.store!(machine14, cmd, (o + 56), 0, 4)
		(machine16, machine__16) = Machine.store!(machine15, cmd, (o + 60), 0, 4)
		(machine17, machine__17) = Machine.store!(machine16, cmd, (o + 64), 0, 4)
		(machine18, machine__18) = Machine.store!(machine17, cmd, (o + 68), 0, 4)
		(machine18, bump((((((((((((((((((machine__1 + machine__2) + machine__3) + machine__4) + machine__5) + machine__6) + machine__7) + machine__8) + machine__9) + machine__10) + machine__11) + machine__12) + machine__13) + machine__14) + machine__15) + machine__16) + machine__17) + machine__18), (idx + 1)))
	})
})
	(machine19, machine__19)
})

put_rect_add! : Machine.Machine, I64, I64, I64, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
put_rect_add! = |machine, cmd, idx, x, y, w, h, col, d| (if (idx >= max_tri) { (machine, idx) } else { ({
	(machine1, machine__1) = put_tri3_add!(machine, cmd, idx, x, y, x, (y + h), (x + w), y, col, col, col, d)
	put_tri3_add!(machine1, cmd, machine__1, (x + w), y, x, (y + h), (x + w), (y + h), col, col, col, d)
}) })

put_tri3_soft! : Machine.Machine, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
put_tri3_soft! = |machine, cmd, idx, x0, y0, x1, y1, x2, y2, col, cx, cy, r| ({
	(machine19, machine__19) = ({
	o : I64
	o = (idx * 72)
	({
		(machine1, machine__1) = Machine.store!(machine, cmd, o, x0, 4)
		(machine2, machine__2) = Machine.store!(machine1, cmd, (o + 4), y0, 4)
		(machine3, machine__3) = Machine.store!(machine2, cmd, (o + 8), x1, 4)
		(machine4, machine__4) = Machine.store!(machine3, cmd, (o + 12), y1, 4)
		(machine5, machine__5) = Machine.store!(machine4, cmd, (o + 16), x2, 4)
		(machine6, machine__6) = Machine.store!(machine5, cmd, (o + 20), y2, 4)
		(machine7, machine__7) = Machine.store!(machine6, cmd, (o + 24), col, 4)
		(machine8, machine__8) = Machine.store!(machine7, cmd, (o + 28), col, 4)
		(machine9, machine__9) = Machine.store!(machine8, cmd, (o + 32), col, 4)
		(machine10, machine__10) = Machine.store!(machine9, cmd, (o + 36), 300, 4)
		(machine11, machine__11) = Machine.store!(machine10, cmd, (o + 40), 300, 4)
		(machine12, machine__12) = Machine.store!(machine11, cmd, (o + 44), 300, 4)
		(machine13, machine__13) = Machine.store!(machine12, cmd, (o + 48), 2, 4)
		(machine14, machine__14) = Machine.store!(machine13, cmd, (o + 52), 0, 4)
		(machine15, machine__15) = Machine.store!(machine14, cmd, (o + 56), cx, 4)
		(machine16, machine__16) = Machine.store!(machine15, cmd, (o + 60), cy, 4)
		(machine17, machine__17) = Machine.store!(machine16, cmd, (o + 64), r, 4)
		(machine18, machine__18) = Machine.store!(machine17, cmd, (o + 68), 0, 4)
		(machine18, bump((((((((((((((((((machine__1 + machine__2) + machine__3) + machine__4) + machine__5) + machine__6) + machine__7) + machine__8) + machine__9) + machine__10) + machine__11) + machine__12) + machine__13) + machine__14) + machine__15) + machine__16) + machine__17) + machine__18), (idx + 1)))
	})
})
	(machine19, machine__19)
})

put_sprite! : Machine.Machine, I64, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
put_sprite! = |machine, cmd, idx, sx, sy, r, col| (if (idx >= max_tri) { (machine, idx) } else { ({
	x0 : I64
	x0 = (sx - r)
	y0 : I64
	y0 = (sy - r)
	x1 : I64
	x1 = (sx + r)
	y1 : I64
	y1 = (sy + r)
	({
		(machine1, machine__1) = put_tri3_soft!(machine, cmd, idx, x0, y0, x0, y1, x1, y0, col, sx, sy, r)
		put_tri3_soft!(machine1, cmd, machine__1, x1, y0, x0, y1, x1, y1, col, sx, sy, r)
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
	bw : I64
	bw = (44 + I64.div_trunc_by((hsh((bx + seed)) * 46), 1024))
	bh : I64
	bh = (90 + I64.div_trunc_by((hsh((((bx * 3) + seed) + 11)) * 340), 1024))
	top : I64
	top = (horizon - bh)
	cols : I64
	cols = I64.div_trunc_by((bw - 12), 12)
	rows : I64
	rows = I64.div_trunc_by((bh - 18), 14)
	({
		(machine1, machine__1) = put_rect!(machine, cmd, idx, bx, top, bw, bh, building_col, 700)
		(machine2, machine__2) = draw_windows!(machine1, cmd, machine__1, bx, top, bw, bh, (bx + seed), 0, cols, rows)
		draw_city!(machine2, cmd, machine__2, ((bx + bw) + 7), seed)
	})
}) }) })

draw_windows! : Machine.Machine, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
draw_windows! = |machine, cmd, idx, bx, top, bw, bh, seed, k, cols, rows| (if (cols <= 0) { (machine, idx) } else { (if (rows <= 0) { (machine, idx) } else { (if (k >= (cols * rows)) { (machine, idx) } else { (if (idx >= max_tri) { (machine, idx) } else { ({
	cc : I64
	cc = (k - (I64.div_trunc_by(k, cols) * cols))
	rr : I64
	rr = I64.div_trunc_by(k, cols)
	lit : I64
	lit = I64.bitwise_and(hsh(((bx + (k * 31)) + seed)), 7)
	(if (lit >= 3) { draw_windows!(machine, cmd, idx, bx, top, bw, bh, seed, (k + 1), cols, rows) } else { ({
		wx : I64
		wx = ((bx + 6) + (cc * 12))
		wy : I64
		wy = ((top + 10) + (rr * 14))
		wcol : I64
		wcol = (if (I64.bitwise_and(hsh(((bx + (k * 7)) + seed)), 1) == 0) { 16765040 } else { 12572927 })
		({
			(machine1, machine__1) = put_rect!(machine, cmd, idx, wx, wy, 6, 8, wcol, 650)
			draw_windows!(machine1, cmd, machine__1, bx, top, bw, bh, seed, (k + 1), cols, rows)
		})
	}) })
}) }) }) }) })

draw_skyline! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
draw_skyline! = |machine, cmd, idx, city| (if (city == 0) { draw_nyc!(machine, cmd, idx) } else { (if (city == 1) { draw_chicago!(machine, cmd, idx) } else { (if (city == 2) { draw_sf!(machine, cmd, idx) } else { (if (city == 3) { draw_seattle!(machine, cmd, idx) } else { draw_dc!(machine, cmd, idx) }) }) }) })

draw_nyc! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
draw_nyc! = |machine, cmd, idx| ({
	(machine1, machine__1) = draw_city!(machine, cmd, idx, 0, 101)
	draw_empire!(machine1, cmd, machine__1, 512)
})

draw_empire! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
draw_empire! = |machine, cmd, idx, cx| ({
	(machine1, machine__1) = put_rect!(machine, cmd, idx, (cx - 60), (horizon - 300), 120, 300, landmark_col, 500)
	(machine2, machine__2) = put_rect!(machine1, cmd, machine__1, (cx - 44), (horizon - 372), 88, 72, landmark_col, 490)
	(machine3, machine__3) = put_rect!(machine2, cmd, machine__2, (cx - 28), (horizon - 430), 56, 58, landmark_col, 480)
	(machine4, machine__4) = put_rect!(machine3, cmd, machine__3, (cx - 8), (horizon - 500), 16, 70, landmark_col, 470)
	put_tri3!(machine4, cmd, machine__4, (cx - 5), (horizon - 500), (cx + 5), (horizon - 500), cx, (horizon - 542), antenna_col, antenna_col, antenna_col, 460)
})

draw_chicago! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
draw_chicago! = |machine, cmd, idx| ({
	(machine1, machine__1) = draw_city!(machine, cmd, idx, 0, 203)
	draw_willis!(machine1, cmd, machine__1, 512)
})

draw_willis! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
draw_willis! = |machine, cmd, idx, cx| ({
	(machine1, machine__1) = put_rect!(machine, cmd, idx, (cx - 80), (horizon - 300), 160, 300, landmark_col, 500)
	(machine2, machine__2) = put_rect!(machine1, cmd, machine__1, (cx - 80), (horizon - 372), 104, 72, landmark_col, 495)
	(machine3, machine__3) = put_rect!(machine2, cmd, machine__2, (cx - 40), (horizon - 420), 80, 48, landmark_col, 490)
	(machine4, machine__4) = put_rect!(machine3, cmd, machine__3, (cx - 30), (horizon - 470), 24, 50, landmark_col, 485)
	(machine5, machine__5) = put_rect!(machine4, cmd, machine__4, (cx + 6), (horizon - 470), 24, 50, landmark_col, 485)
	(machine6, machine__6) = put_rect!(machine5, cmd, machine__5, (cx - 20), (horizon - 512), 4, 42, antenna_col, 480)
	put_rect!(machine6, cmd, machine__6, (cx + 14), (horizon - 512), 4, 42, antenna_col, 480)
})

draw_sf! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
draw_sf! = |machine, cmd, idx| ({
	(machine1, machine__1) = draw_city!(machine, cmd, idx, 0, 307)
	(machine2, machine__2) = draw_transamerica!(machine1, cmd, machine__1, 800)
	draw_goldengate!(machine2, cmd, machine__2, 380, 644)
})

draw_transamerica! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
draw_transamerica! = |machine, cmd, idx, cx| ({
	(machine1, machine__1) = put_rect!(machine, cmd, idx, (cx - 6), (horizon - 120), 12, 120, trans_col, 505)
	put_tri3!(machine1, cmd, machine__1, (cx - 30), (horizon - 120), (cx + 30), (horizon - 120), cx, (horizon - 400), trans_col, trans_col, trans_col, 505)
})

draw_goldengate! : Machine.Machine, I64, I64, I64, I64 => (Machine.Machine, I64)
draw_goldengate! = |machine, cmd, idx, lx, rx| ({
	ttop : I64
	ttop = (horizon - 340)
	({
		(machine1, machine__1) = put_rect!(machine, cmd, idx, (lx - 12), ttop, 24, (horizon - ttop), gg_orange, 450)
		(machine2, machine__2) = put_rect!(machine1, cmd, machine__1, (rx - 12), ttop, 24, (horizon - ttop), gg_orange, 450)
		(machine3, machine__3) = put_rect!(machine2, cmd, machine__2, (lx - 12), (ttop + 40), 24, 14, gg_orange, 445)
		(machine4, machine__4) = put_rect!(machine3, cmd, machine__3, (rx - 12), (ttop + 40), 24, 14, gg_orange, 445)
		(machine5, machine__5) = put_rect!(machine4, cmd, machine__4, lx, (horizon - 150), (rx - lx), 8, gg_orange, 448)
		draw_cable!(machine5, cmd, machine__5, lx, ttop, (rx - lx), 130, 0)
	})
})

draw_cable! : Machine.Machine, I64, I64, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
draw_cable! = |machine, cmd, idx, x0, topy, span, sag, i| (if (i > 24) { (machine, idx) } else { ({
	u : I64
	u = ((i * 2) - 24)
	px : I64
	px = (x0 + I64.div_trunc_by((i * span), 24))
	yy : I64
	yy = ((topy + sag) - I64.div_trunc_by(((sag * u) * u), 576))
	({
		(machine1, machine__1) = put_rect!(machine, cmd, idx, (px - 1), yy, 3, 3, gg_cable, 440)
		draw_cable!(machine1, cmd, machine__1, x0, topy, span, sag, (i + 1))
	})
}) })

draw_seattle! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
draw_seattle! = |machine, cmd, idx| ({
	(machine1, machine__1) = draw_city!(machine, cmd, idx, 0, 411)
	draw_needle!(machine1, cmd, machine__1, 512)
})

draw_needle! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
draw_needle! = |machine, cmd, idx, cx| ({
	(machine1, machine__1) = put_tri3!(machine, cmd, idx, (cx - 60), horizon, (cx - 30), horizon, (cx - 6), (horizon - 280), needle_col, needle_col, needle_col, 500)
	(machine2, machine__2) = put_tri3!(machine1, cmd, machine__1, (cx + 30), horizon, (cx + 60), horizon, (cx + 6), (horizon - 280), needle_col, needle_col, needle_col, 500)
	(machine3, machine__3) = put_rect!(machine2, cmd, machine__2, (cx - 6), (horizon - 280), 12, 280, needle_col, 498)
	(machine4, machine__4) = put_rect!(machine3, cmd, machine__3, (cx - 48), (horizon - 306), 96, 20, needle_col, 490)
	(machine5, machine__5) = put_tri3!(machine4, cmd, machine__4, (cx + 48), (horizon - 286), (cx - 48), (horizon - 286), cx, (horizon - 274), needle_col, needle_col, needle_col, 490)
	(machine6, machine__6) = put_rect!(machine5, cmd, machine__5, (cx - 4), (horizon - 344), 8, 38, needle_col, 488)
	put_tri3!(machine6, cmd, machine__6, (cx - 4), (horizon - 344), (cx + 4), (horizon - 344), cx, (horizon - 362), antenna_col, antenna_col, antenna_col, 486)
})

draw_dc! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
draw_dc! = |machine, cmd, idx| ({
	(machine1, machine__1) = draw_city!(machine, cmd, idx, 0, 523)
	(machine2, machine__2) = draw_monument!(machine1, cmd, machine__1, 400)
	draw_capitol!(machine2, cmd, machine__2, 660)
})

draw_monument! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
draw_monument! = |machine, cmd, idx, cx| ({
	(machine1, machine__1) = put_rect!(machine, cmd, idx, (cx - 13), (horizon - 430), 26, 430, monument_col, 500)
	put_tri3!(machine1, cmd, machine__1, (cx - 13), (horizon - 430), (cx + 13), (horizon - 430), cx, (horizon - 462), monument_col, monument_col, monument_col, 498)
})

draw_capitol! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
draw_capitol! = |machine, cmd, idx, cx| ({
	(machine1, machine__1) = put_rect!(machine, cmd, idx, (cx - 90), (horizon - 70), 180, 70, dome_col, 500)
	(machine2, machine__2) = put_rect!(machine1, cmd, machine__1, (cx - 52), (horizon - 112), 104, 42, dome_col, 498)
	(machine3, machine__3) = put_rect!(machine2, cmd, machine__2, (cx - 34), (horizon - 150), 68, 38, dome_col, 496)
	(machine4, machine__4) = put_tri3!(machine3, cmd, machine__3, (cx - 34), (horizon - 150), (cx + 34), (horizon - 150), cx, (horizon - 188), dome_col, dome_col, dome_col, 494)
	put_rect!(machine4, cmd, machine__4, (cx - 2), (horizon - 204), 4, 16, dome_col, 492)
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
	row : I64
	row = I64.div_trunc_by(i, 3)
	cp : I64
	cp = (i - (row * 3))
	mask : I64
	mask = I64.shl_wrap(1, I64.to_u8_wrap((14 - i)))
	(if (I64.bitwise_and(bits, mask) == 0) { draw_glyph_px!(machine, cmd, idx, x, y, sz, col, bits, (i + 1)) } else { ({
		(machine1, machine__1) = put_rect!(machine, cmd, idx, (x + (cp * sz)), (y + (row * sz)), sz, sz, col, 150)
		draw_glyph_px!(machine1, cmd, machine__1, x, y, sz, col, bits, (i + 1))
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
	x0 : I64
	x0 = 322
	b : I64
	b = band_y
	s : I64
	s = txt_sz
	({
		(machine1, machine__1) = gc!(machine, cmd, idx, x0, b, s, banner_col, 0, g_u)
		(machine2, machine__2) = gc!(machine1, cmd, machine__1, x0, b, s, banner_col, 1, g_s)
		(machine3, machine__3) = gc!(machine2, cmd, machine__2, x0, b, s, banner_col, 2, g_a)
		(machine4, machine__4) = gc!(machine3, cmd, machine__3, x0, b, s, banner_col, 4, g_d2)
		(machine5, machine__5) = gc!(machine4, cmd, machine__4, x0, b, s, banner_col, 5, g_d5)
		(machine6, machine__6) = gc!(machine5, cmd, machine__5, x0, b, s, banner_col, 6, g_d0)
		(machine7, machine__7) = gc!(machine6, cmd, machine__6, x0, b, s, banner_col, 8, g_dot)
		(machine8, machine__8) = gc!(machine7, cmd, machine__7, x0, b, s, banner_col, 10, g_d1)
		(machine9, machine__9) = gc!(machine8, cmd, machine__8, x0, b, s, banner_col, 11, g_d7)
		(machine10, machine__10) = gc!(machine9, cmd, machine__9, x0, b, s, banner_col, 12, g_d7)
		(machine11, machine__11) = gc!(machine10, cmd, machine__10, x0, b, s, banner_col, 13, g_d6)
		(machine12, machine__12) = gc!(machine11, cmd, machine__11, x0, b, s, banner_col, 14, g_dash)
		(machine13, machine__13) = gc!(machine12, cmd, machine__12, x0, b, s, banner_col, 15, g_d2)
		(machine14, machine__14) = gc!(machine13, cmd, machine__13, x0, b, s, banner_col, 16, g_d0)
		(machine15, machine__15) = gc!(machine14, cmd, machine__14, x0, b, s, banner_col, 17, g_d2)
		gc!(machine15, cmd, machine__15, x0, b, s, banner_col, 18, g_d6)
	})
})

draw_city_name! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
draw_city_name! = |machine, cmd, idx, city| (if (city == 0) { draw_name_nyc!(machine, cmd, idx) } else { (if (city == 1) { draw_name_chicago!(machine, cmd, idx) } else { (if (city == 2) { draw_name_sf!(machine, cmd, idx) } else { (if (city == 3) { draw_name_seattle!(machine, cmd, idx) } else { draw_name_dc!(machine, cmd, idx) }) }) }) })

draw_name_nyc! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
draw_name_nyc! = |machine, cmd, idx| ({
	x0 : I64
	x0 = 432
	y : I64
	y = name_y
	s : I64
	s = txt_sz
	({
		(machine1, machine__1) = gc!(machine, cmd, idx, x0, y, s, name_col, 0, g_n)
		(machine2, machine__2) = gc!(machine1, cmd, machine__1, x0, y, s, name_col, 1, g_e)
		(machine3, machine__3) = gc!(machine2, cmd, machine__2, x0, y, s, name_col, 2, g_w)
		(machine4, machine__4) = gc!(machine3, cmd, machine__3, x0, y, s, name_col, 4, g_y)
		(machine5, machine__5) = gc!(machine4, cmd, machine__4, x0, y, s, name_col, 5, g_o)
		(machine6, machine__6) = gc!(machine5, cmd, machine__5, x0, y, s, name_col, 6, g_r)
		gc!(machine6, cmd, machine__6, x0, y, s, name_col, 7, g_k)
	})
})

draw_name_chicago! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
draw_name_chicago! = |machine, cmd, idx| ({
	x0 : I64
	x0 = 442
	y : I64
	y = name_y
	s : I64
	s = txt_sz
	({
		(machine1, machine__1) = gc!(machine, cmd, idx, x0, y, s, name_col, 0, g_c)
		(machine2, machine__2) = gc!(machine1, cmd, machine__1, x0, y, s, name_col, 1, g_h)
		(machine3, machine__3) = gc!(machine2, cmd, machine__2, x0, y, s, name_col, 2, g_i)
		(machine4, machine__4) = gc!(machine3, cmd, machine__3, x0, y, s, name_col, 3, g_c)
		(machine5, machine__5) = gc!(machine4, cmd, machine__4, x0, y, s, name_col, 4, g_a)
		(machine6, machine__6) = gc!(machine5, cmd, machine__5, x0, y, s, name_col, 5, g_g)
		gc!(machine6, cmd, machine__6, x0, y, s, name_col, 6, g_o)
	})
})

draw_name_sf! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
draw_name_sf! = |machine, cmd, idx| ({
	x0 : I64
	x0 = 382
	y : I64
	y = name_y
	s : I64
	s = txt_sz
	({
		(machine1, machine__1) = gc!(machine, cmd, idx, x0, y, s, name_col, 0, g_s)
		(machine2, machine__2) = gc!(machine1, cmd, machine__1, x0, y, s, name_col, 1, g_a)
		(machine3, machine__3) = gc!(machine2, cmd, machine__2, x0, y, s, name_col, 2, g_n)
		(machine4, machine__4) = gc!(machine3, cmd, machine__3, x0, y, s, name_col, 4, g_f)
		(machine5, machine__5) = gc!(machine4, cmd, machine__4, x0, y, s, name_col, 5, g_r)
		(machine6, machine__6) = gc!(machine5, cmd, machine__5, x0, y, s, name_col, 6, g_a)
		(machine7, machine__7) = gc!(machine6, cmd, machine__6, x0, y, s, name_col, 7, g_n)
		(machine8, machine__8) = gc!(machine7, cmd, machine__7, x0, y, s, name_col, 8, g_c)
		(machine9, machine__9) = gc!(machine8, cmd, machine__8, x0, y, s, name_col, 9, g_i)
		(machine10, machine__10) = gc!(machine9, cmd, machine__9, x0, y, s, name_col, 10, g_s)
		(machine11, machine__11) = gc!(machine10, cmd, machine__10, x0, y, s, name_col, 11, g_c)
		gc!(machine11, cmd, machine__11, x0, y, s, name_col, 12, g_o)
	})
})

draw_name_seattle! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
draw_name_seattle! = |machine, cmd, idx| ({
	x0 : I64
	x0 = 442
	y : I64
	y = name_y
	s : I64
	s = txt_sz
	({
		(machine1, machine__1) = gc!(machine, cmd, idx, x0, y, s, name_col, 0, g_s)
		(machine2, machine__2) = gc!(machine1, cmd, machine__1, x0, y, s, name_col, 1, g_e)
		(machine3, machine__3) = gc!(machine2, cmd, machine__2, x0, y, s, name_col, 2, g_a)
		(machine4, machine__4) = gc!(machine3, cmd, machine__3, x0, y, s, name_col, 3, g_t)
		(machine5, machine__5) = gc!(machine4, cmd, machine__4, x0, y, s, name_col, 4, g_t)
		(machine6, machine__6) = gc!(machine5, cmd, machine__5, x0, y, s, name_col, 5, g_l)
		(machine7, machine__7) = gc!(machine6, cmd, machine__6, x0, y, s, name_col, 6, g_e)
		draw_seahawks_line!(machine7, cmd, machine__7)
	})
})

draw_seahawks_line! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
draw_seahawks_line! = |machine, cmd, idx| ({
	x0 : I64
	x0 = 218
	y : I64
	y = 118
	s : I64
	s = 3
	c : I64
	c = seahawks_col
	({
		(machine1, machine__1) = gc!(machine, cmd, idx, x0, y, s, c, 0, g_h)
		(machine2, machine__2) = gc!(machine1, cmd, machine__1, x0, y, s, c, 1, g_o)
		(machine3, machine__3) = gc!(machine2, cmd, machine__2, x0, y, s, c, 2, g_m)
		(machine4, machine__4) = gc!(machine3, cmd, machine__3, x0, y, s, c, 3, g_e)
		(machine5, machine__5) = gc!(machine4, cmd, machine__4, x0, y, s, c, 5, g_o)
		(machine6, machine__6) = gc!(machine5, cmd, machine__5, x0, y, s, c, 6, g_f)
		(machine7, machine__7) = gc!(machine6, cmd, machine__6, x0, y, s, c, 8, g_t)
		(machine8, machine__8) = gc!(machine7, cmd, machine__7, x0, y, s, c, 9, g_h)
		(machine9, machine__9) = gc!(machine8, cmd, machine__8, x0, y, s, c, 10, g_e)
		(machine10, machine__10) = gc!(machine9, cmd, machine__9, x0, y, s, c, 12, g_r)
		(machine11, machine__11) = gc!(machine10, cmd, machine__10, x0, y, s, c, 13, g_e)
		(machine12, machine__12) = gc!(machine11, cmd, machine__11, x0, y, s, c, 14, g_i)
		(machine13, machine__13) = gc!(machine12, cmd, machine__12, x0, y, s, c, 15, g_g)
		(machine14, machine__14) = gc!(machine13, cmd, machine__13, x0, y, s, c, 16, g_n)
		(machine15, machine__15) = gc!(machine14, cmd, machine__14, x0, y, s, c, 17, g_i)
		(machine16, machine__16) = gc!(machine15, cmd, machine__15, x0, y, s, c, 18, g_n)
		(machine17, machine__17) = gc!(machine16, cmd, machine__16, x0, y, s, c, 19, g_g)
		(machine18, machine__18) = gc!(machine17, cmd, machine__17, x0, y, s, c, 21, g_s)
		(machine19, machine__19) = gc!(machine18, cmd, machine__18, x0, y, s, c, 22, g_u)
		(machine20, machine__20) = gc!(machine19, cmd, machine__19, x0, y, s, c, 23, g_p)
		(machine21, machine__21) = gc!(machine20, cmd, machine__20, x0, y, s, c, 24, g_e)
		(machine22, machine__22) = gc!(machine21, cmd, machine__21, x0, y, s, c, 25, g_r)
		(machine23, machine__23) = gc!(machine22, cmd, machine__22, x0, y, s, c, 26, g_b)
		(machine24, machine__24) = gc!(machine23, cmd, machine__23, x0, y, s, c, 27, g_o)
		(machine25, machine__25) = gc!(machine24, cmd, machine__24, x0, y, s, c, 28, g_w)
		(machine26, machine__26) = gc!(machine25, cmd, machine__25, x0, y, s, c, 29, g_l)
		(machine27, machine__27) = gc!(machine26, cmd, machine__26, x0, y, s, c, 31, g_c)
		(machine28, machine__28) = gc!(machine27, cmd, machine__27, x0, y, s, c, 32, g_h)
		(machine29, machine__29) = gc!(machine28, cmd, machine__28, x0, y, s, c, 33, g_a)
		(machine30, machine__30) = gc!(machine29, cmd, machine__29, x0, y, s, c, 34, g_m)
		(machine31, machine__31) = gc!(machine30, cmd, machine__30, x0, y, s, c, 35, g_p)
		(machine32, machine__32) = gc!(machine31, cmd, machine__31, x0, y, s, c, 36, g_i)
		(machine33, machine__33) = gc!(machine32, cmd, machine__32, x0, y, s, c, 37, g_o)
		(machine34, machine__34) = gc!(machine33, cmd, machine__33, x0, y, s, c, 38, g_n)
		(machine35, machine__35) = gc!(machine34, cmd, machine__34, x0, y, s, c, 40, g_s)
		(machine36, machine__36) = gc!(machine35, cmd, machine__35, x0, y, s, c, 41, g_e)
		(machine37, machine__37) = gc!(machine36, cmd, machine__36, x0, y, s, c, 42, g_a)
		(machine38, machine__38) = gc!(machine37, cmd, machine__37, x0, y, s, c, 43, g_h)
		(machine39, machine__39) = gc!(machine38, cmd, machine__38, x0, y, s, c, 44, g_a)
		(machine40, machine__40) = gc!(machine39, cmd, machine__39, x0, y, s, c, 45, g_w)
		(machine41, machine__41) = gc!(machine40, cmd, machine__40, x0, y, s, c, 46, g_k)
		(machine42, machine__42) = gc!(machine41, cmd, machine__41, x0, y, s, c, 47, g_s)
		gc!(machine42, cmd, machine__42, x0, y, s, c, 48, g_bang)
	})
})

draw_name_dc! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
draw_name_dc! = |machine, cmd, idx| ({
	x0 : I64
	x0 = 382
	y : I64
	y = name_y
	s : I64
	s = txt_sz
	({
		(machine1, machine__1) = gc!(machine, cmd, idx, x0, y, s, name_col, 0, g_w)
		(machine2, machine__2) = gc!(machine1, cmd, machine__1, x0, y, s, name_col, 1, g_a)
		(machine3, machine__3) = gc!(machine2, cmd, machine__2, x0, y, s, name_col, 2, g_s)
		(machine4, machine__4) = gc!(machine3, cmd, machine__3, x0, y, s, name_col, 3, g_h)
		(machine5, machine__5) = gc!(machine4, cmd, machine__4, x0, y, s, name_col, 4, g_i)
		(machine6, machine__6) = gc!(machine5, cmd, machine__5, x0, y, s, name_col, 5, g_n)
		(machine7, machine__7) = gc!(machine6, cmd, machine__6, x0, y, s, name_col, 6, g_g)
		(machine8, machine__8) = gc!(machine7, cmd, machine__7, x0, y, s, name_col, 7, g_t)
		(machine9, machine__9) = gc!(machine8, cmd, machine__8, x0, y, s, name_col, 8, g_o)
		(machine10, machine__10) = gc!(machine9, cmd, machine__9, x0, y, s, name_col, 9, g_n)
		(machine11, machine__11) = gc!(machine10, cmd, machine__10, x0, y, s, name_col, 11, g_d)
		gc!(machine11, cmd, machine__11, x0, y, s, name_col, 12, g_c)
	})
})

md : I64, I64 -> I64
md = |a, n| (a - (I64.div_trunc_by(a, n) * n))

rnd : I64 -> I64
rnd = |n| ({
	a : I64
	a = I64.plus_wrap(I64.times_wrap(n, 374761393), 668265263)
	b : I64
	b = I64.bitwise_xor(a, I64.shr_zf_wrap(a, I64.to_u8_wrap(13)))
	c : I64
	c = Wrap64.w64_mul(b, 1274126177)
	I64.bitwise_and(I64.bitwise_xor(c, I64.shr_zf_wrap(c, I64.to_u8_wrap(16))), 16777215)
})

write_particle! : Machine.Machine, I64, I64, I64, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
write_particle! = |machine, slot, px, py, vx, vy, life, col, kind| ({
	(machine9, machine__1) = ({
	o : I64
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
	(machine9, machine__1)
})

clear_parts! : Machine.Machine, I64 => (Machine.Machine, I64)
clear_parts! = |machine, i| (if (i >= part_cap) { (machine, 0) } else { ({
	(machine1, _w) = Machine.store!(machine, part_base, ((i * part_stride) + f_kind), 0, 4)
	clear_parts!(machine1, (i + 1))
}) })

spawn_burst! : Machine.Machine, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
spawn_burst! = |machine, cx, cy, col, cursor, i| (if (i >= burst_count) { (machine, cursor) } else { ({
	jit : I64
	jit = rnd(((cx + (cy * 3)) + (i * 2654435)))
	ang : I64
	ang = (I64.div_trunc_by((i * 6283), burst_count) + I64.bitwise_and(jit, 63))
	spd : I64
	spd = (240 + I64.bitwise_and(I64.shr_zf_wrap(jit, I64.to_u8_wrap(6)), 640))
	vx : I64
	vx = I64.div_trunc_by((fw_cos(ang) * spd), 1000)
	vy : I64
	vy = I64.div_trunc_by((fw_sin(ang) * spd), 1000)
	life : I64
	life = (40 + I64.bitwise_and(I64.shr_zf_wrap(jit, I64.to_u8_wrap(16)), 70))
	slot : I64
	slot = md(cursor, part_cap)
	(machine1, _w) = write_particle!(machine, slot, cx, cy, vx, vy, life, col, 1)
	spawn_burst!(machine1, cx, cy, col, (cursor + 1), (i + 1))
}) })

maybe_launch! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
maybe_launch! = |machine, frame, cursor| ({
	(machine3, machine__2) = (if (md(frame, launch_every) != 0) { (machine, cursor) } else { ({
	(machine2, machine__1) = ({
	r : I64
	r = rnd(((frame * 17) + 3))
	lx : I64
	lx = (70 + I64.div_trunc_by((I64.bitwise_and(r, 1023) * (sw - 140)), 1024))
	vy0 : I64
	vy0 = (0 - (2280 + I64.bitwise_and(I64.shr_zf_wrap(r, I64.to_u8_wrap(10)), 300)))
	vx0 : I64
	vx0 = ((I64.bitwise_and(I64.shr_zf_wrap(r, I64.to_u8_wrap(20)), 255) - 128) * 4)
	col : I64
	col = burst_color(I64.shr_zf_wrap(r, I64.to_u8_wrap(18)))
	slot : I64
	slot = md(cursor, part_cap)
	(machine1, _w) = write_particle!(machine, slot, (lx * 256), ((horizon - 30) * 256), vx0, vy0, 240, col, 2)
	(machine1, (cursor + 1))
})
	(machine2, machine__1)
}) })
	(machine3, machine__2)
})

finale_launch! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
finale_launch! = |machine, frame, cursor, i| (if (i >= 3) { (machine, cursor) } else { ({
	r : I64
	r = rnd((((frame * 131) + (i * 977)) + 7))
	lx : I64
	lx = (60 + I64.div_trunc_by((I64.bitwise_and(r, 1023) * (sw - 120)), 1024))
	vy0 : I64
	vy0 = (0 - (2250 + I64.bitwise_and(I64.shr_zf_wrap(r, I64.to_u8_wrap(10)), 350)))
	vx0 : I64
	vx0 = ((I64.bitwise_and(I64.shr_zf_wrap(r, I64.to_u8_wrap(20)), 255) - 128) * 5)
	col : I64
	col = burst_color(I64.shr_zf_wrap(r, I64.to_u8_wrap(18)))
	slot : I64
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
	(machine1, machine__1) = update_all!(machine, 0, cursor)
	update_steps!(machine1, machine__1, (n - 1))
}) })

update_all! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
update_all! = |machine, i, cursor| (if (i >= part_cap) { (machine, cursor) } else { ({
	o : I64
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
			vy2 : I64
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
				ts : I64
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
	r : I64
	r = I64.bitwise_and(I64.shr_zf_wrap(packed, I64.to_u8_wrap(16)), 255)
	g : I64
	g = I64.bitwise_and(I64.shr_zf_wrap(packed, I64.to_u8_wrap(8)), 255)
	b : I64
	b = I64.bitwise_and(packed, 255)
	I64.bitwise_or(I64.shl_wrap(I64.div_trunc_by((r * f), 1000), I64.to_u8_wrap(16)), I64.bitwise_or(I64.shl_wrap(I64.div_trunc_by((g * f), 1000), I64.to_u8_wrap(8)), I64.div_trunc_by((b * f), 1000)))
})

draw_particles! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
draw_particles! = |machine, cmd, idx, i| (if (i >= part_cap) { (machine, idx) } else { (if (idx >= max_tri) { (machine, idx) } else { ({
	o : I64
	o = (i * part_stride)
	(machine1, kind) = Machine.load!(machine, part_base, (o + f_kind), 4)
	(if (kind == 0) { draw_particles!(machine1, cmd, idx, (i + 1)) } else { ({
		(machine2, life) = Machine.load!(machine1, part_base, (o + f_life), 4)
		(machine3, maxl) = Machine.load!(machine2, part_base, (o + f_max), 4)
		(machine4, machine__1) = Machine.load!(machine3, part_base, (o + f_px), 4)
		sx : I64
		sx = I64.div_trunc_by(machine__1, 256)
		(machine5, machine__2) = Machine.load!(machine4, part_base, (o + f_py), 4)
		sy : I64
		sy = I64.div_trunc_by(machine__2, 256)
		fade : I64
		fade = (if (maxl <= 0) { 0 } else { I64.div_trunc_by((life * 1000), maxl) })
		(machine6, base) = Machine.load!(machine5, part_base, (o + f_col), 4)
		(if (kind == 2) { ({
			(machine7, machine__3) = put_rect_add!(machine6, cmd, idx, (sx - 3), (sy - 3), 6, 6, shell_col, 300)
			draw_particles!(machine7, cmd, machine__3, (i + 1))
		}) } else { ({
			col : I64
			col = scale_col(base, fade)
			sz : I64
			sz = (if (fade > 600) { 3 } else { 2 })
			ry : I64
			ry = ((2 * horizon) - sy)
			({
				(machine8, machine__4) = put_rect_add!(machine6, cmd, idx, (sx - sz), (sy - sz), (sz * 2), (sz * 2), col, 300)
				(machine9, machine__5) = reflect_spark!(machine8, cmd, machine__4, sx, ry, sz, base, fade)
				draw_particles!(machine9, cmd, machine__5, (i + 1))
			})
		}) })
	}) })
}) }) })

cool_col : I64, I64 -> I64
cool_col = |base, fade| (if (fade > 820) { 16774368 } else { (if (fade > 520) { base } else { scale_col(base, ((fade * 2) + 120)) }) })

draw_particles_soft! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
draw_particles_soft! = |machine, cmd, idx, i| (if (i >= part_cap) { (machine, idx) } else { (if (idx >= max_tri) { (machine, idx) } else { ({
	o : I64
	o = (i * part_stride)
	(machine1, kind) = Machine.load!(machine, part_base, (o + f_kind), 4)
	(if (kind == 0) { draw_particles_soft!(machine1, cmd, idx, (i + 1)) } else { ({
		(machine2, life) = Machine.load!(machine1, part_base, (o + f_life), 4)
		(machine3, maxl) = Machine.load!(machine2, part_base, (o + f_max), 4)
		(machine4, machine__1) = Machine.load!(machine3, part_base, (o + f_px), 4)
		sx : I64
		sx = I64.div_trunc_by(machine__1, 256)
		(machine5, machine__2) = Machine.load!(machine4, part_base, (o + f_py), 4)
		sy : I64
		sy = I64.div_trunc_by(machine__2, 256)
		fade : I64
		fade = (if (maxl <= 0) { 0 } else { I64.div_trunc_by((life * 1000), maxl) })
		(machine6, base) = Machine.load!(machine5, part_base, (o + f_col), 4)
		(if (kind == 2) { ({
			(machine7, machine__3) = put_sprite!(machine6, cmd, idx, sx, sy, 5, shell_col)
			draw_particles_soft!(machine7, cmd, machine__3, (i + 1))
		}) } else { ({
			col : I64
			col = cool_col(base, fade)
			sz : I64
			sz = (if (fade > 600) { 5 } else { 4 })
			({
				(machine8, machine__4) = put_sprite!(machine6, cmd, idx, sx, sy, sz, col)
				draw_particles_soft!(machine8, cmd, machine__4, (i + 1))
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
	(machine1, machine__1) = draw_water!(machine, cmd, 0)
	(machine2, machine__2) = draw_skyline!(machine1, cmd, machine__1, scene_city(frame))
	draw_particles_soft!(machine2, cmd, machine__2, 0)
})

render_city_scene! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
render_city_scene! = |machine, cmd, frame| ({
	city : I64
	city = scene_city(frame)
	({
		(machine1, machine__1) = draw_sky!(machine, cmd, 0)
		(machine2, machine__2) = draw_water!(machine1, cmd, machine__1)
		(machine3, machine__3) = draw_skyline!(machine2, cmd, machine__2, city)
		(machine4, machine__4) = draw_particles!(machine3, cmd, machine__3, 0)
		(machine5, machine__5) = draw_banner!(machine4, cmd, machine__4)
		draw_city_name!(machine5, cmd, machine__5, city)
	})
})

render_finale! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
render_finale! = |machine, cmd, _frame| ({
	(machine1, machine__1) = draw_sky!(machine, cmd, 0)
	(machine2, machine__2) = draw_water!(machine1, cmd, machine__1)
	(machine3, machine__3) = draw_city!(machine2, cmd, machine__2, 0, 909)
	(machine4, machine__4) = draw_particles!(machine3, cmd, machine__3, 0)
	(machine5, machine__5) = draw_banner!(machine4, cmd, machine__4)
	draw_finale_text!(machine5, cmd, machine__5)
})

draw_finale_text! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
draw_finale_text! = |machine, cmd, idx| ({
	bx : I64
	bx = 316
	by : I64
	by = 250
	bs : I64
	bs = 14
	({
		(machine1, machine__1) = gc!(machine, cmd, idx, bx, by, bs, banner_col, 0, g_u)
		(machine2, machine__2) = gc!(machine1, cmd, machine__1, bx, by, bs, banner_col, 1, g_s)
		(machine3, machine__3) = gc!(machine2, cmd, machine__2, bx, by, bs, banner_col, 2, g_a)
		(machine4, machine__4) = gc!(machine3, cmd, machine__3, bx, by, bs, banner_col, 4, g_d2)
		(machine5, machine__5) = gc!(machine4, cmd, machine__4, bx, by, bs, banner_col, 5, g_d5)
		(machine6, machine__6) = gc!(machine5, cmd, machine__5, bx, by, bs, banner_col, 6, g_d0)
		draw_finale_sub!(machine6, cmd, machine__6)
	})
})

draw_finale_sub! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
draw_finale_sub! = |machine, cmd, idx| ({
	sx : I64
	sx = 368
	sy : I64
	sy = 470
	ss : I64
	ss = 8
	({
		(machine1, machine__1) = gc!(machine, cmd, idx, sx, sy, ss, name_col, 0, g_d2)
		(machine2, machine__2) = gc!(machine1, cmd, machine__1, sx, sy, ss, name_col, 1, g_d5)
		(machine3, machine__3) = gc!(machine2, cmd, machine__2, sx, sy, ss, name_col, 2, g_d0)
		(machine4, machine__4) = gc!(machine3, cmd, machine__3, sx, sy, ss, name_col, 4, g_y)
		(machine5, machine__5) = gc!(machine4, cmd, machine__4, sx, sy, ss, name_col, 5, g_e)
		(machine6, machine__6) = gc!(machine5, cmd, machine__5, sx, sy, ss, name_col, 6, g_a)
		(machine7, machine__7) = gc!(machine6, cmd, machine__6, sx, sy, ss, name_col, 7, g_r)
		gc!(machine7, cmd, machine__7, sx, sy, ss, name_col, 8, g_s)
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
			(machine4, machine__1) = render_scene!(machine3, cmd, frame, mode)
			flush_ret!(machine4, machine__1, cur2)
		})
	})
})

edge_mode : I64, I64, I64 -> I64
edge_mode = |sc, prev, mode| (if (sc == KeyInput.key_f1) { (if (prev == KeyInput.key_f1) { mode } else { (1 - mode) }) } else { mode })

fw_loop! : Machine.Machine, I64, I64, I64, I64, I64 => (Machine.Machine, CceText)
fw_loop! = |machine, cmd, frame, cursor, mode, prev| ({
	(machine1, sc) = KeyInput.poll_key!(machine)
	({
		(machine2, nc) = render_frame!(machine1, cmd, frame, cursor, edge_mode(sc, prev, mode))
		(match (KeyInput.key_upper(sc) == CceChar.code(CceChar.of_code(63))) {
			True => (machine2, "done")
			_ => fw_loop!(machine2, cmd, (frame + 1), nc, edge_mode(sc, prev, mode), sc)
		})
	})
})

fw_sin : I64 -> I64
fw_sin = |raw| ({
	a : I64
	a = fw_wrap(raw)
	(if (a <= 1570) { fw_sin_core(a) } else { (if (a <= 3141) { fw_sin_core((3141 - a)) } else { (if (a <= 4712) { (0 - fw_sin_core((a - 3141))) } else { (0 - fw_sin_core((6283 - a))) }) }) })
})

fw_cos : I64 -> I64
fw_cos = |raw| fw_sin((raw + 1570))

fw_sin_core : I64 -> I64
fw_sin_core = |x| ({
	x2 : I64
	x2 = I64.div_trunc_by((x * x), 1000)
	x3 : I64
	x3 = I64.div_trunc_by((x2 * x), 1000)
	x5 : I64
	x5 = I64.div_trunc_by((x3 * x2), 1000)
	((x - I64.div_trunc_by(x3, 6)) + I64.div_trunc_by(x5, 120))
})

fw_wrap : I64 -> I64
fw_wrap = |a| ({
	m : I64
	m = (a - (I64.div_trunc_by(a, 6283) * 6283))
	(if (m < 0) { (m + 6283) } else { m })
})

# --- Entry ---

main! = |args| {
	machine = Machine.boot!(args, ["Console", "Device.Port", "Gpu.Compute", "Gpu.Memory"])
	(machine1, machine__1) = Machine.port_out_32!(machine, 1040, 1)
	_con = machine__1
	(machine2, machine__2) = seed_scene!(machine1, 0)
	(machine3, machine__3) = fw_loop!(machine2, cmd_buf, 0, machine__2, 0, 0)
	result = machine__3
	line!(CceText.printed(result))
	Machine.halt!(machine3)
	Ok({})
}
