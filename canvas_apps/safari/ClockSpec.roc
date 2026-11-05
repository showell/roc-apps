## These are Clock's checks: where it starts, that a step moves it on by one,
## and how it reads as a float and as text.
app [main!] {
	lib: "../lib/main.roc",
}

import Clock
import Grade

numbers_got : List(F64)
numbers_got = [
	Clock.start.to_f64(),
	Clock.start.next().to_f64(),
	Clock.start.next().next().to_f64(),
	Clock.at_step(5699).next().to_f64(),
]

numbers_want : List(F64)
numbers_want = [0.0, 1.0, 2.0, 5700.0]

same_got : List(Bool)
same_got = [
	Clock.at_step(0) == Clock.start,
	Clock.start.next() == Clock.at_step(1),
	Clock.start == Clock.at_step(1),
	Clock.at_step(7).next() == Clock.at_step(7),
]

same_want : List(Bool)
same_want = [True, True, False, False]

text_got : List(Bool)
text_got = [
	Clock.start.to_str() == "0",
	Clock.at_step(5700).to_str() == "5700",
]

text_want : List(Bool)
text_want = [True, True]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "ck-numbers",
			got: numbers_got,
			want: numbers_want,
			tol: 0.0,
		}),
		Grade.bools({
			name: "ck-same   ",
			got: same_got,
			want: same_want,
		}),
		Grade.bools({
			name: "ck-text   ",
			got: text_got,
			want: text_want,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
