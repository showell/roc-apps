# Check Shapes' cutting of a frame against Raster's polygon fill, natively.
# Hand-written, like RasterFrame.
#
# The frame is painted twice by Raster, both times with every gradient at its
# flat Shapes colour: once with the commands' own polygons, filled by the
# nonzero rule, and once with the convex polygons and triangles Shapes cut them
# into. It prints how many pixels differ and how many triangles the cutting
# made, then the cut frame as RasterFrame prints one, for ray/pixels_png.mjs.
#
#   roc build --opt=dev ShapesFrame.roc --output=<bin>; <bin> [steps] | ray/pixels_png.mjs <png>
import SafariRide
import Raster
import Shapes
import Paint

ride_to : SafariRide.Model, I64 -> SafariRide.Model
ride_to = |m, n| if n <= 0 { m } else { ride_to(SafariRide.advance(m), n - 1) }

argb : Shapes.Rgba8 -> I64
argb = |c| I64.bitwise_or(I64.bitwise_or(I64.shl_wrap(U8.to_i64(c.a), 24), I64.shl_wrap(U8.to_i64(c.r), 16)), I64.bitwise_or(I64.shl_wrap(U8.to_i64(c.g), 8), U8.to_i64(c.b)))

# A polygon at a flat colour, as a command Raster paints: tag 0 when opaque,
# otherwise a radial fill whose two stops are the same colour.
flat_cmd : List(F64), Shapes.Rgba8 -> Paint.DrawCmd
flat_cmd = |pts, color|
	if color.a == 255 {
		{ tag: 0, color: argb(color), color2: 0, strength: 0.0, geom: [], pts }
	} else {
		{ tag: 4, color: argb(color), color2: argb(color), strength: 0.0, geom: [0.0, 0.0, 1.0], pts }
	}

# The command with its polygon kept whole, at its flat colour.
whole : Paint.DrawCmd -> Paint.DrawCmd
whole = |c| if c.tag == 3 { c } else { flat_cmd(c.pts, Shapes.flat_color(c)) }

# The command as the shapes Shapes cuts it into, turned back into commands.
cut : Paint.DrawCmd -> List(Paint.DrawCmd)
cut = |c|
	if c.tag == 3 {
		[c]
	} else {
		List.map(Shapes.of_command(c), |s|
			match s {
				Convex(p) => flat_cmd(p.pts, p.color)
				Triangle(t) => flat_cmd([t.ax, t.ay, t.bx, t.by, t.cx, t.cy], t.color)
				_ => crash("a polygon cut into something other than polygons")
			})
	}

triangles : List(Paint.DrawCmd) -> U64
triangles = |cs| List.fold(cs, 0, |n, c| n + List.len(List.keep_if(Shapes.of_command(c), |s| match s { Triangle(_) => Bool.True
	_ => Bool.False })))

hex_digit : I64 -> U8
hex_digit = |d| I64.to_u8_wrap(if d < 10 { d + 48 } else { d + 87 })

append_hex : List(U8), I64, U64 -> List(U8)
append_hex = |out, v, digits| {
	var $out = out
	var $k = digits
	while $k > 0 {
		$k = $k - 1
		$out = List.append($out, hex_digit(I64.bitwise_and(I64.shr_wrap(v, U64.to_u8_wrap(4 * $k)), 15)))
	}
	$out
}

main! = |args| {
	steps = I64.from_str(List.get(args, 0) ?? "0") ?? 0
	m = ride_to(SafariRide.init, steps)
	commands = SafariRide.commands(m)
	scene = |cs| { commands: cs, roll: SafariRide.roll(m), sky_top: SafariRide.sky_top(m), sky_horizon: SafariRide.sky_horizon(m), sun: SafariRide.sun(m) }
	a = Raster.paint(scene(List.map(commands, whole)))
	b = Raster.paint(scene(List.join_map(commands, cut)))
	n = List.len(a)
	var $differ = 0
	var $k = 0
	while $k < n {
		$differ = if List.get(a, $k) == List.get(b, $k) { $differ } else { $differ + 1 }
		$k = $k + 1
	}
	var $out = List.with_capacity(n * 6 + 64)
	$out = List.concat($out, Str.to_utf8("differ ${U64.to_str($differ)} of ${U64.to_str(n)}, triangles ${U64.to_str(triangles(commands))}, commands ${U64.to_str(List.len(commands))}\nhash 00000000\n960 600\n"))
	$k = 0
	while $k < n {
		$out = append_hex($out, U32.to_i64(List.get(b, $k) ?? 0), 6)
		$k = $k + 1
	}
	echo!(Str.from_utf8_lossy(List.append($out, 10)))
	Ok({})
}
