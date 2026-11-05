# SafariApp -- the drive, as a value the canvas apps can run.
#
# Hand-written: the shim between the ride Safari actually is and the value a
# runner wants. SafariRide holds the ride and its history; SafariShapes says
# what a frame looks like. This says which keys move it and how the camera
# leans.
#
# The drive plays on its own. Space pauses it. Left steps back through the
# ride's history and Right forward, a frame at a time while paused and faster
# while it runs. J jumps to the next of the route's nineteen segments, and R
# starts the drive again.
#
# SafariFrame paints a frame into pixels for the native proof tools
# (README.md); no runner paints that way.
import lib.CanvasApp
import lib.Input
import lib.Shapes
import SafariRide
import SafariShapes
import Screen

SafariApp :: [].{
	Model : { ride : SafariRide.Model, paused : Bool }

	canvas_app : CanvasApp.CanvasApp(SafariApp.Model)
	canvas_app = {
		size: { width: Screen.width, height: Screen.height },
		# **THIRTY, BY EYE.** The drive's motion is written per tick, and
		# thirty is the speed it is meant to look like.
		fps: 30,
		init: { ride: SafariRide.init, paused: Bool.False },
		advance: |
			m,
			input,
			_dt,
		| step(m, input),
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
		centre = { x: Screen.width / 2.0, y: Screen.height / 2.0 }
		lean = View(
			World({
				target: centre,
				offset: centre,
				rotation: 0.0 - SafariRide.roll(ride).to_radians() * degrees,
				zoom: 1.0,
			}),
		)
		List.prepend(
			SafariShapes.frame(
				SafariRide.shapes(ride),
				{
					sky_top_color: SafariRide.sky_top(ride),
					sky_horizon_color: SafariRide.sky_horizon(ride),
					sun_position: SafariRide.sun(ride),
				},
			),
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
			paused = if input.key_pressed(KeySpace) {
				!m.paused
			} else {
				m.paused
			}
			moved =
				if input.key_down(KeyRight) {
					repeat(
						m.ride,
						{
							step_count: if paused {
								1
							} else {
								4
							},
							step_once: SafariRide.advance,
						},
					)
				} else if input.key_down(KeyLeft) {
					repeat(
						m.ride,
						{
							step_count: if paused {
								1
							} else {
								4
							},
							step_once: SafariRide.back,
						},
					)
				} else if paused {
					m.ride
				} else {
					SafariRide.advance(m.ride)
				}
			ride = if input.key_pressed(KeyJ) {
				next_segment(moved)
			} else {
				moved
			}
			{ ride, paused }
		}

	## The ride after `step_once` has moved it `step_count` times.
	repeat : SafariRide.Model,
	{
		step_count : I64,
		step_once : SafariRide.Model -> SafariRide.Model,
	} -> SafariRide.Model
	repeat = |ride, { step_count: n, step_once: move }| {
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
