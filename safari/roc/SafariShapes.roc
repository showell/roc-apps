# SafariShapes -- Safari's frame, as shapes.
#
# Hand-written. The vocabulary is in movie/Shapes.roc, every movie's; this is
# the part that knows what THIS movie looks like -- the sky's gradient, the
# grass, the sun's glow and disc, and how a Codex draw command becomes a
# polygon.
import Paint
import Sky
import Brush
import SafariBrush
import Shapes

SafariShapes :: [].{
	# The frame in paint order: the sky, the grass, the sun, then every command.
	frame : List(Paint.DrawCmd), I64, I64, Sky.SunPos -> List(Shapes.Shape)
	frame = |commands, sky_top, sky_horizon, sun| {
		var $out = List.with_capacity(2 * List.len(commands) + 8)
		# Oversized, as the blitter draws them, so the rolled frame's corners stay
		# filled: the top colour to a fifth of the way down to the horizon at y
		# 300, then the fade; the grass from a pixel above the horizon.
		sky = Linear({ c0: Brush.opaque(sky_top), c1: Brush.opaque(sky_horizon), o0: 0.2, o1: 1.0, ax: 0.0, ay: 0.0, dx: 0.0, dy: 300.0, len2: 90000.0 })
		$out = List.append($out, Rect({ x: -1080.0, y: -1260.0, w: 3120.0, h: 1560.0, fill: sky }))
		$out = List.append($out, Rect({ x: -1080.0, y: 299.0, w: 3120.0, h: 1561.0, fill: Flat(Brush.opaque(0x4a8f43)) }))
		$out = if sun.visible and sun.scale > 0.0 {
			glow = Glow({
				c0: { r: 255.0, g: 201.0, b: 128.0, a: 0.85 },
				c1: { r: 255.0, g: 150.0, b: 92.0, a: 0.32 },
				c2: { r: 255.0, g: 150.0, b: 92.0, a: 0.0 },
				x: sun.x,
				y: sun.y,
				r0: 8.0 * sun.scale,
				r1: 340.0 * sun.scale,
			})
			disc = Radial({ inner: Brush.opaque(0xffe6a3), outer: Brush.opaque(0xff9d5c), x: sun.x, y: sun.y, r0: 4.0 * sun.scale, r1: 46.0 * sun.scale })
			List.concat($out, [
				Rect({ x: 0.0, y: 0.0, w: 960.0, h: 300.0, fill: glow }),
				Disc({ x: sun.x, y: sun.y, r: 46.0 * sun.scale, fill: disc, clip: Within({ x: 0.0, y: 0.0, w: 960.0, h: 300.0 }) }),
			])
		} else {
			$out
		}
		n = List.len(commands)
		var $k = 0
		while $k < n {
			$out = List.concat($out, of_command(List.get(commands, $k) ?? crash("command out of range")))
			$k = $k + 1
		}
		$out
	}

	# One command's shapes: a disc, or its polygon with its brush.
	of_command : Paint.DrawCmd -> List(Shapes.Shape)
	of_command = |c|
		if c.tag == 3 {
			col = Brush.opaque(c.color)
			[Disc({ x: SafariBrush.geom(c, 0), y: SafariBrush.geom(c, 1), r: SafariBrush.geom(c, 2), fill: Flat({ ..col, a: c.strength }), clip: Anywhere })]
		} else {
			fill = SafariBrush.of_command(c)
			match fill {
				Skip => []
				_ => polygon(c.pts, fill)
			}
		}

	polygon : List(F64), Brush.Fill -> List(Shapes.Shape)
	polygon = |pts, fill| {
		n = List.len(pts) // 2
		if n < 3 { [] } else { [Poly({ pts, fill })] }
	}
}
