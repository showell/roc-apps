# Theme -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Theme :: [].{
	Palette : { pal_bg : I64, pal_fg : I64, pal_primary : I64, pal_secondary : I64, pal_accent : I64, pal_muted : I64, pal_error : I64, pal_success : I64, pal_warning : I64, pal_border : I64 }
	CornerStyle : [CornerSharp, CornerRound(I64), CornerBevel(I64)]
	BorderSide : { brd_width : I64, brd_color : I64 }
	Border : { bdr_top : Theme.BorderSide, bdr_right : Theme.BorderSide, bdr_bottom : Theme.BorderSide, bdr_left : Theme.BorderSide, bdr_corner : Theme.CornerStyle }
	Edges : { edge_top : I64, edge_right : I64, edge_bottom : I64, edge_left : I64 }
	Shadow : { sh_offset_x : I64, sh_offset_y : I64, sh_blur : I64, sh_color : I64, sh_enabled : Bool }
	Gradient : { gr_start_color : I64, gr_end_color : I64, gr_vertical : Bool, gr_enabled : Bool }
	Bevel : { bv_light : I64, bv_shade : I64, bv_width : I64, bv_raised : Bool, bv_enabled : Bool }
	AccentBorder : { ab_side : I64, ab_width : I64, ab_color : I64, ab_enabled : Bool }
	WidgetStyle : { ws_bg : I64, ws_fg : I64, ws_border : Theme.Border, ws_padding : Theme.Edges, ws_margin : Theme.Edges, ws_min_width : I64, ws_min_height : I64, ws_shadow : Theme.Shadow, ws_gradient : Theme.Gradient, ws_accent_border : Theme.AccentBorder, ws_bevel : Theme.Bevel }
	StateStyles : { ss_normal : Theme.WidgetStyle, ss_hover : Theme.WidgetStyle, ss_pressed : Theme.WidgetStyle, ss_disabled : Theme.WidgetStyle, ss_focused : Theme.WidgetStyle }
	Theme : { th_name : List(U8), th_palette : Theme.Palette, th_panel : Theme.StateStyles, th_button : Theme.StateStyles, th_label : Theme.StateStyles, th_input : Theme.StateStyles, th_gauge : Theme.StateStyles, th_separator : Theme.StateStyles }

	shadow_none : Theme.Shadow
	shadow_none = { sh_offset_x: 0, sh_offset_y: 0, sh_blur: 0, sh_color: 0, sh_enabled: False }

	shadow_subtle : I64 -> Theme.Shadow
	shadow_subtle = |color| { sh_offset_x: 2, sh_offset_y: 2, sh_blur: 4, sh_color: color, sh_enabled: True }

	shadow_medium : I64 -> Theme.Shadow
	shadow_medium = |color| { sh_offset_x: 4, sh_offset_y: 4, sh_blur: 8, sh_color: color, sh_enabled: True }

	gradient_none : Theme.Gradient
	gradient_none = { gr_start_color: 0, gr_end_color: 0, gr_vertical: True, gr_enabled: False }

	gradient_v : I64, I64 -> Theme.Gradient
	gradient_v = |start, stop| { gr_start_color: start, gr_end_color: stop, gr_vertical: True, gr_enabled: True }

	gradient_h : I64, I64 -> Theme.Gradient
	gradient_h = |start, stop| { gr_start_color: start, gr_end_color: stop, gr_vertical: False, gr_enabled: True }

	bevel_none : Theme.Bevel
	bevel_none = { bv_light: 0, bv_shade: 0, bv_width: 0, bv_raised: True, bv_enabled: False }

	bevel_raised : I64, I64, I64 -> Theme.Bevel
	bevel_raised = |light, shade, w| { bv_light: light, bv_shade: shade, bv_width: w, bv_raised: True, bv_enabled: True }

	bevel_recessed : I64, I64, I64 -> Theme.Bevel
	bevel_recessed = |light, shade, w| { bv_light: light, bv_shade: shade, bv_width: w, bv_raised: False, bv_enabled: True }

	bevel_tl : Theme.Bevel -> I64
	bevel_tl = |b| (if b.bv_raised { b.bv_light } else { b.bv_shade })

	bevel_br : Theme.Bevel -> I64
	bevel_br = |b| (if b.bv_raised { b.bv_shade } else { b.bv_light })

	accent_border_none : Theme.AccentBorder
	accent_border_none = { ab_side: 0, ab_width: 0, ab_color: 0, ab_enabled: False }

	accent_border_top : I64, I64 -> Theme.AccentBorder
	accent_border_top = |width, color| { ab_side: 0, ab_width: width, ab_color: color, ab_enabled: True }

	accent_border_bottom : I64, I64 -> Theme.AccentBorder
	accent_border_bottom = |width, color| { ab_side: 2, ab_width: width, ab_color: color, ab_enabled: True }

	accent_border_left : I64, I64 -> Theme.AccentBorder
	accent_border_left = |width, color| { ab_side: 3, ab_width: width, ab_color: color, ab_enabled: True }

	edges_uniform : I64 -> Theme.Edges
	edges_uniform = |v| { edge_top: v, edge_right: v, edge_bottom: v, edge_left: v }

	edges_zero : Theme.Edges
	edges_zero = { edge_top: 0, edge_right: 0, edge_bottom: 0, edge_left: 0 }

	edges_xy : I64, I64 -> Theme.Edges
	edges_xy = |x, y| { edge_top: y, edge_right: x, edge_bottom: y, edge_left: x }

	border_side : I64, I64 -> Theme.BorderSide
	border_side = |w, c| { brd_width: w, brd_color: c }

	border_side_none : Theme.BorderSide
	border_side_none = { brd_width: 0, brd_color: 0 }

	border_uniform : I64, I64, Theme.CornerStyle -> Theme.Border
	border_uniform = |w, c, corner| ({
		side = border_side(w, c)
		{ bdr_top: side, bdr_right: side, bdr_bottom: side, bdr_left: side, bdr_corner: corner }
	})

	border_none : Theme.Border
	border_none = { bdr_top: border_side_none, bdr_right: border_side_none, bdr_bottom: border_side_none, bdr_left: border_side_none, bdr_corner: CornerSharp }

	widget_style : I64, I64, Theme.Border, Theme.Edges, Theme.Edges -> Theme.WidgetStyle
	widget_style = |bg, fg, bdr, pad, mar| { ws_bg: bg, ws_fg: fg, ws_border: bdr, ws_padding: pad, ws_margin: mar, ws_min_width: 0, ws_min_height: 0, ws_shadow: shadow_none, ws_gradient: gradient_none, ws_accent_border: accent_border_none, ws_bevel: bevel_none }

	widget_style_sized : I64, I64, Theme.Border, Theme.Edges, Theme.Edges, I64, I64 -> Theme.WidgetStyle
	widget_style_sized = |bg, fg, bdr, pad, mar, minw, minh| { ws_bg: bg, ws_fg: fg, ws_border: bdr, ws_padding: pad, ws_margin: mar, ws_min_width: minw, ws_min_height: minh, ws_shadow: shadow_none, ws_gradient: gradient_none, ws_accent_border: accent_border_none, ws_bevel: bevel_none }

	widget_style_rich : I64, I64, Theme.Border, Theme.Edges, Theme.Edges, Theme.Shadow, Theme.Gradient, Theme.AccentBorder -> Theme.WidgetStyle
	widget_style_rich = |bg, fg, bdr, pad, mar, sh, gr, ab| { ws_bg: bg, ws_fg: fg, ws_border: bdr, ws_padding: pad, ws_margin: mar, ws_min_width: 0, ws_min_height: 0, ws_shadow: sh, ws_gradient: gr, ws_accent_border: ab, ws_bevel: bevel_none }

	widget_style_surface : I64, I64, Theme.Border, Theme.Edges, Theme.Edges, Theme.Gradient, Theme.Bevel -> Theme.WidgetStyle
	widget_style_surface = |bg, fg, bdr, pad, mar, gr, bv| { ws_bg: bg, ws_fg: fg, ws_border: bdr, ws_padding: pad, ws_margin: mar, ws_min_width: 0, ws_min_height: 0, ws_shadow: shadow_none, ws_gradient: gr, ws_accent_border: accent_border_none, ws_bevel: bv }

	widget_style_bare : Theme.WidgetStyle
	widget_style_bare = widget_style(0, 0, border_none, edges_zero, edges_zero)

	state_styles_flat : Theme.WidgetStyle -> Theme.StateStyles
	state_styles_flat = |s| { ss_normal: s, ss_hover: s, ss_pressed: s, ss_disabled: s, ss_focused: s }

	edges_h : Theme.Edges -> I64
	edges_h = |e| (e.edge_left + e.edge_right)

	edges_v : Theme.Edges -> I64
	edges_v = |e| (e.edge_top + e.edge_bottom)

	palette_terminal : Theme.Palette
	palette_terminal = { pal_bg: 1052688, pal_fg: 13421772, pal_primary: 3394611, pal_secondary: 2263842, pal_accent: 5614335, pal_muted: 6710886, pal_error: 13369344, pal_success: 3394560, pal_warning: 13408512, pal_border: 4473924 }

	palette_lcars : Theme.Palette
	palette_lcars = { pal_bg: 0, pal_fg: 16777215, pal_primary: 16753920, pal_secondary: 10066431, pal_accent: 6737151, pal_muted: 8421504, pal_error: 13369344, pal_success: 3394560, pal_warning: 16753920, pal_border: 16753920 }

	palette_minimal : Theme.Palette
	palette_minimal = { pal_bg: 16777215, pal_fg: 2105376, pal_primary: 2236962, pal_secondary: 5592405, pal_accent: 26367, pal_muted: 10066329, pal_error: 13369344, pal_success: 2263842, pal_warning: 15105570, pal_border: 13421772 }

	theme_luma : I64 -> I64
	theme_luma = |c| I64.div_trunc_by((((299 * I64.bitwise_and(I64.shr_zf_wrap(c, I64.to_u8_wrap(16)), 255)) + (587 * I64.bitwise_and(I64.shr_zf_wrap(c, I64.to_u8_wrap(8)), 255))) + (114 * I64.bitwise_and(c, 255))), 1000)

	theme_ink_on : Theme.Palette, I64 -> I64
	theme_ink_on = |p, ground| ({
		dark_ink = (if (theme_luma(p.pal_bg) < theme_luma(p.pal_fg)) { p.pal_bg } else { p.pal_fg })
		light_ink = (if (theme_luma(p.pal_bg) < theme_luma(p.pal_fg)) { p.pal_fg } else { p.pal_bg })
		(if (theme_luma(ground) > 127) { dark_ink } else { light_ink })
	})

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
		{ th_name: [14, 13, 21, 26, 17, 18, 15, 23], th_palette: pal, th_panel: state_styles_flat(base), th_button: { ss_normal: btn, ss_hover: btn_h, ss_pressed: btn_p, ss_disabled: btn_d, ss_focused: btn_h }, th_label: state_styles_flat(lbl), th_input: { ss_normal: inp, ss_hover: inp, ss_pressed: inp, ss_disabled: btn_d, ss_focused: inp_f }, th_gauge: state_styles_flat(widget_style(pal.pal_bg, pal.pal_primary, bdr, edges_uniform(2), mar)), th_separator: state_styles_flat(sep) }
	})

	theme_lcars : Theme.Theme
	theme_lcars = ({
		pal = palette_lcars
		round = CornerRound(12)
		_bdr = border_uniform(2, pal.pal_primary, round)
		pad = edges_xy(16, 8)
		mar = edges_uniform(4)
		base = widget_style(pal.pal_bg, pal.pal_fg, border_uniform(2, pal.pal_primary, round), pad, mar)
		btn = widget_style_sized(pal.pal_primary, pal.pal_bg, border_none, pad, mar, 120, 40)
		btn_h = widget_style_sized(pal.pal_secondary, pal.pal_bg, border_none, pad, mar, 120, 40)
		btn_p = widget_style_sized(pal.pal_accent, pal.pal_bg, border_none, pad, mar, 120, 40)
		btn_d = widget_style_sized(pal.pal_muted, pal.pal_muted, border_none, pad, mar, 120, 40)
		inp = widget_style(pal.pal_bg, pal.pal_fg, border_uniform(2, pal.pal_secondary, round), pad, mar)
		inp_f = widget_style(pal.pal_bg, pal.pal_fg, border_uniform(3, pal.pal_accent, round), pad, mar)
		lbl = widget_style(0, pal.pal_fg, border_none, edges_zero, mar)
		sep = widget_style_sized(pal.pal_primary, pal.pal_primary, border_none, edges_zero, edges_xy(0, 4), 0, 6)
		{ th_name: [23, 24, 15, 21, 19], th_palette: pal, th_panel: state_styles_flat(base), th_button: { ss_normal: btn, ss_hover: btn_h, ss_pressed: btn_p, ss_disabled: btn_d, ss_focused: btn_h }, th_label: state_styles_flat(lbl), th_input: { ss_normal: inp, ss_hover: inp, ss_pressed: inp, ss_disabled: btn_d, ss_focused: inp_f }, th_gauge: state_styles_flat(widget_style(pal.pal_bg, pal.pal_accent, border_uniform(2, pal.pal_secondary, round), edges_uniform(2), mar)), th_separator: state_styles_flat(sep) }
	})

	theme_minimal : Theme.Theme
	theme_minimal = ({
		pal = palette_minimal
		bdr = border_uniform(1, pal.pal_border, CornerSharp)
		pad = edges_xy(8, 4)
		mar = edges_uniform(2)
		base = widget_style(pal.pal_bg, pal.pal_fg, bdr, pad, mar)
		btn = widget_style(pal.pal_bg, pal.pal_primary, border_uniform(1, pal.pal_primary, CornerSharp), pad, mar)
		btn_h = widget_style(pal.pal_primary, pal.pal_bg, border_uniform(1, pal.pal_primary, CornerSharp), pad, mar)
		btn_p = widget_style(pal.pal_accent, pal.pal_bg, border_uniform(1, pal.pal_accent, CornerSharp), pad, mar)
		btn_d = widget_style(pal.pal_muted, pal.pal_muted, border_uniform(1, pal.pal_muted, CornerSharp), pad, mar)
		inp = widget_style(pal.pal_bg, pal.pal_fg, border_uniform(1, pal.pal_border, CornerSharp), pad, mar)
		inp_f = widget_style(pal.pal_bg, pal.pal_fg, border_uniform(2, pal.pal_accent, CornerSharp), pad, mar)
		lbl = widget_style(0, pal.pal_fg, border_none, edges_zero, mar)
		sep = widget_style(pal.pal_border, pal.pal_border, border_none, edges_zero, edges_xy(0, 4))
		{ th_name: [26, 17, 18, 17, 26, 15, 23], th_palette: pal, th_panel: state_styles_flat(base), th_button: { ss_normal: btn, ss_hover: btn_h, ss_pressed: btn_p, ss_disabled: btn_d, ss_focused: btn_h }, th_label: state_styles_flat(lbl), th_input: { ss_normal: inp, ss_hover: inp, ss_pressed: inp, ss_disabled: btn_d, ss_focused: inp_f }, th_gauge: state_styles_flat(widget_style(pal.pal_bg, pal.pal_primary, bdr, edges_uniform(2), mar)), th_separator: state_styles_flat(sep) }
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

	tone_name : I64 -> List(U8)
	tone_name = |tone| (if (tone == tone_primary) { [31, 21, 17, 26, 15, 21, 30] } else { (if (tone == tone_success) { [19, 25, 24, 24, 13, 19, 19] } else { (if (tone == tone_warning) { [27, 15, 21, 18, 17, 18, 29] } else { (if (tone == tone_error) { [13, 21, 21, 16, 21] } else { (if (tone == tone_muted) { [26, 25, 14, 13, 22] } else { [18, 16, 18, 13] }) }) }) }) })

	theme_fmt_bool : Bool -> List(U8)
	theme_fmt_bool = |b| (if b { [14, 21, 25, 13] } else { [28, 15, 23, 19, 13] })

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
}
