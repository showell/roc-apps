## The last pass over a frame's draw commands before they are painted. A
## polygon shaded across its width becomes a span shade between its leftmost
## and rightmost x, darker at the edges and lighter in the middle; every
## other command passes as it is.
import Num_
import Paint

Blit :: [].{

	## The span of x a polygon covers.
	Span : { min_x : F64, max_x : F64 }

	red_of : I64 -> I64
	red_of = |color| I64.bitwise_and(I64.shr_wrap(color, I64.to_u8_wrap(16)), 255)

	green_of : I64 -> I64
	green_of = |color| I64.bitwise_and(I64.shr_wrap(color, I64.to_u8_wrap(8)), 255)

	blue_of : I64 -> I64
	blue_of = |color| I64.bitwise_and(color, 255)

	## A colour as 0xRRGGBB from its three channels.
	pack_rgb : {
		red : I64,
		green : I64,
		blue : I64,
	} -> I64
	pack_rgb = |
		{
			red,
			green,
			blue,
		},
	| {
		red_bits = I64.shl_wrap(red, 16)
		green_bits = I64.shl_wrap(green, 8)
		I64.bitwise_or(I64.bitwise_or(red_bits, green_bits), blue)
	}

	## One channel scaled by `factor`, rounded, and held at 255 at most.
	shade_channel : I64, F64 -> I64
	shade_channel = |channel, factor| {
		scaled = F64.to_i64_wrap(Num_.round_real((I64.to_f64(channel) * factor)))
		if (scaled > 255) 255 else scaled
	}

	shade_color : I64, F64 -> I64
	shade_color = |color, factor|
		pack_rgb({
			red: shade_channel(red_of(color), factor),
			green: shade_channel(green_of(color), factor),
			blue: shade_channel(blue_of(color), factor),
		})

	shade_edge_darken : F64
	shade_edge_darken = 0.4

	shade_middle_lift : F64
	shade_middle_lift = 0.25

	## A shaded polygon's colour at its edges.
	width_shade_edge : I64, F64 -> I64
	width_shade_edge = |color, strength| shade_color(color, (1.0 - (shade_edge_darken * strength)))

	## A shaded polygon's colour in its middle.
	width_shade_middle : I64, F64 -> I64
	width_shade_middle = |color, strength| shade_color(
		color,
		(1.0 + (shade_middle_lift * strength)),
	)

	## A shaded polygon's colours from edge to edge.
	width_shade_stops : I64, F64 -> List(I64)
	width_shade_stops = |color, strength| [
		width_shade_edge(color, strength),
		width_shade_middle(color, strength),
		width_shade_edge(color, strength),
	]

	min_shade_width : F64
	min_shade_width = 1.0

	is_too_narrow_to_shade : Blit.Span -> Bool
	is_too_narrow_to_shade = |span| ((span.max_x - span.min_x) < min_shade_width)

	## The span of x over a polygon's points, given flat as x0, y0, x1, y1, ...
	## It has at least one point.
	x_span : List(F64) -> Blit.Span
	x_span = |pts|
		match xs_of(pts) {
			[first, .. as rest] => {
				min_x: rest.fold(first, |least, x| if (x < least) x else least),
				max_x: rest.fold(first, |most, x| if (x > most) x else most),
			}
			[] => crash "Blit.x_span: a polygon has a point"
		}

	## A shaded polygon as the blitter paints it: a span shade where it is
	## shaded and wide enough, else a solid polygon.
	expand_shade : Paint.DrawCmd -> Paint.DrawCmd
	expand_shade = |cmd|
		if cmd.strength <= 0.0 or cmd.pts.len() < 2 {
			as_solid(cmd)
		} else {
			span = x_span(cmd.pts)
			if (is_too_narrow_to_shade(span)) as_solid(cmd) else as_span_shade(cmd, span)
		}

	## A round polygon, tag 1, is shaded across its width, and every other
	## command goes through.
	blit_expand : List(Paint.DrawCmd) -> List(Paint.DrawCmd)
	blit_expand = |cmds| cmds.map(|cmd| if (cmd.tag == 1) expand_shade(cmd) else cmd)
}

## The x of each point in a flat list of x, y pairs.
xs_of : List(F64) -> List(F64)
xs_of = |pts|
	pts.chunks_of(2).map(
		|point|
			match point {
				[x, ..] => x
				[] => crash "Blit.xs_of: a chunk of points holds an x"
			},
	)

as_solid : Paint.DrawCmd -> Paint.DrawCmd
as_solid = |cmd| {
	tag: 0,
	color: cmd.color,
	color2: 0,
	strength: 0.0,
	geom: [],
	pts: cmd.pts,
}

as_span_shade : Paint.DrawCmd, Blit.Span -> Paint.DrawCmd
as_span_shade = |cmd, span| {
	tag: 2,
	color: Blit.width_shade_edge(cmd.color, cmd.strength),
	color2: Blit.width_shade_middle(cmd.color, cmd.strength),
	strength: 0.0,
	geom: [span.min_x, span.max_x],
	pts: cmd.pts,
}
