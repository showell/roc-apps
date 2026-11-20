## Backyard draws everything behind the table: the dusk sky with the sun going
## down, the lawn, a row of trees and the fence, in two parts so a crowd can
## stand between the trees and the fence. The world is flat, so the
## horizon sits at eye level whatever the eye does, and the sky and the lawn
## are screen rectangles; the sun, the trees and the fence stand in the
## backyard's metres and go through the View.
import lib.Brush
import lib.Pixels
import lib.Point
import lib.RgbColor
import lib.Shapes
import View

Backyard :: [].{

	## The sky, the sun, the lawn and the trees, back to front.
	beyond_fence_shapes : View -> List(Shapes.Shape)
	beyond_fence_shapes = |view| {
		width = view.screen_width()
		horizon = view.screen_height() / 2.0
		band = horizon * 0.6
		sky = [
			Shapes.rectangle({
				top_left: Point.at(0.0, 0.0),
				width: Pixels.of(width),
				height: Pixels.of(band + 1.0),
				fill: gradient({
					top: 0.0,
					bottom: band,
					top_color: 0x241E4A,
					bottom_color: 0x8C4F7A,
				}),
			}),
			Shapes.rectangle({
				top_left: Point.at(0.0, band),
				width: Pixels.of(width),
				height: Pixels.of(horizon - band + 1.0),
				fill: gradient({
					top: band,
					bottom: horizon,
					top_color: 0x8C4F7A,
					bottom_color: 0xF39A58,
				}),
			}),
		]
		lawn = [
			Shapes.rectangle({
				top_left: Point.at(0.0, horizon),
				width: Pixels.of(width),
				height: Pixels.of(view.screen_height() - horizon),
				fill: gradient({
					top: horizon,
					bottom: view.screen_height(),
					top_color: 0x3A4626,
					bottom_color: 0x1F2B18,
				}),
			}),
		]
		[
			sky,
			sun_shapes(view),
			lawn,
			tree_shapes(view),
		].join()
	}

	## A board fence across the back: one panel, a dark gap every board's width,
	## and a rail along its top.
	fence_shapes : View -> List(Shapes.Shape)
	fence_shapes = |view| {
		reach = 80.0
		panel = view.region_shapes({
			corners: [
				{
					right: 0.0 - reach,
					forward: fence_forward,
					height: 0.0,
				},
				{
					right: reach,
					forward: fence_forward,
					height: 0.0,
				},
				{
					right: reach,
					forward: fence_forward,
					height: fence_high,
				},
				{
					right: 0.0 - reach,
					forward: fence_forward,
					height: fence_high,
				},
			],
			fill: Brush.flat(RgbColor.of(0x6E5040)),
		})
		gap = Brush.flat(RgbColor.of(0x4A342A))
		boards : U64
		boards = 160
		var $out = panel
		for k in 0..=boards {
			right = 0.0 - reach + 2.0 * reach * k.to_f64() / boards.to_f64()
			$out = List.concat(
				$out,
				view.line_shapes({
					from: { right, forward: fence_forward, height: 0.0 },
					to: { right, forward: fence_forward, height: fence_high },
					width: 0.03,
					fill: gap,
				}),
			)
		}
		List.concat(
			$out,
			view.line_shapes({
				from: {
					right: 0.0 - reach,
					forward: fence_forward,
					height: fence_high - 0.25,
				},
				to: {
					right: reach,
					forward: fence_forward,
					height: fence_high - 0.25,
				},
				width: 0.08,
				fill: gap,
			}),
		)
	}
}

gradient : {
	top : F64,
	bottom : F64,
	top_color : I64,
	bottom_color : I64,
} -> Brush.Fill
gradient = |{ top, bottom, top_color, bottom_color }|
	Linear({
		stops: {
			start_color: Brush.opaque_rgba(RgbColor.of(top_color)),
			end_color: Brush.opaque_rgba(RgbColor.of(bottom_color)),
			start_offset: 0.0,
			end_offset: 1.0,
		},
		start_point: Point.at(0.0, top),
		end_point: Point.at(0.0, bottom),
	})

# The sun is far off and low, just over the fence, with its glow added to
# the sky around it.
sun_shapes : View -> List(Shapes.Shape)
sun_shapes = |view|
	match view.sighting({
		right: -70.0,
		forward: 320.0,
		height: 30.0,
	}) {
		Ok({ point, pixels_per_metre }) =>
			Shapes.added_light_shapes([
				Shapes.halo(
					{ center: point, radius: Pixels.of(90.0) },
					{ ..Brush.opaque_rgba(RgbColor.of(0xFFB067)), a: 0.55 },
				),
			])
				.append(
					Disc({
						center: point,
						radius: Pixels.of(11.0 * pixels_per_metre),
						fill: Brush.flat(RgbColor.of(0xFFD9A0)),
					}),
				)
		Err(BehindEye) => []
	}

# Dark rounded crowns beyond the fence, each on a short trunk.
trees : List(
	{
		right : F64,
		forward : F64,
		crown : F64,
	},
)
trees = [
	{
		right: -26.0,
		forward: 34.0,
		crown: 2.6,
	},
	{
		right: -16.0,
		forward: 30.0,
		crown: 2.2,
	},
	{
		right: -9.0,
		forward: 36.0,
		crown: 3.0,
	},
	{
		right: 1.0,
		forward: 32.0,
		crown: 2.0,
	},
	{
		right: 8.0,
		forward: 35.0,
		crown: 2.8,
	},
	{
		right: 15.0,
		forward: 31.0,
		crown: 2.3,
	},
	{
		right: 24.0,
		forward: 36.0,
		crown: 3.1,
	},
]

tree_shapes : View -> List(Shapes.Shape)
tree_shapes = |view| {
	trunk = Brush.flat(RgbColor.of(0x231C26))
	crown = Brush.flat(RgbColor.of(0x2C2440))
	trees.map(
		|tree| {
			stem = view.line_shapes({
				from: {
					right: tree.right,
					forward: tree.forward,
					height: 0.0,
				},
				to: {
					right: tree.right,
					forward: tree.forward,
					height: tree.crown * 1.2,
				},
				width: 0.5,
				fill: trunk,
			})
			# A crown is three discs, a big one low and two smaller above it, so
			# it reads as a tree rather than a ball.
			lobes = [
				{
					across: 0.0,
					up: 1.5,
					size: 1.0,
				},
				{
					across: -0.45,
					up: 2.2,
					size: 0.7,
				},
				{
					across: 0.35,
					up: 2.6,
					size: 0.6,
				},
			]
			crowns = lobes.map(
				|lobe|
					match view.sighting({
						right: tree.right + lobe.across * tree.crown,
						forward: tree.forward,
						height: tree.crown * lobe.up,
					}) {
						Ok({ point, pixels_per_metre }) => [
							Disc({
								center: point,
								radius: Pixels.of(tree.crown * lobe.size * pixels_per_metre),
								fill: crown,
							}),
						]
						Err(BehindEye) => []
					},
			).join()
			List.concat(stem, crowns)
		},
	).join()
}

fence_forward : F64
fence_forward = 11.0

fence_high : F64
fence_high = 1.7
