# SafariApp -- the drive, as a value the canvas apps can run.
#
# Hand-written: the shim between the ride Safari actually is and the value a
# runner wants. SafariRide holds the ride and its history; SafariShapes says
# what a frame looks like. This says which keys move it and how the camera
# leans.
#
# The drive plays on its own. Space pauses it. Left steps back through the
# ride's history and Right forward, a frame at a time while paused and faster
# while it runs. Enter jumps to the next of the route's nineteen segments, and
# R starts the drive again.
#
# Raster still paints a frame into pixels, and ShapesFrame checks the two
# against each other, natively; neither is on the path a runner takes.
import lib.CanvasApp
import lib.Input
import lib.Shapes
import SafariRide
import SafariShapes

SafariApp :: [].{
	Model : { ride : SafariRide.Model, paused : Bool }

	width : F64
	width = 960.0

	height : F64
	height = 600.0

	canvas_app : CanvasApp.CanvasApp(SafariApp.Model)
	canvas_app = {
		size: { width, height },
		# **THIRTY, BY EYE.** The drive's motion is written per tick, and
		# thirty is the speed it is meant to look like.
		fps: 30,
		init: { ride: SafariRide.init, paused: Bool.False },
		advance: |m, input, _dt| step(m, input),
		frame: |m| frame(m.ride),
		sounds: |_m| 0,
		tones: [],
		title: "Safari",
	}

	## What to draw, turned by the rider's lean.
	##
	## **THE WHOLE FRAME LEANS**, backdrop and all, so the world banks into a
	## turn. That is a camera whose target and offset are both the middle of
	## the screen and whose rotation is the roll, the other way round: a
	## `View` mark in front of everything else.
	frame : SafariRide.Model -> List(Shapes.Shape)
	frame = |ride| {
		centre = { x: width / 2.0, y: height / 2.0 }
		lean = View(World({ target: centre, offset: centre, rotation: 0.0 - SafariRide.roll(ride) * degrees, zoom: 1.0 }))
		List.prepend(
			SafariShapes.frame(SafariRide.commands(ride), SafariRide.sky_top(ride), SafariRide.sky_horizon(ride), SafariRide.sun(ride)),
			lean,
		)
	}

	degrees : F64
	degrees = 57.29577951308232

	step : SafariApp.Model, Input.Snapshot -> SafariApp.Model
	step = |m, input|
		if input.key_pressed(KeyR) {
			{ ride: SafariRide.init, paused: Bool.False }
		} else {
			paused = if input.key_pressed(KeySpace) { !m.paused } else { m.paused }
			moved =
				if input.key_down(KeyRight) {
					repeat(m.ride, if paused { 1 } else { 4 }, SafariRide.advance)
				} else if input.key_down(KeyLeft) {
					repeat(m.ride, if paused { 1 } else { 4 }, SafariRide.back)
				} else if paused {
					m.ride
				} else {
					SafariRide.advance(m.ride)
				}
			ride = if input.key_pressed(KeyEnter) { next_segment(moved) } else { moved }
			{ ride, paused }
		}

	repeat : SafariRide.Model, I64, (SafariRide.Model -> SafariRide.Model) -> SafariRide.Model
	repeat = |ride, n, move| {
		var $ride = ride
		var $i = 0
		while $i < n {
			$ride = move($ride)
			$i = $i + 1
		}
		$ride
	}

	# The route's segments are its scenes, and reaching the next one means
	# stepping until the segment changes.
	next_segment : SafariRide.Model -> SafariRide.Model
	next_segment = |ride| {
		from = ride.ride.rider.segment
		var $ride = SafariRide.advance(ride)
		var $guard = 0
		while $ride.ride.rider.segment == from and $guard < step_guard {
			$ride = SafariRide.advance($ride)
			$guard = $guard + 1
		}
		$ride
	}

	# A segment is long, but not unbounded.
	step_guard : I64
	step_guard = 200000
}
