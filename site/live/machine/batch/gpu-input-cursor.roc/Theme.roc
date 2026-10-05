# Theme -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceText

Theme :: [].{
	Palette := { pal_bg : I64, pal_fg : I64, pal_primary : I64, pal_secondary : I64, pal_accent : I64, pal_muted : I64, pal_error : I64, pal_success : I64, pal_warning : I64, pal_border : I64 }.{
		is_eq : Theme.Palette, Theme.Palette -> Bool
		is_eq = |a, b| eq_Palette(a, b)
	}
	CornerStyle : [CornerSharp, CornerRound(I64), CornerBevel(I64)]
	BorderSide := { brd_width : I64, brd_color : I64 }.{
		is_eq : Theme.BorderSide, Theme.BorderSide -> Bool
		is_eq = |a, b| eq_BorderSide(a, b)
	}
	Border := { bdr_top : Theme.BorderSide, bdr_right : Theme.BorderSide, bdr_bottom : Theme.BorderSide, bdr_left : Theme.BorderSide, bdr_corner : Theme.CornerStyle }.{
		is_eq : Theme.Border, Theme.Border -> Bool
		is_eq = |a, b| eq_Border(a, b)
	}
	Edges := { edge_top : I64, edge_right : I64, edge_bottom : I64, edge_left : I64 }.{
		is_eq : Theme.Edges, Theme.Edges -> Bool
		is_eq = |a, b| eq_Edges(a, b)
	}
	Shadow := { sh_offset_x : I64, sh_offset_y : I64, sh_blur : I64, sh_color : I64, sh_enabled : Bool }.{
		is_eq : Theme.Shadow, Theme.Shadow -> Bool
		is_eq = |a, b| eq_Shadow(a, b)
	}
	Gradient := { gr_start_color : I64, gr_end_color : I64, gr_vertical : Bool, gr_enabled : Bool }.{
		is_eq : Theme.Gradient, Theme.Gradient -> Bool
		is_eq = |a, b| eq_Gradient(a, b)
	}
	Bevel := { bv_light : I64, bv_shade : I64, bv_width : I64, bv_raised : Bool, bv_enabled : Bool }.{
		is_eq : Theme.Bevel, Theme.Bevel -> Bool
		is_eq = |a, b| eq_Bevel(a, b)
	}
	AccentBorder := { ab_side : I64, ab_width : I64, ab_color : I64, ab_enabled : Bool }.{
		is_eq : Theme.AccentBorder, Theme.AccentBorder -> Bool
		is_eq = |a, b| eq_AccentBorder(a, b)
	}
	WidgetStyle := { ws_bg : I64, ws_fg : I64, ws_border : Theme.Border, ws_padding : Theme.Edges, ws_margin : Theme.Edges, ws_min_width : I64, ws_min_height : I64, ws_shadow : Theme.Shadow, ws_gradient : Theme.Gradient, ws_accent_border : Theme.AccentBorder, ws_bevel : Theme.Bevel }.{
		is_eq : Theme.WidgetStyle, Theme.WidgetStyle -> Bool
		is_eq = |a, b| eq_WidgetStyle(a, b)
	}
	StateStyles := { ss_normal : Theme.WidgetStyle, ss_hover : Theme.WidgetStyle, ss_pressed : Theme.WidgetStyle, ss_disabled : Theme.WidgetStyle, ss_focused : Theme.WidgetStyle }.{
		is_eq : Theme.StateStyles, Theme.StateStyles -> Bool
		is_eq = |a, b| eq_StateStyles(a, b)
	}
	Theme := { th_name : CceText, th_palette : Theme.Palette, th_panel : Theme.StateStyles, th_button : Theme.StateStyles, th_label : Theme.StateStyles, th_input : Theme.StateStyles, th_gauge : Theme.StateStyles, th_separator : Theme.StateStyles }.{
		is_eq : Theme.Theme, Theme.Theme -> Bool
		is_eq = |a, b| eq_Theme(a, b)
	}

	shadow_none : Theme.Shadow
	shadow_none = Theme.Shadow.{ sh_offset_x: 0, sh_offset_y: 0, sh_blur: 0, sh_color: 0, sh_enabled: False }

	gradient_none : Theme.Gradient
	gradient_none = Theme.Gradient.{ gr_start_color: 0, gr_end_color: 0, gr_vertical: True, gr_enabled: False }

	bevel_none : Theme.Bevel
	bevel_none = Theme.Bevel.{ bv_light: 0, bv_shade: 0, bv_width: 0, bv_raised: True, bv_enabled: False }

	accent_border_none : Theme.AccentBorder
	accent_border_none = Theme.AccentBorder.{ ab_side: 0, ab_width: 0, ab_color: 0, ab_enabled: False }

	edges_uniform : I64 -> Theme.Edges
	edges_uniform = |v| Theme.Edges.{ edge_top: v, edge_right: v, edge_bottom: v, edge_left: v }

	edges_zero : Theme.Edges
	edges_zero = Theme.Edges.{ edge_top: 0, edge_right: 0, edge_bottom: 0, edge_left: 0 }

	edges_xy : I64, I64 -> Theme.Edges
	edges_xy = |x, y| Theme.Edges.{ edge_top: y, edge_right: x, edge_bottom: y, edge_left: x }

	border_side : I64, I64 -> Theme.BorderSide
	border_side = |w, c| Theme.BorderSide.{ brd_width: w, brd_color: c }

	border_side_none : Theme.BorderSide
	border_side_none = Theme.BorderSide.{ brd_width: 0, brd_color: 0 }

	border_uniform : I64, I64, Theme.CornerStyle -> Theme.Border
	border_uniform = |w, c, corner| ({
		side = border_side(w, c)
		Theme.Border.{ bdr_top: side, bdr_right: side, bdr_bottom: side, bdr_left: side, bdr_corner: corner }
	})

	border_none : Theme.Border
	border_none = Theme.Border.{ bdr_top: border_side_none, bdr_right: border_side_none, bdr_bottom: border_side_none, bdr_left: border_side_none, bdr_corner: CornerSharp }

	widget_style : I64, I64, Theme.Border, Theme.Edges, Theme.Edges -> Theme.WidgetStyle
	widget_style = |bg, fg, bdr, pad, mar| Theme.WidgetStyle.{ ws_bg: bg, ws_fg: fg, ws_border: bdr, ws_padding: pad, ws_margin: mar, ws_min_width: 0, ws_min_height: 0, ws_shadow: shadow_none, ws_gradient: gradient_none, ws_accent_border: accent_border_none, ws_bevel: bevel_none }

	widget_style_bare : Theme.WidgetStyle
	widget_style_bare = widget_style(0, 0, border_none, edges_zero, edges_zero)

	state_styles_flat : Theme.WidgetStyle -> Theme.StateStyles
	state_styles_flat = |s| Theme.StateStyles.{ ss_normal: s, ss_hover: s, ss_pressed: s, ss_disabled: s, ss_focused: s }

	edges_h : Theme.Edges -> I64
	edges_h = |e| (e.edge_left + e.edge_right)

	edges_v : Theme.Edges -> I64
	edges_v = |e| (e.edge_top + e.edge_bottom)

	palette_terminal : Theme.Palette
	palette_terminal = Theme.Palette.{ pal_bg: 1052688, pal_fg: 13421772, pal_primary: 3394611, pal_secondary: 2263842, pal_accent: 5614335, pal_muted: 6710886, pal_error: 13369344, pal_success: 3394560, pal_warning: 13408512, pal_border: 4473924 }

	theme_terminal : Theme.Theme
	theme_terminal = ({
		pal = palette_terminal
		bdr = border_uniform(1, pal.pal_border, CornerSharp)
		pad = edges_uniform(4)
		mar = edges_uniform(2)
		base = widget_style(pal.pal_bg, pal.pal_fg, bdr, pad, mar)
		btn = widget_style(pal.pal_primary, pal.pal_bg, bdr, pad, mar)
		btn_h = widget_style(pal.pal_accent, pal.pal_bg, bdr, pad, mar)
		btn_p = widget_style(pal.pal_secondary, pal.pal_fg, bdr, pad, mar)
		btn_d = widget_style(pal.pal_muted, pal.pal_muted, bdr, pad, mar)
		inp = widget_style(pal.pal_bg, pal.pal_fg, border_uniform(1, pal.pal_muted, CornerSharp), pad, mar)
		inp_f = widget_style(pal.pal_bg, pal.pal_fg, border_uniform(2, pal.pal_accent, CornerSharp), pad, mar)
		lbl = widget_style(0, pal.pal_fg, border_none, edges_zero, mar)
		sep = widget_style(pal.pal_border, pal.pal_border, border_none, edges_zero, edges_xy(0, 4))
		Theme.Theme.{ th_name: "terminal", th_palette: pal, th_panel: state_styles_flat(base), th_button: Theme.StateStyles.{ ss_normal: btn, ss_hover: btn_h, ss_pressed: btn_p, ss_disabled: btn_d, ss_focused: btn_h }, th_label: state_styles_flat(lbl), th_input: Theme.StateStyles.{ ss_normal: inp, ss_hover: inp, ss_pressed: inp, ss_disabled: btn_d, ss_focused: inp_f }, th_gauge: state_styles_flat(widget_style(pal.pal_bg, pal.pal_primary, bdr, edges_uniform(2), mar)), th_separator: state_styles_flat(sep) }
	})

	theme_resolve_panel : Theme.Theme, I64 -> Theme.WidgetStyle
	theme_resolve_panel = |th, state| resolve_state(th.th_panel, state)

	theme_resolve_button : Theme.Theme, I64 -> Theme.WidgetStyle
	theme_resolve_button = |th, state| resolve_state(th.th_button, state)

	theme_resolve_label : Theme.Theme, I64 -> Theme.WidgetStyle
	theme_resolve_label = |th, state| resolve_state(th.th_label, state)

	theme_resolve_input : Theme.Theme, I64 -> Theme.WidgetStyle
	theme_resolve_input = |th, state| resolve_state(th.th_input, state)

	theme_resolve_gauge : Theme.Theme, I64 -> Theme.WidgetStyle
	theme_resolve_gauge = |th, state| resolve_state(th.th_gauge, state)

	theme_resolve_separator : Theme.Theme, I64 -> Theme.WidgetStyle
	theme_resolve_separator = |th, state| resolve_state(th.th_separator, state)

	resolve_state : Theme.StateStyles, I64 -> Theme.WidgetStyle
	resolve_state = |ss, state| (if (state == 1) { ss.ss_hover } else { (if (state == 2) { ss.ss_pressed } else { (if (state == 3) { ss.ss_disabled } else { (if (state == 4) { ss.ss_focused } else { ss.ss_normal }) }) }) })

	state_normal : I64
	state_normal = 0

	state_hover : I64
	state_hover = 1

	state_pressed : I64
	state_pressed = 2

	state_disabled : I64
	state_disabled = 3

	state_focused : I64
	state_focused = 4

	flag_focused : I64
	flag_focused = 1

	flag_hovered : I64
	flag_hovered = 2

	flag_pressed : I64
	flag_pressed = 4

	flag_disabled : I64
	flag_disabled = 16

	flag_has : I64, I64 -> Bool
	flag_has = |flags, f| (I64.bitwise_and(flags, f) != 0)

	theme_state_of_flags : I64 -> I64
	theme_state_of_flags = |flags| (if flag_has(flags, flag_disabled) { state_disabled } else { (if flag_has(flags, flag_pressed) { state_pressed } else { (if flag_has(flags, flag_hovered) { state_hover } else { (if flag_has(flags, flag_focused) { state_focused } else { state_normal }) }) }) })

	tone_none : I64
	tone_none = 0

	tone_primary : I64
	tone_primary = 1

	tone_success : I64
	tone_success = 2

	tone_warning : I64
	tone_warning = 3

	tone_error : I64
	tone_error = 4

	tone_muted : I64
	tone_muted = 5

	theme_tone_fg : Theme.Theme, I64, I64 -> I64
	theme_tone_fg = |th, tone, fallback| ({
		pal = th.th_palette
		(if (tone == tone_primary) { pal.pal_primary } else { (if (tone == tone_success) { pal.pal_success } else { (if (tone == tone_warning) { pal.pal_warning } else { (if (tone == tone_error) { pal.pal_error } else { (if (tone == tone_muted) { pal.pal_muted } else { fallback }) }) }) }) })
	})

	eq_Palette : Theme.Palette, Theme.Palette -> Bool
	eq_Palette = |ex, ey| ((((((((((ex.pal_bg == ey.pal_bg) and (ex.pal_fg == ey.pal_fg)) and (ex.pal_primary == ey.pal_primary)) and (ex.pal_secondary == ey.pal_secondary)) and (ex.pal_accent == ey.pal_accent)) and (ex.pal_muted == ey.pal_muted)) and (ex.pal_error == ey.pal_error)) and (ex.pal_success == ey.pal_success)) and (ex.pal_warning == ey.pal_warning)) and (ex.pal_border == ey.pal_border))

	eq_CornerStyle : Theme.CornerStyle, Theme.CornerStyle -> Bool
	eq_CornerStyle = |ex, ey| (match ex {
		CornerSharp => (match ey {
			CornerSharp => True
			_ => False
		})
		CornerRound(exf0) => (match ey {
			CornerRound(eyf0) => (exf0 == eyf0)
			_ => False
		})
		CornerBevel(exf0) => (match ey {
			CornerBevel(eyf0) => (exf0 == eyf0)
			_ => False
		})
	})

	eq_BorderSide : Theme.BorderSide, Theme.BorderSide -> Bool
	eq_BorderSide = |ex, ey| ((ex.brd_width == ey.brd_width) and (ex.brd_color == ey.brd_color))

	eq_Border : Theme.Border, Theme.Border -> Bool
	eq_Border = |ex, ey| ((((eq_BorderSide(ex.bdr_top, ey.bdr_top) and eq_BorderSide(ex.bdr_right, ey.bdr_right)) and eq_BorderSide(ex.bdr_bottom, ey.bdr_bottom)) and eq_BorderSide(ex.bdr_left, ey.bdr_left)) and eq_CornerStyle(ex.bdr_corner, ey.bdr_corner))

	eq_Edges : Theme.Edges, Theme.Edges -> Bool
	eq_Edges = |ex, ey| ((((ex.edge_top == ey.edge_top) and (ex.edge_right == ey.edge_right)) and (ex.edge_bottom == ey.edge_bottom)) and (ex.edge_left == ey.edge_left))

	eq_Shadow : Theme.Shadow, Theme.Shadow -> Bool
	eq_Shadow = |ex, ey| (((((ex.sh_offset_x == ey.sh_offset_x) and (ex.sh_offset_y == ey.sh_offset_y)) and (ex.sh_blur == ey.sh_blur)) and (ex.sh_color == ey.sh_color)) and (ex.sh_enabled == ey.sh_enabled))

	eq_Gradient : Theme.Gradient, Theme.Gradient -> Bool
	eq_Gradient = |ex, ey| ((((ex.gr_start_color == ey.gr_start_color) and (ex.gr_end_color == ey.gr_end_color)) and (ex.gr_vertical == ey.gr_vertical)) and (ex.gr_enabled == ey.gr_enabled))

	eq_Bevel : Theme.Bevel, Theme.Bevel -> Bool
	eq_Bevel = |ex, ey| (((((ex.bv_light == ey.bv_light) and (ex.bv_shade == ey.bv_shade)) and (ex.bv_width == ey.bv_width)) and (ex.bv_raised == ey.bv_raised)) and (ex.bv_enabled == ey.bv_enabled))

	eq_AccentBorder : Theme.AccentBorder, Theme.AccentBorder -> Bool
	eq_AccentBorder = |ex, ey| ((((ex.ab_side == ey.ab_side) and (ex.ab_width == ey.ab_width)) and (ex.ab_color == ey.ab_color)) and (ex.ab_enabled == ey.ab_enabled))

	eq_WidgetStyle : Theme.WidgetStyle, Theme.WidgetStyle -> Bool
	eq_WidgetStyle = |ex, ey| (((((((((((ex.ws_bg == ey.ws_bg) and (ex.ws_fg == ey.ws_fg)) and eq_Border(ex.ws_border, ey.ws_border)) and eq_Edges(ex.ws_padding, ey.ws_padding)) and eq_Edges(ex.ws_margin, ey.ws_margin)) and (ex.ws_min_width == ey.ws_min_width)) and (ex.ws_min_height == ey.ws_min_height)) and eq_Shadow(ex.ws_shadow, ey.ws_shadow)) and eq_Gradient(ex.ws_gradient, ey.ws_gradient)) and eq_AccentBorder(ex.ws_accent_border, ey.ws_accent_border)) and eq_Bevel(ex.ws_bevel, ey.ws_bevel))

	eq_StateStyles : Theme.StateStyles, Theme.StateStyles -> Bool
	eq_StateStyles = |ex, ey| ((((eq_WidgetStyle(ex.ss_normal, ey.ss_normal) and eq_WidgetStyle(ex.ss_hover, ey.ss_hover)) and eq_WidgetStyle(ex.ss_pressed, ey.ss_pressed)) and eq_WidgetStyle(ex.ss_disabled, ey.ss_disabled)) and eq_WidgetStyle(ex.ss_focused, ey.ss_focused))

	eq_Theme : Theme.Theme, Theme.Theme -> Bool
	eq_Theme = |ex, ey| ((((((((ex.th_name == ey.th_name) and eq_Palette(ex.th_palette, ey.th_palette)) and eq_StateStyles(ex.th_panel, ey.th_panel)) and eq_StateStyles(ex.th_button, ey.th_button)) and eq_StateStyles(ex.th_label, ey.th_label)) and eq_StateStyles(ex.th_input, ey.th_input)) and eq_StateStyles(ex.th_gauge, ey.th_gauge)) and eq_StateStyles(ex.th_separator, ey.th_separator))
}
