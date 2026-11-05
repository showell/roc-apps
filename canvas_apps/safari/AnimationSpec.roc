## These are Animation's checks: the stages of both rules at and around each
## boundary, a track's cuts on both sides, alternating looks across a cut, and
## every kind of path and ease.
app [main!] {
	lib: "../lib/main.roc",
}

import Animation
import Beats
import Fraction
import Grade
import Speed

## A stage as numbers, so a table can hold each tag beside its payload: 0 for
## waiting, 1 and its progress for playing, 2 and its metres for past.
stage_numbers : Animation.Stage -> List(F64)
stage_numbers = |stage|
	match stage {
		Waiting => [0.0, 0.0]
		Playing(progress) => [1.0, progress.to_f64()]
		Past(metres) => [2.0, metres]
	}

gap_stage : F64 -> Animation.Stage
gap_stage = |gap| Animation.over_gap({ starts_at: 60.0, ends_at: 20.0 }, gap)

over_gap_got : List(F64)
over_gap_got = [
	61.0,
	60.0,
	59.0,
	40.0,
	21.0,
	20.0,
	19.0,
].join_map(|gap| stage_numbers(gap_stage(gap)))

over_gap_want : List(F64)
over_gap_want = [
	0.0,
	0.0,
	0.0,
	0.0,
	1.0,
	0.025,
	1.0,
	0.5,
	1.0,
	0.975,
	2.0,
	0.0,
	2.0,
	1.0,
]

beat_stage : F64, F64 -> Animation.Stage
beat_stage = |gap, speed|
	Animation.over_beats(
		{ length: Beats.of(10.0), buffer: 3.0 },
		{ gap, speed: Speed.metres_a_step(speed) },
	)

over_beats_got : List(F64)
over_beats_got = [
	beat_stage(14.0, 1.0),
	beat_stage(13.0, 1.0),
	beat_stage(12.0, 1.0),
	beat_stage(8.0, 1.0),
	beat_stage(4.0, 1.0),
	beat_stage(3.0, 1.0),
	beat_stage(1.0, 1.0),
	beat_stage(23.0, 2.0),
	beat_stage(13.0, 2.0),
].join_map(stage_numbers)

over_beats_want : List(F64)
over_beats_want = [
	0.0,
	0.0,
	1.0,
	0.0,
	1.0,
	0.1,
	1.0,
	0.5,
	1.0,
	0.9,
	2.0,
	0.0,
	2.0,
	2.0,
	1.0,
	0.0,
	1.0,
	0.5,
]

## A rider at rest in the stretch is waiting, because no stretch is covered.
## One creeping inside it holds the animation at its start, and one creeping
## beyond the end is past.
still_got : List(F64)
still_got = [
	beat_stage(3.5, 0.0),
	beat_stage(3.0, 0.0),
	beat_stage(3.000001, 0.000001),
	beat_stage(3.000001, 0.000002),
	beat_stage(2.0, 0.000001),
].join_map(stage_numbers)

still_want : List(F64)
still_want = [
	0.0,
	0.0,
	2.0,
	0.0,
	1.0,
	0.0,
	1.0,
	0.95,
	2.0,
	1.0,
]

Note : [First, Second, Third, Fourth, BeforeIt, AfterIt]

at_spot : F64 -> Animation.Spot
at_spot = |across| {
	along: 0.0,
	across,
	lift: 0.0,
}

## A timeline ten beats long with both kinds of cut on each track.
cut_timeline : Animation.Timeline(Note)
cut_timeline = Animation.Timeline.(
	{
		length: Beats.of(10.0),
		before: { pose: BeforeIt, spot: at_spot(-1.0) },
		after: { pose: AfterIt, spot: at_spot(99.0) },
		looks: {
			stretches: [
				{ until: Through(Beats.of(2.0)), plays: Holds(First) },
				{ until: Before(Beats.of(5.0)), plays: Holds(Second) },
				{ until: Through(Beats.of(7.0)), plays: Holds(Third) },
			],
			finally: Holds(Fourth),
		},
		path: {
			stretches: [
				{ until: Before(Beats.of(4.0)), plays: StaysAt(at_spot(1.0)) },
				{ until: Through(Beats.of(8.0)), plays: StaysAt(at_spot(2.0)) },
			],
			finally: StaysAt(at_spot(3.0)),
		},
	},
)

looks_got : List(Bool)
looks_got = [
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
].map(|(beat, note)| cut_timeline.at_beat(Beats.of(beat)).pose == note)

looks_want : List(Bool)
looks_want = List.repeat(True, 11)

path_cuts_got : List(F64)
path_cuts_got = [
	0.0,
	3.99,
	4.0,
	4.01,
	7.99,
	8.0,
	8.01,
	10.0,
].map(|beat| cut_timeline.at_beat(Beats.of(beat)).spot.across)

path_cuts_want : List(F64)
path_cuts_want = [
	1.0,
	1.0,
	2.0,
	2.0,
	2.0,
	2.0,
	3.0,
	3.0,
]

## The instant at each stage: a stage's rest is the timeline's own, and playing
## reaches a beat by `progress` times the timeline's length.
stage_instant_got : List(Bool)
stage_instant_got = [
	cut_timeline.instant(Waiting).pose == BeforeIt,
	cut_timeline.instant(Past(5.0)).pose == AfterIt,
	cut_timeline.instant(Playing(Fraction.zero)).pose == First,
	cut_timeline.instant(Playing(Fraction.of(0.3))).pose == Second,
	cut_timeline.instant(Playing(Fraction.whole)).pose == Fourth,
]

stage_instant_want : List(Bool)
stage_instant_want = List.repeat(True, 5)

