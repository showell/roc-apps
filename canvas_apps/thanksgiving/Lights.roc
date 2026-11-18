## Lights draws the string lights over the table: a strand along each side,
## sagging between three posts, with a bulb every half metre. It is told how
## bright each bulb is, nearest the guest first, and paints the lit ones with
## a glow, so the blinking is the caller's.
import lib.Brush
import lib.Pixels
import lib.RgbColor
import lib.Shapes
import View

Lights :: [].{

	## How many bulbs hang on each strand.
	bulb_count : U64
	bulb_count = 13

	## How far down the table bulb `index` hangs, the first nearest the guest.
	bulb_forward : U64 -> F64
	bulb_forward = |index| first_post + spacing * index.to_f64()

	## The bulb that hangs nearest to `forward` metres down the table.
	nearest_bulb : F64 -> U64
	nearest_bulb = |forward| {
		steps = (forward - first_post) / spacing + 0.5
		if steps <= 0.0 {
			0
		} else if steps >= (bulb_count - 1).to_f64() {
			bulb_count - 1
		} else {
			steps.to_u64_wrap()
		}
	}

	## The six posts the strands hang from. They stand on the lawn beside the
	## chairs, so they are painted with the backyard, behind the robots.
	post_shapes : View -> List(Shapes.Shape)
	post_shapes = |view| {
		var $out = List.with_capacity(6)
		for side in [-1.0, 1.0] {
			for post in [0.0, 1.0, 2.0] {
				right = side * strand_right
				forward = first_post + post * post_gap
				$out = $out.concat(
					view.line_shapes({
						from: { right, forward, height: 0.0 },
						to: { right, forward, height: post_top + 0.1 },
						width: 0.07,
						fill: post_wood,
					}),
				)
			}
		}
		$out
	}

	## The two strands and their bulbs, `glows` giving each bulb's brightness
	## from 0 to 1, nearest first. They hang above every head, so they are
	## painted over everything at the table.
	strand_shapes : View, List(F64) -> List(Shapes.Shape)
	strand_shapes = |view, glows| {
		var $out = List.with_capacity(200)
		var $halos = List.with_capacity(30)
		for side in [-1.0, 1.0] {
			right = side * strand_right
			var $wire = List.with_capacity(wire_samples + 1)
			for k in 0..=wire_samples {
				forward = first_post + 2.0 * post_gap * k.to_f64() / wire_samples.to_f64()
				$wire = $wire.append({ right, forward, height: wire_height(forward) })
			}
			for (a, b) in $wire.drop_last(1).map2($wire.drop_first(1), |a, b| (a, b)) {
				$out = $out.concat(
					view.line_shapes({
						from: a,
						to: b,
						width: 0.015,
						fill: wire_dark,
					}),
				)
			}
			for k in 0..<bulb_count {
				glow = glows.get(k) ?? crash "Lights.strand_shapes: a brightness for every bulb"
				forward = Lights.bulb_forward(k)
				hang = {
					right,
					forward,
					height: wire_height(forward) - bulb_drop,
				}
				match view.sighting(hang) {
					Ok({ point, pixels_per_metre }) => {
						color = Brush.mix({
							from: bulb_off,
							to: bulb_on,
							fraction: glow,
						})
						$out = $out.append(
							Disc({
								center: point,
								radius: Pixels.of(bulb_radius * pixels_per_metre),
								fill: Flat(color),
							}),
						)
						if glow > 0.0 {
							$halos = $halos.append(
								Shapes.halo(
									{ center: point, radius: Pixels.of(0.28 * pixels_per_metre) },
									{ ..bulb_on, a: 0.4 * glow },
								),
							)
						}
					}
					Err(BehindEye) => {}
				}
			}
		}
		$out.concat(Shapes.added_light_shapes($halos))
	}
}

first_post : F64
first_post = 0.6

post_gap : F64
post_gap = 3.0

spacing : F64
spacing = 0.5

strand_right : F64
strand_right = 2.0

post_top : F64
post_top = 2.5

wire_samples : U64
wire_samples = 24

bulb_drop : F64
bulb_drop = 0.07

bulb_radius : F64
bulb_radius = 0.05

# The wire hangs between posts as a shallow parabola, lowest halfway.
wire_height : F64 -> F64
wire_height = |forward| {
	along = (forward - first_post) / post_gap
	part = along - along.to_i64_wrap().to_f64()
	post_top - 0.32 * 4.0 * part * (1.0 - part)
}

post_wood : Brush.Fill
post_wood = Brush.flat(RgbColor.of(0x3B2A1E))

wire_dark : Brush.Fill
wire_dark = Brush.flat(RgbColor.of(0x1D1A18))

bulb_off : Brush.Rgba
bulb_off = Brush.opaque_rgba(RgbColor.of(0x5B5340))

bulb_on : Brush.Rgba
bulb_on = Brush.opaque_rgba(RgbColor.of(0xFFF1B8))

expect Lights.nearest_bulb(0.0) == 0
expect Lights.nearest_bulb(2.6) == 4
expect Lights.nearest_bulb(20.0) == 12
expect (Lights.bulb_forward(12) - 6.6).abs() <= 0.000001

# The wire is at the top of a post at the post, and lower between posts.
expect wire_height(first_post) == post_top
expect wire_height(first_post + post_gap / 2.0) < post_top
