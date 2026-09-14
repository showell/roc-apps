# Blit -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Num_
import Paint

Blit :: [].{

	chan_r : I64 -> I64
	chan_r = |c| I64.bitwise_and(I64.shr_zf_wrap(c, I64.to_u8_wrap(16)), 255)

	chan_g : I64 -> I64
	chan_g = |c| I64.bitwise_and(I64.shr_zf_wrap(c, I64.to_u8_wrap(8)), 255)

	chan_b : I64 -> I64
	chan_b = |c| I64.bitwise_and(c, 255)

	pack_rgb : I64, I64, I64 -> I64
	pack_rgb = |r, g, b| I64.bitwise_or(I64.bitwise_or(I64.shl_wrap(r, I64.to_u8_wrap(16)), I64.shl_wrap(g, I64.to_u8_wrap(8))), b)

	shade_chan : I64, F64 -> I64
	shade_chan = |v, f| ({
		scaled = F64.to_i64_wrap(Num_.round_real((I64.to_f64(v) * f)))
		(if (scaled > 255) { 255 } else { scaled })
	})

	shade_color : I64, F64 -> I64
	shade_color = |c, f| pack_rgb(shade_chan(chan_r(c), f), shade_chan(chan_g(c), f), shade_chan(chan_b(c), f))

	shade_edge_darken : F64
	shade_edge_darken = 0.4

	shade_middle_lift : F64
	shade_middle_lift = 0.25

	width_shade_edge : I64, F64 -> I64
	width_shade_edge = |color, strength| shade_color(color, (1.0 - (shade_edge_darken * strength)))

	width_shade_middle : I64, F64 -> I64
	width_shade_middle = |color, strength| shade_color(color, (1.0 + (shade_middle_lift * strength)))

	width_shade_stops : I64, F64 -> List(I64)
	width_shade_stops = |color, strength| [width_shade_edge(color, strength), width_shade_middle(color, strength), width_shade_edge(color, strength)]

	min_disc_radius : F64
	min_disc_radius = 0.5

	min_disc_alpha : F64
	min_disc_alpha = 0.02

	min_gradient_radius : F64
	min_gradient_radius = 0.5

	min_shade_width : F64
	min_shade_width = 1.0

	disc_visible : F64, F64 -> Bool
	disc_visible = |r, alpha| ((r >= min_disc_radius) and (alpha >= min_disc_alpha))

	radial_visible : F64 -> Bool
	radial_visible = |r| (r >= min_gradient_radius)

	too_narrow_to_shade : F64, F64 -> Bool
	too_narrow_to_shade = |min_x, max_x| ((max_x - min_x) < min_shade_width)

	span_lo : List(F64), I64, F64 -> F64
	span_lo = |xs, i, acc| (if (i >= U64.to_i64_wrap(List.len(xs))) { acc } else { span_lo(xs, (i + 2), (if ((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) < acc) { (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) } else { acc })) })

	span_hi : List(F64), I64, F64 -> F64
	span_hi = |xs, i, acc| (if (i >= U64.to_i64_wrap(List.len(xs))) { acc } else { span_hi(xs, (i + 2), (if ((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) > acc) { (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) } else { acc })) })

	as_solid : Paint.DrawCmd -> Paint.DrawCmd
	as_solid = |c| { tag: 0, color: c.color, color2: 0, strength: 0.0, geom: [], pts: c.pts }

	as_span_shade : Paint.DrawCmd, F64, F64 -> Paint.DrawCmd
	as_span_shade = |c, lo, hi| { tag: 2, color: width_shade_edge(c.color, c.strength), color2: width_shade_middle(c.color, c.strength), strength: 0.0, geom: [lo, hi], pts: c.pts }

	expand_shade : Paint.DrawCmd -> Paint.DrawCmd
	expand_shade = |c| (if (c.strength <= 0.0) { as_solid(c) } else { (if (U64.to_i64_wrap(List.len(c.pts)) < 2) { as_solid(c) } else { ({
		lo = span_lo(c.pts, 0, (List.get(c.pts, I64.to_u64_wrap(0)) ?? crash("list-at out of range")))
		hi = span_hi(c.pts, 0, (List.get(c.pts, I64.to_u64_wrap(0)) ?? crash("list-at out of range")))
		(if too_narrow_to_shade(lo, hi) { as_solid(c) } else { as_span_shade(c, lo, hi) })
	}) }) })

	expand_cmd : Paint.DrawCmd -> List(Paint.DrawCmd)
	expand_cmd = |c| (if (c.tag == 1) { [expand_shade(c)] } else { (if (c.tag == 3) { (if disc_visible((List.get(c.geom, I64.to_u64_wrap(2)) ?? crash("list-at out of range")), c.strength) { [c] } else { [] }) } else { (if (c.tag == 4) { (if radial_visible((List.get(c.geom, I64.to_u64_wrap(2)) ?? crash("list-at out of range"))) { [c] } else { [] }) } else { [c] }) }) })

	# blit_expand builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	blit_expand : List(Paint.DrawCmd), I64 -> List(Paint.DrawCmd)
	blit_expand = |cs, i| blit_expand_acc(cs, i, [])

	blit_expand_acc : List(Paint.DrawCmd), I64, List(Paint.DrawCmd) -> List(Paint.DrawCmd)
	blit_expand_acc = |cs, i, acc| (if (i >= U64.to_i64_wrap(List.len(cs))) { acc } else { blit_expand_acc(cs, (i + 1), List.concat(acc, expand_cmd((List.get(cs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))) })
}
