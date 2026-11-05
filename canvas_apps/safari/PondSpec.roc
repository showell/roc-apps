## These are Pond's checks: its sizes and colours, a few of its points, and
## that every duck is on the water, facing its own way.
app [main!] {
	lib: "../lib/main.roc",
}

import Along
import Across
import Grade
import Pond

size_got : List(I64)
size_got = [
	Pond.water_outline.len().to_i64_wrap(),
	Pond.bank.len().to_i64_wrap(),
	Pond.ducks.len().to_i64_wrap(),
	Pond.water_color,
	Pond.bank_color,
	Pond.duck_codepoint,
]

size_want : List(I64)
size_want = [7, 6, 6, 3112588, 12759680, 129414]

spot_got : List(F64)
spot_got = {
	water_first = Pond.water_outline.get(0) ?? crash "PondSpec: the water has a first point"
	water_fifth = Pond.water_outline.get(4) ?? crash "PondSpec: the water has a fifth point"
	bank_first = Pond.bank.get(0) ?? crash "PondSpec: the bank has a first point"
	[
		water_first.across.to_metres(),
		water_first.along.to_metres(),
		water_fifth.across.to_metres(),
		water_fifth.along.to_metres(),
		bank_first.across.to_metres(),
		bank_first.along.to_metres(),
		Pond.duck_height.to_metres(),
	]
}

spot_want : List(F64)
spot_want = [
	(-2.0),
	3.0,
	(-15.0),
	32.0,
	(-5.0),
	29.0,
	0.9,
]

inside : Pond.Duck -> Bool
inside = |duck|
	duck.at.across <= Across.metres(-1.0)
		and duck.at.across >= Across.metres(-31.0)
		and duck.at.along >= Along.metres(3.0)
		and duck.at.along <= Along.metres(32.0)

inside_got : List(Bool)
inside_got = Pond.ducks.map(inside)

inside_want : List(Bool)
inside_want = [True, True, True, True, True, True]

face_got : List(Bool)
face_got = Pond.ducks.map(|duck| duck.facing == FacesRight)

face_want : List(Bool)
face_want = [True, False, True, True, False, True]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.ints({
			name: "pd-size",
			got: size_got,
			want: size_want,
		}),
		Grade.reals({
			name: "pd-spot",
			got: spot_got,
			want: spot_want,
			tol: 0.0,
		}),
		Grade.bools({
			name: "pd-in  ",
			got: inside_got,
			want: inside_want,
		}),
		Grade.bools({
			name: "pd-face",
			got: face_got,
			want: face_want,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
