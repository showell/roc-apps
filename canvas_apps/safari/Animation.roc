## How a critter plays out as the rider comes. Animation holds two ideas that
## know nothing of each other. A rule, `over_gap` or `over_beats`, turns where
## the rider is into a stage: waiting, playing, or past. A timeline turns a
## stage into an instant: how the critter looks and where it is. A timeline is
## data, so a critter's whole animation reads in one place, as a score.
##
## A timeline runs on two tracks, one for how the critter looks and one for
## where it goes, because the two change at different points. Each track's
## cuts are in beats from the start of the timeline. The instants before and
## after are the timeline's own, because a critter can rest somewhere no
## stretch of a track ever reaches.
##
## A spot is relative to the critter's home, which only its owner knows, so
## critters with different homes can share a timeline.
import Across
import Along
import Beat
import Beats
import Distance
import Easing
import Fraction
import Speed
import lib.Trig

Animation :: [].{

	## How the rider comes on a thing: the gap from the rider ahead to it, and
	## the rider's speed.
	Approach : { gap : Distance, speed : Speed }

	## Where an animation has got to: not begun, playing and this far through,
	## or over, with the rider this far beyond its end.
	Stage : [Waiting, Playing(Fraction), Past(Distance)]

	## A rider this slow is standing still.
	standstill : Speed
	standstill = Speed.metres_a_step(0.000001)

	## An animation that plays while the rider closes from a gap of `starts_at`
	## to `ends_at`, however fast. It is playing only strictly between the two,
	## so a critter is at rest at both ends.
	over_gap : { starts_at : Distance, ends_at : Distance }, Distance -> Animation.Stage
	over_gap = |{ starts_at, ends_at }, gap| {
		progress = Fraction.clamp(starts_at.minus(gap).ratio_to(starts_at.minus(ends_at)))
		if progress <= Fraction.zero {
			Waiting
		} else if progress >= Fraction.whole {
			Past(ends_at.minus(gap))
		} else {
			Playing(progress)
		}
	}

	## An animation `length` long, played at a beat a step at the rider's
	## speed, that ends with the rider `buffer` short, however fast the rider
	## comes. It is playing from the instant the rider is that far away,
	## and a rider standing still inside that stretch holds it at its start.
	over_beats : { length : Beats, buffer : Distance }, Animation.Approach -> Animation.Stage
	over_beats = |{ length, buffer }, { gap, speed }| {
		gap_left = gap.minus(buffer)
		stretch = speed.distance_in(length)
		if gap_left <= Distance.zero {
			Past(gap_left.opposite())
		} else if gap_left > stretch {
			Waiting
		} else if speed <= standstill {
			Playing(Fraction.zero)
		} else {
			Playing(Fraction.clamp(1.0 - gap_left.ratio_to(stretch)))
		}
	}

	## A place, relative to a critter's home. How high it is, its `lift`, is in
	## the unit its owner states: `CatHeights` for a cat, `Distance` for a bird.
	Spot(lift) : {
		along : Along,
		across : Across,
		lift : lift,
	}

	## How a move spreads over its stretch.
	Ease : [Steady, Smooth, ThreeQuarterPower]

	## A move in a straight line.
	Line(lift) : {
		from : Animation.Spot(lift),
		to : Animation.Spot(lift),
		ease : Animation.Ease,
	}

	## Where a critter goes over one stretch of a timeline. An arc's top is
	## `rise` above its line, halfway through the stretch, however it is eased.
	Path(lift) : [
		StaysAt(Animation.Spot(lift)),
		Line(Animation.Line(lift)),
		Arc({ line : Animation.Line(lift), rise : lift }),
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
				count : U32,
				over : Beats,
			},
		),
	]

	## Where a stretch ends, in beats from the timeline's start: the cut's own
	## beat belongs to the stretch that ends `Through` it, and to the next one
	## after a stretch that ends `Before` it.
	Cut : [Through(Beat), Before(Beat)]

	## One stretch of a track, and what plays over it. It begins where the
	## stretch before it ended, or at the timeline's start.
	Stretch(kind) : { until : Animation.Cut, plays : kind }

	## One track of a timeline. The last stretch needs no cut, so a track always
	## has something to play: it runs to the timeline's end.
	Track(kind) : { stretches : List(Animation.Stretch(kind)), finally : kind }

	## A critter at one instant: how it looks, and where it is.
	Instant(pose, lift) : { pose : pose, spot : Animation.Spot(lift) }

	## A whole animation: how many beats long it is, the critter at rest before
	## and after, how it looks, and where it goes.
	Timeline(pose, lift) := {
		length : Beats,
		before : Animation.Instant(pose, lift),
		after : Animation.Instant(pose, lift),
		looks : Animation.Track(Animation.Looks(pose)),
		path : Animation.Track(Animation.Path(lift)),
	}.{

		## The critter at `stage`.
		instant : Animation.Timeline(pose, lift), Animation.Stage -> Animation.Instant(pose, lift)
			where [
				lift.plus : lift, lift -> lift,
				lift.minus : lift, lift -> lift,
				lift.times : lift, F64 -> lift,
			]
		instant = |timeline, stage| {
			Animation.Timeline.(score) = timeline
			match stage {
				Waiting => score.before
				Playing(progress) => timeline.at_beat(Beat.at(score.length.portion(progress)))
				Past(_) => score.after
			}
		}

		## The critter at `beat` of the animation.
		at_beat : Animation.Timeline(pose, lift), Beat -> Animation.Instant(pose, lift)
			where [
				lift.plus : lift, lift -> lift,
				lift.minus : lift, lift -> lift,
				lift.times : lift, F64 -> lift,
			]
		at_beat = |Animation.Timeline.(score), beat| {
			looks = playing_at(score.looks, { beat, length: score.length })
			path = playing_at(score.path, { beat, length: score.length })
			played = beat.beats_from(path.from)
			fraction = Fraction.of(played.ratio_to(path.to.beats_from(path.from)))
			{ pose: pose_of(looks.plays, beat), spot: path_spot(path.plays, fraction) }
		}
	}
}

