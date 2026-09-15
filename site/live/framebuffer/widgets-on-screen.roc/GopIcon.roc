# GopIcon -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import GopDraw
import Icon
import Mem
import Vector

GopIcon :: [].{
	IconKit : { ik_dir : Icon.Icon, ik_src : Icon.Icon, ik_img : Icon.Icon, ik_bin : Icon.Icon }

	gicon_dir : I64
	gicon_dir = 0

	gicon_src : I64
	gicon_src = 1

	gicon_img : I64
	gicon_img = 2

	gicon_bin : I64
	gicon_bin = 3

	gicon_kit : GopIcon.IconKit
	gicon_kit = { ik_dir: Icon.ico_folder_8, ik_src: Icon.ico_code_8, ik_img: Icon.ico_image_8, ik_bin: Icon.ico_file_8 }

	gicon_pick : GopIcon.IconKit, I64 -> Icon.Icon
	gicon_pick = |kit, kind| (if (kind == gicon_dir) { kit.ik_dir } else { (if (kind == gicon_src) { kit.ik_src } else { (if (kind == gicon_img) { kit.ik_img } else { kit.ik_bin }) }) })

	gicon_cols! : Mem.Mem, I64, I64, I64, Icon.Icon, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gicon_cols! = |mem, base, stride, rows, ico, px, py, scale, color, row, col| (if (col >= ico.ico_width) { (mem, 0) } else { (if ((px + ((col + 1) * scale)) > stride) { (mem, 0) } else { ({
		on = Icon.icon_get(ico, col, row)
		(mem1, _d) = (if (on == 1) { GopDraw.gop_fill_rect!(mem, base, stride, rows, (px + (col * scale)), (py + (row * scale)), scale, scale, color) } else { (mem, 0) })
		gicon_cols!(mem1, base, stride, rows, ico, px, py, scale, color, row, (col + 1))
	}) }) })

	gicon_rows! : Mem.Mem, I64, I64, I64, Icon.Icon, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gicon_rows! = |mem, base, stride, rows, ico, px, py, scale, color, row| (if (row >= ico.ico_height) { (mem, 0) } else { ({
		(mem1, _r) = gicon_cols!(mem, base, stride, rows, ico, px, py, scale, color, row, 0)
		gicon_rows!(mem1, base, stride, rows, ico, px, py, scale, color, (row + 1))
	}) })

	gicon_blit! : Mem.Mem, I64, I64, I64, Icon.Icon, I64, I64, I64, I64 => (Mem.Mem, I64)
	gicon_blit! = |mem, base, stride, rows, ico, px, py, scale, color| (if (scale <= 0) { (mem, 0) } else { gicon_rows!(mem, base, stride, rows, ico, px, py, scale, color, 0) })

	gicon_size : Icon.Icon, I64 -> I64
	gicon_size = |ico, scale| (ico.ico_width * scale)

	gicon_render! : Mem.Mem, Vector.VecPath, I64 => (Mem.Mem, I64)
	gicon_render! = |mem, p, n| ({
		(mem3, mem__26) = ({
		(mem1, buf) = Mem.alloc(mem, (n * n))
		cov = Vector.vec_coverage_in(p, gicon_em, n)
		(mem2, _w) = gicon_store!(mem1, buf, cov, 0, (n * n))
		(mem2, buf)
	})
		(mem3, mem__26)
	})

	gicon_store! : Mem.Mem, I64, List(I64), I64, I64 => (Mem.Mem, I64)
	gicon_store! = |mem, buf, cov, i, n| (if (i >= n) { (mem, 0) } else { ({
		(mem1, _w) = Mem.store!(mem, buf, i, (List.get(cov, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), 1)
		gicon_store!(mem1, buf, cov, (i + 1), n)
	}) })

	gicon_cov_at! : Mem.Mem, I64, I64, I64, I64 => (Mem.Mem, I64)
	gicon_cov_at! = |mem, blob, n, x, y| Mem.load!(mem, blob, ((y * n) + x), 1)

	gicon_cov_cols! : Mem.Mem, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gicon_cov_cols! = |mem, base, stride, rows, blob, n, px, py, color, row, col| (if (col >= n) { (mem, 0) } else { (if ((px + col) >= stride) { (mem, 0) } else { ({
		(mem2, _d) = ({
			(mem1, mem__27) = gicon_cov_at!(mem, blob, n, col, row)
			GopDraw.gop_blend!(mem1, base, stride, rows, (px + col), (py + row), color, mem__27)
		})
		gicon_cov_cols!(mem2, base, stride, rows, blob, n, px, py, color, row, (col + 1))
	}) }) })

	gicon_cov_rows! : Mem.Mem, I64, I64, I64, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gicon_cov_rows! = |mem, base, stride, rows, blob, n, px, py, color, row| (if (row >= n) { (mem, 0) } else { ({
		(mem1, _r) = gicon_cov_cols!(mem, base, stride, rows, blob, n, px, py, color, row, 0)
		gicon_cov_rows!(mem1, base, stride, rows, blob, n, px, py, color, (row + 1))
	}) })

	gicon_blit_cov! : Mem.Mem, I64, I64, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gicon_blit_cov! = |mem, base, stride, rows, blob, n, px, py, color| (if (n <= 0) { (mem, 0) } else { gicon_cov_rows!(mem, base, stride, rows, blob, n, px, py, color, 0) })

	gicon_em : I64
	gicon_em = 32

	gicon_box : Vector.VecPath, I64, I64, I64, I64 -> Vector.VecPath
	gicon_box = |p, x, y, w, h| ({
		a = Vector.vec_move_to(p, x, y)
		b = Vector.vec_line_to(a, (x + w), y)
		c = Vector.vec_line_to(b, (x + w), (y + h))
		d = Vector.vec_line_to(c, x, (y + h))
		Vector.vec_close(d)
	})

	gicon_ring : Vector.VecPath, I64, I64, I64, I64 -> Vector.VecPath
	gicon_ring = |p, cx, cy, ro, ri| Vector.vec_circle_loop(Vector.vec_circle_loop(p, cx, cy, ro, 24, 0, True), cx, cy, ri, 24, 0, True)

	gicon_vec_menu : Vector.VecPath
	gicon_vec_menu = gicon_box(gicon_box(gicon_box(Vector.vec_path_new, 5, 7, 22, 3), 5, 14, 22, 3), 5, 21, 22, 3)

	gicon_vec_grid : Vector.VecPath
	gicon_vec_grid = gicon_box(gicon_box(gicon_box(gicon_box(Vector.vec_path_new, 5, 5, 9, 9), 18, 5, 9, 9), 5, 18, 9, 9), 18, 18, 9, 9)

	gicon_vec_folder : Vector.VecPath
	gicon_vec_folder = ({
		p = Vector.vec_move_to(Vector.vec_path_new, 4, 9)
		p2 = Vector.vec_line_to(p, 13, 9)
		p3 = Vector.vec_line_to(p2, 15, 12)
		p4 = Vector.vec_line_to(p3, 28, 12)
		p5 = Vector.vec_line_to(p4, 28, 26)
		p6 = Vector.vec_line_to(p5, 4, 26)
		Vector.vec_close(p6)
	})

	gicon_vec_edit : Vector.VecPath
	gicon_vec_edit = ({
		p = Vector.vec_move_to(Vector.vec_path_new, 22, 4)
		p2 = Vector.vec_line_to(p, 28, 10)
		p3 = Vector.vec_line_to(p2, 13, 25)
		p4 = Vector.vec_line_to(p3, 5, 27)
		p5 = Vector.vec_line_to(p4, 7, 19)
		Vector.vec_close(p5)
	})

	gicon_vec_terminal : Vector.VecPath
	gicon_vec_terminal = ({
		frame = gicon_box(gicon_box(Vector.vec_path_new, 3, 6, 26, 20), 6, 9, 20, 14)
		p = Vector.vec_move_to(frame, 9, 13)
		p2 = Vector.vec_line_to(p, 15, 16)
		p3 = Vector.vec_line_to(p2, 9, 19)
		p4 = Vector.vec_line_to(p3, 9, 17)
		p5 = Vector.vec_line_to(p4, 12, 16)
		p6 = Vector.vec_line_to(p5, 9, 15)
		Vector.vec_close(p6)
	})

	gicon_vec_power : Vector.VecPath
	gicon_vec_power = gicon_box(gicon_ring(Vector.vec_path_new, 16, 18, 12, 8), 14, 4, 4, 13)

	gicon_vec_clock : Vector.VecPath
	gicon_vec_clock = ({
		r = gicon_ring(Vector.vec_path_new, 16, 16, 13, 10)
		gicon_box(gicon_box(r, 15, 8, 2, 9), 16, 15, 7, 2)
	})

	gicon_vec_calendar : Vector.VecPath
	gicon_vec_calendar = ({
		f = gicon_box(gicon_box(Vector.vec_path_new, 4, 7, 24, 21), 7, 14, 18, 11)
		gicon_box(gicon_box(f, 9, 3, 3, 6), 20, 3, 3, 6)
	})

	gicon_vec_eye : Vector.VecPath
	gicon_vec_eye = ({
		p = Vector.vec_move_to(Vector.vec_path_new, 3, 16)
		p2 = Vector.vec_bezier_to(p, 10, 6, 22, 6, 29, 16)
		p3 = Vector.vec_bezier_to(p2, 22, 26, 10, 26, 3, 16)
		lens = Vector.vec_close(p3)
		Vector.vec_circle_loop(lens, 16, 16, 4, 16, 0, True)
	})

	gicon_vec_bell : Vector.VecPath
	gicon_vec_bell = ({
		p = Vector.vec_move_to(Vector.vec_path_new, 7, 22)
		p2 = Vector.vec_bezier_to(p, 9, 18, 8, 8, 16, 5)
		p3 = Vector.vec_bezier_to(p2, 24, 8, 23, 18, 25, 22)
		p4 = Vector.vec_line_to(p3, 7, 22)
		body = Vector.vec_close(p4)
		gicon_box(body, 13, 24, 6, 3)
	})

	gicon_vec_cloud : Vector.VecPath
	gicon_vec_cloud = ({
		p = Vector.vec_move_to(Vector.vec_path_new, 6, 23)
		p2 = Vector.vec_bezier_to(p, 1, 23, 1, 15, 7, 15)
		p3 = Vector.vec_bezier_to(p2, 7, 6, 19, 5, 21, 13)
		p4 = Vector.vec_bezier_to(p3, 29, 12, 31, 23, 25, 23)
		Vector.vec_close(p4)
	})

	gicon_vec_check : Vector.VecPath
	gicon_vec_check = ({
		p = Vector.vec_move_to(Vector.vec_path_new, 5, 16)
		p2 = Vector.vec_line_to(p, 9, 12)
		p3 = Vector.vec_line_to(p2, 13, 17)
		p4 = Vector.vec_line_to(p3, 24, 6)
		p5 = Vector.vec_line_to(p4, 28, 10)
		p6 = Vector.vec_line_to(p5, 13, 26)
		Vector.vec_close(p6)
	})

	gicon_vec_image : Vector.VecPath
	gicon_vec_image = ({
		f = gicon_box(gicon_box(Vector.vec_path_new, 3, 6, 26, 20), 6, 9, 20, 14)
		s = Vector.vec_circle_loop(f, 11, 14, 3, 16, 0, True)
		p = Vector.vec_move_to(s, 8, 22)
		p2 = Vector.vec_line_to(p, 14, 15)
		p3 = Vector.vec_line_to(p2, 20, 22)
		Vector.vec_close(p3)
	})

	gicon_vec_star : Vector.VecPath
	gicon_vec_star = ({
		p = Vector.vec_move_to(Vector.vec_path_new, 16, 3)
		p2 = Vector.vec_line_to(p, 20, 12)
		p3 = Vector.vec_line_to(p2, 30, 13)
		p4 = Vector.vec_line_to(p3, 22, 19)
		p5 = Vector.vec_line_to(p4, 25, 29)
		p6 = Vector.vec_line_to(p5, 16, 23)
		p7 = Vector.vec_line_to(p6, 7, 29)
		p8 = Vector.vec_line_to(p7, 10, 19)
		p9 = Vector.vec_line_to(p8, 2, 13)
		p10 = Vector.vec_line_to(p9, 12, 12)
		Vector.vec_close(p10)
	})

	gicon_vec_settings : Vector.VecPath
	gicon_vec_settings = ({
		r = gicon_ring(Vector.vec_path_new, 16, 16, 11, 6)
		t = gicon_box(gicon_box(r, 13, 1, 6, 4), 13, 27, 6, 4)
		gicon_box(gicon_box(t, 1, 13, 4, 6), 27, 13, 4, 6)
	})

	gicon_vec_info : Vector.VecPath
	gicon_vec_info = ({
		d = Vector.vec_circle_loop(Vector.vec_path_new, 16, 16, 13, 24, 0, True)
		gicon_box(gicon_box(d, 14, 8, 4, 4), 14, 14, 4, 11)
	})

	gicon_vec_code : Vector.VecPath
	gicon_vec_code = ({
		a = Vector.vec_move_to(Vector.vec_path_new, 11, 8)
		a2 = Vector.vec_line_to(a, 14, 11)
		a3 = Vector.vec_line_to(a2, 8, 16)
		a4 = Vector.vec_line_to(a3, 14, 21)
		a5 = Vector.vec_line_to(a4, 11, 24)
		a6 = Vector.vec_line_to(a5, 2, 16)
		left = Vector.vec_close(a6)
		b = Vector.vec_move_to(left, 21, 8)
		b2 = Vector.vec_line_to(b, 30, 16)
		b3 = Vector.vec_line_to(b2, 21, 24)
		b4 = Vector.vec_line_to(b3, 18, 21)
		b5 = Vector.vec_line_to(b4, 24, 16)
		b6 = Vector.vec_line_to(b5, 18, 11)
		Vector.vec_close(b6)
	})

	gicon_vec_file : Vector.VecPath
	gicon_vec_file = ({
		p = Vector.vec_move_to(Vector.vec_path_new, 7, 3)
		p2 = Vector.vec_line_to(p, 19, 3)
		p3 = Vector.vec_line_to(p2, 25, 9)
		p4 = Vector.vec_line_to(p3, 25, 29)
		p5 = Vector.vec_line_to(p4, 7, 29)
		Vector.vec_close(p5)
	})

	gicon_vec_home : Vector.VecPath
	gicon_vec_home = ({
		p = Vector.vec_move_to(Vector.vec_path_new, 16, 3)
		p2 = Vector.vec_line_to(p, 30, 15)
		p3 = Vector.vec_line_to(p2, 26, 15)
		p4 = Vector.vec_line_to(p3, 26, 28)
		p5 = Vector.vec_line_to(p4, 6, 28)
		p6 = Vector.vec_line_to(p5, 6, 15)
		p7 = Vector.vec_line_to(p6, 2, 15)
		Vector.vec_close(p7)
	})

	gicon_vec_named : Str -> Vector.VecPath
	gicon_vec_named = |name| (if (name == "menu") { gicon_vec_menu } else { (if (name == "grid") { gicon_vec_grid } else { (if (name == "folder") { gicon_vec_folder } else { (if (name == "edit") { gicon_vec_edit } else { (if (name == "terminal") { gicon_vec_terminal } else { (if (name == "power") { gicon_vec_power } else { (if (name == "clock") { gicon_vec_clock } else { (if (name == "calendar") { gicon_vec_calendar } else { (if (name == "eye") { gicon_vec_eye } else { (if (name == "bell") { gicon_vec_bell } else { (if (name == "cloud") { gicon_vec_cloud } else { (if (name == "check") { gicon_vec_check } else { (if (name == "image") { gicon_vec_image } else { (if (name == "star") { gicon_vec_star } else { (if (name == "settings") { gicon_vec_settings } else { (if (name == "info") { gicon_vec_info } else { (if (name == "code") { gicon_vec_code } else { (if (name == "home") { gicon_vec_home } else { (if (name == "win-close") { gicon_vec_win_close } else { (if (name == "win-min") { gicon_vec_win_min } else { (if (name == "win-max") { gicon_vec_win_max } else { gicon_vec_file }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) })

	gicon_vec_win_close : Vector.VecPath
	gicon_vec_win_close = ({
		a = Vector.vec_move_to(Vector.vec_path_new, 6, 9)
		b = Vector.vec_line_to(a, 9, 6)
		c = Vector.vec_line_to(b, 16, 13)
		d = Vector.vec_line_to(c, 23, 6)
		e = Vector.vec_line_to(d, 26, 9)
		f = Vector.vec_line_to(e, 19, 16)
		g = Vector.vec_line_to(f, 26, 23)
		i = Vector.vec_line_to(g, 23, 26)
		j = Vector.vec_line_to(i, 16, 19)
		k = Vector.vec_line_to(j, 9, 26)
		l = Vector.vec_line_to(k, 6, 23)
		m = Vector.vec_line_to(l, 13, 16)
		Vector.vec_close(m)
	})

	gicon_vec_win_min : Vector.VecPath
	gicon_vec_win_min = gicon_box(Vector.vec_path_new, 6, 20, 20, 3)

	gicon_vec_win_max : Vector.VecPath
	gicon_vec_win_max = gicon_box(gicon_box(Vector.vec_path_new, 6, 6, 20, 20), 9, 9, 14, 14)

	gicon_drawn_count : I64
	gicon_drawn_count = 22

	gicon_drawn_name : I64 -> Str
	gicon_drawn_name = |i| (if (i == 0) { "menu" } else { (if (i == 1) { "grid" } else { (if (i == 2) { "folder" } else { (if (i == 3) { "edit" } else { (if (i == 4) { "terminal" } else { (if (i == 5) { "power" } else { (if (i == 6) { "clock" } else { (if (i == 7) { "calendar" } else { (if (i == 8) { "eye" } else { (if (i == 9) { "bell" } else { (if (i == 10) { "cloud" } else { (if (i == 11) { "check" } else { (if (i == 12) { "image" } else { (if (i == 13) { "star" } else { (if (i == 14) { "settings" } else { (if (i == 15) { "info" } else { (if (i == 16) { "code" } else { (if (i == 17) { "home" } else { (if (i == 19) { "win-close" } else { (if (i == 20) { "win-min" } else { (if (i == 21) { "win-max" } else { "file" }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) })

	gicon_drawn_slot : Str, I64 -> I64
	gicon_drawn_slot = |name, i| (if (i >= gicon_drawn_count) { (0 - 1) } else { (if (gicon_drawn_name(i) == name) { i } else { gicon_drawn_slot(name, (i + 1)) }) })

	gicon_drawn : Str -> Bool
	gicon_drawn = |name| (gicon_drawn_slot(name, 0) >= 0)

	gicon_vec_disc : Vector.VecPath
	gicon_vec_disc = Vector.vec_circle(16, 16, 13, 24)

	gicon_vec_doc : Vector.VecPath
	gicon_vec_doc = ({
		p = Vector.vec_move_to(Vector.vec_path_new, 8, 4)
		p2 = Vector.vec_line_to(p, 20, 4)
		p3 = Vector.vec_line_to(p2, 24, 8)
		p4 = Vector.vec_line_to(p3, 24, 28)
		p5 = Vector.vec_line_to(p4, 8, 28)
		Vector.vec_close(p5)
	})

	gicon_vec_drop : Vector.VecPath
	gicon_vec_drop = ({
		p = Vector.vec_move_to(Vector.vec_path_new, 16, 4)
		p2 = Vector.vec_bezier_to(p, 28, 14, 28, 22, 16, 28)
		p3 = Vector.vec_bezier_to(p2, 4, 22, 4, 14, 16, 4)
		Vector.vec_close(p3)
	})

	gicon_named : Str -> Icon.Icon
	gicon_named = |name| (if (name == "folder") { Icon.ico_folder_8 } else { (if (name == "code") { Icon.ico_code_8 } else { (if (name == "image") { Icon.ico_image_8 } else { (if (name == "clock") { Icon.ico_clock_8 } else { (if (name == "calendar") { Icon.ico_calendar_8 } else { (if (name == "grid") { Icon.ico_grid_8 } else { (if (name == "eye") { Icon.ico_eye_8 } else { (if (name == "edit") { Icon.ico_edit_8 } else { (if (name == "bell") { Icon.ico_bell_8 } else { (if (name == "terminal") { Icon.ico_terminal_8 } else { (if (name == "cloud") { Icon.ico_cloud_8 } else { (if (name == "check") { Icon.ico_check_8 } else { (if (name == "star") { Icon.ico_star_8 } else { (if (name == "settings") { Icon.ico_settings_8 } else { (if (name == "info") { Icon.ico_info_8 } else { (if (name == "menu") { Icon.ico_menu_8 } else { (if (name == "power") { Icon.ico_power_8 } else { (if (name == "home") { Icon.ico_home_8 } else { Icon.ico_file_8 }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) })
}
