## These are Clock's checks and Steps': where a clock starts, that a step moves
## it on by one, what two clocks subtract to, how a duration adds, multiplies,
## wraps and compares, and how each reads as a float and as text.
app [main!] {
	lib: "../lib/main.roc",
}

import Clock
import Grade
import Steps

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

since_got : List(F64)
since_got = [
	Clock.at_step(9).minus(Clock.at_step(9)).to_f64(),
	Clock.at_step(9).minus(Clock.at_step(8)).to_f64(),
	Clock.at_step(9).minus(Clock.start).to_f64(),
	Clock.start.next().minus(Clock.start).to_f64(),
]

since_want : List(F64)
since_want = [0.0, 1.0, 9.0, 1.0]

sums_got : List(F64)
sums_got = [
	Steps.zero.to_f64(),
	Steps.one.to_f64(),
	Steps.of(5).plus(Steps.of(7)).to_f64(),
	Steps.of(37).times(3).to_f64(),
	Steps.of(37).times(0).to_f64(),
]

sums_want : List(F64)
sums_want = [0.0, 1.0, 12.0, 111.0, 0.0]

## A count of steps wrapped to a cycle of 120: at, just under and just over
## its ends.
wrapped : U32 -> F64
wrapped = |count| Steps.of(count).wrapped_to(Steps.of(120)).to_f64()

wrapped_got : List(F64)
wrapped_got = [
	wrapped(0),
	wrapped(1),
	wrapped(119),
	wrapped(120),
	wrapped(121),
	wrapped(239),
	wrapped(240),
]

wrapped_want : List(F64)
wrapped_want = [0.0, 1.0, 119.0, 0.0, 1.0, 119.0, 0.0]

order_got : List(Bool)
order_got = [
	Steps.of(3) > Steps.of(2),
	Steps.of(3) > Steps.of(3),
	Steps.of(3) >= Steps.of(3),
	Steps.of(2) >= Steps.of(3),
	Steps.of(2) < Steps.of(3),
	Steps.of(3) < Steps.of(3),
	Steps.of(3) == Steps.of(3),
	Steps.of(3) == Steps.of(4),
]

order_want : List(Bool)
order_want = [
	True,
	False,
	True,
	False,
	True,
	False,
	True,
	False,
]

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
		Grade.reals({
			name: "ck-since  ",
			got: since_got,
			want: since_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "st-sums   ",
			got: sums_got,
			want: sums_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "st-wrapped",
			got: wrapped_got,
			want: wrapped_want,
			tol: 0.0,
		}),
		Grade.bools({
			name: "st-order  ",
			got: order_got,
			want: order_want,
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