stage_spot_got : List(F64)
stage_spot_got = [
	cut_timeline.instant(Waiting).spot.across,
	cut_timeline.instant(Past(5.0)).spot.across,
	cut_timeline.instant(Playing(Fraction.of(0.5))).spot.across,
]

stage_spot_want : List(F64)
stage_spot_want = [-1.0, 99.0, 2.0]

## Looks that alternate through two cycles over eight beats and cross a cut at
## beat 3, on a timeline twelve beats long. Past its eight beats they go on
## alternating.
alternating_timeline : Animation.Timeline(Note)
alternating_timeline = {
	alternating = |up, down|
		Alternates({
			up,
			down,
			count: 2.0,
			over: Beats.of(8.0),
		})
	Animation.Timeline.(
		{
			length: Beats.of(12.0),
			before: { pose: BeforeIt, spot: at_spot(0.0) },
			after: { pose: AfterIt, spot: at_spot(0.0) },
			looks: {
				stretches: [{ until: Before(Beats.of(3.0)), plays: alternating(First, Second) }],
				finally: alternating(Third, Fourth),
			},
			path: { stretches: [], finally: StaysAt(at_spot(0.0)) },
		},
	)
}

alternating_got : List(Bool)
alternating_got = [
	(0.0, Second),
	(1.0, First),
	(2.5, Second),
	(3.0, Fourth),
	(5.0, Third),
	(7.0, Fourth),
	(9.0, Third),
	(11.0, Fourth),
].map(|(beat, note)| alternating_timeline.at_beat(Beats.of(beat)).pose == note)

alternating_want : List(Bool)
alternating_want = List.repeat(True, 8)

## A timeline four beats long that plays `path` between beats 2 and 4.
path_timeline : Animation.Path -> Animation.Timeline(Note)
path_timeline = |path|
	Animation.Timeline.(
		{
			length: Beats.of(4.0),
			before: { pose: BeforeIt, spot: at_spot(0.0) },
			after: { pose: AfterIt, spot: at_spot(0.0) },
			looks: { stretches: [], finally: Holds(First) },
			path: {
				stretches: [{ until: Before(Beats.of(2.0)), plays: StaysAt(at_spot(0.0)) }],
				finally: path,
			},
		},
	)

start_spot : Animation.Spot
start_spot = {
	along: 10.0,
	across: 20.0,
	lift: 30.0,
}

end_spot : Animation.Spot
end_spot = {
	along: 18.0,
	across: 4.0,
	lift: 46.0,
}

## The spot's three parts, at `beat` of `path`'s timeline.
spot_numbers : Animation.Path, F64 -> List(F64)
spot_numbers = |path, beat| {
	spot = path_timeline(path).at_beat(Beats.of(beat)).spot
	[
		spot.along,
		spot.across,
		spot.lift,
	]
}

line : Animation.Ease -> Animation.Line
line = |ease| {
	from: start_spot,
	to: end_spot,
	ease,
}

line_got : List(F64)
line_got = List.join([
	spot_numbers(Line(line(Steady)), 2.0),
	spot_numbers(Line(line(Steady)), 2.5),
	spot_numbers(Line(line(Steady)), 4.0),
	spot_numbers(Line(line(Smooth)), 2.5),
	spot_numbers(Line(line(ThreeQuarterPower)), 2.125),
])

line_want : List(F64)
line_want = [
	10.0,
	20.0,
	30.0,
	12.0,
	16.0,
	34.0,
	18.0,
	4.0,
	46.0,
	11.25,
	17.5,
	32.5,
	11.0,
	18.0,
	32.0,
]

arc_got : List(F64)
arc_got = {
	arc = Arc({ line: line(Steady), rise: 5.0 })
	smooth_arc = Arc({ line: line(Smooth), rise: 5.0 })
	List.join([
		spot_numbers(arc, 2.0),
		spot_numbers(arc, 3.0),
		spot_numbers(arc, 4.0),
		spot_numbers(smooth_arc, 2.5),
	])
}

## The rise follows the stretch itself, not the ease: a quarter of the way
## through, the smooth arc is at 0.75 of its rise whatever its line has done.
arc_want : List(F64)
arc_want = [
	10.0,
	20.0,
	30.0,
	14.0,
	12.0,
	43.0,
	18.0,
	4.0,
	46.0,
	11.25,
	17.5,
	36.25,
]

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "an-over-gap  ",
			got: over_gap_got,
			want: over_gap_want,
			tol: 0.000000001,
		}),
		Grade.reals({
			name: "an-over-beats",
			got: over_beats_got,
			want: over_beats_want,
			tol: 0.000000001,
		}),
		Grade.reals({
			name: "an-standstill",
			got: still_got,
			want: still_want,
			tol: 0.000000001,
		}),
		Grade.bools({
			name: "an-looks     ",
			got: looks_got,
			want: looks_want,
		}),
		Grade.reals({
			name: "an-path-cuts ",
			got: path_cuts_got,
			want: path_cuts_want,
			tol: 0.0,
		}),
		Grade.bools({
			name: "an-stage     ",
			got: stage_instant_got,
			want: stage_instant_want,
		}),
		Grade.reals({
			name: "an-stage-spot",
			got: stage_spot_got,
			want: stage_spot_want,
			tol: 0.0,
		}),
		Grade.bools({
			name: "an-alternates",
			got: alternating_got,
			want: alternating_want,
		}),
		Grade.reals({
			name: "an-line      ",
			got: line_got,
			want: line_want,
			tol: 0.000000001,
		}),
		Grade.reals({
			name: "an-arc       ",
			got: arc_got,
			want: arc_want,
			tol: 0.000000001,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
