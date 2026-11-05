## ShapesFrame checks that cutting a frame changes nothing on screen. The
## browser fills a concave polygon itself, but roc-ray fills only convex ones,
## so the native runner draws what Shapes.cut makes of a frame: each concave
## polygon as triangles. Safari's gate runs this check (see SafariFrame for
## more context). It paints a frame twice with ShapesPixels: once as
## SafariFrame paints it, with its polygons whole, and once with them cut.
## Gradients included, the two agree pixel for pixel when the triangles cover
## exactly what their polygons do.
##
## It prints how many pixels differ, how many triangles cutting the shapes
## made and how many shapes there were, then the shapes' frame in
## RasterFrame's format, which pixels_png.mjs turns into a PNG.
##
##   roc build --opt=dev ShapesFrame.roc --output=<bin>; <bin> [steps] | node pixels_png.mjs <png>
app [main!] {
	game: "../game.roc",
	lib: "../../lib/main.roc",
}

import game.SafariRide
import SafariFrame
import ShapesPixels
import lib.Shapes
import game.Screen
import Hex

ride_to : SafariRide.Model, I64 -> SafariRide.Model
ride_to = |m, n| if n <= 0 {
	m
} else {
	ride_to(SafariRide.advance(m), n - 1)
}

triangles : List(Shapes.Shape) -> U64
triangles = |shapes| List.fold(
	shapes,
	0,
	|n, s|
		match s {
			Pieces(p) => n + List.len(p.tris) // 6
			_ => n
		},
)

main! = |args| {
	# With no argument, the run takes its usual number of steps.
	steps =
		match args.get(0) {
			Ok(text) => I64.from_str(text) ?? crash "ShapesFrame: steps must be a whole number"
			Err(OutOfBounds) => 0
		}
	m = ride_to(SafariRide.init, steps)
	ride_shapes = SafariRide.shapes(m)
	roll = SafariRide.roll(m)
	scene = {
		shapes: ride_shapes,
		roll,
		sky_top: SafariRide.sky_top(m),
		sky_horizon: SafariRide.sky_horizon(m),
		sun: SafariRide.sun(m),
	}
	cut_shapes = Shapes.cut(ride_shapes)
	a = SafariFrame.paint(scene)
	backdrop = SafariFrame.paint({ ..scene, shapes: [] })
	b = ShapesPixels.paint(backdrop, { roll: SafariFrame.screen_roll(roll), shapes: cut_shapes })
	n = List.len(a)
	var $differ = 0
	var $k = 0
	while $k < n {
		$differ = if List.get(a, $k) == List.get(b, $k) {
			$differ
		} else {
			$differ + 1
		}
		$k = $k + 1
	}
	var $out = List.with_capacity(n * 6 + 64)
	differing = "differ ${U64.to_str($differ)} of ${U64.to_str(n)}"
	totals = "triangles ${triangles(cut_shapes).to_str()}, shapes ${ride_shapes.len().to_str()}"
	size = "${Screen.width_px.to_str()} ${Screen.height_px.to_str()}"
	$out = List.concat($out, Str.to_utf8("${differing}, ${totals}\nhash 00000000\n${size}\n"))
	$k = 0
	while $k < n {
		$out = Hex.append_digits($out, { number: U32.to_i64(List.get(b, $k) ?? 0), digits: 6 })
		$k = $k + 1
	}
	echo!(Str.from_utf8_lossy(List.append($out, 10)))
	Ok({})
}
