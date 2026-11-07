## How an animal plays out on the ride: its timeline. A timeline is a list of
## frames, each a pose and a location, so an animal's whole animation reads in
## one place, and it turns a `Stage`, where the animation has got to, into an
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
	Location : {
		along : Along,
		across : Across,
		lift : Distance,
	}

	## The location `fraction` of the way from `from` to `to`, in a straight line.
	location_between : {
		from : Animation.Location,
		to : Animation.Location,
		fraction : Fraction,
	} -> Animation.Location
	location_between = |{ from, to, fraction }| {
		between = |start, end| Easing.lerp({ from: start, to: end, fraction })
		{
			along: Along.metres(between(from.along.to_metres(), to.along.to_metres())),
			across: Across.metres(between(from.across.to_metres(), to.across.to_metres())),
			lift: Distance.metres(between(from.lift.to_metres(), to.lift.to_metres())),
		}
	}

	## An animal at one instant: how it looks, and where it is.
	Instant(pose) : { pose : pose, location : Animation.Location }

	## `instant` as an object on the road: it stands at the instant's location,
	## and its kind is the instant's pose.
	placed_instant : Animation.Instant(pose) -> Geom.Placed({ pose : pose })
	placed_instant = |{ pose, location }| {
		road_point: { along: location.along, across: location.across },
		lift: location.lift,
		kind: { pose: pose },
	}

	## A whole animation: the animal at rest before, the frames it plays through,
	## one a step, and the animal at rest after.
	Timeline(pose) := {
		before : Animation.Instant(pose),
		frames : List(Animation.Instant(pose)),
		after : Animation.Instant(pose),
	}.{

		## The animal at `stage`.
		instant : Animation.Timeline(pose), Animation.Stage -> Animation.Instant(pose)
		instant = |Animation.Timeline.(timeline), stage|
			match stage {
				Waiting => timeline.before
				Playing(steps_in) =>
					match timeline.frames.get(steps_in.to_u32().to_u64()) {
						Ok(frame) => frame
						Err(OutOfBounds) =>
							crash "Animation.Timeline.instant: a stage plays past the last frame, so the span it was staged by disagrees with its timeline"
					}
				Past(_) => timeline.after
			}
	}
}

Note : [First, Second, Third, Fourth, BeforeIt, AfterIt]

location_at : F64 -> Animation.Location
location_at = |across| {
	along: Along.metres(0.0),
	across: Across.metres(across),
	lift: Distance.zero,
}

## A timeline of four frames.
four_frames : Animation.Timeline(Note)
four_frames = Animation.Timeline.(
	{
		before: { pose: BeforeIt, location: location_at(-1.0) },
		frames: [
			{ pose: First, location: location_at(1.0) },
			{ pose: Second, location: location_at(2.0) },
			{ pose: Third, location: location_at(3.0) },
			{ pose: Fourth, location: location_at(4.0) },
		],
		after: { pose: AfterIt, location: location_at(99.0) },
	},
)

# Each step in shows its own frame.
expect
	[
		(0, First),
		(1, Second),
		(2, Third),
		(3, Fourth),
	].all(|(steps_in, note)| four_frames.instant(Playing(Steps.of(steps_in))).pose == note)

expect four_frames.instant(Waiting).pose == BeforeIt
expect four_frames.instant(Past(Steps.of(5))).pose == AfterIt
expect four_frames.instant(Waiting).location.across.to_metres() == -1.0
expect four_frames.instant(Playing(Steps.of(2))).location.across.to_metres() == 3.0
expect four_frames.instant(Past(Steps.of(5))).location.across.to_metres() == 99.0

start_location : Animation.Location
start_location = {
	along: Along.metres(10.0),
	across: Across.metres(20.0),
	lift: Distance.metres(30.0),
}

end_location : Animation.Location
end_location = {
	along: Along.metres(18.0),
	across: Across.metres(4.0),
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
	[location.along.to_metres(), location.across.to_metres(), location.lift.to_metres()]
}

expect
	[
		(0.0, [10.0, 20.0, 30.0]),
		(0.25, [12.0, 16.0, 34.0]),
		(1.0, [18.0, 4.0, 46.0]),
	].all(|(fraction, want)| location_numbers(fraction) == want)
