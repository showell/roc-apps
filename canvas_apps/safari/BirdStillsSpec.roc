## These are BirdStills' checks: which drawing each pose gets, how many polygons
## and corners each drawing has, that each stays inside the unit frame and in
## the logo's two purples, and that a drawing no pose shows is still whole.
app [main!] {
	lib: "../lib/main.roc",
}

import BirdFlight
import BirdStills
import Grade
import Stills

poses : List(BirdFlight.Pose)
poses = [
	Perched,
	Side(WingsUp),
	Side(WingsDown),
	Away(WingsUp),
	Away(WingsDown),
	Diving,
]

stills : List(List(Stills.StillPoly))
stills = poses.map(BirdStills.pose_polys).append(BirdStills.toward_us)

## A still's polygon count, corner count and gradient count.
facts : List(Stills.StillPoly) -> List(I64)
facts = |polys| [
	polys.len().to_i64_wrap(),
	polys.fold(0, |sum, poly| sum + poly.pts.len().to_i64_wrap()),
	polys.fold(0, |sum, poly| sum + poly.grad.len().to_i64_wrap()),
]

table_got : List(I64)
table_got = stills.join_map(facts)

table_want : List(I64)
table_want = [
	6,
	21,
	0,
	6,
	21,
	0,
	6,
	21,
	0,
	4,
	17,
	0,
	4,
	17,
	0,
	6,
	22,
	0,
	6,
	21,
	0,
]

## The x of the first corner of a still's first polygon, which tells the
## drawings apart.
first_x : List(Stills.StillPoly) -> F64
first_x = |polys| {
	first_poly = polys.first() ?? crash "BirdStillsSpec: every still has polygons"
	first_pt = first_poly.pts.first() ?? crash "BirdStillsSpec: every polygon has corners"
	first_pt.x
}

## The y of the first corner of a still's first polygon, which tells apart
## the drawings that start at the same x.
first_y : List(Stills.StillPoly) -> F64
first_y = |polys| {
	first_poly = polys.first() ?? crash "BirdStillsSpec: every still has polygons"
	first_pt = first_poly.pts.first() ?? crash "BirdStillsSpec: every polygon has corners"
	first_pt.y
}

drawn_got : List(F64)
drawn_got = stills.join_map(|polys| [first_x(polys), first_y(polys)])

drawn_want : List(F64)
drawn_want = [
	-0.0344,
	0.5715,
	-0.45,
	0.42,
	-0.45,
	0.52,
	-0.06,
	0.58,
	-0.06,
	0.56,
	-0.2,
	0.9,
	-0.08,
	0.54,
]

## Whether every corner of a still is in the unit frame.
is_in_frame : List(Stills.StillPoly) -> Bool
is_in_frame = |polys|
	polys.all(
		|poly| poly.pts.all(|pt| pt.x >= -1.0 and pt.x <= 1.0 and pt.y >= 0.0 and pt.y <= 1.0),
	)

## Whether every polygon of a still is one of the logo's two purples.
is_logo_coloured : List(Stills.StillPoly) -> Bool
is_logo_coloured = |polys| polys.all(|poly| poly.color == 6368222 or poly.color == 8542181)

frame_got : List(Bool)
frame_got = List.concat(
	stills.map(is_in_frame),
	[
		is_in_frame([
			{
				color: 6368222,
				grad: [],
				pts: [{ x: 1.1, y: 0.5 }],
			},
		]),
	],
)

frame_want : List(Bool)
frame_want = [
	True,
	True,
	True,
	True,
	True,
	True,
	True,
	False,
]

colours_got : List(Bool)
colours_got = List.concat(
	stills.map(is_logo_coloured),
	[
		is_logo_coloured([
			{
				color: 0,
				grad: [],
				pts: [],
			},
		]),
	],
)

colours_want : List(Bool)
colours_want = frame_want

main! = |_args| {
	verdicts = [
		Grade.ints({
			name: "bs-table ",
			got: table_got,
			want: table_want,
		}),
		Grade.reals({
			name: "bs-drawn ",
			got: drawn_got,
			want: drawn_want,
			tol: 0.0,
		}),
		Grade.bools({
			name: "bs-frame ",
			got: frame_got,
			want: frame_want,
		}),
		Grade.bools({
			name: "bs-colour",
			got: colours_got,
			want: colours_want,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
