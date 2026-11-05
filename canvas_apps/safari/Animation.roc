## How a critter plays out as the rider comes. Animation holds two ideas that
## know nothing of each other. A rule, `over_gap` or `over_beats`, turns where
## the rider is into a stage: waiting, playing, or past. A timeline turns a
## stage into a moment: how the critter looks and where it is. A timeline is
## data, so a critter's whole animation reads in one place, as a score.
##
## A timeline runs on two tracks, one for how the critter looks and one for
## where it goes, because the two change at different points. Each track's
## cuts are in beats from the start of the timeline. The moments before and
## after are the timeline's own, because a critter can rest somewhere no
## stretch of a track ever reaches.
##
## A spot is relative to the critter's home, which only its owner knows, so
## critters with different homes can share a timeline.
import Beats
import Easing
import Fraction
import Speed
import lib.Trig

Animation :: [].{

	## How the rider comes on a thing: the gap from the rider ahead to it, in
	## metres, and the rider's speed.
	Approach : { gap : F64, speed : Speed }

	## Where an animation has got to: not begun, playing and this far through,
	## or over, with the rider this many metres beyond its end.
	Stage : [
		Waiting,
		Playing(Fraction),
		Past(F64),
	]

	## A rider this slow is standing still.
	standstill : Speed
	standstill = Speed.metres_a_step(0.000001)

	## An animation that plays while the rider closes from `starts_at` metres
	## to `ends_at`, however fast. It is playing only strictly between the two,
	## so a critter is at rest at both ends.
	over_gap : { starts_at : F64, ends_at : F64 }, F64 -> Animation.Stage
	over_gap = |{ starts_at, ends_at }, gap| {
		progress = Fraction.clamp((starts_at - gap) / (starts_at - ends_at))
		if progress <= Fraction.zero {
			Waiting
		} else if progress >= Fraction.whole {
			Past(ends_at - gap)
		} else {
			Playing(progress)
		}
	}

	## An animation `length` long, played at a beat a step at the rider's
	## speed, that ends with the rider `buffer` metres short, however fast the
	## rider comes. It is playing from the moment the rider is that far away,
	## and a rider standing still inside that stretch holds it at its start.
	over_beats : { length : Beats, buffer : F64 }, Animation.Approach -> Animation.Stage
	over_beats = |{ length, buffer }, { gap, speed }| {
		gap_left = gap - buffer
		stretch = speed.distance_in(length)
		if gap_left <= 0.0 {
			Past(0.0 - gap_left)
		} else if gap_left > stretch {
			Waiting
		} else if speed <= standstill {
			Playing(Fraction.zero)
		} else {
			Playing(Fraction.clamp(1.0 - gap_left / stretch))
		}
	}

	## A place, relative to a critter's home. What `lift` measures is the
	## critter's own affair.
	Spot : {
		along : F64,
		across : F64,
		lift : F64,
	}

	## How a move spreads over its stretch.
	Ease : [Steady, Smooth, ThreeQuarterPower]

	## A move in a straight line.
	Line : {
		from : Animation.Spot,
		to : Animation.Spot,
		ease : Animation.Ease,
	}

	## Where a critter goes over one stretch of a timeline. An arc's top is
	## `rise` above its line, halfway through the stretch, however it is eased.
	Path : [
		StaysAt(Animation.Spot),
		Line(Animation.Line),
		Arc({ line : Animation.Line, rise : F64 }),
	]

	## How a critter looks over one stretch of a timeline: one pose held still,
	## or two taking turns, as a bird flaps its wings up and down or a cat puts
	## one foot in front of the other. Two poses take turns by following a sine
	## wave, which swings smoothly above and below zero: the critter shows `up`
	## while the wave is above zero, and `down` while it isn't. It goes through
	## `count` whole cycles in `over` beats counted from the timeline's start, so
	## a bird's wing beat runs on across a cut without restarting.
	Looks(pose) : [
		Holds(pose),
		Alternates(
			{
				up : pose,
				down : pose,
				count : F64,
				over : Beats,
			},
		),
	]

	## Where a stretch ends, in beats from the timeline's start: the cut's own
	## beat belongs to the stretch that ends `Through` it, and to the next one
	## after a stretch that ends `Before` it.
	Cut : [Through(Beats), Before(Beats)]

	## One stretch of a track, and what plays over it. It begins where the
	## stretch before it ended, or at the timeline's start.
	Stretch(kind) : { until : Animation.Cut, plays : kind }

	## One track of a timeline. The last stretch needs no cut, so a track always
	## has something to play: it runs to the timeline's end.
	Track(kind) : { stretches : List(Animation.Stretch(kind)), finally : kind }

	## A critter at one moment: how it looks, and where it is.
	Moment(pose) : { pose : pose, spot : Animation.Spot }

	## A whole animation: how many beats long it is, the critter at rest before
	## and after, how it looks, and where it goes.
	Timeline(pose) := {
		length : Beats,
		before : Animation.Moment(pose),
		after : Animation.Moment(pose),
		looks : Animation.Track(Animation.Looks(pose)),
		path : Animation.Track(Animation.Path),
	}.{

		## The critter at `stage`.
		moment : Animation.Timeline(pose), Animation.Stage -> Animation.Moment(pose)
		moment = |timeline, stage| {
			Animation.Timeline.(score) = timeline
			match stage {
				Waiting => score.before
				Playing(progress) => timeline.at_beat(score.length.portion(progress))
				Past(_) => score.after
			}
		}

		## The critter at `beat` of the animation.
		at_beat : Animation.Timeline(pose), Beats -> Animation.Moment(pose)
		at_beat = |Animation.Timeline.(score), beat| {
			looks = playing_at(score.looks, { beat, length: score.length })
			path = playing_at(score.path, { beat, length: score.length })
			fraction = Fraction.of(beat.minus(path.from).ratio_to(path.to.minus(path.from)))
			{
				pose: pose_of(looks.plays, beat),
				spot: path_spot(path.plays, fraction),
			}
		}
	}
}

