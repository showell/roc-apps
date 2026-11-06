## The widget for the Safari tutorial's beacons. Dragging across the canvas sets
## the ride's clock, and each frame is worked out from that clock alone, so two
## towers blink opposite each other under the pointer, at dusk, where a beacon
## shows up. The towers are drawn by Safari's own Tower, and how bright each is
## comes from TowerSighting. Below them, a ruler shows the clock, with the first
## tower's bright stretches marked, and four lines of text read it out.
import game.Clock
import game.Distance
import game.Fraction
import game.Lens
import game.Steps
import game.Tower
import game.TowerSighting
import lib.CanvasApp
import lib.Shapes
import widget.ScrubWidget

BeaconWidgetApp :: [].{

	## The whole state of the widget: the ride's clock.
	Model : { clock : Clock }

	canvas_app : CanvasApp.CanvasApp(BeaconWidgetApp.Model)
	canvas_app = ScrubWidget.canvas_app({
		title: "Two beacons",
		init: { clock: ScrubWidget.clock_at(Fraction.zero, clock_range) },
		model_at: |share| { clock: ScrubWidget.clock_at(share, clock_range) },
		frame: |model| frame_at(model.clock),
	})
}

## Two whole blinks, late in the ride. The first step is a whole number of blinks
## in, so the ruler starts where a blink starts.
clock_range : ScrubWidget.ClockRange
clock_range = {
	first_step: 5400.0,
	last_step: 5640.0,
}

## The beacon keys of a tower past a segment's end, and of the tower halfway along
## the same segment, which blinks opposite it.
first_tower_key : U32
first_tower_key = 0

second_tower_key : U32
second_tower_key = 60

## How bright the beacon with `key` is at `clock`, as TowerSighting works it out.
brightness_at : Clock, U32 -> Fraction
brightness_at = |clock, key| {
	offset = TowerSighting.beacon_offset_for(key)
	TowerSighting.beacon_brightness(clock.minus(Clock.start).plus(offset))
}

## How far ahead of the picture's eye the towers stand, so that their tops fit.
tower_forward : Distance
tower_forward = Distance.metres(200.0)

## How far to each side of the road a tower stands.
tower_right : Distance
tower_right = Distance.metres(70.0)

## Everything on the canvas at `clock`.
frame_at : Clock -> List(Shapes.Shape)
frame_at = |clock|
	ScrubWidget.frame_shapes({
		picture: picture(clock),
		dot_at: ScrubWidget.step_share(clock.to_f64(), clock_range),
		marked: bright_stretches,
		status: status_lines(clock),
	})

## The two towers in the ride's sky at `clock`.
picture : Clock -> List(Shapes.Shape)
picture = |clock|
	ScrubWidget.ride_picture(
		[
			tower(tower_right.opposite(), brightness_at(clock, first_tower_key)),
			tower(tower_right, brightness_at(clock, second_tower_key)),
		].join(),
		{ clock, sun: OutOfView },
	)

## A tower standing `right` of the road, its beacon at `brightness`.
tower : Distance, Fraction -> List(Shapes.Shape)
tower = |right, brightness| {
	center = { right, forward: tower_forward }
	corner_point = |corner| {
		offset = Tower.corner_offset(corner)
		{
			right: right.plus(Tower.tower_half.times(offset.across)),
			forward: tower_forward.plus(Tower.tower_half.times(offset.along)),
		}
	}
	Tower.draw({
		footprint: {
			back_left: corner_point(BackLeft),
			back_right: corner_point(BackRight),
			front_right: corner_point(FrontRight),
			front_left: corner_point(FrontLeft),
		},
		center,
		cam_focal: Lens.focal,
		beacon_brightness: brightness,
	})
}

## The steps of a blink that the first tower is more than half bright, one
## stretch each: the middle half of the blink.
bright_stretches : List(ScrubWidget.Stretch)
bright_stretches = {
	period = TowerSighting.beacon_period.to_f64()
	bright_in_blink = |first_blink_step|
		{
			from: ScrubWidget.step_share(first_blink_step + period / 4.0, clock_range),
			to: ScrubWidget.step_share(first_blink_step + period * 3.0 / 4.0, clock_range),
		}
	[
		bright_in_blink(clock_range.first_step),
		bright_in_blink(clock_range.first_step + period),
	]
}

## What the clock and the beacons say at `clock`, a line each.
status_lines : Clock -> List(Str)
status_lines = |clock| {
	period = TowerSighting.beacon_period
	into_blink = clock.minus(Clock.start).wrapped_to(period)
	first_tower = ScrubWidget.percent_text(brightness_at(clock, first_tower_key))
	second_tower = ScrubWidget.percent_text(brightness_at(clock, second_tower_key))
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

# The real towers' key step: half a period past a whole number of periods.
expect TowerSighting.beacon_offset_for(first_tower_key) == Steps.zero
expect TowerSighting.beacon_offset_for(second_tower_key) == Steps.of(60)

# Whatever the clock says, what one beacon lacks the other has.
expect
	[5400, 5430, 5447, 5459, 5460, 5461, 5519, 5520, 5640].all(
		|step| {
			clock = Clock.at_step(step)
			first_tower = brightness_at(clock, first_tower_key)
			second_tower = brightness_at(clock, second_tower_key)
			is_near(first_tower, second_tower.complement().to_f64())
		},
	)

expect
	status_lines(Clock.at_step(5400))
		== [
			"Clock: step 5400",
			"Blink: 0 of 120 steps",
			"First tower: 0%",
			"Second tower: 100%",
		]

expect
	status_lines(Clock.at_step(5415))
		== [
			"Clock: step 5415",
			"Blink: 15 of 120 steps",
			"First tower: 14%",
			"Second tower: 85%",
		]

expect
	status_lines(Clock.at_step(5520))
		== [
			"Clock: step 5520",
			"Blink: 0 of 120 steps",
			"First tower: 0%",
			"Second tower: 100%",
		]

expect ScrubWidget.clock_at(Fraction.zero, clock_range) == Clock.at_step(5400)
expect ScrubWidget.clock_at(Fraction.whole, clock_range) == Clock.at_step(5640)

## Whether a share is `want`, to within rounding.
is_near : Fraction, F64 -> Bool
is_near = |share, want| (share.to_f64() - want).abs() <= 0.0000001

# A stretch for each of the two blinks: the middle half of each.
expect bright_stretches.len() == 2
expect {
	first_blink = bright_stretches.first() ?? crash "the blink has a stretch"
	is_near(first_blink.from, 0.125) and is_near(first_blink.to, 0.375)
}
expect {
	second_blink = bright_stretches.last() ?? crash "the blink has a stretch"
	is_near(second_blink.from, 0.625) and is_near(second_blink.to, 0.875)
}

# The picture depends on the clock. A beacon comes back after a whole blink,
# though the sky goes on darkening.
expect picture(Clock.at_step(5430)) != picture(Clock.at_step(5431))
expect brightness_at(Clock.at_step(5430), 0) == brightness_at(Clock.at_step(5550), 0)
