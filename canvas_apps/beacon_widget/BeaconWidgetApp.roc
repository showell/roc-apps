## The widget for the Safari tutorial's beacons. Video recorder buttons run the
## ride's clock, and each frame is worked out from that clock alone, so two towers
## blink opposite each other at dusk, where a beacon shows up. The towers are drawn
## by Safari's own Tower, and how bright each is comes from Beacon. Below
## them, the buttons and four lines of text that read out the clock.
import game.Across
import game.Along
import game.Angle
import game.Beacon
import game.Clock
import game.Distance
import game.Fraction
import game.Geom
import game.Lens
import game.Pipeline
import game.RoadAhead
import game.Route
import game.SegmentPlace
import game.Sky
import game.Steps
import game.Tower
import game.World
import lib.CanvasApp
import lib.Shapes
import widget.ReadoutText
import widget.ScrubWidget
import widget.VcrButtons

BeaconWidgetApp :: [].{

	## The whole state of the widget: the buttons, which hold the ride's clock.
	Model : VcrButtons.Transport(Clock)

	canvas_app : CanvasApp.CanvasApp(BeaconWidgetApp.Model)
	canvas_app = VcrButtons.canvas_app({
		title: "Two beacons",
		range: blinks,
		opens_at: blinks.first,
		frame_shapes: shapes_at,
	})
}

## Two whole blinks, late in the ride, a blink in two seconds. The first step is a
## whole number of blinks in, so the range starts where a blink starts.
blinks : VcrButtons.NumberRange(Clock)
blinks = VcrButtons.clock_range({
	first_step: 5400,
	last_step: 5640,
	steps_a_frame: 1.0,
})

## The beacons of a tower past a segment's end, and of the tower halfway along
## the same segment, which blinks opposite it.
first_beacon : Beacon
first_beacon = Beacon.(0)

second_beacon : Beacon
second_beacon = first_beacon.opposite()

## How far down the road from the picture's eye the towers stand, so that their
## tops fit.
tower_forward : Distance
tower_forward = Distance.metres(200.0)

## How far to each side of the road a tower stands.
tower_right : Distance
tower_right = Distance.metres(70.0)

## Everything on the canvas.
shapes_at : BeaconWidgetApp.Model -> List(Shapes.Shape)
shapes_at = |transport|
	VcrButtons.frame_shapes(
		transport,
		{
			range: blinks,
			picture_shapes: picture_shapes(transport.at),
			status_lines: status_lines(transport.at),
		},
	)

## The two towers in the ride's sky at `clock`.
picture_shapes : Clock -> List(Shapes.Shape)
picture_shapes = |clock|
	ScrubWidget.picture_shapes({
		backdrop: { sky_colors: Sky.colors_at(clock), sun_sighting: OutOfView },
		ride_shapes: [
			tower_shapes(tower_right.opposite(), first_beacon.brightness_at(clock)),
			tower_shapes(tower_right, second_beacon.brightness_at(clock)),
		].join(),
		roll: Angle.upright,
	})

## The road ahead of a rider on the route's first segment, straight for well
## past the towers.
straight_road : RoadAhead.RoadView
straight_road = RoadAhead.RoadView.ahead_of(World.route, Route.SegmentIndex.first)

## The picture's eye, at the start of the route, looking down the road.
eye : Geom.Vantage
eye = {
	along: Along.metres(0.0),
	across: Across.metres(0.0),
	yaw: Angle.straight_ahead,
}

## A tower standing `right` of the road's middle, unturned, its beacon at
## `brightness`, or nothing if it stood behind the camera.
tower_shapes : Distance, Fraction -> List(Shapes.Shape)
tower_shapes = |right, brightness| {
	placed_tower : Geom.Placed(Tower)
	placed_tower = {
		road_point: { along: Along.at(tower_forward), across: Across.right_of_middle(right) },
		lift: Distance.zero,
		kind: { yaw: Angle.straight_ahead, beacon_brightness: brightness },
	}
	place = Ahead(SegmentPlace.Position.first)
	match Pipeline.sighting_of(placed_tower, { road: straight_road, vantage: eye, place }) {
		Ok(sighting) =>
			sighting.kind.scenery_picture({
				spot: sighting.spot,
				cam_focal: Lens.resting_focal,
				context: { road: straight_road, vantage: eye },
			}).to_shapes()
		Err(BehindCamera) => []
	}
}

## What the clock and the beacons say at `clock`, a line each.
status_lines : Clock -> List(Str)
status_lines = |clock| {
	period = Beacon.beacon_period
	into_blink = clock.steps_since(Clock.start).wrapped_to(period)
	first_tower = ReadoutText.percent_text(first_beacon.brightness_at(clock))
	second_tower = ReadoutText.percent_text(second_beacon.brightness_at(clock))
	[
		"Clock: step ${clock.to_str()}",
		"Blink: ${step_count_text(into_blink)} of ${step_count_text(period)} steps",
		"First tower: ${first_tower}",
		"Second tower: ${second_tower}",
	]
}

## A whole number of steps, as a number.
step_count_text : Steps -> Str
step_count_text = |steps| steps.to_f64().to_i64_wrap().to_str()

# Whatever the clock says, what one beacon lacks the other has.
expect
	[5400, 5430, 5447, 5459, 5460, 5461, 5519, 5520, 5640].all(
		|step| {
			clock = Clock.at_step(step)
			first_tower = first_beacon.brightness_at(clock)
			second_tower = second_beacon.brightness_at(clock)
			is_near(first_tower, second_tower.less().to_f64())
		},
	)

expect
	status_lines(Clock.at_step(5400))
		== ["Clock: step 5400", "Blink: 0 of 120 steps", "First tower: 0%", "Second tower: 100%"]

# The range runs two whole blinks.
expect blinks.last.steps_since(blinks.first).to_f64() == 2.0 * Beacon.beacon_period.to_f64()

## Whether a share is `want`, to within rounding.
is_near : Fraction, F64 -> Bool
is_near = |share, want| (share.to_f64() - want).abs() <= 0.0000001

# The picture depends on the clock. A beacon comes back after a whole blink,
# though the sky goes on darkening.
expect picture_shapes(Clock.at_step(5430)) != picture_shapes(Clock.at_step(5431))
expect first_beacon.brightness_at(Clock.at_step(5430)) == first_beacon.brightness_at(Clock.at_step(5550))

# The picture follows the buttons' clock.
expect
	shapes_at(VcrButtons.transport_at(Clock.at_step(5430)))
		!= shapes_at(VcrButtons.transport_at(Clock.at_step(5431)))
