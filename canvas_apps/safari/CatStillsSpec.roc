## These are CatStills' checks: how many polygons, corners and gradient
## stops each pose's still has, and where four of them start.
app [main!] {
	lib: "../lib/main.roc",
}

import Cat
import CatStills
import Grade
import Stills

## A still's polygon count, corner count and gradient stop count.
facts : List(Stills.StillPoly) -> List(I64)
facts = |polys| [
	polys.len().to_i64_wrap(),
	polys.fold(0, |sum, poly| sum + poly.pts.len().to_i64_wrap()),
	polys.fold(0, |sum, poly| sum + poly.grad.len().to_i64_wrap()),
]

poses : List(Cat.Pose)
poses = [Rest, Stride, Frozen, Coil, Flight, Land, Collapse]

table_got : List(I64)
table_got = poses.join_map(|pose| facts(CatStills.pose_polys(pose)))

table_want : List(I64)
table_want = [
	46,
	2198,
	0,
	46,
	2198,
	0,
	47,
	2197,
	0,
	34,
	1715,
	0,
	34,
	1715,
	0,
	34,
	1715,
	0,
	34,
	1715,
	0,
]

## The x of the first corner of a pose's first polygon.
first_x : Cat.Pose -> F64
first_x = |pose| {
	first_poly = CatStills.pose_polys(pose).first()
		?? crash "CatStillsSpec: every pose has polygons"
	first_pt = first_poly.pts.first() ?? crash "CatStillsSpec: every polygon has corners"
	first_pt.x
}

spot_got : List(F64)
spot_got = [Coil, Flight, Land, Collapse].map(first_x)

spot_want : List(F64)
spot_want = [0.5062, 0.6873, 0.6467, 0.6377]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.ints({
			name: "cs-table",
			got: table_got,
			want: table_want,
		}),
		Grade.reals({
			name: "cs-spot ",
			got: spot_got,
			want: spot_want,
			tol: 0.0,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
