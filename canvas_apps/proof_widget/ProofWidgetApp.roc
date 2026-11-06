## The widget for the Safari tutorial's chapter on proving it. The ruler has four
## stops, each a step that the gate holds a frame hash for. A click on one rides
## there from the start, keeps the frame's shapes, starts over, rides there
## again, and compares the two lists of shapes with `==`. Nothing is stored
## but a Tour, so the second ride can't come out any other way.
import game.Clock
import game.Fraction
import game.SafariShapes
import game.Tour
import lib.CanvasApp
import lib.Input
import lib.Shapes
import widget.ScrubWidget

ProofWidgetApp :: [].{

	## One of the steps the gate looks at, and what its frame shows.
	Stop : { step : U32, shows : Str }

	## The whole state of the widget: the journey, the stop it's riding to, and
	## how far it has got. The second ride carries the first ride's frame.
	Model : {
		tour : Tour,
		stop : ProofWidgetApp.Stop,
		stage : [
			Resting,
			FirstRide,
			SecondRide(List(Shapes.Shape)),
			Compared({ shapes : U64, same : [SameShapes, DifferentShapes] }),
		],
	}

	canvas_app : CanvasApp.CanvasApp(ProofWidgetApp.Model)
	canvas_app = {
		size: { width: ScrubWidget.canvas_width, height: ScrubWidget.canvas_height },
		fps: 30,
		init: { tour: Tour.initial, stop: bird_stop, stage: Resting },
		advance: |model, input, _seconds| played(aimed(model, input)),
		frame: frame_at,
		sounds: |_model| 0,
		tones: [],
		title: "The same ride twice",
	}
}

bird_stop : ProofWidgetApp.Stop
bird_stop = { step: 100, shows: "Step 100: a bird in flight" }

## Four of the steps in `gates/proof.expected`.
stops : List(ProofWidgetApp.Stop)
stops = [
	bird_stop,
	{ step: 1570, shows: "Step 1570: a cat frozen in the lane" },
	{ step: 1586, shows: "Step 1586: the cat in mid-leap" },
	{ step: 3742, shows: "Step 3742: a distant truck" },
]

## How many steps of the ride are played in one frame of the widget.
played_a_frame : U32
played_a_frame = 24

## Which of the stops a share of the ruler falls in.
stop_index_at : Fraction -> U64
stop_index_at = |share| {
	index = (share.to_f64() * stops.len().to_f64()).to_i64_wrap().to_u64_wrap()
	if index >= stops.len() {
		stops.len() - 1
	} else {
		index
	}
}

stop_at : Fraction -> ProofWidgetApp.Stop
stop_at = |share|
	stops.get(stop_index_at(share)) ?? crash "ProofWidgetApp.stop_at: the index is in range"

## The widget setting off for `stop`, from the start of the ride.
set_off_for : ProofWidgetApp.Stop -> ProofWidgetApp.Model
set_off_for = |stop| { tour: Tour.initial, stop, stage: FirstRide }

## `model` after a press, or a drag onto another stop, has set it off.
aimed : ProofWidgetApp.Model, Input.Snapshot -> ProofWidgetApp.Model
aimed = |model, input|
	if input.mouse.button_down(Left) {
		stop = stop_at(ScrubWidget.share_under(input.mouse.position().x.to_f64()))
		if input.mouse.button_pressed(Left) or stop.step != model.stop.step {
			set_off_for(stop)
		} else {
			model
		}
	} else {
		model
	}

## `tour` a frame's worth of steps closer to `step`.
ridden_on : Tour, U32 -> Tour
ridden_on = |tour, step| {
	var $tour = tour
	var $left = played_a_frame
	while $left > 0 and $tour.instant.clock != Clock.at_step(step) {
		$tour = Tour.advance($tour)
		$left = $left - 1
	}
	$tour
}

## `model` a frame on.
played : ProofWidgetApp.Model -> ProofWidgetApp.Model
played = |model| {
	there = Clock.at_step(model.stop.step)
	match model.stage {
		Resting | Compared(_) => model
		FirstRide => {
			tour = ridden_on(model.tour, model.stop.step)
			if tour.instant.clock == there {
				{ ..model, tour: Tour.initial, stage: SecondRide(Tour.shapes(tour)) }
			} else {
				{ ..model, tour }
			}
		}
		SecondRide(first_shapes) => {
			tour = ridden_on(model.tour, model.stop.step)
			if tour.instant.clock == there {
				{ ..model, tour, stage: Compared(comparison(first_shapes, Tour.shapes(tour))) }
			} else {
				{ ..model, tour }
			}
		}
	}
}

## What comparing two frames found.
comparison : List(Shapes.Shape), List(Shapes.Shape) -> { shapes : U64, same : [SameShapes, DifferentShapes] }
comparison = |first_shapes, second_shapes| {
	shapes: second_shapes.len(),
	same: if first_shapes == second_shapes {
		SameShapes
	} else {
		DifferentShapes
	},
}

## How far along the screen the middle of a stop's stretch of ruler is.
stop_share : U64 -> F64
stop_share = |index| (index.to_f64() + 0.5) / stops.len().to_f64()

