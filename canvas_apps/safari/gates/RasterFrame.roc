## RasterFrame paints one Safari frame with SafariFrame and prints it: a hash
## line, the size, then every pixel as six hex digits, which pixels_png.mjs
## turns into a PNG. Safari's gate runs it (see SafariFrame for more
## context).
##
##   roc build --opt=dev RasterFrame.roc --output=<bin>; <bin> [steps] | node pixels_png.mjs <png>
app [main!] {
	game: "../game.roc",
	lib: "../../lib/main.roc",
}

import game.Tour
import SafariFrame
import game.Screen
import Hex

ride_to : Tour, I64 -> Tour
ride_to = |tour, n| if n <= 0 {
	tour
} else {
	ride_to(Tour.advance(tour), n - 1)
}

# FNV-1a over each pixel's four little-endian bytes. The product stays under
# 2^57, so it needs no wrapping arithmetic.
## One byte folded into an FNV-1a hash.
fnv_step : I64, I64 -> I64
fnv_step = |h, byte| I64.bitwise_and(I64.bitwise_xor(h, byte) * 16777619, 4294967295)

## The byte of `v` that starts `shift` bits up.
byte_of : I64, U8 -> I64
byte_of = |v, shift| I64.bitwise_and(I64.shr_wrap(v, shift), 255)

hash : List(U32) -> I64
hash = |pixels| List.fold(
	pixels,
	2166136261,
	|h, p| {
		v = U32.to_i64(p)
		b0 = fnv_step(h, byte_of(v, 0))
		b1 = fnv_step(b0, byte_of(v, 8))
		b2 = fnv_step(b1, byte_of(v, 16))
		fnv_step(b2, byte_of(v, 24))
	},
)

main! = |args| {
	# With no argument, the run takes its usual number of steps.
	steps =
		match args.get(0) {
			Ok(text) => I64.from_str(text) ?? crash "RasterFrame: steps must be a whole number"
			Err(OutOfBounds) => 0
		}
	tour = ride_to(Tour.init, steps)
	pixels = SafariFrame.paint({
		shapes: Tour.shapes(tour),
		roll: Tour.roll(tour),
		sky_top: Tour.sky_top(tour),
		sky_horizon: Tour.sky_horizon(tour),
		sun: Tour.sun(tour),
	})
	var $out = List.with_capacity(List.len(pixels) * 6 + 32)
	$out = List.concat($out, Str.to_utf8("hash "))
	$out = Hex.append_digits($out, { number: hash(pixels), digits: 8 })
	$out = List.concat(
		$out,
		Str.to_utf8("\n${Screen.width_px.to_str()} ${Screen.height_px.to_str()}\n"),
	)
	n = List.len(pixels)
	var $k = 0
	while $k < n {
		$out = Hex.append_digits($out, { number: U32.to_i64(List.get(pixels, $k) ?? 0), digits: 6 })
		$k = $k + 1
	}
	echo!(Str.from_utf8_lossy(List.append($out, 10)))
	Ok({})
}
