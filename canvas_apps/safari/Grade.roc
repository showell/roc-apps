# Grade -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
#
# THE SPEC APPS' VERDICT LINES. A spec app prints one line for each table it
# checks, and the lines are held byte for byte to safari-codex's
# `units/<Spec>.expected`: `<name> ok <count>`, `<name> BAD at <index>` where
# the table first goes wrong (with both values for integers), or
# `<name> BAD length <got> want <want>`. Each line ends in a newline, because a
# spec app's `echo!` writes none.

Grade :: [].{
	## Reals, each within `tol` of its want; a value that isn't finite fails.
	reals : { name : Str, got : List(F64), want : List(F64), tol : F64 } -> Str
	reals = |{ name, got, want, tol }|
		verdict({
			name,
			got: got.len(),
			want: want.len(),
			is_bad: |i| {
				g = real_at(got, i)
				is_infinite_or_nan(g) or (g - real_at(want, i)).abs() > tol
			},
			detail: |_| "",
		})

	## Reals, each within `tol` of its want scaled by the want's size (at
	## least 1); a value that isn't finite fails.
	rel : { name : Str, got : List(F64), want : List(F64), tol : F64 } -> Str
	rel = |{ name, got, want, tol }|
		verdict({
			name,
			got: got.len(),
			want: want.len(),
			is_bad: |i| {
				g = real_at(got, i)
				w = real_at(want, i)
				w_size = w.abs()
				scale = if 1.0 > w_size { 1.0 } else { w_size }
				is_infinite_or_nan(g) or (g - w).abs() > tol * scale
			},
			detail: |_| "",
		})

	## Integers, each equal to its want; a miss names both values.
	ints : { name : Str, got : List(I64), want : List(I64) } -> Str
	ints = |{ name, got, want }|
		verdict({
			name,
			got: got.len(),
			want: want.len(),
			is_bad: |i| int_at(got, i) != int_at(want, i),
			detail: |i| " got ${int_at(got, i).to_str()} want ${int_at(want, i).to_str()}",
		})

	## Bools, each equal to its want.
	bools : { name : Str, got : List(Bool), want : List(Bool) } -> Str
	bools = |{ name, got, want }|
		verdict({
			name,
			got: got.len(),
			want: want.len(),
			is_bad: |i| bool_at(got, i) != bool_at(want, i),
			detail: |_| "",
		})
}

## The line for a table of `got` values against `want`: `is_bad` is asked of
## each index while the lengths agree, and `detail` follows a miss's index.
verdict : { name : Str, got : U64, want : U64, is_bad : U64 -> Bool, detail : U64 -> Str } -> Str
verdict = |{ name, got, want, is_bad, detail }|
	if got != want {
		"${name} BAD length ${got.to_str()} want ${want.to_str()}\n"
	} else {
		match first_bad_from({ count: got, is_bad, at: 0 }) {
			BadAt(i) => "${name} BAD at ${i.to_str()}${detail(i)}\n"
			AllGood => "${name} ok ${got.to_str()}\n"
		}
	}

## The first index from `at` below `count` at which `is_bad` holds.
first_bad_from : { count : U64, is_bad : U64 -> Bool, at : U64 } -> [BadAt(U64), AllGood]
first_bad_from = |{ count, is_bad, at }|
	if at >= count {
		AllGood
	} else if is_bad(at) {
		BadAt(at)
	} else {
		first_bad_from({ count, is_bad, at: at + 1 })
	}

## The exponent's bits all set: an infinity or a NaN.
is_infinite_or_nan : F64 -> Bool
is_infinite_or_nan = |x| I64.bitwise_and(U64.to_i64_wrap(F64.to_bits(x)), 9223372036854775807) >= 9218868437227405312

real_at : List(F64), U64 -> F64
real_at = |l, i| l.get(i) ?? crash("Grade: an index past a table's end, which the length check rules out")

int_at : List(I64), U64 -> I64
int_at = |l, i| l.get(i) ?? crash("Grade: an index past a table's end, which the length check rules out")

bool_at : List(Bool), U64 -> Bool
bool_at = |l, i| l.get(i) ?? crash("Grade: an index past a table's end, which the length check rules out")