## What a track plays over one stretch, and the beats it begins and ends at.
StretchPlaying(kind) : {
	plays : kind,
	from : Beat,
	to : Beat,
}

## What a track plays at `beat`, of a timeline `length` long.
playing_at : Animation.Track(kind), { beat : Beat, length : Beats } -> StretchPlaying(kind)
playing_at = |track, { beat, length }| {
	var $from = Beat.start
	for stretch in track.stretches {
		to =
			match stretch.until {
				Through(cut) | Before(cut) => cut
			}
		if is_short_of(beat, stretch.until) {
			return { plays: stretch.plays, from: $from, to }
		}
		$from = to
	}
	{
		plays: track.finally,
		from: $from,
		to: Beat.at(length),
	}
}

is_short_of : Beat, Animation.Cut -> Bool
is_short_of = |beat, cut|
	match cut {
		Through(last) => beat <= last
		Before(first_past) => beat < first_past
	}

## The pose `looks` shows at `beat` of the timeline.
pose_of : Animation.Looks(pose), Beat -> pose
pose_of = |looks, beat|
	match looks {
		Holds(pose) => pose
		Alternates({ up, down, count, over }) =>
			if Trig.r_sin(beat.from_start().ratio_to(over) * count.to_f64() * Trig.two_pi) > 0.0 {
				up
			} else {
				down
			}
	}

## The spot `fraction` of the way through a stretch of `path`.
path_spot : Animation.Path(lift), Fraction -> Animation.Spot(lift)
	where [
		lift.plus : lift, lift -> lift,
		lift.minus : lift, lift -> lift,
		lift.times : lift, F64 -> lift,
	]
path_spot = |path, fraction|
	match path {
		StaysAt(spot) => spot
		Line(line) => line_spot(line, fraction)
		Arc({ line, rise }) => {
			on_line = line_spot(line, fraction)
			through = fraction.to_f64()
			above_line = rise.times(4.0).times(through).times(1.0 - through)
			{ ..on_line, lift: on_line.lift.plus(above_line) }
		}
	}

## The spot `fraction` of the way along `line`.
line_spot : Animation.Line(lift), Fraction -> Animation.Spot(lift)
	where [
		lift.plus : lift, lift -> lift,
		lift.minus : lift, lift -> lift,
		lift.times : lift, F64 -> lift,
	]
line_spot = |line, fraction| {
	eased = eased_fraction(line.ease, fraction)
	between = |start, end|
		Easing.lerp({
			from: start,
			to: end,
			fraction: eased,
		})
	{
		along: Along.metres(between(line.from.along.to_metres(), line.to.along.to_metres())),
		across: Across.metres(between(line.from.across.to_metres(), line.to.across.to_metres())),
		lift: line.from.lift.plus(line.to.lift.minus(line.from.lift).times(eased.to_f64())),
	}
}

eased_fraction : Animation.Ease, Fraction -> Fraction
eased_fraction = |ease, fraction|
	match ease {
		Steady => fraction
		Smooth => Easing.smoothstep(fraction)
		ThreeQuarterPower => Easing.three_quarter_power(fraction)
	}

## Whether each of `got` is within a billionth of its `want`.
is_near : List(F64), List(F64) -> Bool
is_near = |got, want| {
	closeness = got.map2(want, |one, wanted| (one - wanted).abs() <= 0.000000001)
	got.len() == want.len() and closeness.all(|is_close| is_close)
}

