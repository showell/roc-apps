# Check Shapes' cutting of a frame against Raster's polygon fill, natively.
# Hand-written, like RasterFrame.
#
# The frame is painted twice by Raster: once as Raster paints it, and once with
# the commands replaced by the shapes Shapes cuts them into, each piece filled
# by Raster with the piece's brush. Gradients included, the two agree pixel for
# pixel when the pieces cover exactly what their polygon covers. It prints how
# many pixels differ and how many triangles the cutting made, then the cut
# frame as RasterFrame prints one, for ray/pixels_png.mjs.
#
#   roc build --opt=dev ShapesFrame.roc --output=<bin>; <bin> [steps] | ray/pixels_png.mjs <png>
import SafariRide
import Raster
import Shapes

ride_to : SafariRide.Model, I64 -> SafariRide.Model
ride_to = |m, n| if n <= 0 { m } else { ride_to(SafariRide.advance(m), n - 1) }

# The shapes of the commands, filled by Raster onto `pixels`.
paint_shapes : List(U32), Raster.View, List(Shapes.Shape) -> List(U32)
paint_shapes = |pixels, view, shapes| {
	n = List.len(shapes)
	var $px = pixels
	var $k = 0
	while $k < n {
		$px = match List.get(shapes, $k) ?? crash("shape out of range") {
			Poly(p) => Raster.fill_polygon($px, view, p.pts, p.fill)
			Pieces(p) => paint_pieces($px, view, p.tris, p.fill)
			Disc(d) => {
				col = match d.fill {
					Flat(c) => c
					_ => crash("a command's disc with a gradient")
				}
				Raster.disc($px, view, d.x, d.y, d.r, col)
			}
			Rect(_) => crash("a command cut into a rectangle")
		}
		$k = $k + 1
	}
	$px
}

paint_pieces : List(U32), Raster.View, List(F64), _ -> List(U32)
paint_pieces = |pixels, view, tris, fill| {
	m = List.len(tris) // 6
	var $px = pixels
	var $k = 0
	while $k < m {
		$px = Raster.fill_polygon($px, view, List.sublist(tris, { start: 6 * $k, len: 6 }), fill)
		$k = $k + 1
	}
	$px
}

triangles : List(Shapes.Shape) -> U64
triangles = |shapes| List.fold(shapes, 0, |n, s|
	match s {
		Pieces(p) => n + List.len(p.tris) // 6
		_ => n
	})

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
	roll = SafariRide.roll(m)
	scene = { commands, roll, sky_top: SafariRide.sky_top(m), sky_horizon: SafariRide.sky_horizon(m), sun: SafariRide.sun(m) }
	shapes = Shapes.cut(List.join_map(commands, Shapes.of_command))
	a = Raster.paint(scene)
	b = paint_shapes(Raster.paint({ ..scene, commands: [] }), Raster.view_of(roll), shapes)
	n = List.len(a)
	var $differ = 0
	var $k = 0
	while $k < n {
		$differ = if List.get(a, $k) == List.get(b, $k) { $differ } else { $differ + 1 }
		$k = $k + 1
	}
	var $out = List.with_capacity(n * 6 + 64)
	$out = List.concat($out, Str.to_utf8("differ ${U64.to_str($differ)} of ${U64.to_str(n)}, triangles ${U64.to_str(triangles(shapes))}, commands ${U64.to_str(List.len(commands))}\nhash 00000000\n960 600\n"))
	$k = 0
	while $k < n {
		$out = append_hex($out, U32.to_i64(List.get(b, $k) ?? 0), 6)
		$k = $k + 1
	}
	echo!(Str.from_utf8_lossy(List.append($out, 10)))
	Ok({})
}
