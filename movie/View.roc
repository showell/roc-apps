# View -- a movie's eye: where a thing in the world lands on the screen.
#
# Hand-written. Safari has a camera of its own, with a 600-pixel screen and an
# adult's 1.2-metre eye baked in, because for a long time there was one movie
# and it was a motorcycle. This is the same arithmetic with those as
# parameters, so a movie can be seen from a child's height on a screen of its
# own size.
#
# **THE WORLD IS THREE NUMBERS**: `right` across, `forward` away, `height` up
# from the ground, all in metres. The screen is pixels. `focal` is what turns
# one into the other -- the pixels a metre subtends a metre away -- so a bigger
# focal is a longer lens and a narrower view.

View :: [].{
	View : { width : F64, height : F64, eye : F64, focal : F64 }

	At : { right : F64, forward : F64, height : F64 }

	# Nothing nearer than this is drawn: at the eye it would be infinite.
	near : F64
	near = 0.35

	project : View.View, View.At -> { x : F64, y : F64 }
	project = |v, p| {
		x: v.width / 2.0 + p.right / p.forward * v.focal,
		y: v.height / 2.0 - (p.height - v.eye) / p.forward * v.focal,
	}

	# How many pixels a metre is, that far away. A figure's size, and the
	# width of anything drawn flat.
	pixels_per_metre : View.View, F64 -> F64
	pixels_per_metre = |v, forward| v.focal / forward
}
