## SafariApp is the ride as a value the canvas apps can run. It sits between the
## ride and what a runner wants: Tour holds the ride and its history, Backdrop
## says what is behind it, and this module says which keys move it and how the
## camera leans.
##
## The ride plays on its own. Space pauses it. Left steps back through the ride's
## history and Right forward, a frame at a time while paused and faster while it
## runs. J jumps to the next of the route's nineteen segments, and R starts the
## ride again.
import lib.CanvasApp
import lib.Input
import lib.Shapes
import Backdrop
import Screen
import Tour

SafariApp :: [].{
	Model : { tour : Tour, paused : Bool }

	canvas_app : CanvasApp.CanvasApp(SafariApp.Model)
	canvas_app = {
		size: { width: Screen.width.to_f64(), height: Screen.height.to_f64() },
		# The ride's motion is written per step, and thirty steps a second is the
		# speed it is meant to look like, chosen by eye.
		fps: 30,
		init: { tour: Tour.initial, paused: Bool.False },
		advance: CanvasApp.untimed_advance(step),
		frame: |m| frame(m.tour),
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
	frame : Tour -> List(Shapes.Shape)
	frame = |tour| {
		centre = { x: Screen.width.to_f64() / 2.0, y: Screen.height.to_f64() / 2.0 }
		lean = View(
			World({
				target: centre,
				offset: centre,
				rotation: 0.0 - Tour.roll(tour).to_degrees(),
				zoom: 1.0,
			}),
		)
		Backdrop.behind(
			Tour.shapes(tour),
			{
				sky_top_color: Tour.sky_top_color(tour),
				sky_horizon_color: Tour.sky_horizon_color(tour),
				sun_sighting: Tour.sun(tour),
			},
		).prepend(lean)
	}

	step : SafariApp.Model, Input.Snapshot -> SafariApp.Model
	step = |m, input|
		if input.key_pressed(KeyR) {
			{ tour: Tour.initial, paused: Bool.False }
		} else {
			paused = if input.key_pressed(KeySpace) {
				!m.paused
			} else {
				m.paused
			}
			moved =
				if input.key_down(KeyRight) {
					repeat(
						m.tour,
						{
							step_count: if paused {
								1
							} else {
								4
							},
							step_once: Tour.step_forward,
						},
					)
				} else if input.key_down(KeyLeft) {
					repeat(
						m.tour,
						{
							step_count: if paused {
								1
							} else {
								4
							},
							step_once: Tour.step_back,
						},
					)
				} else if paused {
					m.tour
				} else {
					Tour.step_forward(m.tour)
				}
			tour = if input.key_pressed(KeyJ) {
				next_segment(moved)
			} else {
				moved
			}
			{ tour, paused }
		}

	## The tour after `step_once` has moved it `step_count` times.
	repeat : Tour, { step_count : I64, step_once : Tour -> Tour } -> Tour
	repeat = |tour, { step_count: n, step_once: move }| {
		var $tour = tour
		var $i = 0
		while $i < n {
			$tour = move($tour)
			$i = $i + 1
		}
		$tour
	}

	# The route's segments are its scenes, and reaching the next one means
	# stepping until the segment changes.
	next_segment : Tour -> Tour
	next_segment = |tour| {
		from = tour.instant.rider.segment_index
		var $tour = Tour.step_forward(tour)
		var $guard = 0
		while $tour.instant.rider.segment_index == from and $guard < step_guard {
			$tour = Tour.step_forward($tour)
			$guard = $guard + 1
		}
		$tour
	}

	# A segment is long, but not unbounded.
	step_guard : I64
	step_guard = 200000
}
