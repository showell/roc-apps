## These are Animation's checks: the stages of both rules at and around each
## boundary, a track's cuts on both sides, alternating looks across a cut, and
## every kind of path and ease.
app [main!] {
	lib: "../lib/main.roc",
}

import Animation
import Grade
import Speed

## A stage as numbers, so a table can hold each tag beside its payload: 0 for
## waiting, 1 and its progress for playing, 2 and its metres for past.
stage_numbers : Animation.Stage -> List(F64)
stage_numbers = |stage|
	match stage {
		Waiting => [0.0, 0.0]
		Playing(progress) => [1.0, progress]
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

step_stage : F64, F64 -> Animation.Stage
step_stage = |gap, speed|
	Animation.over_steps(
		{ steps: 10.0, buffer: 3.0 },
		{ gap, speed: Speed.metres_a_step(speed) },
	)

over_steps_got : List(F64)
over_steps_got = [
	step_stage(14.0, 1.0),
	step_stage(13.0, 1.0),
	step_stage(12.0, 1.0),
	step_stage(8.0, 1.0),
	step_stage(4.0, 1.0),
	step_stage(3.0, 1.0),
	step_stage(1.0, 1.0),
	step_stage(23.0, 2.0),
	step_stage(13.0, 2.0),
].join_map(stage_numbers)

over_steps_want : List(F64)
over_steps_want = [
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
	step_stage(3.5, 0.0),
	step_stage(3.0, 0.0),
	step_stage(3.000001, 0.000001),
	step_stage(3.000001, 0.000002),
	step_stage(2.0, 0.000001),
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

## A timeline ten steps long with both kinds of cut on each track.
cut_timeline : Animation.Timeline(Note)
cut_timeline = Animation.Timeline.(
	{
		steps: 10.0,
		before: { pose: BeforeIt, spot: at_spot(-1.0) },
		after: { pose: AfterIt, spot: at_spot(99.0) },
		looks: {
			stretches: [
				{ until: Through(2.0), plays: Holds(First) },
				{ until: Before(5.0), plays: Holds(Second) },
				{ until: Through(7.0), plays: Holds(Third) },
			],
			finally: Holds(Fourth),
		},
		path: {
			stretches: [
				{ until: Before(4.0), plays: StaysAt(at_spot(1.0)) },
				{ until: Through(8.0), plays: StaysAt(at_spot(2.0)) },
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
].map(|(step, note)| cut_timeline.at_step(step).pose == note)

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
].map(|step| cut_timeline.at_step(step).spot.across)

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

## The moment at each stage: a stage's rest is the timeline's own, and playing
## reaches a step by `progress` times the timeline's length.
stage_moment_got : List(Bool)
stage_moment_got = [
	cut_timeline.moment(Waiting).pose == BeforeIt,
	cut_timeline.moment(Past(5.0)).pose == AfterIt,
	cut_timeline.moment(Playing(0.0)).pose == First,
	cut_timeline.moment(Playing(0.3)).pose == Second,
	cut_timeline.moment(Playing(1.0)).pose == Fourth,
]

stage_moment_want : List(Bool)
stage_moment_want = List.repeat(True, 5)

stage_spot_got : List(F64)
stage_spot_got = [
	cut_timeline.moment(Waiting).spot.across,
	cut_timeline.moment(Past(5.0)).spot.across,
	cut_timeline.moment(Playing(0.5)).spot.across,
]

stage_spot_want : List(F64)
stage_spot_want = [-1.0, 99.0, 2.0]

## A beat of two cycles over eight steps that crosses a cut at step 3, on a
## timeline twelve steps long. Past its eight steps it goes on beating.
beat_timeline : Animation.Timeline(Note)
beat_timeline = {
	beat = |up, down|
		Alternates({
			up,
			down,
			count: 2.0,
			over: 8.0,
		})
	Animation.Timeline.(
		{
			steps: 12.0,
			before: { pose: BeforeIt, spot: at_spot(0.0) },
			after: { pose: AfterIt, spot: at_spot(0.0) },
			looks: {
				stretches: [{ until: Before(3.0), plays: beat(First, Second) }],
				finally: beat(Third, Fourth),
			},
			path: { stretches: [], finally: StaysAt(at_spot(0.0)) },
		},
	)
}

beat_got : List(Bool)
beat_got = [
	(0.0, Second),
	(1.0, First),
	(2.5, Second),
	(3.0, Fourth),
	(5.0, Third),
	(7.0, Fourth),
	(9.0, Third),
	(11.0, Fourth),
].map(|(step, note)| beat_timeline.at_step(step).pose == note)

beat_want : List(Bool)
beat_want = List.repeat(True, 8)

## A timeline four steps long that plays `path` between steps 2 and 4.
path_timeline : Animation.Path -> Animation.Timeline(Note)
path_timeline = |path|
	Animation.Timeline.(
		{
			steps: 4.0,
			before: { pose: BeforeIt, spot: at_spot(0.0) },
			after: { pose: AfterIt, spot: at_spot(0.0) },
			looks: { stretches: [], finally: Holds(First) },
			path: {
				stretches: [{ until: Before(2.0), plays: StaysAt(at_spot(0.0)) }],
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

## The spot's three parts, `step` into `path`'s timeline.
spot_numbers : Animation.Path, F64 -> List(F64)
spot_numbers = |path, step| {
	spot = path_timeline(path).at_step(step).spot
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
			name: "an-over-steps",
			got: over_steps_got,
			want: over_steps_want,
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
			got: stage_moment_got,
			want: stage_moment_want,
		}),
		Grade.reals({
			name: "an-stage-spot",
			got: stage_spot_got,
			want: stage_spot_want,
			tol: 0.0,
		}),
		Grade.bools({
			name: "an-beat      ",
			got: beat_got,
			want: beat_want,
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
