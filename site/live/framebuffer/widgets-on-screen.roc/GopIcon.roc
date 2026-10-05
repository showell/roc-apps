# GopIcon -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceText
import GopDraw
import Icon
import Mem

GopIcon :: [].{
	IconKit := { ik_dir : Icon.Icon, ik_src : Icon.Icon, ik_img : Icon.Icon, ik_bin : Icon.Icon }.{
		is_eq : GopIcon.IconKit, GopIcon.IconKit -> Bool
		is_eq = |a, b| eq_IconKit(a, b)
	}

	gicon_cols! : Mem.Mem, I64, I64, I64, Icon.Icon, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gicon_cols! = |mem, base, stride, rows, ico, px, py, scale, color, row, col| (if (col >= ico.ico_width) { (mem, 0) } else { (if ((px + ((col + 1) * scale)) > stride) { (mem, 0) } else { ({
		on : I64
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

	gicon_named : CceText -> Icon.Icon
	gicon_named = |name| (if (name == "folder") { Icon.ico_folder_8 } else { (if (name == "code") { Icon.ico_code_8 } else { (if (name == "image") { Icon.ico_image_8 } else { (if (name == "clock") { Icon.ico_clock_8 } else { (if (name == "calendar") { Icon.ico_calendar_8 } else { (if (name == "grid") { Icon.ico_grid_8 } else { (if (name == "eye") { Icon.ico_eye_8 } else { (if (name == "edit") { Icon.ico_edit_8 } else { (if (name == "bell") { Icon.ico_bell_8 } else { (if (name == "terminal") { Icon.ico_terminal_8 } else { (if (name == "cloud") { Icon.ico_cloud_8 } else { (if (name == "check") { Icon.ico_check_8 } else { (if (name == "star") { Icon.ico_star_8 } else { (if (name == "settings") { Icon.ico_settings_8 } else { (if (name == "info") { Icon.ico_info_8 } else { (if (name == "menu") { Icon.ico_menu_8 } else { (if (name == "power") { Icon.ico_power_8 } else { (if (name == "home") { Icon.ico_home_8 } else { Icon.ico_file_8 }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) })

	eq_IconKit : GopIcon.IconKit, GopIcon.IconKit -> Bool
	eq_IconKit = |ex, ey| (((Icon.eq_Icon(ex.ik_dir, ey.ik_dir) and Icon.eq_Icon(ex.ik_src, ey.ik_src)) and Icon.eq_Icon(ex.ik_img, ey.ik_img)) and Icon.eq_Icon(ex.ik_bin, ey.ik_bin))
}
