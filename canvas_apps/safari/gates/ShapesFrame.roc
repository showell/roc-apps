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
## RasterFrame's format, which pixels_png.mjs turns into a PNG. Given `held`
## and rising depths, it prints only each depth's counts, from one pass through
## the ride.
##
##   roc build --opt=dev ShapesFrame.roc --output=<bin>; <bin> [steps] | node pixels_png.mjs <png>
##   <bin> held 0 100 3000
app [main!] {
	game: "../game.roc",
	lib: "../../lib/main.roc",
}

import game.Tour
import SafariFrame
import ShapesPixels
import lib.Shapes
import game.Screen
import Hex
import ProofRide

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

## One frame painted both ways: `pixels` as cut, and the counts that say how
## they went.
Comparison : { pixels : List(U32), counts : Str }

compare : Tour -> Comparison
compare = |tour| {
	instant_shapes = Tour.shapes(tour)
	roll = Tour.roll(tour)
	scene = {
		shapes: instant_shapes,
		roll,
		sky_top: Tour.sky_top(tour),
		sky_horizon: Tour.sky_horizon(tour),
		sun: Tour.sun(tour),
	}
	cut_shapes = Shapes.cut(instant_shapes)
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
	differing = "differ ${U64.to_str($differ)} of ${U64.to_str(n)}"
	totals = "triangles ${triangles(cut_shapes).to_str()}, shapes ${instant_shapes.len().to_str()}"
	{ pixels: b, counts: "${differing}, ${totals}" }
}

held_line : I64, Tour -> Str
held_line = |depth, tour| "ShapesFrame ${depth.to_str()}: ${compare(tour).counts}"

picture! : I64 => {}
picture! = |steps| {
	comparison = compare(ProofRide.ride_on(Tour.initial, steps))
	pixels = comparison.pixels
	n = List.len(pixels)
	var $out = List.with_capacity(n * 6 + 64)
	size = "${Screen.width_px.to_str()} ${Screen.height_px.to_str()}"
	$out = List.concat($out, Str.to_utf8("${comparison.counts}\nhash 00000000\n${size}\n"))
	var $k = 0
	while $k < n {
		$out = Hex.append_digits($out, { number: U32.to_i64(List.get(pixels, $k) ?? 0), digits: 6 })
		$k = $k + 1
	}
	echo!(Str.from_utf8_lossy(List.append($out, 10)))
}

main! = |args| {
	match args {
		["held", .. as depths] => echo!(ProofRide.held_lines(depths, held_line))
		[steps] => picture!(ProofRide.depth_of(steps))
		# With no argument, the run takes its usual number of steps.
		_ => picture!(0)
	}
	Ok({})
}
