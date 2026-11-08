## The widget for the Safari tutorial's beacons. Video recorder buttons run the
## ride's clock, and each frame is worked out from that clock alone, so two towers
## blink opposite each other at dusk, where a beacon shows up. The towers are drawn
## by Safari's own Tower, and each beacon's blink comes from Beacon. Below
## them, the buttons and four lines of text that read out the clock.
import game.Across
import game.Along
import game.Angle
import game.Beacon
import game.Clock
import game.Distance
import game.Geom
import game.Lens
import game.Pipeline
import game.Route
import game.SegmentPlace
import game.Sky
import game.Tower
import game.World
import lib.CanvasApp
import lib.Shapes
import widget.ReadoutText
import widget.WidgetPage
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

## The beacon at `clock` of a tower on the first segment: past its end for the
## first tower, and halfway along it, blinking opposite, for the second.
beacon_at : [AtEnd, Midway], Clock -> Beacon
beacon_at = |place, clock| Beacon.at({ segment: Route.SegmentIndex.first, place }, clock)

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
	WidgetPage.picture_shapes({
		backdrop: { sky_colors: Sky.colors_at(clock), sun_sighting: OutOfView },
		ride_shapes: [
			tower_shapes(tower_right.opposite(), beacon_at(AtEnd, clock)),
			tower_shapes(tower_right, beacon_at(Midway, clock)),
		].join(),
	})

## The picture's eye, at the start of the route, looking down the road.
eye : Geom.Vantage
eye = {
	along: Along.metres(0.0),
	across: Across.metres(0.0),
	yaw: Angle.straight_ahead,
}

## A tower standing `right` of the road's middle, unturned, with `beacon` on
## top, or nothing if it stood behind the camera.
tower_shapes : Distance, Beacon -> List(Shapes.Shape)
tower_shapes = |right, beacon| {
	placed_tower : Geom.Placed(Tower)
	placed_tower = {
		road_point: { along: Along.at(tower_forward), across: Across.right_of_middle(right) },
		lift: Distance.zero,
		kind: Tower.standing({ yaw: Angle.straight_ahead, beacon }),
	}
	place = Ahead(SegmentPlace.Position.first)
	camera = { vantage: eye, focal_length: Lens.resting_focal_length }
	WidgetPage.resting_lens_shapes(
		Pipeline.sighting_of(placed_tower, { road: World.road_at_start, camera, place }),
		{ road: World.road_at_start, vantage: eye },
	)
}

## What the clock and the beacons say at `clock`, a line each.
status_lines : Clock -> List(Str)
status_lines = |clock| {
	period = Beacon.beacon_period
	into_blink = clock.steps_since(Clock.start).wrapped_to(period)
	first_tower = ReadoutText.percent_text(beacon_at(AtEnd, clock).brightness())
	second_tower = ReadoutText.percent_text(beacon_at(Midway, clock).brightness())
	[
		"Clock: step ${clock.to_str()}",
		"Blink: ${ReadoutText.whole_text(into_blink.to_f64())} of ${ReadoutText.whole_text(period.to_f64())} steps",
		"First tower: ${first_tower}",
		"Second tower: ${second_tower}",
	]
}

expect
	status_lines(Clock.at_step(5400))
		== ["Clock: step 5400", "Blink: 0 of 120 steps", "First tower: 0%", "Second tower: 100%"]

# The range runs two whole blinks.
expect blinks.last.steps_since(blinks.first).to_f64() == 2.0 * Beacon.beacon_period.to_f64()

# The picture depends on the clock.
expect picture_shapes(Clock.at_step(5430)) != picture_shapes(Clock.at_step(5431))

# The picture follows the buttons' clock.
expect
	shapes_at(VcrButtons.transport_at(Clock.at_step(5430)))
		!= shapes_at(VcrButtons.transport_at(Clock.at_step(5431)))
