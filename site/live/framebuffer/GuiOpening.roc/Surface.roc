# Surface -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceText
import Rasterizer

Surface :: [].{
	Surface := { sf_id : CceText, sf_x : I64, sf_y : I64, sf_z : I64, sf_fb : Rasterizer.Framebuf, sf_visible : Bool, sf_dirty : Bool, sf_opacity : I64 }.{
		is_eq : Surface.Surface, Surface.Surface -> Bool
		is_eq = |a, b| eq_Surface(a, b)
	}
	Compositor := { comp_surfaces : List(Surface.Surface), comp_count : I64, comp_width : I64, comp_height : I64, comp_bg : I64 }.{
		is_eq : Surface.Compositor, Surface.Compositor -> Bool
		is_eq = |a, b| eq_Compositor(a, b)
	}

	compositor_new : I64, I64, I64 -> Surface.Compositor
	compositor_new = |w, h, bg| Surface.Compositor.{ comp_surfaces: [], comp_count: 0, comp_width: w, comp_height: h, comp_bg: bg }

	eq_Surface : Surface.Surface, Surface.Surface -> Bool
	eq_Surface = |ex, ey| ((((((((ex.sf_id == ey.sf_id) and (ex.sf_x == ey.sf_x)) and (ex.sf_y == ey.sf_y)) and (ex.sf_z == ey.sf_z)) and Rasterizer.eq_Framebuf(ex.sf_fb, ey.sf_fb)) and (ex.sf_visible == ey.sf_visible)) and (ex.sf_dirty == ey.sf_dirty)) and (ex.sf_opacity == ey.sf_opacity))

	eq_Compositor : Surface.Compositor, Surface.Compositor -> Bool
	eq_Compositor = |ex, ey| (((((ex.comp_surfaces == ey.comp_surfaces) and (ex.comp_count == ey.comp_count)) and (ex.comp_width == ey.comp_width)) and (ex.comp_height == ey.comp_height)) and (ex.comp_bg == ey.comp_bg))
}