## What a track plays over one stretch, and the beats it begins and ends at.
StretchPlaying(kind) : {
	plays : kind,
	from : Beats,
	to : Beats,
}

## What a track plays at `beat`, of a timeline `length` long.
playing_at : Animation.Track(kind), { beat : Beats, length : Beats } -> StretchPlaying(kind)
playing_at = |track, { beat, length }| {
	var $from = Beats.zero
	for stretch in track.stretches {
		to =
			match stretch.until {
				Through(cut) | Before(cut) => cut
			}
		if is_short_of(beat, stretch.until) {
			return {
				plays: stretch.plays,
				from: $from,
				to,
			}
		}
		$from = to
	}
	{
		plays: track.finally,
		from: $from,
		to: length,
	}
}

is_short_of : Beats, Animation.Cut -> Bool
is_short_of = |beat, cut|
	match cut {
		Through(last) => beat <= last
		Before(first_past) => beat < first_past
	}

## The pose `looks` shows at `beat` of the timeline.
pose_of : Animation.Looks(pose), Beats -> pose
pose_of = |looks, beat|
	match looks {
		Holds(pose) => pose
		Alternates(
			{
				up,
				down,
				count,
				over,
			},
		) =>
			if Trig.r_sin(beat.ratio_to(over) * count * Trig.two_pi) > 0.0 {
				up
			} else {
				down
			}
	}

## The spot `fraction` of the way through a stretch of `path`.
path_spot : Animation.Path, Fraction -> Animation.Spot
path_spot = |path, fraction|
	match path {
		StaysAt(spot) => spot
		Line(line) => line_spot(line, fraction)
		Arc({ line, rise }) => {
			on_line = line_spot(line, fraction)
			through = fraction.to_f64()
			{ ..on_line, lift: on_line.lift + rise * 4.0 * through * (1.0 - through) }
		}
	}

## The spot `fraction` of the way along `line`.
line_spot : Animation.Line, Fraction -> Animation.Spot
line_spot = |line, fraction| {
	eased = eased_fraction(line.ease, fraction)
	between = |start, end|
		Easing.lerp({
			from: start,
			to: end,
			fraction: eased,
		})
	{
		along: between(line.from.along, line.to.along),
		across: between(line.from.across, line.to.across),
		lift: between(line.from.lift, line.to.lift),
	}
}

eased_fraction : Animation.Ease, Fraction -> Fraction
eased_fraction = |ease, fraction|
	match ease {
		Steady => fraction
		Smooth => Easing.smoothstep(fraction)
		ThreeQuarterPower => Easing.three_quarter_power(fraction)
	}
