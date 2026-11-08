## How an animal plays out on the ride: its timeline. A timeline is a list of
## frames and how to show one, so an animal's whole animation reads in one
## place, and it turns a `Stage`, where the animation has got to, into an
## `Instant`, what the animal shows then. Nothing here plays a timeline but that
## lookup, and nothing here knows when the animation starts: that is
## EncounterPlan's. The instants before and after are the timeline's own,
## because an animal can rest somewhere no frame ever reaches.
import Across
import Along
import Distance
import Easing
import Fraction
import Geom
import Steps

Animation :: [].{

	## Where an animation has got to: not begun, playing and this many steps in,
	## which is the frame it shows, or over this many steps ago.
	Stage : [Waiting, Playing(Steps), Past(Steps)]

	## Where an animal is: a place on its segment, and how high it is off the
	## ground.
	Location : { road_point : Geom.RoadPoint, lift : Distance }

	## The location `fraction` of the way from `from` to `to`, in a straight line.
	location_between : {
		from : Animation.Location,
		to : Animation.Location,
		fraction : Fraction,
	} -> Animation.Location
	location_between = |{ from, to, fraction }| {
		between = |start, end| Easing.lerp({ from: start, to: end, fraction })
		{
			road_point: {
				along: Along.metres(
					between(from.road_point.along.to_metres(), to.road_point.along.to_metres()),
				),
				across: Across.metres(
					between(from.road_point.across.to_metres(), to.road_point.across.to_metres()),
				),
			},
			lift: Distance.metres(between(from.lift.to_metres(), to.lift.to_metres())),
		}
	}

	## An animal at one instant: how it looks, and where it is.
	Instant(pose) : { pose : pose, location : Animation.Location }

	## `instant` as an object on the road: it stands at the instant's location,
	## and its kind is the instant's pose.
	placed_instant : Animation.Instant(pose) -> Geom.Placed({ pose : pose })
	placed_instant = |{ pose, location }| {
		road_point: location.road_point,
		lift: location.lift,
		kind: { pose: pose },
	}

	## A whole animation: the animal at rest before, the frames it plays through,
	## one a step, and the animal at rest after. The frames are the animation's
	## choreography, a constant list, and `frame_instant` turns a frame and its
	## number into the animal then, so playing a frame builds only that frame.
	Timeline(frame, pose) :: {
		before : Animation.Instant(pose),
		frames : List(frame),
		frame_instant : frame, Steps -> Animation.Instant(pose),
		after : Animation.Instant(pose),
	}.{

		## The timeline that rests at `before`, plays `frames` one a step, each
		## shown by `frame_instant` with its frame number, then rests at `after`.
		of : {
			before : Animation.Instant(pose),
			frames : List(frame),
			frame_instant : frame, Steps -> Animation.Instant(pose),
			after : Animation.Instant(pose),
		} -> Animation.Timeline(frame, pose)
		of = |parts| Animation.Timeline.(parts)

		## The animal at `stage`.
		instant : Animation.Timeline(frame, pose), Animation.Stage -> Animation.Instant(pose)
		instant = |Animation.Timeline.(timeline), stage|
			match stage {
				Waiting => timeline.before
				Playing(steps_in) => {
					frame_number = steps_in.to_u32().to_u64()
					match timeline.frames.get(frame_number) {
						Ok(frame) => (timeline.frame_instant)(frame, steps_in)
						Err(OutOfBounds) =>
							crash "Animation.Timeline.instant: a stage plays past the last frame, so the span it was staged by disagrees with its timeline"
					}
				}
				Past(_) => timeline.after
			}
	}
}

Note : [First, Second, Third, Fourth, BeforeIt, AfterIt]

sideways_location : F64 -> Animation.Location
sideways_location = |across| {
	road_point: { along: Along.metres(0.0), across: Across.metres(across) },
	lift: Distance.zero,
}

## A timeline of four frames, each as far across as ten times its frame number.
four_frames : Animation.Timeline(Note, Note)
four_frames = Animation.Timeline.of({
	before: { pose: BeforeIt, location: sideways_location(-1.0) },
	frames: [First, Second, Third, Fourth],
	frame_instant: |note, frame_number| {
		pose: note,
		location: sideways_location(10.0 * frame_number.to_f64()),
	},
	after: { pose: AfterIt, location: sideways_location(99.0) },
})

## The pose and how far across the timeline is at `stage`.
four_frames_at : Animation.Stage -> (Note, F64)
four_frames_at = |stage| {
	instant = four_frames.instant(stage)
	(instant.pose, instant.location.road_point.across.to_metres())
}

# The first and last frames play with their own numbers; before them and past
# them the timeline rests.
expect
	[
		(Waiting, (BeforeIt, -1.0)),
		(Playing(Steps.zero), (First, 0.0)),
		(Playing(Steps.of(2)), (Third, 20.0)),
		(Playing(Steps.of(3)), (Fourth, 30.0)),
		(Past(Steps.zero), (AfterIt, 99.0)),
	].all(|(stage, want)| four_frames_at(stage) == want)

start_location : Animation.Location
start_location = {
	road_point: { along: Along.metres(10.0), across: Across.metres(20.0) },
	lift: Distance.metres(30.0),
}

end_location : Animation.Location
end_location = {
	road_point: { along: Along.metres(18.0), across: Across.metres(4.0) },
	lift: Distance.metres(46.0),
}

## The location's three parts, `fraction` of the way from `start_location` to `end_location`.
location_numbers : F64 -> List(F64)
location_numbers = |fraction| {
	location = Animation.location_between({
		from: start_location,
		to: end_location,
		fraction: Fraction.of(fraction),
	})
	point = location.road_point
	[point.along.to_metres(), point.across.to_metres(), location.lift.to_metres()]
}

expect
	[
		(0.0, [10.0, 20.0, 30.0]),
		(0.25, [12.0, 16.0, 34.0]),
		(1.0, [18.0, 4.0, 46.0]),
	].all(|(fraction, want)| location_numbers(fraction) == want)
