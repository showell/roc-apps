## The widget for the Safari tutorial's chapter on the Roc bird. Video recorder
## buttons run how far the rider is from the tree the bird starts on, coming at
## a steady 1.25 m a step, and each frame is worked out from that gap alone:
## the step of the ride it is, and the start the ride plans for the flight, so the
## flight plays forward and backward. The picture stays still, looking up the
## road from a place short of the first tree, so the bird shrinks as it flies
## off. It is drawn by Safari's own Tree and Bird. Below it, the buttons
## and four lines of text that say what BirdFlight makes of the gap.
import game.Across
import game.Angle
import game.Animation
import game.EncounterPlan
import game.BirdFlight
import game.Clock
import game.Distance
import game.Lens
import game.Bird
import game.Geom
import game.GroundPatch
import game.GroundSighting
import game.Pipeline
import game.SegmentFromRider
import game.Speed
import game.Trees
import game.Sky
import game.World
import lib.CanvasApp
import lib.Shapes
import widget.ReadoutText
import widget.WidgetPage
import widget.VcrButtons

BirdWidgetApp :: [].{

	## The whole state of the widget: the buttons, which hold the gap from the
	## rider to the bird's first tree.
	Model : VcrButtons.Transport(Distance)

	canvas_app : CanvasApp.CanvasApp(BirdWidgetApp.Model)
	canvas_app = VcrButtons.canvas_app({
		title: "The bird taking off",
		range: closing_gap,
		opens_at: closing_gap.first,
		frame_shapes: shapes_at,
	})
}

## The rider's approach, from a gap past where the bird takes off down to zero, in
## ten seconds.
closing_gap : VcrButtons.NumberRange(Distance)
closing_gap = VcrButtons.gap_range({ farthest: Distance.metres(75.0), metres_a_frame: 0.125 })

## The rider's speed, steady, and the widget's own choice. The flight plays a
## frame a step, so this is how much of the gap each frame of the flight takes,
## and it sets the gap the flight starts at.
rider_speed : Speed
rider_speed = Speed.metres_a_step(1.25)

## The flight's timing with the rider `gap` from the bird's first tree.
flight_timing : Distance -> EncounterPlan.Timing
flight_timing = |gap|
	EncounterPlan.steady_approach_timing(
		BirdFlight.flight_span,
		{ gap_at_start: closing_gap.first, speed: rider_speed, gap },
	)

## Where the flight has got to with the rider `gap` from the bird's first tree.
stage_at : Distance -> Animation.Stage
stage_at = |gap| BirdFlight.flight_stage(flight_timing(gap))

## How far the picture's eye stands short of the first tree: far enough for
## the bird perched on top of it to fit.
eye_to_first_tree : Distance
eye_to_first_tree = Distance.metres(18.0)

## Everything on the canvas.
shapes_at : BirdWidgetApp.Model -> List(Shapes.Shape)
shapes_at = |transport|
	VcrButtons.frame_shapes(
		transport,
		{
			range: closing_gap,
			picture_shapes: picture_shapes(transport.at),
			status_lines: status_lines(transport.at),
		},
	)

## The road and the two trees, far things first, and the bird at `gap`.
picture_shapes : Distance -> List(Shapes.Shape)
picture_shapes = |gap|
	WidgetPage.picture_shapes({
		backdrop: { sky_colors: Sky.colors_at(Clock.start), sun_sighting: OutOfView },
		ride_shapes: [
			road_shapes,
			tree_shapes(World.first_bird_flight.to),
			tree_shapes(World.first_bird_flight.from),
			bird_shapes(gap),
		].join(),
	})

## The road the eye sees, as the game lays it: the bird's segment, the bend
## at its end and the road beyond, up to the horizon.
road_shapes : List(Shapes.Shape)
road_shapes =
	GroundSighting.patches_in_view(World.road_at_start, eye).keep_oks(
		|patch| GroundPatch.patch_shape(patch, Lens.resting_focal_length),
	)

## The picture's eye, on the middle of the road `eye_to_first_tree` short of
## the first tree, looking down the road.
eye : Geom.Vantage
eye = {
	along: World.first_bird_flight.planned_along().minus(eye_to_first_tree),
	across: Across.middle,
	yaw: Angle.straight_ahead,
}

## `placed` as the picture's eye sees it, if it is in front of the eye.
sighting_from_eye : Geom.Placed(kind) -> Try(Pipeline.Sighted(kind), [BehindCamera])
sighting_from_eye = |placed|
	Pipeline.sighting_of(
		placed,
		{
			road: World.road_at_start,
			vantage: eye,
			from_rider: Ahead(SegmentFromRider.Position.first),
		},
	)

tree_shapes : Trees.RoadsideTree -> List(Shapes.Shape)
tree_shapes = |tree| WidgetPage.resting_lens_shapes(
	sighting_from_eye(tree),
	{ nearer_tree_count: 0 },
)

## The bird as `gap` finds it, drawn by Safari's own stills.
bird_shapes : Distance -> List(Shapes.Shape)
bird_shapes = |gap| {
	placed_bird : Geom.Placed(Bird)
	placed_bird = Animation.placed_instant(World.first_bird_flight.bird_instant_at(stage_at(gap)))
	WidgetPage.resting_lens_shapes(sighting_from_eye(placed_bird), {})
}

## What BirdFlight says at `gap`, a line each.
status_lines : Distance -> List(Str)
status_lines = |gap| {
	stage = stage_at(gap)
	instant = World.first_bird_flight.bird_instant_at(stage)
	[
		ReadoutText.stage_text(stage),
		"Pose: ${Bird.pose_name(instant.pose)}",
		"Gap: ${ReadoutText.tenths_text(gap.to_metres())} m",
		"Height: ${ReadoutText.tenths_text(instant.location.lift.to_metres())} m",
	]
}

## The gap the flight starts at, for a rider at `rider_speed`: 15 m for the gap
## it lands at and 45 m for its 36 steps.
takeoff_gap : Distance
takeoff_gap = EncounterPlan.planning_gap(BirdFlight.flight_span, rider_speed)

# The bird flies on the route's first segment, the one `World.road_at_start`
# and the eye's `Ahead(SegmentFromRider.Position.first)` stand on.
expect
	match World.route.route_segments() {
		[first, ..] =>
			match first.encounter {
				BirdHere(_) => True
				CatCrosses(_) | QuietRoad => False
			}
		[] => False
	}

# The whole flight is on the range, with some road to spare at the far end.
expect takeoff_gap < closing_gap.first
expect BirdFlight.flight_span.ends_at > closing_gap.last

expect
	status_lines(Distance.metres(61.0))
		== ["Waiting", "Pose: Perched", "Gap: 61.0 m", "Height: 6.4 m"]

expect
	status_lines(Distance.metres(58.0))
		== ["Playing: frame 2", "Pose: Side on, wings up", "Gap: 58.0 m", "Height: 6.9 m"]

expect
	status_lines(Distance.metres(30.0))
		== ["Playing: frame 25", "Pose: Flying away, wings up", "Gap: 30.0 m", "Height: 9.6 m"]

expect
	status_lines(Distance.metres(4.7))
		== ["Past", "Pose: Perched", "Gap: 4.7 m", "Height: 4.9 m"]

# The picture depends on the gap, and it doesn't change once the bird is down.
expect picture_shapes(Distance.metres(30.0)) != picture_shapes(Distance.metres(31.0))
expect picture_shapes(Distance.metres(5.0)) == picture_shapes(Distance.metres(4.0))
