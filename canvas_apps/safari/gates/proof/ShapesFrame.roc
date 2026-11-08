## ShapesFrame checks that cutting a frame changes nothing on screen. The
## browser fills a concave polygon itself, but roc-ray fills only convex ones,
## so the native runner draws what ConvexCut makes of a frame: each concave
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
app [main!] { game: "../../game.roc", lib: "../../../lib/main.roc" }

import game.FrameView
import game.Tour
import SafariFrame
import ShapesPixels
import lib.ConvexCut
import lib.Shapes
import game.Screen
import Hex
import ProofRide

triangles : List(ConvexCut.CutShape) -> U64
triangles = |cut_shapes| cut_shapes.fold(
	0,
	|n, cut_shape|
		match cut_shape {
			Triangles(t) => n + t.triangle_coordinates.len() // 6
			Uncut(_) => n
		},
)

## The cut frame as shapes ShapesPixels paints: each triangle a polygon of its
## own, with its polygon's fill.
shapes_of_cut : List(ConvexCut.CutShape) -> List(Shapes.Shape)
shapes_of_cut = |cut_shapes| cut_shapes.join_map(
	|cut_shape|
		match cut_shape {
			Uncut(shape) => [shape]
			Triangles(t) =>
				List.from_iter(U64.until(0, t.triangle_coordinates.len() // 6)).map(
					|k|
						Poly({
							coordinates: t.triangle_coordinates.sublist({ start: 6 * k, len: 6 }),
							fill: t.fill,
						}),
				)
		},
)

## One frame painted both ways: `pixels` as cut, and the counts that say how
## they went.
Comparison : { pixels : List(U32), counts : Str }

compare : Tour -> Comparison
compare = |tour| {
	view = FrameView.frame_view_at(tour.route(), tour.instant())
	instant_shapes = FrameView.ride_shape_lists(view).join()
	cut_shapes = ConvexCut.cut_shapes(instant_shapes)
	a = SafariFrame.picture_pixels(view)
	backdrop = SafariFrame.backdrop_pixels(view)
	b = ShapesPixels.pixels_with_shapes(
		backdrop,
		{ roll: SafariFrame.screen_roll(view.roll), shapes: shapes_of_cut(cut_shapes) },
	)
	n = a.len()
	var $differ = 0
	for k in 0..<n {
		if a.get(k) != b.get(k) {
			$differ = $differ + 1
		}
	}
	differing = "differ ${U64.to_str($differ)} of ${U64.to_str(n)}"
	totals = "triangles ${triangles(cut_shapes).to_str()}, shapes ${instant_shapes.len().to_str()}"
	{ pixels: b, counts: "${differing}, ${totals}" }
}

held_line : I64, Tour -> Str
held_line = |depth, tour| "ShapesFrame ${depth.to_str()}: ${compare(tour).counts}"

print_picture! : I64 => {}
print_picture! = |steps| {
	comparison = compare(ProofRide.ride_on(Tour.initial, steps))
	pixels = comparison.pixels
	var $out = List.with_capacity(pixels.len() * 6 + 64)
	size = "${Screen.width_px.to_str()} ${Screen.height_px.to_str()}"
	$out = $out.concat("${comparison.counts}\nhash 00000000\n${size}\n".to_utf8())
	for pixel in pixels {
		$out = Hex.append_digits($out, { number: pixel.to_i64(), digits: 6 })
	}
	echo!(Str.from_utf8_lossy($out.append(10)))
}

main! = |args| {
	match args {
		["held", .. as depths] => echo!(ProofRide.held_lines(depths, held_line))
		[steps] => print_picture!(ProofRide.depth_of(steps))
		# With no argument, the run takes its usual number of steps.
		_ => print_picture!(0)
	}
	Ok({})
}