## A short stretch of the ruler at each stop.
stop_marks : List(ScrubWidget.Stretch)
stop_marks =
	stops.map_with_index(
		|_stop, index| {
			from: Fraction.clamp(stop_share(index) - 0.012),
			to: Fraction.clamp(stop_share(index) + 0.012),
		},
	)

## The index of a stop in the list.
index_of : ProofWidgetApp.Stop -> U64
index_of = |stop|
	stops.find_first_index(|candidate| candidate.step == stop.step) ?? 0

## The upper part of the ride's frame, at two thirds of its size. The frame is
## taller than the widget's picture, so this keeps a flying bird and the horizon.
window : Shapes.Shape
window = View(
	World({
		target: { x: 480.0, y: 250.0 },
		offset: { x: ScrubWidget.canvas_width / 2.0, y: ScrubWidget.picture_bottom_y / 2.0 },
		rotation: 0.0,
		zoom: 2.0 / 3.0,
	}),
)

## The ride's own frame at `tour`.
picture : Tour -> List(Shapes.Shape)
picture = |tour|
	[
		[window],
		SafariShapes.frame(
			Tour.shapes(tour),
			{
				sky_top_color: Tour.sky_top(tour),
				sky_horizon_color: Tour.sky_horizon(tour),
				sun_position: Tour.sun(tour),
			},
		),
		[View(Screen)],
	].join()

## How far a ride has got, in words.
ride_text : ProofWidgetApp.Model -> Str
ride_text = |{ tour, stop, .. }|
	"step ${tour.instant.clock.to_str()} of ${stop.step.to_str()}"

## How the comparison came out, in words.
same_text : [SameShapes, DifferentShapes] -> Str
same_text = |same|
	match same {
		SameShapes => "The same, shape for shape"
		DifferentShapes => "Different shapes"
	}

## How far the rides have got, a line each.
status_lines : ProofWidgetApp.Model -> List(Str)
status_lines = |model|
	match model.stage {
		Resting =>
			[
				"Click a stop on the ruler",
				"The ride goes there, starts over,",
				"goes there again, and compares",
				"the two frames with ==",
			]
		FirstRide =>
			[
				model.stop.shows,
				"First ride: ${ride_text(model)}",
				"Second ride: waiting",
			]
		SecondRide(first_shapes) =>
			[
				model.stop.shows,
				"First ride: ${first_shapes.len().to_str()} shapes, kept",
				"Second ride: ${ride_text(model)}",
			]
		Compared({ shapes, same }) =>
			[
				model.stop.shows,
				"First ride: ${shapes.to_str()} shapes",
				"Second ride: ${shapes.to_str()} shapes",
				same_text(same),
			]
	}

## Everything on the canvas.
frame_at : ProofWidgetApp.Model -> List(Shapes.Shape)
frame_at = |model|
	ScrubWidget.frame_shapes({
		picture: picture(model.tour),
		dot_at: Fraction.clamp(stop_share(index_of(model.stop))),
		marked: stop_marks,
		status: status_lines(model),
	})

## `model` after `frames` frames with nobody touching it.
left_alone : ProofWidgetApp.Model, U64 -> ProofWidgetApp.Model
left_alone = |model, frames| {
	var $model = model
	var $left = frames
	while $left > 0 {
		$model = played($model)
		$left = $left - 1
	}
	$model
}

## The stop the first short ride goes to, in as few frames as a test can wait.
near_stop : ProofWidgetApp.Stop
near_stop = { step: 30, shows: "" }

# The first ride goes all the way there, then the second starts from step 0.
expect left_alone(set_off_for(near_stop), 1).tour.instant.clock == Clock.at_step(24)
expect left_alone(set_off_for(near_stop), 2).tour.instant.clock == Clock.start
expect
	match left_alone(set_off_for(near_stop), 2).stage {
		SecondRide(first_shapes) => !first_shapes.is_empty()
		_ => False
	}

# The second ride gets there, and the two frames are the same.
expect
	match left_alone(set_off_for(near_stop), 4).stage {
		Compared({ shapes, same }) => shapes > 0 and same == SameShapes
		_ => False
	}

# Once compared, it stays where it is.
expect {
	done = left_alone(set_off_for(near_stop), 4)
	played(done).tour.instant.clock == done.tour.instant.clock
}

# Resting, it doesn't go anywhere.
expect left_alone({ tour: Tour.initial, stop: bird_stop, stage: Resting }, 3).tour.instant.clock == Clock.start

# The frames at two steps aren't the same, so `==` can tell.
expect {
	one = Tour.shapes(ridden_on(Tour.initial, 10))
	other = Tour.shapes(ridden_on(Tour.initial, 11))
	comparison(one, one).same == SameShapes and comparison(one, other).same == DifferentShapes
}

# The ruler's four stretches, at both ends and between them.
expect stop_index_at(Fraction.zero) == 0
expect stop_index_at(Fraction.of(0.24)) == 0
expect stop_index_at(Fraction.of(0.26)) == 1
expect stop_index_at(Fraction.whole) == 3

expect index_of(bird_stop) == 0
expect stop_share(0) == 0.125
expect stop_share(3) == 0.875

expect same_text(SameShapes) == "The same, shape for shape"
expect same_text(DifferentShapes) == "Different shapes"