## A stage as numbers, so a table can hold each tag beside its payload: 0 for
## waiting, 1 and its progress for playing, 2 and its metres for past.
stage_numbers : Animation.Stage -> List(F64)
stage_numbers = |stage|
	match stage {
		Waiting => [0.0, 0.0]
		Playing(progress) => [1.0, progress.to_f64()]
		Past(beyond) => [2.0, beyond.to_metres()]
	}

gap_stage : F64 -> Animation.Stage
gap_stage = |gap|
	Animation.over_gap(
		{ starts_at: Distance.metres(60.0), ends_at: Distance.metres(20.0) },
		Distance.metres(gap),
	)

expect
	[
		(61.0, [0.0, 0.0]),
		(60.0, [0.0, 0.0]),
		(59.0, [1.0, 0.025]),
		(40.0, [1.0, 0.5]),
		(21.0, [1.0, 0.975]),
		(20.0, [2.0, 0.0]),
		(19.0, [2.0, 1.0]),
	].all(|(gap, want)| is_near(stage_numbers(gap_stage(gap)), want))

beat_stage : F64, F64 -> Animation.Stage
beat_stage = |gap, speed|
	Animation.over_beats(
		{ length: Beats.of(10.0), buffer: Distance.metres(3.0) },
		{ gap: Distance.metres(gap), speed: Speed.metres_a_step(speed) },
	)

expect
	[
		(beat_stage(14.0, 1.0), [0.0, 0.0]),
		(beat_stage(13.0, 1.0), [1.0, 0.0]),
		(beat_stage(12.0, 1.0), [1.0, 0.1]),
		(beat_stage(8.0, 1.0), [1.0, 0.5]),
		(beat_stage(4.0, 1.0), [1.0, 0.9]),
		(beat_stage(3.0, 1.0), [2.0, 0.0]),
		(beat_stage(1.0, 1.0), [2.0, 2.0]),
		(beat_stage(23.0, 2.0), [1.0, 0.0]),
		(beat_stage(13.0, 2.0), [1.0, 0.5]),
	].all(|(stage, want)| is_near(stage_numbers(stage), want))

# A rider at rest in the stretch is waiting, because no stretch is covered.
# One creeping inside it holds the animation at its start, and one creeping
# beyond the end is past.
expect
	[
		(beat_stage(3.5, 0.0), [0.0, 0.0]),
		(beat_stage(3.0, 0.0), [2.0, 0.0]),
		(beat_stage(3.000001, 0.000001), [1.0, 0.0]),
		(beat_stage(3.000001, 0.000002), [1.0, 0.95]),
		(beat_stage(2.0, 0.000001), [2.0, 1.0]),
	].all(|(stage, want)| is_near(stage_numbers(stage), want))

Note : [First, Second, Third, Fourth, BeforeIt, AfterIt]

at_spot : F64 -> Animation.Spot(Distance)
at_spot = |across| {
	along: Along.metres(0.0),
	across: Across.metres(across),
	lift: Distance.zero,
}

## A timeline ten beats long with both kinds of cut on each track.
cut_timeline : Animation.Timeline(Note, Distance)
cut_timeline = Animation.Timeline.(
	{
		length: Beats.of(10.0),
		before: { pose: BeforeIt, spot: at_spot(-1.0) },
		after: { pose: AfterIt, spot: at_spot(99.0) },
		looks: {
			stretches: [
				{ until: Through(Beat.of(2.0)), plays: Holds(First) },
				{ until: Before(Beat.of(5.0)), plays: Holds(Second) },
				{ until: Through(Beat.of(7.0)), plays: Holds(Third) },
			],
			finally: Holds(Fourth),
		},
		path: {
			stretches: [
				{ until: Before(Beat.of(4.0)), plays: StaysAt(at_spot(1.0)) },
				{ until: Through(Beat.of(8.0)), plays: StaysAt(at_spot(2.0)) },
			],
			finally: StaysAt(at_spot(3.0)),
		},
	},
)

expect
	[
		(0.0, First),
		(1.99, First),
		(2.0, First),
		(2.01, Second),
		(4.99, Second),
		(5.0, Third),
		(5.01, Third),
		(6.99, Third),
		(7.0, Third),
		(7.01, Fourth),
		(10.0, Fourth),
	].all(|(beat, note)| cut_timeline.at_beat(Beat.of(beat)).pose == note)

expect
	[
		(0.0, 1.0),
		(3.99, 1.0),
		(4.0, 2.0),
		(4.01, 2.0),
		(7.99, 2.0),
		(8.0, 2.0),
		(8.01, 3.0),
		(10.0, 3.0),
	].all(|(beat, want)| cut_timeline.at_beat(Beat.of(beat)).spot.across.to_metres() == want)

# The instant at each stage: a stage's rest is the timeline's own, and playing
# reaches a beat by `progress` times the timeline's length.
expect cut_timeline.instant(Waiting).pose == BeforeIt
expect cut_timeline.instant(Past(Distance.metres(5.0))).pose == AfterIt
expect cut_timeline.instant(Playing(Fraction.zero)).pose == First
expect cut_timeline.instant(Playing(Fraction.of(0.3))).pose == Second
expect cut_timeline.instant(Playing(Fraction.whole)).pose == Fourth

expect cut_timeline.instant(Waiting).spot.across.to_metres() == -1.0
expect cut_timeline.instant(Past(Distance.metres(5.0))).spot.across.to_metres() == 99.0
expect cut_timeline.instant(Playing(Fraction.of(0.5))).spot.across.to_metres() == 2.0

## Looks that alternate through two cycles over eight beats and cross a cut at
## beat 3, on a timeline twelve beats long. Past its eight beats they go on
## alternating.
alternating_timeline : Animation.Timeline(Note, Distance)
alternating_timeline = {
	alternating = |up, down|
		Alternates({
			up,
			down,
			count: 2,
			over: Beats.of(8.0),
		})
	Animation.Timeline.(
		{
			length: Beats.of(12.0),
			before: { pose: BeforeIt, spot: at_spot(0.0) },
			after: { pose: AfterIt, spot: at_spot(0.0) },
			looks: {
				stretches: [{ until: Before(Beat.of(3.0)), plays: alternating(First, Second) }],
				finally: alternating(Third, Fourth),
			},
			path: { stretches: [], finally: StaysAt(at_spot(0.0)) },
		},
	)
}

expect
	[
		(0.0, Second),
		(1.0, First),
		(2.5, Second),
		(3.0, Fourth),
		(5.0, Third),
		(7.0, Fourth),
		(9.0, Third),
		(11.0, Fourth),
	].all(|(beat, note)| alternating_timeline.at_beat(Beat.of(beat)).pose == note)

## A timeline four beats long that plays `path` between beats 2 and 4.
path_timeline : Animation.Path(Distance) -> Animation.Timeline(Note, Distance)
path_timeline = |path|
	Animation.Timeline.(
		{
			length: Beats.of(4.0),
			before: { pose: BeforeIt, spot: at_spot(0.0) },
			after: { pose: AfterIt, spot: at_spot(0.0) },
			looks: { stretches: [], finally: Holds(First) },
			path: {
				stretches: [{ until: Before(Beat.of(2.0)), plays: StaysAt(at_spot(0.0)) }],
				finally: path,
			},
		},
	)

start_spot : Animation.Spot(Distance)
start_spot = {
	along: Along.metres(10.0),
	across: Across.metres(20.0),
	lift: Distance.metres(30.0),
}

end_spot : Animation.Spot(Distance)
end_spot = {
	along: Along.metres(18.0),
	across: Across.metres(4.0),
	lift: Distance.metres(46.0),
}

steady_arc : Animation.Path(Distance)
steady_arc = Arc({ line: line(Steady), rise: Distance.metres(5.0) })

smooth_arc : Animation.Path(Distance)
smooth_arc = Arc({ line: line(Smooth), rise: Distance.metres(5.0) })

## The spot's three parts, at `beat` of `path`'s timeline.
spot_numbers : Animation.Path(Distance), F64 -> List(F64)
spot_numbers = |path, beat| {
	spot = path_timeline(path).at_beat(Beat.of(beat)).spot
	[spot.along.to_metres(), spot.across.to_metres(), spot.lift.to_metres()]
}

line : Animation.Ease -> Animation.Line(Distance)
line = |ease| { from: start_spot, to: end_spot, ease }

expect
	[
		(spot_numbers(Line(line(Steady)), 2.0), [10.0, 20.0, 30.0]),
		(spot_numbers(Line(line(Steady)), 2.5), [12.0, 16.0, 34.0]),
		(spot_numbers(Line(line(Steady)), 4.0), [18.0, 4.0, 46.0]),
		(spot_numbers(Line(line(Smooth)), 2.5), [11.25, 17.5, 32.5]),
		(spot_numbers(Line(line(ThreeQuarterPower)), 2.125), [11.0, 18.0, 32.0]),
	].all(|(spot, want)| is_near(spot, want))

expect
	[
		(spot_numbers(steady_arc, 2.0), [10.0, 20.0, 30.0]),
		(spot_numbers(steady_arc, 3.0), [14.0, 12.0, 43.0]),
		(spot_numbers(steady_arc, 4.0), [18.0, 4.0, 46.0]),
		(spot_numbers(smooth_arc, 2.5), [11.25, 17.5, 36.25]),
	].all(|(spot, want)| is_near(spot, want))
